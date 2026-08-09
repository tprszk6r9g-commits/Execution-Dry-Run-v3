// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract RusteeCapabilityRegistry {
    error NotOwner();
    error NotPendingOwner();
    error NotGuardianOrOwner();
    error Paused();
    error ZeroAddress();
    error InvalidCapability();
    error InvalidWindow();
    error WindowTooLong();
    error InvalidUses();
    error InvalidRiskLimits();
    error InvalidSlippage();
    error NonceTooLow();
    error NonceAlreadyClaimed();
    error CapabilityExists();
    error CapabilityIsRevoked();
    error CapabilityExpired();
    error CapabilityNotStarted();
    error CapabilityExhausted();
    error WrongExecutor();
    error WrongAction();
    error ActionAlreadyConsumed();
    error WrongGeneration();
    error WrongTradingAccount();
    error WrongChain();
    error WrongBroker();
    error WrongTokenId();

    uint64 public constant MAX_VALIDITY = 30 days;
    uint32 public constant MAX_USES = 10_000;
    bytes32 public constant SCHEMA_HASH = keccak256("RusteeCapabilityRegistry/v3.6B.1");

    struct Capability {
        address brokerNFT;
        uint256 tokenId;
        address tradingAccount;
        uint32 generation;
        bytes32 assetsHash;
        uint256 actions;
        uint256 maxTradeUsd18;
        uint256 maxDailyUsd18;
        uint32 maxTrades;
        uint32 maxSlippageBps;
        uint64 validAfter;
        uint64 validUntil;
        uint256 nonce;
        uint32 maxUses;
        uint32 uses;
        address executor;
        bytes32 passportDigest;
        bool revoked;
    }

    address public owner;
    address public pendingOwner;
    address public guardian;
    bool public paused;
    bytes32 public auditHead;
    uint256 public auditSequence;
    mapping(bytes32 => Capability) private _capabilities;
    mapping(address => mapping(uint256 => uint256)) public nonceFloor;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public nonceClaimed;
    mapping(address => bool) public authorizedExecutors;
    mapping(bytes32 => mapping(bytes32 => bool)) public actionConsumed;

    event OwnershipTransferStarted(address indexed owner, address indexed pendingOwner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event PauseChanged(bool paused, address indexed actor);
    event ExecutorAuthorization(address indexed executor, bool allowed);
    event NonceFloorAdvanced(address indexed brokerNFT, uint256 indexed tokenId, uint256 newFloor);
    event CapabilityIssued(
        bytes32 indexed id,
        address indexed brokerNFT,
        uint256 indexed tokenId,
        address tradingAccount,
        uint32 generation,
        uint256 nonce,
        uint32 maxUses,
        address executor,
        bytes32 passportDigest
    );
    event CapabilityRevoked(bytes32 indexed id);
    event CapabilityConsumed(
        bytes32 indexed id, bytes32 indexed actionDigest, address indexed executor, uint32 useNumber, bytes32 auditHead
    );
    event AuditAdvanced(uint256 indexed sequence, bytes32 indexed eventDigest, bytes32 auditHead);

    constructor(address initialOwner, address initialGuardian) {
        if (initialOwner == address(0) || initialGuardian == address(0)) revert ZeroAddress();
        owner = initialOwner;
        guardian = initialGuardian;
        _audit(keccak256(abi.encode("CONSTRUCTOR", initialOwner, initialGuardian, block.chainid)));
        emit OwnershipTransferred(address(0), initialOwner);
        emit GuardianChanged(address(0), initialGuardian);
    }
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    function transferOwnership(address next) external onlyOwner {
        if (next == address(0)) revert ZeroAddress();
        pendingOwner = next;
        _audit(keccak256(abi.encode("OWNERSHIP_TRANSFER_STARTED", owner, next)));
        emit OwnershipTransferStarted(owner, next);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert NotPendingOwner();
        address old = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        _audit(keccak256(abi.encode("OWNERSHIP_TRANSFER_ACCEPTED", old, msg.sender)));
        emit OwnershipTransferred(old, msg.sender);
    }

    function setGuardian(address next) external onlyOwner {
        if (next == address(0)) revert ZeroAddress();
        address old = guardian;
        guardian = next;
        _audit(keccak256(abi.encode("GUARDIAN_CHANGED", old, next)));
        emit GuardianChanged(old, next);
    }

    function setPaused(bool value) external {
        if (msg.sender != owner) {
            if (msg.sender != guardian) revert NotGuardianOrOwner();
            if (!value) revert NotOwner();
        }
        paused = value;
        _audit(keccak256(abi.encode("PAUSE_CHANGED", value, msg.sender)));
        emit PauseChanged(value, msg.sender);
    }

    function setExecutor(address e, bool allowed) external onlyOwner {
        if (e == address(0)) revert ZeroAddress();
        authorizedExecutors[e] = allowed;
        _audit(keccak256(abi.encode("EXECUTOR_AUTHORIZATION", e, allowed)));
        emit ExecutorAuthorization(e, allowed);
    }

    function advanceNonceFloor(address nft, uint256 tokenId, uint256 floor) external onlyOwner {
        uint256 old = nonceFloor[nft][tokenId];
        if (floor <= old) revert NonceTooLow();
        nonceFloor[nft][tokenId] = floor;
        _audit(keccak256(abi.encode("NONCE_FLOOR", nft, tokenId, old, floor)));
        emit NonceFloorAdvanced(nft, tokenId, floor);
    }

    function capabilityId(Capability memory c) public view returns (bytes32) {
        bytes32 identityHash = keccak256(abi.encode(c.brokerNFT, c.tokenId, c.tradingAccount, c.generation));
        bytes32 policyHash = keccak256(
            abi.encode(c.assetsHash, c.actions, c.maxTradeUsd18, c.maxDailyUsd18, c.maxTrades, c.maxSlippageBps)
        );
        bytes32 lifecycleHash =
            keccak256(abi.encode(c.validAfter, c.validUntil, c.nonce, c.maxUses, c.executor, c.passportDigest));
        return keccak256(abi.encode(SCHEMA_HASH, block.chainid, address(this), identityHash, policyHash, lifecycleHash));
    }

    function issue(Capability calldata input) external onlyOwner whenNotPaused returns (bytes32 id) {
        _validate(input);
        if (nonceClaimed[input.brokerNFT][input.tokenId][input.nonce]) revert NonceAlreadyClaimed();
        Capability memory c = input;
        c.uses = 0;
        c.revoked = false;
        id = capabilityId(c);
        if (_capabilities[id].brokerNFT != address(0)) revert CapabilityExists();
        nonceClaimed[c.brokerNFT][c.tokenId][c.nonce] = true;
        _capabilities[id] = c;
        _audit(keccak256(abi.encode("CAPABILITY_ISSUED", id, c.passportDigest, c.executor)));
        emit CapabilityIssued(
            id, c.brokerNFT, c.tokenId, c.tradingAccount, c.generation, c.nonce, c.maxUses, c.executor, c.passportDigest
        );
    }

    function revoke(bytes32 id) external onlyOwner {
        Capability storage c = _capabilities[id];
        if (c.brokerNFT == address(0)) revert InvalidCapability();
        if (!c.revoked) {
            c.revoked = true;
            _audit(keccak256(abi.encode("CAPABILITY_REVOKED", id)));
            emit CapabilityRevoked(id);
        }
    }

    function get(bytes32 id) external view returns (Capability memory) {
        return _capabilities[id];
    }

    function isLifecycleActive(bytes32 id) public view returns (bool) {
        Capability storage c = _capabilities[id];
        return c.brokerNFT != address(0) && !paused && !c.revoked && block.timestamp >= c.validAfter
            && block.timestamp <= c.validUntil && c.uses < c.maxUses && c.nonce >= nonceFloor[c.brokerNFT][c.tokenId];
    }

    function isConsumableBy(bytes32 id, address e) external view returns (bool) {
        Capability storage c = _capabilities[id];
        return isLifecycleActive(id) && e == c.executor && authorizedExecutors[e];
    }

    function consume(
        bytes32 id,
        bytes32 actionDigest,
        address nft,
        uint256 tokenId,
        address tradingAccount,
        uint32 generation,
        uint256 expectedChainId
    ) external whenNotPaused returns (uint32 useNumber) {
        Capability storage c = _capabilities[id];
        if (c.brokerNFT == address(0)) revert InvalidCapability();
        if (c.revoked) revert CapabilityIsRevoked();
        if (block.timestamp < c.validAfter) revert CapabilityNotStarted();
        if (block.timestamp > c.validUntil) revert CapabilityExpired();
        if (c.uses >= c.maxUses) revert CapabilityExhausted();
        if (c.nonce < nonceFloor[c.brokerNFT][c.tokenId]) revert NonceTooLow();
        if (msg.sender != c.executor || !authorizedExecutors[msg.sender]) revert WrongExecutor();
        if (actionDigest == bytes32(0)) revert WrongAction();
        if (actionConsumed[id][actionDigest]) revert ActionAlreadyConsumed();
        if (nft != c.brokerNFT) revert WrongBroker();
        if (tokenId != c.tokenId) revert WrongTokenId();
        if (tradingAccount != c.tradingAccount) revert WrongTradingAccount();
        if (generation != c.generation) revert WrongGeneration();
        if (expectedChainId != block.chainid) revert WrongChain();
        actionConsumed[id][actionDigest] = true;
        unchecked {
            c.uses += 1;
        }
        useNumber = c.uses;
        _audit(keccak256(abi.encode("CAPABILITY_CONSUMED", id, actionDigest, msg.sender, useNumber)));
        emit CapabilityConsumed(id, actionDigest, msg.sender, useNumber, auditHead);
    }

    function _validate(Capability calldata c) internal view {
        if (
            c.brokerNFT == address(0) || c.tradingAccount == address(0) || c.executor == address(0)
                || c.assetsHash == bytes32(0) || c.passportDigest == bytes32(0) || c.actions == 0
        ) revert InvalidCapability();
        if (c.validUntil <= c.validAfter || c.validUntil <= block.timestamp) revert InvalidWindow();
        if (c.validUntil - c.validAfter > MAX_VALIDITY) revert WindowTooLong();
        if (c.maxUses == 0 || c.maxUses > MAX_USES || c.maxTrades == 0) revert InvalidUses();
        if (c.maxTradeUsd18 == 0 || c.maxDailyUsd18 < c.maxTradeUsd18) revert InvalidRiskLimits();
        if (c.maxSlippageBps > 10_000) revert InvalidSlippage();
        if (c.nonce < nonceFloor[c.brokerNFT][c.tokenId]) revert NonceTooLow();
        if (!authorizedExecutors[c.executor]) revert WrongExecutor();
    }

    function _audit(bytes32 eventDigest) internal {
        unchecked {
            auditSequence += 1;
        }
        auditHead = keccak256(abi.encode(auditHead, auditSequence, eventDigest, block.chainid, address(this)));
        emit AuditAdvanced(auditSequence, eventDigest, auditHead);
    }
}
