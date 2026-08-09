// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRusteeBrokerNFTMetadata {
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function acceptOwnership() external;
    function transferOwnership(address newOwner) external;
    function setTokenURI(string calldata newURI) external;
    function freezeMetadata() external;
    function metadataFrozen() external view returns (bool);
}

/// @title RusteeMetadataController
/// @notice Makes Broker NFT metadata authority dynamically follow ownerOf(tokenId).
/// @dev The existing Broker NFT remains unchanged. Its Ownable admin is transferred
///      to this controller once. Every privileged action then re-resolves ownerOf.
contract RusteeMetadataController {
    error NotTokenOwner();
    error ZeroAddress();
    error AlreadyFrozen();
    error ControllerNotPendingOwner();
    error ControllerNotNFTAdmin();

    bytes32 public constant CONTROLLER_ID = keccak256("RusteeMetadataController/v3.6B.2");

    IRusteeBrokerNFTMetadata public immutable brokerNFT;
    uint256 public immutable tokenId;

    event NFTAdministrationAccepted(address indexed tokenOwner);
    event MetadataUpdated(address indexed tokenOwner, bytes32 indexed uriHash);
    event MetadataFrozenByTokenOwner(address indexed tokenOwner);
    event NFTAdministrationTransferStarted(address indexed tokenOwner, address indexed newAdmin);

    constructor(address brokerNFT_, uint256 tokenId_) {
        if (brokerNFT_ == address(0)) revert ZeroAddress();
        brokerNFT = IRusteeBrokerNFTMetadata(brokerNFT_);
        tokenId = tokenId_;
        // Proves the token exists and the supplied binding is real.
        brokerNFT.ownerOf(tokenId_);
    }

    modifier onlyTokenOwner() {
        if (msg.sender != brokerNFT.ownerOf(tokenId)) revert NotTokenOwner();
        _;
    }

    function currentTokenOwner() public view returns (address) {
        return brokerNFT.ownerOf(tokenId);
    }

    function isNFTAdmin() public view returns (bool) {
        return brokerNFT.owner() == address(this);
    }

    function isPendingNFTAdmin() public view returns (bool) {
        return brokerNFT.pendingOwner() == address(this);
    }

    /// @notice Step 2 of migration. The old NFT-contract admin must first call
    ///         BrokerNFT.transferOwnership(address(this)). The CURRENT NFT holder
    ///         then calls this function; the controller accepts Ownable2Step ownership.
    function acceptNFTAdministration() external onlyTokenOwner {
        if (!isPendingNFTAdmin()) revert ControllerNotPendingOwner();
        brokerNFT.acceptOwnership();
        emit NFTAdministrationAccepted(msg.sender);
    }

    function setTokenURI(string calldata newURI) external onlyTokenOwner {
        if (!isNFTAdmin()) revert ControllerNotNFTAdmin();
        if (brokerNFT.metadataFrozen()) revert AlreadyFrozen();
        brokerNFT.setTokenURI(newURI);
        emit MetadataUpdated(msg.sender, keccak256(bytes(newURI)));
    }

    function freezeMetadata() external onlyTokenOwner {
        if (!isNFTAdmin()) revert ControllerNotNFTAdmin();
        if (brokerNFT.metadataFrozen()) revert AlreadyFrozen();
        brokerNFT.freezeMetadata();
        emit MetadataFrozenByTokenOwner(msg.sender);
    }

    /// @notice Recovery/replacement path. Only the current Broker NFT holder can
    ///         move the NFT-contract admin away from this controller.
    function transferNFTAdministration(address newAdmin) external onlyTokenOwner {
        if (newAdmin == address(0)) revert ZeroAddress();
        if (!isNFTAdmin()) revert ControllerNotNFTAdmin();
        brokerNFT.transferOwnership(newAdmin);
        emit NFTAdministrationTransferStarted(msg.sender, newAdmin);
    }
}
