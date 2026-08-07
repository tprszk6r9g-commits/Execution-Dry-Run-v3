# Rustee STONKBROKER Historical + Manipulation Analysis v4.6

This phase follows the corrected v4.5.2 TWAP math.

## What it does

- confirms the canonical WETH/STONKBROKER Uniswap V3 pool;
- samples 30-minute TWAP, spot tick and active liquidity across recent historical blocks when the public RPC exposes the required historical state;
- never substitutes current state when an archive sample is unavailable;
- runs a discrete WETH→STONKBROKER swap stress grid on a fresh Foundry fork;
- measures the post-swap spot tick movement;
- converts the stress grid into coarse gross-WETH brackets for several hypothetical 30-minute TWAP biases and manipulation hold durations;
- keeps every live-mainnet execution gate disabled.

## Important interpretation

The stress grid is **not** an exact manipulation-cost proof. Gross input is not the same as net economic cost. A complete adversarial study must model both swap directions, unwind/recovery, pool tick liquidity, fees, arbitrage, MEV, competing liquidity, and the time profile required to influence a 30-minute TWAP.

## GitHub upload

Put `main.yaml` at:

`.github/workflows/main.yaml`

and put `index.html` at repository root. The full ZIP already includes that structure.
