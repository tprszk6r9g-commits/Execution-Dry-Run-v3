// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../src/RobinhoodExecutionGuardV2.sol";

interface Vm {
    function prank(address) external;
    function expectRevert(bytes4) external;
}

contract RegistryV2ForkTest {
    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    address constant OWNER = 0x8fC320c8582f812695b6f62b2b5d13B14475B955;

    function testGuardStartsPaused() public {
        RobinhoodExecutionGuardV2 g = new RobinhoodExecutionGuardV2(OWNER);
        vm.expectRevert(RobinhoodExecutionGuardV2.Paused.selector);
        g.requireExecutionAllowed();
    }

    function testOnlyOwnerCanUnpause() public {
        RobinhoodExecutionGuardV2 g = new RobinhoodExecutionGuardV2(OWNER);
        vm.expectRevert(RobinhoodExecutionGuardV2.NotOwner.selector);
        g.setPaused(false);

        vm.prank(OWNER);
        g.setPaused(false);
        g.requireExecutionAllowed();
    }
}
