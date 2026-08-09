// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RusteeProductionRunner.sol";
import "../src/RobinhoodRestrictedTradeAdapter.sol";
import "../src/EngineAuthorizedTradingAccount.sol";
import "../src/RusteeCapabilityRegistryV2.sol";
import "../src/RusteeTradingEngine.sol";
import "../src/vendor/ERC6551RegistryReference.sol";

contract MockNFTV374 {
    mapping(uint256 => address) public owners;

    function setOwner(uint256 id, address owner) external {
        owners[id] = owner;
    }

    function ownerOf(uint256 id) external view returns (address) {
        return owners[id];
    }
}

contract MockERC20V374 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory n, string memory s) {
        name = n;
        symbol = s;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "BAL");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 a = allowance[from][msg.sender];
        require(a >= amount, "ALLOW");
        require(balanceOf[from] >= amount, "BAL");
        if (a != type(uint256).max) allowance[from][msg.sender] = a - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MockVenueV374 {
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, address recipient)
        external
        returns (bytes32)
    {
        MockERC20V374(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        MockERC20V374(tokenOut).mint(recipient, amountOut);
        return keccak256("OK");
    }
}

contract MockEngineV374 is IRusteeTradingEngineRunner {
    uint256 public calls;
    address public lastCaller;
    TradeIntent public lastIntent;

    function executeIntent(TradeIntent calldata intent, bytes32[] calldata) external returns (bytes memory) {
        calls++;
        lastCaller = msg.sender;
        lastIntent = intent;
        return abi.encode(bytes32("ENGINE_OK"));
    }
}

