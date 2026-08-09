// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC721AdapterOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC20Restricted {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title RobinhoodRestrictedTradeAdapter
/// @notice Fail-closed ERC-20 spot adapter for a single Rustee Generation/TBA on Robinhood Chain.
/// @dev This contract does not discover venues and ships with no venue/token/selector enabled.
///      The Broker NFT owner must explicitly enable every token, pair, venue and venue function selector.
///      It never accepts native value, always sends trade proceeds back to the bound TBA, and zeroes venue allowance.
contract RobinhoodRestrictedTradeAdapter {
    error NotAuthority();
    error NotGuardianOrAuthority();
    error NotTradingAccount();
    error Paused();
    error ZeroAddress();
    error WrongChain();
    error NativeValueDisabled();
    error Reentrancy();
    error TokenNotAllowed();
    error PairNotAllowed();
    error VenueNotAllowed();
    error VenueHasNoCode();
    error SelectorNotAllowed();
    error InvalidTrade();
    error TokenCallFailed();
    error FeeOnTransferUnsupported();
    error InsufficientOutput();
    error VenueCallFailed(bytes reason);

    address public immutable brokerNFT;
    uint256 public immutable tokenId;
    address public immutable tradingAccount;
    uint32 public immutable generation;
    uint256 public immutable expectedChainId;

    address public guardian;
    bool public paused = true;
    uint256 private _lock = 1;

    struct TradeParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address venue;
        bytes venueData;
    }

    mapping(address => bool) public allowedTokens;
    mapping(bytes32 => bool) public allowedPairs;
    mapping(address => bool) public allowedVenues;
    mapping(address => mapping(bytes4 => bool)) public allowedVenueSelectors;

    event PauseChanged(bool paused, address indexed actor);
    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event TokenAuthorization(address indexed token, bool allowed);
    event PairAuthorization(address indexed tokenIn, address indexed tokenOut, bool allowed);
    event VenueAuthorization(address indexed venue, bool allowed);
    event VenueSelectorAuthorization(address indexed venue, bytes4 indexed selector, bool allowed);
    event TradeExecuted(
        address indexed tradingAccount,
        address indexed tokenIn,
        address indexed tokenOut,
        address venue,
        uint256 amountIn,
        uint256 amountOut,
        bytes4 venueSelector
    );

    constructor(
        address brokerNFT_,
        uint256 tokenId_,
        address tradingAccount_,
        uint32 generation_,
        uint256 expectedChainId_,
        address guardian_
    ) {
        if (brokerNFT_ == address(0) || tradingAccount_ == address(0) || guardian_ == address(0)) {
            revert ZeroAddress();
        }
        brokerNFT = brokerNFT_;
        tokenId = tokenId_;
        tradingAccount = tradingAccount_;
        generation = generation_;
        expectedChainId = expectedChainId_;
        guardian = guardian_;
    }

    receive() external payable {
        revert NativeValueDisabled();
    }

    function authority() public view returns (address) {
        return IERC721AdapterOwner(brokerNFT).ownerOf(tokenId);
    }

    modifier onlyAuthority() {
        if (msg.sender != authority()) revert NotAuthority();
        _;
    }

    modifier nonReentrant() {
        if (_lock != 1) revert Reentrancy();
        _lock = 2;
        _;
        _lock = 1;
    }

    function pairKey(address tokenIn, address tokenOut) public pure returns (bytes32) {
        return keccak256(abi.encode(tokenIn, tokenOut));
    }

    function setGuardian(address next) external onlyAuthority {
        if (next == address(0)) revert ZeroAddress();
        address old = guardian;
        guardian = next;
        emit GuardianChanged(old, next);
    }

    /// @notice NFT holder may pause/unpause. Guardian may only pause.
    function setPaused(bool value) external {
        address nftOwner = authority();
        if (msg.sender != nftOwner) {
            if (msg.sender != guardian) revert NotGuardianOrAuthority();
            if (!value) revert NotAuthority();
        }
        paused = value;
        emit PauseChanged(value, msg.sender);
    }

    function setToken(address token, bool allowed) external onlyAuthority {
        if (token == address(0)) revert ZeroAddress();
        if (allowed && token.code.length == 0) revert TokenCallFailed();
        allowedTokens[token] = allowed;
        emit TokenAuthorization(token, allowed);
    }

    function setPair(address tokenIn, address tokenOut, bool allowed) external onlyAuthority {
        if (tokenIn == address(0) || tokenOut == address(0) || tokenIn == tokenOut) revert InvalidTrade();
        allowedPairs[pairKey(tokenIn, tokenOut)] = allowed;
        emit PairAuthorization(tokenIn, tokenOut, allowed);
    }

    function setVenue(address venue, bool allowed) external onlyAuthority {
        if (venue == address(0)) revert ZeroAddress();
        if (allowed && venue.code.length == 0) revert VenueHasNoCode();
        allowedVenues[venue] = allowed;
        emit VenueAuthorization(venue, allowed);
    }

    function setVenueSelector(address venue, bytes4 selector, bool allowed) external onlyAuthority {
        if (venue == address(0) || selector == bytes4(0)) revert InvalidTrade();
        if (allowed && !allowedVenues[venue]) revert VenueNotAllowed();
        allowedVenueSelectors[venue][selector] = allowed;
        emit VenueSelectorAuthorization(venue, selector, allowed);
    }

    /// @notice Execute one exact-input ERC-20 trade through an explicitly authorized venue function.
    /// @dev venueData MUST encode the adapter itself as the venue recipient, so output arrives here for balance checks.
    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address venue,
        bytes calldata venueData
    ) external payable nonReentrant returns (uint256 amountOut, bytes memory venueResult) {
        TradeParams memory p = TradeParams(tokenIn, tokenOut, amountIn, minAmountOut, venue, bytes(venueData));
        return _executeTrade(p);
    }

    function _executeTrade(TradeParams memory p) internal returns (uint256 amountOut, bytes memory venueResult) {
        if (msg.value != 0) revert NativeValueDisabled();
        if (block.chainid != expectedChainId) revert WrongChain();
        if (paused) revert Paused();
        if (msg.sender != tradingAccount) revert NotTradingAccount();
        if (
            p.tokenIn == address(0) || p.tokenOut == address(0) || p.tokenIn == p.tokenOut || p.amountIn == 0
                || p.minAmountOut == 0 || p.venueData.length < 4
        ) revert InvalidTrade();
        if (!allowedTokens[p.tokenIn] || !allowedTokens[p.tokenOut]) revert TokenNotAllowed();
        if (!allowedPairs[pairKey(p.tokenIn, p.tokenOut)]) revert PairNotAllowed();
        if (!allowedVenues[p.venue]) revert VenueNotAllowed();
        if (p.venue.code.length == 0) revert VenueHasNoCode();

        bytes4 selector = _selector(p.venueData);
        if (!allowedVenueSelectors[p.venue][selector]) revert SelectorNotAllowed();

        uint256 inStart = IERC20Restricted(p.tokenIn).balanceOf(address(this));
        uint256 outStart = IERC20Restricted(p.tokenOut).balanceOf(address(this));

        _safeTransferFrom(p.tokenIn, tradingAccount, address(this), p.amountIn);
        if (IERC20Restricted(p.tokenIn).balanceOf(address(this)) - inStart != p.amountIn) {
            revert FeeOnTransferUnsupported();
        }

        _forceApprove(p.tokenIn, p.venue, p.amountIn);
        (bool ok, bytes memory ret) = p.venue.call(p.venueData);
        if (!ok) revert VenueCallFailed(ret);
        _forceApprove(p.tokenIn, p.venue, 0);

        uint256 outAfter = IERC20Restricted(p.tokenOut).balanceOf(address(this));
        if (outAfter < outStart) revert InsufficientOutput();
        amountOut = outAfter - outStart;
        if (amountOut < p.minAmountOut) revert InsufficientOutput();

        if (amountOut != 0) _safeTransfer(p.tokenOut, tradingAccount, amountOut);

        uint256 refund = IERC20Restricted(p.tokenIn).balanceOf(address(this)) - inStart;
        if (refund != 0) _safeTransfer(p.tokenIn, tradingAccount, refund);

        emit TradeExecuted(tradingAccount, p.tokenIn, p.tokenOut, p.venue, p.amountIn, amountOut, selector);
        return (amountOut, ret);
    }

    function _selector(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(data, 32))
        }
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) = token.call(abi.encodeWithSelector(IERC20Restricted.transfer.selector, to, amount));
        if (!ok || (ret.length != 0 && !abi.decode(ret, (bool)))) revert TokenCallFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory ret) =
            token.call(abi.encodeWithSelector(IERC20Restricted.transferFrom.selector, from, to, amount));
        if (!ok || (ret.length != 0 && !abi.decode(ret, (bool)))) revert TokenCallFailed();
    }

    function _forceApprove(address token, address spender, uint256 amount) internal {
        (bool ok0, bytes memory ret0) =
            token.call(abi.encodeWithSelector(IERC20Restricted.approve.selector, spender, 0));
        if (!ok0 || (ret0.length != 0 && !abi.decode(ret0, (bool)))) revert TokenCallFailed();
        if (amount != 0) {
            (bool ok1, bytes memory ret1) =
                token.call(abi.encodeWithSelector(IERC20Restricted.approve.selector, spender, amount));
            if (!ok1 || (ret1.length != 0 && !abi.decode(ret1, (bool)))) revert TokenCallFailed();
        }
    }
}
