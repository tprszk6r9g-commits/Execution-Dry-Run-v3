// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../src/RusteeCapabilityRegistry.sol";

contract RusteeCapabilityRegistryTest is Test {
    RusteeCapabilityRegistry r;
    address o = address(0xA11CE);
    address g = address(0xCAFE);
    address e = address(0xB0B);
    address e2 = address(0xBEEF);
    address nft = address(0x1001);
    address tba = address(0x2002);

    function setUp() public {
        r = new RusteeCapabilityRegistry(o, g);
        vm.prank(o);
        r.setExecutor(e, true);
    }

    function cap(uint256 n, uint32 u) internal view returns (RusteeCapabilityRegistry.Capability memory c) {
        c = RusteeCapabilityRegistry.Capability(
            nft,
            1,
            tba,
            2,
            keccak256("NVDA,STONKBROKER"),
            3,
            5e18,
            10e18,
            10,
            50,
            uint64(block.timestamp),
            uint64(block.timestamp + 1 hours),
            n,
            u,
            0,
            e,
            keccak256("signed-passport"),
            false
        );
    }

    function issue(uint256 n, uint32 u) internal returns (bytes32 id) {
        vm.prank(o);
        id = r.issue(cap(n, u));
    }

    function consume(bytes32 id, bytes32 a) internal {
        vm.prank(e);
        r.consume(id, a, nft, 1, tba, 2, block.chainid);
    }

    function testOneTime() public {
        bytes32 id = issue(1, 1);
        consume(id, keccak256("A"));
        assertFalse(r.isLifecycleActive(id));
    }

    function testActionReplayBlocked() public {
        bytes32 id = issue(1, 2);
        bytes32 a = keccak256("A");
        consume(id, a);
        vm.prank(e);
        vm.expectRevert(RusteeCapabilityRegistry.ActionAlreadyConsumed.selector);
        r.consume(id, a, nft, 1, tba, 2, block.chainid);
    }

    function testNonceReuseBlocked() public {
        issue(7, 2);
        RusteeCapabilityRegistry.Capability memory c = cap(7, 2);
        c.passportDigest = keccak256("different");
        vm.prank(o);
        vm.expectRevert(RusteeCapabilityRegistry.NonceAlreadyClaimed.selector);
        r.issue(c);
    }

    function testGuardianPauseOnly() public {
        vm.prank(g);
        r.setPaused(true);
        vm.prank(g);
        vm.expectRevert(RusteeCapabilityRegistry.NotOwner.selector);
        r.setPaused(false);
        vm.prank(o);
        r.setPaused(false);
    }

    function testDeauthorizedExecutorFails() public {
        bytes32 id = issue(1, 2);
        vm.prank(o);
        r.setExecutor(e, false);
        assertFalse(r.isConsumableBy(id, e));
        vm.prank(e);
        vm.expectRevert(RusteeCapabilityRegistry.WrongExecutor.selector);
        r.consume(id, keccak256("A"), nft, 1, tba, 2, block.chainid);
    }

    function testOtherExecutorCannotSteal() public {
        bytes32 id = issue(1, 2);
        vm.prank(o);
        r.setExecutor(e2, true);
        vm.prank(e2);
        vm.expectRevert(RusteeCapabilityRegistry.WrongExecutor.selector);
        r.consume(id, keccak256("A"), nft, 1, tba, 2, block.chainid);
    }

    function testNonceFloorInvalidates() public {
        bytes32 id = issue(1, 2);
        vm.prank(o);
        r.advanceNonceFloor(nft, 1, 2);
        assertFalse(r.isLifecycleActive(id));
    }

    function testExpiration() public {
        bytes32 id = issue(1, 2);
        vm.warp(block.timestamp + 1 hours + 1);
        vm.prank(e);
        vm.expectRevert(RusteeCapabilityRegistry.CapabilityExpired.selector);
        r.consume(id, keccak256("A"), nft, 1, tba, 2, block.chainid);
    }

    function testFuzzUses(uint8 u) public {
        vm.assume(u > 0);
        bytes32 id = issue(1, u);
        for (uint256 i; i < u; i++) {
            consume(id, keccak256(abi.encode(i)));
        }
        vm.prank(e);
        vm.expectRevert(RusteeCapabilityRegistry.CapabilityExhausted.selector);
        r.consume(id, keccak256("X"), nft, 1, tba, 2, block.chainid);
    }
}
