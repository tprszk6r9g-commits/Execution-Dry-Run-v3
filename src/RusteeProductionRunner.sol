// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC721RunnerOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRusteeTradingEngineRunner {
    struct TradeIntent {
        bytes32 capabilityId;
        uint256 action;
        address asset;
        uint256 amountUnits;
        uint256 notionalUsd18;
        uint32 slippageBps;
        address adapter;
        uint256 value;
        bytes data;
        uint64 deadline;
        uint256 nonce;
    }

    function executeIntent(TradeIntent calldata intent, bytes32[] calldata assetProof)
        external
        returns (bytes memory result);
}

/// @notice Standard production adapter entry point accepted by RusteeProductionRunner.
interface IRusteeRestrictedTradeAdapter {
    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address venue,
        bytes calldata venueData
    ) external returns (uint256 amountOut, bytes memory venueResult);
}

/// @title RusteeProductionRunner
/// @notice Narrow operator relay for the RusteeTradingEngine.
/// @dev Holds no assets, cannot make arbitrary calls, and is bound to one engine + one production adapter.
///      NFT ownership remains the configuration authority. Guardian can pause but cannot unpause.
contract RusteeProductionRunner {
    error NotAuthority();
    error NotGuardianOrAuthority();
    error NotOperator();
    error Paused();
    error ZeroAddress();
    error WrongChain();
    error WrongAdapter();
    error WrongAdapterSelector();
    error InvalidTradeEncoding();
    error IntentAssetMismatch();
    error IntentAmountMismatch();

    uint256 public constant ACTION_BUY = 1 << 0;
    uint256 public constant ACTION_SELL = 1 << 1;

    address public immutable brokerNFT;
    uint256 public immutable tokenId;
    address public immutable engine;
    address public immutable adapter;
    uint256 public immutable expectedChainId;

    address public guardian;
    bool public paused = true;
    mapping(address => bool) public operators;

    event PauseChanged(bool paused, address indexed actor);
    event GuardianChanged(address indexed oldGuardian, address indexed newGuardian);
    event OperatorAuthorization(address indexed operator, bool allowed);
    event IntentSubmitted(
        bytes32 indexed capabilityId, uint256 indexed nonce, address indexed operator, bytes32 intentHash
    );

    constructor(
        address brokerNFT_,
        uint256 tokenId_,
        address engine_,
        address adapter_,
        uint256 expectedChainId_,
        address guardian_
    ) {
        if (brokerNFT_ == address(0) || engine_ == address(0) || adapter_ == address(0) || guardian_ == address(0)) {
            revert ZeroAddress();
        }
        brokerNFT = brokerNFT_;
        tokenId = tokenId_;
        engine = engine_;
        adapter = adapter_;
        expectedChainId = expectedChainId_;
        guardian = guardian_;
    }

    function authority() public view returns (address) {
        return IERC721RunnerOwner(brokerNFT).ownerOf(tokenId);
    }

    function setGuardian(address next) external {
        if (msg.sender != authority()) revert NotAuthority();
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

    function setOperator(address operator, bool allowed) external {
        if (msg.sender != authority()) revert NotAuthority();
        if (operator == address(0)) revert ZeroAddress();
        operators[operator] = allowed;
        emit OperatorAuthorization(operator, allowed);
    }

    /// @notice Submit one standardized trade intent to the immutable Rustee engine.
    /// @dev The runner binds the engine's `asset` and `amountUnits` fields to the adapter calldata.
    function submit(IRusteeTradingEngineRunner.TradeIntent calldata intent, bytes32[] calldata assetProof)
        external
        returns (bytes memory result)
    {
        if (block.chainid != expectedChainId) revert WrongChain();
        if (paused) revert Paused();
        if (!operators[msg.sender]) revert NotOperator();
        if (intent.adapter != adapter) revert WrongAdapter();
        if (intent.data.length < 4) revert InvalidTradeEncoding();

        bytes4 selector = bytes4(intent.data[:4]);
        if (selector != IRusteeRestrictedTradeAdapter.executeTrade.selector) revert WrongAdapterSelector();

        (
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 minAmountOut,
            address venue,
            bytes memory venueData
        ) = abi.decode(intent.data[4:], (address, address, uint256, uint256, address, bytes));

        if (
            tokenIn == address(0) || tokenOut == address(0) || tokenIn == tokenOut || amountIn == 0 || minAmountOut == 0
                || venue == address(0) || venueData.length < 4
        ) revert InvalidTradeEncoding();

        if (intent.action == ACTION_BUY) {
            if (intent.asset != tokenOut) revert IntentAssetMismatch();
            if (intent.amountUnits != minAmountOut) revert IntentAmountMismatch();
        } else if (intent.action == ACTION_SELL) {
            if (intent.asset != tokenIn) revert IntentAssetMismatch();
            if (intent.amountUnits != amountIn) revert IntentAmountMismatch();
        } else {
            revert InvalidTradeEncoding();
        }

        bytes32 h = keccak256(abi.encode(intent.capabilityId, intent.nonce, keccak256(intent.data)));

        result = IRusteeTradingEngineRunner(engine).executeIntent(intent, assetProof);
        emit IntentSubmitted(intent.capabilityId, intent.nonce, msg.sender, h);
    }
}