contract RusteeProductionExecutionLayerTest is Test {
    uint256 constant TOKEN_ID = 1;
    uint32 constant GENERATION = 10;
    uint256 constant CHAIN = 4663;

    address owner = address(0xA11CE);
    address nextOwner = address(0xB0B);
    address guardian = address(0xCAFE);
    address operator = address(0xD00D);
    address attacker = address(0xBAD);
    address tba = address(0x6551);

    MockNFTV374 nft;
    MockEngineV374 mockEngine;
    MockERC20V374 tokenA;
    MockERC20V374 tokenB;
    MockVenueV374 venue;
    RobinhoodRestrictedTradeAdapter adapter;
    RusteeProductionRunner runner;

    function setUp() public {
        vm.chainId(CHAIN);
        nft = new MockNFTV374();
        nft.setOwner(TOKEN_ID, owner);
        mockEngine = new MockEngineV374();
        tokenA = new MockERC20V374("USDG", "USDG");
        tokenB = new MockERC20V374("RWA", "RWA");
        venue = new MockVenueV374();
        adapter = new RobinhoodRestrictedTradeAdapter(address(nft), TOKEN_ID, tba, GENERATION, CHAIN, guardian);
        runner =
            new RusteeProductionRunner(address(nft), TOKEN_ID, address(mockEngine), address(adapter), CHAIN, guardian);

        vm.startPrank(owner);
        adapter.setToken(address(tokenA), true);
        adapter.setToken(address(tokenB), true);
        adapter.setPair(address(tokenA), address(tokenB), true);
        adapter.setVenue(address(venue), true);
        adapter.setVenueSelector(address(venue), MockVenueV374.swap.selector, true);
        adapter.setPaused(false);
        runner.setOperator(operator, true);
        runner.setPaused(false);
        vm.stopPrank();

        tokenA.mint(tba, 1000 ether);
        vm.prank(tba);
        tokenA.approve(address(adapter), type(uint256).max);
    }

    function venueData(uint256 amountIn, uint256 amountOut) internal view returns (bytes memory) {
        return abi.encodeWithSelector(
            MockVenueV374.swap.selector, address(tokenA), address(tokenB), amountIn, amountOut, address(adapter)
        );
    }

    function adapterData(uint256 amountIn, uint256 minOut, uint256 actualOut) internal view returns (bytes memory) {
        return abi.encodeWithSelector(
            RobinhoodRestrictedTradeAdapter.executeTrade.selector,
            address(tokenA),
            address(tokenB),
            amountIn,
            minOut,
            address(venue),
            venueData(amountIn, actualOut)
        );
    }

    function intent(uint256 amountIn, uint256 minOut, uint256 actualOut)
        internal
        view
        returns (IRusteeTradingEngineRunner.TradeIntent memory i)
    {
        i = IRusteeTradingEngineRunner.TradeIntent({
            capabilityId: keccak256("CAP"),
            action: 1,
            asset: address(tokenB),
            amountUnits: minOut,
            notionalUsd18: 5 ether,
            slippageBps: 50,
            adapter: address(adapter),
            value: 0,
            data: adapterData(amountIn, minOut, actualOut),
            deadline: uint64(block.timestamp + 5 minutes),
            nonce: 0
        });
    }

    function testAdapterExecutesExactInputAndReturnsOutputToTBA() public {
        uint256 beforeA = tokenA.balanceOf(tba);
        vm.prank(tba);
        (uint256 out,) = adapter.executeTrade(
            address(tokenA), address(tokenB), 10 ether, 9 ether, address(venue), venueData(10 ether, 10 ether)
        );
        assertEq(out, 10 ether);
        assertEq(tokenA.balanceOf(tba), beforeA - 10 ether);
        assertEq(tokenB.balanceOf(tba), 10 ether);
        assertEq(tokenA.allowance(address(adapter), address(venue)), 0);
        assertEq(tokenA.balanceOf(address(adapter)), 0);
        assertEq(tokenB.balanceOf(address(adapter)), 0);
    }

    function testAdapterRejectsCallerOtherThanBoundTBA() public {
        vm.prank(attacker);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.NotTradingAccount.selector);
        adapter.executeTrade(
            address(tokenA), address(tokenB), 1 ether, 1 ether, address(venue), venueData(1 ether, 1 ether)
        );
    }

    function testAdapterRejectsUnlistedPair() public {
        vm.prank(owner);
        adapter.setPair(address(tokenA), address(tokenB), false);
        vm.prank(tba);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.PairNotAllowed.selector);
        adapter.executeTrade(
            address(tokenA), address(tokenB), 1 ether, 1 ether, address(venue), venueData(1 ether, 1 ether)
        );
    }

    function testAdapterRejectsUnlistedSelector() public {
        vm.prank(owner);
        adapter.setVenueSelector(address(venue), MockVenueV374.swap.selector, false);
        vm.prank(tba);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.SelectorNotAllowed.selector);
        adapter.executeTrade(
            address(tokenA), address(tokenB), 1 ether, 1 ether, address(venue), venueData(1 ether, 1 ether)
        );
    }

    function testAdapterRejectsInsufficientOutputAtomically() public {
        uint256 bal = tokenA.balanceOf(tba);
        vm.prank(tba);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.InsufficientOutput.selector);
        adapter.executeTrade(
            address(tokenA), address(tokenB), 10 ether, 11 ether, address(venue), venueData(10 ether, 10 ether)
        );
        assertEq(tokenA.balanceOf(tba), bal);
        assertEq(tokenB.balanceOf(tba), 0);
    }

    function testGuardianCanPauseButCannotUnpauseAdapter() public {
        vm.prank(guardian);
        adapter.setPaused(true);
        assertTrue(adapter.paused());
        vm.prank(guardian);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.NotAuthority.selector);
        adapter.setPaused(false);
    }

    function testNFTTransferMovesAdapterAuthority() public {
        nft.setOwner(TOKEN_ID, nextOwner);
        vm.prank(owner);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.NotAuthority.selector);
        adapter.setToken(address(tokenA), false);
        vm.prank(nextOwner);
        adapter.setToken(address(tokenA), false);
        assertFalse(adapter.allowedTokens(address(tokenA)));
    }

    function testRunnerOnlyAllowsOperator() public {
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(attacker);
        vm.expectRevert(RusteeProductionRunner.NotOperator.selector);
        runner.submit(intent(10 ether, 9 ether, 10 ether), proof);
    }

    function testRunnerBindsBuyAssetToTokenOut() public {
        bytes32[] memory proof = new bytes32[](0);
        IRusteeTradingEngineRunner.TradeIntent memory i = intent(10 ether, 9 ether, 10 ether);
        i.asset = address(tokenA);
        vm.prank(operator);
        vm.expectRevert(RusteeProductionRunner.IntentAssetMismatch.selector);
        runner.submit(i, proof);
    }

    function testRunnerBindsBuyAmountUnitsToMinOut() public {
        bytes32[] memory proof = new bytes32[](0);
        IRusteeTradingEngineRunner.TradeIntent memory i = intent(10 ether, 9 ether, 10 ether);
        i.amountUnits = 8 ether;
        vm.prank(operator);
        vm.expectRevert(RusteeProductionRunner.IntentAmountMismatch.selector);
        runner.submit(i, proof);
    }

    function testRunnerForwardsOnlyStandardizedIntentToExactEngine() public {
        bytes32[] memory proof = new bytes32[](0);
        vm.prank(operator);
        bytes memory r = runner.submit(intent(10 ether, 9 ether, 10 ether), proof);
        assertGt(r.length, 0);
        assertEq(mockEngine.calls(), 1);
        assertEq(mockEngine.lastCaller(), address(runner));
    }

    function testRunnerGuardianPauseOnly() public {
        vm.prank(guardian);
        runner.setPaused(true);
        assertTrue(runner.paused());
        vm.prank(guardian);
        vm.expectRevert(RusteeProductionRunner.NotAuthority.selector);
        runner.setPaused(false);
    }

    function testNFTTransferMovesRunnerAuthority() public {
        nft.setOwner(TOKEN_ID, nextOwner);
        vm.prank(owner);
        vm.expectRevert(RusteeProductionRunner.NotAuthority.selector);
        runner.setOperator(attacker, true);
        vm.prank(nextOwner);
        runner.setOperator(attacker, true);
        assertTrue(runner.operators(attacker));
    }

    function testFuzzAdapterRejectsOutputBelowMinimum(uint96 actualRaw, uint96 minRaw) public {
        uint256 actual = bound(uint256(actualRaw), 1, 100 ether);
        uint256 minOut = bound(uint256(minRaw), actual + 1, actual + 100 ether);
        vm.prank(tba);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.InsufficientOutput.selector);
        adapter.executeTrade(
            address(tokenA), address(tokenB), 1 ether, minOut, address(venue), venueData(1 ether, actual)
        );
    }
}

