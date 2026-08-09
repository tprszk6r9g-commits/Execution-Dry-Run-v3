// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RusteeCapabilityRegistry
/// @notice Phase-2 lifecycle registry. It never executes trades or transfers assets.
contract RusteeCapabilityRegistry {
    error NotOwner(); error NotPendingOwner(); error Paused(); error ZeroAddress();
    error InvalidCapability(); error InvalidWindow(); error InvalidUses(); error NonceTooLow();
    error CapabilityExists(); error CapabilityRevoked(); error CapabilityExpired();
    error CapabilityNotStarted(); error CapabilityExhausted(); error WrongExecutor();
    error WrongAction(); error WrongGeneration(); error WrongTradingAccount(); error WrongChain();
    error WrongBroker(); error WrongTokenId();

    struct Capability {
        address brokerNFT; uint256 tokenId; address tradingAccount; uint32 generation;
        bytes32 assetsHash; uint256 actions; uint256 maxTradeUsd18; uint256 maxDailyUsd18;
        uint32 maxTrades; uint32 maxSlippageBps; uint64 validAfter; uint64 validUntil;
        uint256 nonce; uint32 maxUses; uint32 uses; address executor; bool revoked;
    }

    address public owner;
    address public pendingOwner;
    bool public paused;
    bytes32 public auditHead;
    mapping(bytes32 => Capability) private _capabilities;
    mapping(address => mapping(uint256 => uint256)) public nonceFloor;
    mapping(address => bool) public authorizedExecutors;

    event OwnershipTransferStarted(address indexed owner,address indexed pendingOwner);
    event OwnershipTransferred(address indexed oldOwner,address indexed newOwner);
    event PauseChanged(bool paused);
    event ExecutorAuthorization(address indexed executor,bool allowed);
    event NonceFloorAdvanced(address indexed brokerNFT,uint256 indexed tokenId,uint256 newFloor);
    event CapabilityIssued(bytes32 indexed id,address indexed brokerNFT,uint256 indexed tokenId,address tradingAccount,uint32 generation,uint256 nonce,uint32 maxUses,address executor);
    event CapabilityRevoked(bytes32 indexed id);
    event CapabilityConsumed(bytes32 indexed id,bytes32 indexed actionDigest,address indexed executor,uint32 useNumber,bytes32 auditHead);

    constructor(address initialOwner) {
        if(initialOwner==address(0)) revert ZeroAddress();
        owner=initialOwner; emit OwnershipTransferred(address(0),initialOwner);
    }
    modifier onlyOwner(){if(msg.sender!=owner)revert NotOwner();_;}
    modifier whenNotPaused(){if(paused)revert Paused();_;}

    function transferOwnership(address next) external onlyOwner {
        if(next==address(0))revert ZeroAddress(); pendingOwner=next;
        emit OwnershipTransferStarted(owner,next);
    }
    function acceptOwnership() external {
        if(msg.sender!=pendingOwner)revert NotPendingOwner();
        address old=owner; owner=msg.sender; pendingOwner=address(0);
        emit OwnershipTransferred(old,msg.sender);
    }
    function setPaused(bool v) external onlyOwner {paused=v;emit PauseChanged(v);}
    function setExecutor(address e,bool allowed) external onlyOwner {
        if(e==address(0))revert ZeroAddress(); authorizedExecutors[e]=allowed;
        emit ExecutorAuthorization(e,allowed);
    }
    function advanceNonceFloor(address nft,uint256 tokenId,uint256 floor) external onlyOwner {
        if(floor<=nonceFloor[nft][tokenId])revert NonceTooLow();
        nonceFloor[nft][tokenId]=floor;emit NonceFloorAdvanced(nft,tokenId,floor);
    }

    function capabilityId(Capability memory c) public view returns(bytes32){
        return keccak256(abi.encode(block.chainid,address(this),c.brokerNFT,c.tokenId,c.tradingAccount,
        c.generation,c.assetsHash,c.actions,c.maxTradeUsd18,c.maxDailyUsd18,c.maxTrades,
        c.maxSlippageBps,c.validAfter,c.validUntil,c.nonce,c.maxUses,c.executor));
    }

    function issue(Capability calldata input) external onlyOwner whenNotPaused returns(bytes32 id){
        if(input.brokerNFT==address(0)||input.tradingAccount==address(0))revert InvalidCapability();
        if(input.validUntil<=input.validAfter||input.validUntil<=block.timestamp)revert InvalidWindow();
        if(input.maxUses==0||input.maxTrades==0)revert InvalidUses();
        if(input.nonce<nonceFloor[input.brokerNFT][input.tokenId])revert NonceTooLow();
        if(input.executor!=address(0)&&!authorizedExecutors[input.executor])revert WrongExecutor();
        Capability memory c=input;c.uses=0;c.revoked=false;id=capabilityId(c);
        if(_capabilities[id].brokerNFT!=address(0))revert CapabilityExists();
        _capabilities[id]=c;
        emit CapabilityIssued(id,c.brokerNFT,c.tokenId,c.tradingAccount,c.generation,c.nonce,c.maxUses,c.executor);
    }

    function revoke(bytes32 id) external onlyOwner {
        Capability storage c=_capabilities[id];if(c.brokerNFT==address(0))revert InvalidCapability();
        c.revoked=true;emit CapabilityRevoked(id);
    }
    function get(bytes32 id) external view returns(Capability memory){return _capabilities[id];}
    function isActive(bytes32 id) public view returns(bool){
        Capability storage c=_capabilities[id];
        return c.brokerNFT!=address(0)&&!paused&&!c.revoked&&block.timestamp>=c.validAfter
        &&block.timestamp<=c.validUntil&&c.uses<c.maxUses&&c.nonce>=nonceFloor[c.brokerNFT][c.tokenId];
    }

    function consume(bytes32 id,bytes32 actionDigest,address nft,uint256 tokenId,address tradingAccount,
        uint32 generation,uint256 expectedChainId) external whenNotPaused returns(uint32 useNumber){
        Capability storage c=_capabilities[id];
        if(c.brokerNFT==address(0))revert InvalidCapability();
        if(c.revoked)revert CapabilityRevoked();
        if(block.timestamp<c.validAfter)revert CapabilityNotStarted();
        if(block.timestamp>c.validUntil)revert CapabilityExpired();
        if(c.uses>=c.maxUses)revert CapabilityExhausted();
        if(c.nonce<nonceFloor[c.brokerNFT][c.tokenId])revert NonceTooLow();
        if(!authorizedExecutors[msg.sender])revert WrongExecutor();
        if(c.executor!=address(0)&&c.executor!=msg.sender)revert WrongExecutor();
        if(actionDigest==bytes32(0))revert WrongAction();
        if(nft!=c.brokerNFT)revert WrongBroker(); if(tokenId!=c.tokenId)revert WrongTokenId();
        if(tradingAccount!=c.tradingAccount)revert WrongTradingAccount();
        if(generation!=c.generation)revert WrongGeneration();
        if(expectedChainId!=block.chainid)revert WrongChain();
        unchecked{c.uses+=1;} useNumber=c.uses;
        auditHead=keccak256(abi.encode(auditHead,id,actionDigest,msg.sender,useNumber,block.number));
        emit CapabilityConsumed(id,actionDigest,msg.sender,useNumber,auditHead);
    }
}
