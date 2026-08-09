// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/EngineAuthorizedTradingAccount.sol";
import "../src/RusteeCapabilityRegistryV2.sol";
import "../src/RusteeTradingEngine.sol";
import "../src/RusteeProductionRunner.sol";
import "../src/RobinhoodRestrictedTradeAdapter.sol";

interface IERC721ExecutionLayerOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @notice Adds the production execution layer to an EXISTING engine-authorized TBA generation.
/// @dev Does not create a new TBA. Runner and Adapter both remain PAUSED after deployment.
contract DeployProductionExecutionLayer is Script {
    function run() external returns (RobinhoodRestrictedTradeAdapter adapter, RusteeProductionRunner runner) {
        address brokerNFT = vm.envAddress("RUSTEE_BROKER_NFT");
        uint256 tokenId = vm.envUint("RUSTEE_BROKER_TOKEN_ID");
        address tradingAccount = vm.envAddress("RUSTEE_ENGINE_TBA");
        uint32 generation = uint32(vm.envUint("RUSTEE_ENGINE_GENERATION"));
        address registry = vm.envAddress("RUSTEE_CAPABILITY_REGISTRY_V2");
        address engineAddr = vm.envAddress("RUSTEE_TRADING_ENGINE");
        address guardian = vm.envAddress("RUSTEE_ENGINE_GUARDIAN");
        address operator = vm.envOr("RUSTEE_PRODUCTION_OPERATOR", address(0));
        address expectedOwner = vm.envAddress("RUSTEE_NFT_OWNER");

        require(block.chainid == 4663, "ROBINHOOD MAINNET ONLY");
        require(IERC721ExecutionLayerOwner(brokerNFT).ownerOf(tokenId) == expectedOwner, "NFT OWNER MISMATCH");

        RusteeTradingEngine engine = RusteeTradingEngine(engineAddr);
        require(engine.brokerNFT() == brokerNFT, "ENGINE NFT MISMATCH");
        require(engine.tokenId() == tokenId, "ENGINE TOKEN ID MISMATCH");
        require(engine.registry() == registry, "ENGINE REGISTRY MISMATCH");
        require(engine.tradingAccount() == tradingAccount, "ENGINE TBA MISMATCH");
        require(engine.generation() == generation, "ENGINE GENERATION MISMATCH");
        require(engine.paused(), "ENGINE MUST BE PAUSED");

        EngineAuthorizedTradingAccount account = EngineAuthorizedTradingAccount(payable(tradingAccount));
        require(account.owner() == expectedOwner, "TBA OWNER MISMATCH");
        require(account.engine() == engineAddr, "TBA ENGINE MISMATCH");
        require(account.enginePaused(), "TBA ENGINE PATH MUST BE PAUSED");

        vm.startBroadcast();
        adapter = new RobinhoodRestrictedTradeAdapter(
            brokerNFT, tokenId, tradingAccount, generation, block.chainid, guardian
        );
        runner = new RusteeProductionRunner(brokerNFT, tokenId, engineAddr, address(adapter), block.chainid, guardian);

        // Three independent allowlist edges must all agree.
        account.setEngineTarget(address(adapter), true);
        engine.setAdapter(address(adapter), true);
        engine.setRunner(address(runner), true);

        if (operator != address(0)) {
            runner.setOperator(operator, true);
        }
        vm.stopBroadcast();

        // SAFETY:
        // - Existing RusteeTradingEngine remains paused.
        // - Existing EngineAuthorizedTradingAccount engine path remains paused.
        // - New RusteeProductionRunner starts paused.
        // - New RobinhoodRestrictedTradeAdapter starts paused.
        // - No tokens, pairs, venues, or venue selectors are enabled by default.
    }
}
