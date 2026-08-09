# Rustee Broker v3.4.2 — Live Policy Controls

## Purpose
Remove the old operational `$5 / $10 / 1` dashboard hardcodes and give the current Broker NFT owner a safe, simulated, wallet-signed editor for the deployed StockTokenRegistry trading policy.

## New capabilities
- Owner-signed Registry policy editor for max trade USD, max daily USD, and max trades/day.
- Current Registry paused/unpaused state is read live and preserved exactly during numeric policy updates.
- Operator max trade, daily budget, trades/day, max slippage, and local native-input cap are editable from Limits + Risk.
- The former 0.005 ETH supervised-route input ceiling is now an editable local risk parameter (default remains 0.005 ETH).
- Effective BUY limit is the lowest applicable value among operator max trade, live Registry max trade, and the local native-input cap converted with the available ETH/USD reference.
- Optional post-confirmation sync copies newly confirmed Registry values into the operator profile.

## Wallet handoff invariant
Policy preparation performs authority resolution, Registry read, calldata construction, gas estimation, exact `eth_call`, and wallet arming. The final **Open wallet to sign policy update** tap goes directly through the existing prepared-wallet handoff. No network/account/policy refresh is inserted before `eth_sendTransaction`.

## What this release does NOT change
- No autonomous transaction broadcasting.
- No private-key or seed-phrase handling.
- No Solidity source, Foundry config, or existing tests are modified.
- `DataStreamsPolicyGateV2.sol` remains byte-identical to v3.4.1; its separate compiled `$5` constant is not altered by this dashboard-only release.
- Metadata Studio and ownership hardening remain intact.
