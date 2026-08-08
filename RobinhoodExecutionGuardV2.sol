// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Prototype chain-specific guard for fork review only.
/// It deliberately does NOT model Robinhood's websocket sequencer feed as AggregatorV3.
contract RobinhoodExecutionGuardV2 {
    uint256 public constant ROBINHOOD_CHAIN_ID = 4663;
    address public immutable owner;
    bool public paused = true;

    error WrongChain();
    error NotOwner();
    error Paused();

    constructor(address owner_) {
        if (block.chainid != ROBINHOOD_CHAIN_ID) revert WrongChain();
        owner = owner_;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function requireExecutionAllowed() external view {
        if (block.chainid != ROBINHOOD_CHAIN_ID) revert WrongChain();
        if (paused) revert Paused();
    }
}
