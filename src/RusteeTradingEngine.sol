// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC721EngineOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRusteeCapabilityRegistryV2 {
    struct Capability {
        address brokerNFT;
        uint256 tokenId;
        address tradingAccount;
        uint32 generation;
        bytes32 assetsRoot;
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

    function get(bytes32 id) external view returns (Capability memory);
    function consume(bytes32 id, bytes32 actionDigest, address tradingAccount, uint32 generation, uint256 chainId)
        external
        returns (uint32);
}

interface IRusteeEngineAccount {
    function executeEngineCall(address target, uint256 value, bytes calldata data) external returns (bytes memory);
}

/// @title RusteeTradingEngine
/// @notice Capability-gated atomic execution core for a future engine-authorized Trading TBA generation.
/// @dev Defaults paused. No current Rustee TBA is modified by deploying this contract.
contract RusteeTradingEngine {
    error NotAuthority();
    error NotGuardianOrAuthority();
    error Paused();
    error ZeroAddress();
    error RunnerNotAllowed();
    error AdapterNotAllowed();
    error AdapterHasNoCode();
    error WrongCapability();
    error WrongExecutor();
    error WrongTradingAccount();
    error WrongGeneration();
    error ActionNotAllowed();
    error AssetNotAllowed();
    error InvalidNotional();
    error DailyLimitExceeded();
    error TradeCountExceeded();
    error SlippageExceeded();
    error DeadlineExpired();
    error DeadlineBeyondCapability();
    error WrongIntentNonce();
    error EmptyCallData();
    error NativeValueDisabled();

    uint256 public constant ACTION_BUY = 1 << 0;
    uint256 public constant ACTION_SELL = 1 << 1;

    struct TradeIntent {
        bytes32 capabilityId;
        uint256 action;
        address asset;
        uint256 amountUnits;
        uint256 notionalUsd18;
        uint32 slippageBps;
        address adapter;
        uint256 value;
        bytes data;
        uint64 deadline;
        uint256 nonce;
    }

    struct DailyUsage {
        uint256 notionalUsd18;
        uint32 trades;
    }

    address public immutable brokerNFT;
    uint256 public immutable tokenId;
    address public immutable registry;
    address public immutable tradingAccount;
    uint32 public immutable generation;

    address public guardian;
    bool public paused = true;

    mapping(address => bool) public allowedRunners;
    mapping(address => bool) public allowedAdapters;
    mapping(bytes32 => uint256) public nextIntentNonce;
    mapping(bytes32 => mapping(uint256 => DailyUsage)) private _dailyUsage;

    bytes32 public auditHead;
    uint256 public auditSequence;

    event PauseChanged(bool paused, address indexed actor);
    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event RunnerAuthorization(address indexed runner, bool allowed);
    event AdapterAuthorization(address indexed adapter, bool allowed);
    event IntentExecuted(
        bytes32 indexed capabilityId,
        bytes32 indexed actionDigest,
        address indexed runner,
        uint256 action,
        address asset,
        uint256 notionalUsd18,
        uint256 nonce,
        bytes32 returnDataHash
    );
    event AuditAdvanced(uint256 indexed sequence, bytes32 indexed eventDigest, bytes32 auditHead);

    constructor(
        address brokerNFT_,
        uint256 tokenId_,
        address registry_,
        address tradingAccount_,
        uint32 generation_,
        address guardian_
    ) {
        if (
            brokerNFT_ == address(0) || registry_ == address(0) || tradingAccount_ == address(0)
                || guardian_ == address(0)
        ) revert ZeroAddress();
        brokerNFT = brokerNFT_;
        tokenId = tokenId_;
        registry = registry_;
        tradingAccount = tradingAccount_;
        generation = generation_;
        guardian = guardian_;
        _audit(keccak256(abi.encode("CONSTRUCTOR", brokerNFT_, tokenId_, registry_, tradingAccount_, generation_)));
    }

    modifier onlyAuthority() {
        if (msg.sender != authority()) revert NotAuthority();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    function authority() public view returns (address) {
        return IERC721EngineOwner(brokerNFT).ownerOf(tokenId);
    }

    function setGuardian(address next) external onlyAuthority {
        if (next == address(0)) revert ZeroAddress();
        address old = guardian;
        guardian = next;
        _audit(keccak256(abi.encode("GUARDIAN_CHANGED", old, next)));
        emit GuardianChanged(old, next);
    }

    /// @notice NFT holder may pause/unpause. Guardian may only pause.
    function setPaused(bool value) external {
        address nftOwner = authority();
        if (msg.sender != nftOwner) {
            if (msg.sender != guardian) revert NotGuardianOrAuthority();
            if (!value) revert NotAuthority();
        }
        paused = value;
        _audit(keccak256(abi.encode("PAUSE_CHANGED", value, msg.sender)));
        emit PauseChanged(value, msg.sender);
    }

    function setRunner(address runner, bool allowed) external onlyAuthority {
        if (runner == address(0)) revert ZeroAddress();
        allowedRunners[runner] = allowed;
        _audit(keccak256(abi.encode("RUNNER_AUTHORIZATION", runner, allowed)));
        emit RunnerAuthorization(runner, allowed);
    }

    function setAdapter(address adapter, bool allowed) external onlyAuthority {
        if (adapter == address(0)) revert ZeroAddress();
        if (allowed && adapter.code.length == 0) revert AdapterHasNoCode();
        allowedAdapters[adapter] = allowed;
        _audit(keccak256(abi.encode("ADAPTER_AUTHORIZATION", adapter, allowed)));
        emit AdapterAuthorization(adapter, allowed);
    }

    function dayBucket() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function dailyUsage(bytes32 capabilityId, uint256 bucket) external view returns (DailyUsage memory) {
        return _dailyUsage[capabilityId][bucket];
    }

    function assetLeaf(address asset) public pure returns (bytes32) {
        return keccak256(abi.encode(asset));
    }

    function verifyAsset(bytes32 root, address asset, bytes32[] calldata proof) public pure returns (bool) {
        bytes32 hash = assetLeaf(asset);
        for (uint256 i = 0; i < proof.length; ++i) {
            bytes32 p = proof[i];
            hash = hash < p ? keccak256(abi.encodePacked(hash, p)) : keccak256(abi.encodePacked(p, hash));
        }
        return hash == root;
    }

    function intentDigest(TradeIntent calldata intent) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                block.chainid,
                address(this),
                intent.capabilityId,
                intent.action,
                intent.asset,
                intent.amountUnits,
                intent.notionalUsd18,
                intent.slippageBps,
                intent.adapter,
                intent.value,
                keccak256(intent.data),
                intent.deadline,
                intent.nonce
            )
        );
    }

    /// @notice Validates, consumes the capability, and executes the account call atomically.
    /// @dev If the account/adapter call reverts, registry consumption and usage accounting revert as well.
    function executeIntent(TradeIntent calldata intent, bytes32[] calldata assetProof)
        external
        whenNotPaused
        returns (bytes memory result)
    {
        if (!allowedRunners[msg.sender]) revert RunnerNotAllowed();
        if (!allowedAdapters[intent.adapter]) revert AdapterNotAllowed();
        if (intent.adapter.code.length == 0) revert AdapterHasNoCode();
        if (intent.value != 0) revert NativeValueDisabled();
        if (intent.data.length == 0) revert EmptyCallData();
        if (block.timestamp > intent.deadline) revert DeadlineExpired();

        IRusteeCapabilityRegistryV2.Capability memory c = IRusteeCapabilityRegistryV2(registry).get(intent.capabilityId);

        if (c.brokerNFT != brokerNFT || c.tokenId != tokenId) revert WrongCapability();
        if (c.executor != address(this)) revert WrongExecutor();
        if (c.tradingAccount != tradingAccount) revert WrongTradingAccount();
        if (c.generation != generation) revert WrongGeneration();
        if ((c.actions & intent.action) == 0 || (intent.action != ACTION_BUY && intent.action != ACTION_SELL)) {
            revert ActionNotAllowed();
        }
        if (!verifyAsset(c.assetsRoot, intent.asset, assetProof)) revert AssetNotAllowed();
        if (intent.notionalUsd18 == 0 || intent.notionalUsd18 > c.maxTradeUsd18) revert InvalidNotional();
        if (intent.slippageBps > c.maxSlippageBps) revert SlippageExceeded();
        if (intent.deadline > c.validUntil) revert DeadlineBeyondCapability();

        uint256 expectedNonce = nextIntentNonce[intent.capabilityId];
        if (intent.nonce != expectedNonce) revert WrongIntentNonce();

        uint256 bucket = dayBucket();
        DailyUsage storage usage = _dailyUsage[intent.capabilityId][bucket];
        if (usage.trades >= c.maxTrades) revert TradeCountExceeded();
        if (usage.notionalUsd18 + intent.notionalUsd18 > c.maxDailyUsd18) revert DailyLimitExceeded();

        bytes32 digest = intentDigest(intent);

        // Registry consume first; any later execution failure reverts this state change atomically.
        IRusteeCapabilityRegistryV2(registry)
            .consume(intent.capabilityId, digest, tradingAccount, generation, block.chainid);

        usage.notionalUsd18 += intent.notionalUsd18;
        unchecked {
            usage.trades += 1;
            nextIntentNonce[intent.capabilityId] = expectedNonce + 1;
        }

        result = IRusteeEngineAccount(tradingAccount).executeEngineCall(intent.adapter, 0, intent.data);

        bytes32 returnHash = keccak256(result);
        bytes32 tradeHash = keccak256(abi.encode(intent.action, intent.asset, intent.notionalUsd18, intent.nonce));
        _audit(keccak256(abi.encode("INTENT_EXECUTED", intent.capabilityId, digest, msg.sender, tradeHash, returnHash)));
        _emitIntentExecuted(intent, digest, returnHash);
    }

    function _emitIntentExecuted(TradeIntent calldata intent, bytes32 digest, bytes32 returnHash) internal {
        emit IntentExecuted(
            intent.capabilityId,
            digest,
            msg.sender,
            intent.action,
            intent.asset,
            intent.notionalUsd18,
            intent.nonce,
            returnHash
        );
    }

    function _audit(bytes32 eventDigest) internal {
        unchecked {
            auditSequence += 1;
        }
        auditHead = keccak256(abi.encode(auditHead, auditSequence, eventDigest, block.chainid, address(this)));
        emit AuditAdvanced(auditSequence, eventDigest, auditHead);
    }
}
