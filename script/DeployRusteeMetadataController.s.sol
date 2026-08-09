// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/RusteeMetadataController.sol";

contract DeployRusteeMetadataController is Script {
    function run() external returns (RusteeMetadataController controller) {
        address brokerNFT = vm.envAddress("RUSTEE_BROKER_NFT");
        uint256 tokenId = vm.envOr("RUSTEE_BROKER_TOKEN_ID", uint256(1));

        if (block.chainid == 4663) {
            string memory allowMainnet = vm.envOr("ALLOW_MAINNET_DEPLOY", string("NO"));
            require(keccak256(bytes(allowMainnet)) == keccak256(bytes("YES")), "MAINNET DEPLOYMENT BLOCKED");
        }

        vm.startBroadcast();
        controller = new RusteeMetadataController(brokerNFT, tokenId);
        vm.stopBroadcast();
    }
}
