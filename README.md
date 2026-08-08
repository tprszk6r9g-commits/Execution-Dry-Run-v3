# Rustee STONKBROKER Archive + Bidirectional Manipulation v4.7.3

v4.7.3 follows the green/corrected v4.5.2 math and the v4.6.1 finding that
Robinhood's public RPC did not expose enough historical state.

## New requirement

Set a repository variable:

`ARCHIVE_RPC_URL`

to an archive-capable Robinhood Chain RPC endpoint you trust.

The workflow does not hardcode or guess a paid provider endpoint.

## Historical gate

v4.7.3 attempts 14 recent samples spanning 0 to 168 hours. The archive evidence
gate requires at least 8 successful historical samples.

## Bidirectional stress

The fresh-fork test expands WETH -> STONKBROKER gross inputs up to 1 WETH, then
seeds STONKBROKER and tests the reverse STONKBROKER -> WETH direction across
progressive fractions.

The report measures spot-tick movement and builds coarse capital brackets for
hypothetical 30-minute TWAP biases.

## Important limitation

Gross trade input is not exact net manipulation cost. Exact adversarial P&L
depends on unwind/recovery, active tick liquidity, arbitrage, MEV, fees and
capital recovery.

## Safety

All mainnet deployment, Registry-write, funding, approval, unpause, trade and
broadcast flags remain false.
