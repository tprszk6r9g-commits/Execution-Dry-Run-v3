// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/EngineAuthorizedTradingAccount.sol";
import "../src/RusteeCapabilityRegistryV2.sol";
import "../src/RusteeTradingEngine.sol";
import "../src/vendor/ERC6551RegistryReference.sol";

contract MockBrokerNFTV371 {
    mapping(uint256 => address) public ownerOf;

    function setOwner(uint256 tokenId, address next) external {
        ownerOf[tokenId] = next;
    }
}

contract MockTradeAdapterV371 {
    uint256 public calls;
    bytes public lastData;
    bool public shouldRevert;

    function setShouldRevert(bool v) external {
        shouldRevert = v;
    }

    function trade(bytes calldata data) external returns (bytes32) {
        if (shouldRevert) revert("TRADE_REVERT");
        ++calls;
        lastData = data;
        return keccak256(data);
    }
}

contract DummyEngineV371 {
    function callAccount(address account, address target, bytes calldata data) external returns (bytes memory) {
        return EngineAuthorizedTradingAccount(payable(account)).executeEngineCall(target, 0, data);
    }
}

contract EngineAuthorizedTradingAccountTest is Test {
    ERC6551Registry refRegistry;
    EngineAuthorizedTradingAccount implementation;
    EngineAuthorizedTradingAccount account;
    MockBrokerNFTV371 nft;
    MockTradeAdapterV371 adapter;
    RusteeCapabilityRegistryV2 capabilityRegistry;
    RusteeTradingEngine engine;

    address owner = address(0xA11CE);
    address nextOwner = address(0xB0B01);
    address guardian = address(0xCAFE);
    address runner = address(0xB0B);
    address attacker = address(0xBAD);
    address asset = address(0x1001);
    uint256 tokenId = 1;
    uint32 generation = 6;
    bytes32 salt = keccak256("RUSTEE_ENGINE_TRADING_GEN_6");

    function setUp() public {
        nft = new MockBrokerNFTV371();
        nft.setOwner(tokenId, owner);
        adapter = new MockTradeAdapterV371();
        refRegistry = new ERC6551Registry();
        implementation = new EngineAuthorizedTradingAccount();
        address predicted = refRegistry.account(address(implementation), salt, block.chainid, address(nft), tokenId);
        address deployed =
            refRegistry.createAccount(address(implementation), salt, block.chainid, address(nft), tokenId);
        assertEq(deployed, predicted);
        account = EngineAuthorizedTradingAccount(payable(deployed));

        capabilityRegistry = new RusteeCapabilityRegistryV2(address(nft), tokenId, guardian);
        engine = new RusteeTradingEngine(
            address(nft), tokenId, address(capabilityRegistry), address(account), generation, guardian
        );

        vm.startPrank(owner);
        account.setEngine(address(engine));
        account.setEngineTarget(address(adapter), true);
        capabilityRegistry.setExecutor(address(engine), true);
        engine.setRunner(runner, true);
        engine.setAdapter(address(adapter), true);
        account.setEnginePaused(false);
        engine.setPaused(false);
        vm.stopPrank();
    }

    function _cap(uint256 nonce, uint256 actions, uint256 maxTrade, uint256 maxDaily, uint32 maxTrades)
        internal
        view
        returns (RusteeCapabilityRegistryV2.Capability memory c)
    {
        c = RusteeCapabilityRegistryV2.Capability({
            brokerNFT: address(nft),
            tokenId: tokenId,
            tradingAccount: address(account),
            generation: generation,
            assetsRoot: engine.assetLeaf(asset),
            actions: actions,
            maxTradeUsd18: maxTrade,
            maxDailyUsd18: maxDaily,
            maxTrades: maxTrades,
            maxSlippageBps: 50,
            validAfter: uint64(block.timestamp),
            validUntil: uint64(block.timestamp + 1 hours),
            nonce: nonce,
            maxUses: 20,
            uses: 0,
            executor: address(engine),
            passportDigest: keccak256(abi.encode("PASSPORT", nonce)),
            revoked: false
        });
    }

    function _issue(uint256 nonce) internal returns (bytes32 id) {
        RusteeCapabilityRegistryV2.Capability memory c = _cap(nonce, 3, 5e18, 10e18, 3);
        vm.prank(owner);
        id = capabilityRegistry.issue(c);
    }

    function _intent(bytes32 id, uint256 nonce, uint256 notional)
        internal
        view
        returns (RusteeTradingEngine.TradeIntent memory i)
    {
        i = RusteeTradingEngine.TradeIntent({
            capabilityId: id,
            action: 1,
            asset: asset,
            amountUnits: 123,
            notionalUsd18: notional,
            slippageBps: 25,
            adapter: address(adapter),
            value: 0,
            data: abi.encodeWithSelector(MockTradeAdapterV371.trade.selector, bytes("trade")),
            deadline: uint64(block.timestamp + 10 minutes),
            nonce: nonce
        });
    }

    function _execute(bytes32 id, uint256 nonce, uint256 notional) internal returns (bytes memory) {
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(runner);
        return engine.executeIntent(_intent(id, nonce, notional), proof);
    }

    function testERC6551BindingAndOwnerFollowNFT() public {
        (uint256 chainId, address tokenContract, uint256 boundId) = account.token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(nft));
        assertEq(boundId, tokenId);
        assertEq(account.owner(), owner);
        nft.setOwner(tokenId, nextOwner);
        assertEq(account.owner(), nextOwner);
    }

    function testOwnerRecoveryExecute() public {
        bytes memory data = abi.encodeWithSelector(MockTradeAdapterV371.trade.selector, bytes("owner-recovery"));
        vm.prank(owner);
        account.execute(address(adapter), 0, data, 0);
        assertEq(adapter.calls(), 1);
    }

    function testNonOwnerCannotRecoveryExecute() public {
        bytes memory data = abi.encodeWithSelector(MockTradeAdapterV371.trade.selector, bytes("x"));
        vm.prank(attacker);
        vm.expectRevert(EngineAuthorizedTradingAccount.NotOwner.selector);
        account.execute(address(adapter), 0, data, 0);
    }

    function testOnlyConfiguredEngineCanUseEnginePath() public {
        bytes memory data = abi.encodeWithSelector(MockTradeAdapterV371.trade.selector, bytes("x"));
        vm.prank(attacker);
        vm.expectRevert(EngineAuthorizedTradingAccount.NotEngine.selector);
        account.executeEngineCall(address(adapter), 0, data);
    }

    function testAccountTargetAllowlistIsIndependentDefense() public {
        DummyEngineV371 dummy = new DummyEngineV371();
        vm.prank(owner);
        account.setEngine(address(dummy));
        vm.prank(owner);
        account.setEnginePaused(false);
        MockTradeAdapterV371 unlisted = new MockTradeAdapterV371();
        vm.expectRevert(EngineAuthorizedTradingAccount.TargetNotAllowed.selector);
        dummy.callAccount(
            address(account), address(unlisted), abi.encodeWithSelector(unlisted.trade.selector, bytes("x"))
        );
    }

    function testChangingEngineAutomaticallyPausesAccountEnginePath() public {
        DummyEngineV371 dummy = new DummyEngineV371();
        vm.prank(owner);
        account.setEngine(address(dummy));
        assertTrue(account.enginePaused());
    }

    function testIntegratedCapabilityGatedExecutionThroughRealERC6551Account() public {
        bytes32 id = _issue(1);
        bytes memory result = _execute(id, 0, 4e18);
        assertGt(result.length, 0);
        assertEq(adapter.calls(), 1);
        assertEq(account.state(), 1);
        RusteeCapabilityRegistryV2.Capability memory c = capabilityRegistry.get(id);
        assertEq(c.uses, 1);
    }

    function testIntegratedTradeRevertRollsBackAccountEngineAndCapabilityState() public {
        bytes32 id = _issue(1);
        adapter.setShouldRevert(true);
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(runner);
        vm.expectRevert(bytes("TRADE_REVERT"));
        engine.executeIntent(_intent(id, 0, 4e18), proof);
        assertEq(account.state(), 0);
        assertEq(engine.nextIntentNonce(id), 0);
        RusteeCapabilityRegistryV2.Capability memory c = capabilityRegistry.get(id);
        assertEq(c.uses, 0);
    }

    function testAccountPauseBlocksEngineEvenIfEngineUnpaused() public {
        bytes32 id = _issue(1);
        vm.prank(owner);
        account.setEnginePaused(true);
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(runner);
        vm.expectRevert(EngineAuthorizedTradingAccount.EnginePaused.selector);
        engine.executeIntent(_intent(id, 0, 1e18), proof);
        RusteeCapabilityRegistryV2.Capability memory c = capabilityRegistry.get(id);
        assertEq(c.uses, 0);
    }

    function testAdapterMustBeAllowedByBothEngineAndAccount() public {
        MockTradeAdapterV371 second = new MockTradeAdapterV371();
        vm.prank(owner);
        engine.setAdapter(address(second), true);
        bytes32 id = _issue(1);
        RusteeTradingEngine.TradeIntent memory i = _intent(id, 0, 1e18);
        i.adapter = address(second);
        i.data = abi.encodeWithSelector(second.trade.selector, bytes("x"));
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(runner);
        vm.expectRevert(EngineAuthorizedTradingAccount.TargetNotAllowed.selector);
        engine.executeIntent(i, proof);
    }

    function testNFTTransferRemovesOldOwnerAccountConfigurationAuthority() public {
        nft.setOwner(tokenId, nextOwner);
        vm.prank(owner);
        vm.expectRevert(EngineAuthorizedTradingAccount.NotOwner.selector);
        account.setEnginePaused(true);
        vm.prank(nextOwner);
        account.setEnginePaused(true);
        assertTrue(account.enginePaused());
    }

    function testNFTTransferAlsoMovesRegistryAndEngineAuthority() public {
        nft.setOwner(tokenId, nextOwner);
        vm.prank(owner);
        vm.expectRevert(RusteeTradingEngine.NotGuardianOrAuthority.selector);
        engine.setPaused(true);
        vm.prank(nextOwner);
        engine.setPaused(true);
        assertTrue(engine.paused());

        vm.prank(owner);
        vm.expectRevert(RusteeCapabilityRegistryV2.NotAuthority.selector);
        capabilityRegistry.setExecutor(address(engine), false);
        vm.prank(nextOwner);
        capabilityRegistry.setExecutor(address(engine), false);
        assertFalse(capabilityRegistry.authorizedExecutors(address(engine)));
    }

    function testFuzzOwnerAlwaysFollowsNFT(address newOwner) public {
        vm.assume(newOwner != address(0));
        nft.setOwner(tokenId, newOwner);
        assertEq(account.owner(), newOwner);
    }

    function testFuzzEngineCannotExceedCapabilityTradeLimit(uint96 notionalRaw) public {
        uint256 notional = bound(uint256(notionalRaw), 5e18 + 1, 1000e18);
        bytes32 id = _issue(1);
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(runner);
        vm.expectRevert(RusteeTradingEngine.InvalidNotional.selector);
        engine.executeIntent(_intent(id, 0, notional), proof);
        assertEq(account.state(), 0);
    }
}