contract RusteeProductionExecutionIntegrationTest is Test {
    uint256 constant CHAIN = 4663;
    uint256 constant TOKEN_ID = 1;
    uint32 constant GENERATION = 10;
    address owner = address(0xA11CE);
    address guardian = address(0xCAFE);
    address operator = address(0xD00D);

    MockNFTV374 nft;
    ERC6551Registry registry6551;
    EngineAuthorizedTradingAccount implementation;
    EngineAuthorizedTradingAccount account;
    RusteeCapabilityRegistryV2 capabilityRegistry;
    RusteeTradingEngine engine;
    RobinhoodRestrictedTradeAdapter adapter;
    RusteeProductionRunner runner;
    MockERC20V374 usd;
    MockERC20V374 rwa;
    MockVenueV374 venue;

    function setUp() public {
        vm.chainId(CHAIN);
        nft = new MockNFTV374();
        nft.setOwner(TOKEN_ID, owner);

        registry6551 = new ERC6551Registry();
        implementation = new EngineAuthorizedTradingAccount();
        bytes32 salt = keccak256("RUSTEE_ENGINE_GEN_10_PROD_TEST");
        address a = registry6551.createAccount(address(implementation), salt, CHAIN, address(nft), TOKEN_ID);
        account = EngineAuthorizedTradingAccount(payable(a));

        capabilityRegistry = new RusteeCapabilityRegistryV2(address(nft), TOKEN_ID, guardian);
        engine = new RusteeTradingEngine(address(nft), TOKEN_ID, address(capabilityRegistry), a, GENERATION, guardian);
        adapter = new RobinhoodRestrictedTradeAdapter(address(nft), TOKEN_ID, a, GENERATION, CHAIN, guardian);
        runner = new RusteeProductionRunner(address(nft), TOKEN_ID, address(engine), address(adapter), CHAIN, guardian);

        usd = new MockERC20V374("USDG", "USDG");
        rwa = new MockERC20V374("RWA", "RWA");
        venue = new MockVenueV374();
        usd.mint(a, 100 ether);

        vm.startPrank(owner);
        account.setEngine(address(engine));
        account.setEngineTarget(address(adapter), true);
        capabilityRegistry.setExecutor(address(engine), true);
        engine.setRunner(address(runner), true);
        engine.setAdapter(address(adapter), true);

        adapter.setToken(address(usd), true);
        adapter.setToken(address(rwa), true);
        adapter.setPair(address(usd), address(rwa), true);
        adapter.setVenue(address(venue), true);
        adapter.setVenueSelector(address(venue), MockVenueV374.swap.selector, true);

        runner.setOperator(operator, true);

        account.execute(
            address(usd),
            0,
            abi.encodeWithSelector(MockERC20V374.approve.selector, address(adapter), type(uint256).max),
            0
        );

        adapter.setPaused(false);
        runner.setPaused(false);
        account.setEnginePaused(false);
        engine.setPaused(false);
        vm.stopPrank();
    }

    function _issue() internal returns (bytes32 id) {
        RusteeCapabilityRegistryV2.Capability memory c = RusteeCapabilityRegistryV2.Capability({
            brokerNFT: address(nft),
            tokenId: TOKEN_ID,
            tradingAccount: address(account),
            generation: GENERATION,
            assetsRoot: engine.assetLeaf(address(rwa)),
            actions: 1,
            maxTradeUsd18: 5 ether,
            maxDailyUsd18: 10 ether,
            maxTrades: 2,
            maxSlippageBps: 100,
            validAfter: uint64(block.timestamp),
            validUntil: uint64(block.timestamp + 1 hours),
            nonce: 1,
            maxUses: 2,
            uses: 0,
            executor: address(engine),
            passportDigest: keccak256("PROD"),
            revoked: false
        });
        vm.prank(owner);
        id = capabilityRegistry.issue(c);
    }

    function _intent(bytes32 id, uint256 actualOut, uint256 minOut)
        internal
        view
        returns (IRusteeTradingEngineRunner.TradeIntent memory i)
    {
        bytes memory venueCall = abi.encodeWithSelector(
            MockVenueV374.swap.selector, address(usd), address(rwa), 10 ether, actualOut, address(adapter)
        );
        bytes memory adapterCall = abi.encodeWithSelector(
            RobinhoodRestrictedTradeAdapter.executeTrade.selector,
            address(usd),
            address(rwa),
            10 ether,
            minOut,
            address(venue),
            venueCall
        );
        i = IRusteeTradingEngineRunner.TradeIntent({
            capabilityId: id,
            action: 1,
            asset: address(rwa),
            amountUnits: minOut,
            notionalUsd18: 4 ether,
            slippageBps: 50,
            adapter: address(adapter),
            value: 0,
            data: adapterCall,
            deadline: uint64(block.timestamp + 10 minutes),
            nonce: 0
        });
    }

    function testFullCapabilityRunnerEngineTBAAdapterVenuePath() public {
        bytes32 id = _issue();
        bytes32[] memory proof = new bytes32[](0);
        uint256 usdBefore = usd.balanceOf(address(account));
        vm.prank(operator);
        runner.submit(_intent(id, 10 ether, 9 ether), proof);

        assertEq(usd.balanceOf(address(account)), usdBefore - 10 ether);
        assertEq(rwa.balanceOf(address(account)), 10 ether);
        assertEq(account.state(), 2);
        assertEq(engine.nextIntentNonce(id), 1);
        assertEq(capabilityRegistry.get(id).uses, 1);
        assertEq(usd.allowance(address(adapter), address(venue)), 0);
    }

    function testVenueFailureRollsBackCapabilityNonceAndFunds() public {
        bytes32 id = _issue();
        bytes32[] memory proof = new bytes32[](0);
        uint256 usdBefore = usd.balanceOf(address(account));
        vm.prank(operator);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.InsufficientOutput.selector);
        runner.submit(_intent(id, 8 ether, 9 ether), proof);

        assertEq(usd.balanceOf(address(account)), usdBefore);
        assertEq(rwa.balanceOf(address(account)), 0);
        assertEq(account.state(), 1);
        assertEq(engine.nextIntentNonce(id), 0);
        assertEq(capabilityRegistry.get(id).uses, 0);
    }
}
