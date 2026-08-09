// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import "../src/RusteeCapabilityRegistry.sol";

contract DeployCapabilityRegistry is Script {
    function run() external returns (RusteeCapabilityRegistry r) {
        address owner = vm.envAddress("RUSTEE_CAPABILITY_OWNER");
        address guardian = vm.envAddress("RUSTEE_CAPABILITY_GUARDIAN");
        if (block.chainid == 4663) {
            string memory x = vm.envOr("ALLOW_MAINNET_DEPLOY", string("NO"));
            require(keccak256(bytes(x)) == keccak256(bytes("YES")), "MAINNET DEPLOYMENT BLOCKED");
        }
        vm.startBroadcast();
        r = new RusteeCapabilityRegistry(owner, guardian);
        vm.stopBroadcast();
    }
}
