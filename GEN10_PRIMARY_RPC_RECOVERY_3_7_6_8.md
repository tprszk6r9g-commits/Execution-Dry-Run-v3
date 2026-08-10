# Rustee Broker v3.7.6.8 — Gen10 Primary + RPC Recovery

Fixes three regressions seen on iPhone/Rabby:

1. **Trading TBA reverted visually/operationally to Generation 1.** Gen 10 (`0xfb2aed3d206c71bf0c6a69a40f71727ae62086e9`) is now the durable default primary Trading TBA. Explicit user rotations still override it.
2. **NFT + Identity showed the hardcoded Gen 1 Trading address.** The card is now dynamic and displays the active generation/address.
3. **`Load failed` during Robinhood Chain connection / verification.** Read-only RPC now prefers Rabby's injected provider when it is on chain 4663 and uses bounded public-RPC retries only as fallback.

The v3.7.6.7 generation-aware sweep remains intact. One-Tap Sweep and Move Assets both resolve the same active `TRADING` address.

## Test

- Reopen Rustee in Rabby.
- NFT + Identity must show **Trading TBA · Gen 10** and `0xfb2aed...2086e9`.
- Command Center should connect without the generic `Load failed` alert.
- `Verify complete stack` should populate results.
- One-Tap Sweep: select **Trading TBA**, WETH only, Build plan. The log must identify Gen 10 and the Gen10 address before simulation.
- Simulate before executing. Keep autonomous execution paused.
