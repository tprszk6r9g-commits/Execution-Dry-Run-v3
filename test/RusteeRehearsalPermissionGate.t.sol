// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/RobinhoodRestrictedTradeAdapter.sol";
import "../src/RusteeProductionRunner.sol";
import "../src/EngineAuthorizedTradingAccount.sol";
import "../src/vendor/ERC6551RegistryReference.sol";

contract MockNFTV375 {
    mapping(uint256 => address) public owners;

    function setOwner(uint256 id, address owner) external {
        owners[id] = owner;
    }

    function ownerOf(uint256 id) external view returns (address) {
        return owners[id];
    }
}

contract MockERC20V375 {
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockVenueV375 {
    function exactTinySwap() external pure returns (bytes4) {
        return this.exactTinySwap.selector;
    }

    function forbiddenSwap() external pure returns (bytes4) {
        return this.forbiddenSwap.selector;
    }
}

contract MockEngineV375 {
    bool public paused = true;
}

contract RusteeRehearsalPermissionGateTest is Test {
    uint256 constant CHAIN = 4663;
    uint256 constant TOKEN_ID = 1;
    uint32 constant GENERATION = 10;

    address owner = address(0xA11CE);
    address guardian = address(0xCAFE);

    MockNFTV375 nft;
    EngineAuthorizedTradingAccount account;
    RobinhoodRestrictedTradeAdapter adapter;
    RusteeProductionRunner runner;
    MockEngineV375 engine;
    MockERC20V375 tokenIn;
    MockERC20V375 tokenOut;
    MockVenueV375 venue;

    function setUp() public {
        vm.chainId(CHAIN);
        nft = new MockNFTV375();
        nft.setOwner(TOKEN_ID, owner);
        ERC6551Registry reg = new ERC6551Registry();
        EngineAuthorizedTradingAccount impl = new EngineAuthorizedTradingAccount();
        account = EngineAuthorizedTradingAccount(
            payable(reg.createAccount(address(impl), keccak256("RUSTEE_V375_REHEARSAL"), CHAIN, address(nft), TOKEN_ID))
        );
        engine = new MockEngineV375();
        adapter =
            new RobinhoodRestrictedTradeAdapter(address(nft), TOKEN_ID, address(account), GENERATION, CHAIN, guardian);
        runner = new RusteeProductionRunner(address(nft), TOKEN_ID, address(engine), address(adapter), CHAIN, guardian);
        tokenIn = new MockERC20V375();
        tokenOut = new MockERC20V375();
        venue = new MockVenueV375();
    }

    function _stagePermissions() internal {
        vm.startPrank(owner);
        adapter.setToken(address(tokenIn), true);
        adapter.setToken(address(tokenOut), true);
        adapter.setPair(address(tokenIn), address(tokenOut), true);
        adapter.setVenue(address(venue), true);
        adapter.setVenueSelector(address(venue), MockVenueV375.exactTinySwap.selector, true);
        vm.stopPrank();
    }

    function testExactPermissionGateStaysPaused() public {
        _stagePermissions();
        assertTrue(adapter.allowedTokens(address(tokenIn)));
        assertTrue(adapter.allowedTokens(address(tokenOut)));
        assertTrue(adapter.allowedPairs(adapter.pairKey(address(tokenIn), address(tokenOut))));
        assertFalse(adapter.allowedPairs(adapter.pairKey(address(tokenOut), address(tokenIn))));
        assertTrue(adapter.allowedVenues(address(venue)));
        assertTrue(adapter.allowedVenueSelectors(address(venue), MockVenueV375.exactTinySwap.selector));
        assertFalse(adapter.allowedVenueSelectors(address(venue), MockVenueV375.forbiddenSwap.selector));
        assertTrue(adapter.paused());
        assertTrue(runner.paused());
    }

    function testExactAllowanceCanBeGrantedAndRevokedThroughGenerationTBA() public {
        _stagePermissions();
        uint256 tiny = 1e15;
        vm.prank(owner);
        account.execute(
            address(tokenIn), 0, abi.encodeWithSelector(MockERC20V375.approve.selector, address(adapter), tiny), 0
        );
        assertEq(tokenIn.allowance(address(account), address(adapter)), tiny);
        assertTrue(adapter.paused());
        assertTrue(runner.paused());

        vm.prank(owner);
        account.execute(
            address(tokenIn), 0, abi.encodeWithSelector(MockERC20V375.approve.selector, address(adapter), 0), 0
        );
        assertEq(tokenIn.allowance(address(account), address(adapter)), 0);
    }

    function testGuardianCannotGrantPermissions() public {
        vm.prank(guardian);
        vm.expectRevert(RobinhoodRestrictedTradeAdapter.NotAuthority.selector);
        adapter.setToken(address(tokenIn), true);
    }

    function testFuzzExactAllowanceRoundTrip(uint96 raw) public {
        uint256 tiny = bound(uint256(raw), 1, type(uint96).max);
        vm.prank(owner);
        account.execute(
            address(tokenIn), 0, abi.encodeWithSelector(MockERC20V375.approve.selector, address(adapter), tiny), 0
        );
        assertEq(tokenIn.allowance(address(account), address(adapter)), tiny);
        vm.prank(owner);
        account.execute(
            address(tokenIn), 0, abi.encodeWithSelector(MockERC20V375.approve.selector, address(adapter), 0), 0
        );
        assertEq(tokenIn.allowance(address(account), address(adapter)), 0);
    }
}
