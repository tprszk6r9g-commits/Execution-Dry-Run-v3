// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/EngineAuthorizedTradingAccount.sol";
import "../src/RusteeCapabilityRegistryV2.sol";
import "../src/RusteeTradingEngine.sol";

interface IERC6551RegistryV371 {
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);
    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address account);
}

interface IERC721OwnerDeployV371 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @notice Deploys a NEW engine-authorized Trading TBA generation. Leaves both engine layers PAUSED.
contract DeployEngineAuthorizedTradingGeneration is Script {
    address internal constant CANONICAL_6551_REGISTRY = 0x000000006551c19487814612e58FE06813775758;

    function run()
        external
        returns (
            EngineAuthorizedTradingAccount implementation,
            address tradingAccount,
            RusteeCapabilityRegistryV2 capabilityRegistry,
            RusteeTradingEngine engine
        )
    {
        address brokerNFT = vm.envAddress("RUSTEE_BROKER_NFT");
        uint256 tokenId = vm.envUint("RUSTEE_BROKER_TOKEN_ID");
        uint32 generation = uint32(vm.envUint("RUSTEE_ENGINE_GENERATION"));
        bytes32 salt = vm.envBytes32("RUSTEE_ENGINE_TBA_SALT");
        address guardian = vm.envAddress("RUSTEE_ENGINE_GUARDIAN");
        address runner = vm.envAddress("RUSTEE_ENGINE_RUNNER");
        address adapter = vm.envAddress("RUSTEE_ENGINE_ADAPTER");
        address expectedOwner = vm.envAddress("RUSTEE_NFT_OWNER");

        require(IERC721OwnerDeployV371(brokerNFT).ownerOf(tokenId) == expectedOwner, "NFT OWNER MISMATCH");
        if (block.chainid == 4663) {
            string memory allowMainnet = vm.envOr("ALLOW_MAINNET_DEPLOY", string("NO"));
            require(keccak256(bytes(allowMainnet)) == keccak256(bytes("YES")), "MAINNET DEPLOYMENT BLOCKED");
        }

        IERC6551RegistryV371 erc6551 = IERC6551RegistryV371(CANONICAL_6551_REGISTRY);

        vm.startBroadcast();
        implementation = new EngineAuthorizedTradingAccount();
        tradingAccount = erc6551.createAccount(address(implementation), salt, block.chainid, brokerNFT, tokenId);
        capabilityRegistry = new RusteeCapabilityRegistryV2(brokerNFT, tokenId, guardian);
        engine = new RusteeTradingEngine(
            brokerNFT, tokenId, address(capabilityRegistry), tradingAccount, generation, guardian
        );

        // Configuration is owner-only and therefore intentionally proves the broadcaster is the current NFT holder.
        EngineAuthorizedTradingAccount(payable(tradingAccount)).setEngine(address(engine));
        EngineAuthorizedTradingAccount(payable(tradingAccount)).setEngineTarget(adapter, true);
        capabilityRegistry.setExecutor(address(engine), true);
        engine.setRunner(runner, true);
        engine.setAdapter(adapter, true);
        vm.stopBroadcast();

        // SAFETY: EngineAuthorizedTradingAccount.enginePaused == true and RusteeTradingEngine.paused == true here.
    }
}
