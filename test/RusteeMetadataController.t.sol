// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RusteeMetadataController.sol";

contract MockBrokerNFTMetadata {
    mapping(uint256 => address) internal _owners;
    address public owner;
    address public pendingOwner;
    bool public metadataFrozen;
    string public tokenURIValue;

    constructor(address admin, address tokenOwner, uint256 id) {
        owner = admin;
        _owners[id] = tokenOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not admin");
        _;
    }

    function ownerOf(uint256 id) external view returns (address) {
        return _owners[id];
    }

    function transferToken(uint256 id, address to) external {
        require(msg.sender == _owners[id], "not holder");
        _owners[id] = to;
    }

    function transferOwnership(address next) external onlyOwner {
        pendingOwner = next;
    }

    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "not pending");
        owner = msg.sender;
        pendingOwner = address(0);
    }

    function setTokenURI(string calldata uri) external onlyOwner {
        require(!metadataFrozen, "frozen");
        tokenURIValue = uri;
    }

    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
    }
}

contract RusteeMetadataControllerTest is Test {
    address oldAdmin = address(0xA11CE);
    address holder1 = address(0xB0B);
    address holder2 = address(0xCAFE);
    MockBrokerNFTMetadata nft;
    RusteeMetadataController controller;

    function setUp() public {
        nft = new MockBrokerNFTMetadata(oldAdmin, holder1, 1);
        controller = new RusteeMetadataController(address(nft), 1);
        vm.prank(oldAdmin);
        nft.transferOwnership(address(controller));
        vm.prank(holder1);
        controller.acceptNFTAdministration();
    }

    function testControllerBecomesAdmin() public view {
        assertEq(nft.owner(), address(controller));
        assertEq(controller.currentTokenOwner(), holder1);
        assertTrue(controller.isNFTAdmin());
    }

    function testCurrentHolderCanUpdateMetadata() public {
        vm.prank(holder1);
        controller.setTokenURI("data:application/json,{\"name\":\"Rustee\"}");
        assertEq(nft.tokenURIValue(), "data:application/json,{\"name\":\"Rustee\"}");
    }

    function testMetadataAuthorityAutomaticallyFollowsNFTTransfer() public {
        vm.prank(holder1);
        nft.transferToken(1, holder2);

        vm.prank(holder1);
        vm.expectRevert(RusteeMetadataController.NotTokenOwner.selector);
        controller.setTokenURI("old-holder-blocked");

        vm.prank(holder2);
        controller.setTokenURI("new-holder-authorized");
        assertEq(nft.tokenURIValue(), "new-holder-authorized");
    }

    function testOnlyCurrentHolderCanFreeze() public {
        vm.prank(holder1);
        nft.transferToken(1, holder2);

        vm.prank(holder1);
        vm.expectRevert(RusteeMetadataController.NotTokenOwner.selector);
        controller.freezeMetadata();

        vm.prank(holder2);
        controller.freezeMetadata();
        assertTrue(nft.metadataFrozen());
    }

    function testCurrentHolderCanStartControllerReplacement() public {
        address replacement = address(0xD00D);
        vm.prank(holder1);
        controller.transferNFTAdministration(replacement);
        assertEq(nft.pendingOwner(), replacement);
    }

    function testNonHolderCannotReplaceController() public {
        vm.prank(address(0xBAD));
        vm.expectRevert(RusteeMetadataController.NotTokenOwner.selector);
        controller.transferNFTAdministration(address(0xD00D));
    }

    function testFuzzMetadataAuthorityFollowsAnyNewHolder(address nextHolder) public {
        vm.assume(nextHolder != address(0));
        vm.assume(nextHolder != holder1);

        vm.prank(holder1);
        nft.transferToken(1, nextHolder);

        vm.prank(holder1);
        vm.expectRevert(RusteeMetadataController.NotTokenOwner.selector);
        controller.setTokenURI("old-holder-must-fail");

        vm.prank(nextHolder);
        controller.setTokenURI("new-holder-pass");
        assertEq(nft.tokenURIValue(), "new-holder-pass");
        assertEq(controller.currentTokenOwner(), nextHolder);
    }
}
