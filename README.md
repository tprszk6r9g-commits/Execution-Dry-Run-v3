# Rustee Portfolio Terminal v2.4 — Phase 4 Trading

Phase 4 adds a manual, owner-signed **Multi-Asset Buy + Sell Terminal** while preserving Portfolio discovery, resilient price/history snapshots, P&L, Account Center, Universal Asset Mover, Operations Center, the proven NVDA buy path, and restricted Trading-TBA withdrawals.

## Buy
- Canonical Stock Token selector populated from Robinhood chain-4663 asset metadata.
- $1 / $2 / $5 / custom sizing up to the current $5 UI ceiling.
- compares 0.05%, 0.30%, and 1.00% QuoterV2 fee tiers.
- operator-controlled slippage.
- Vault ETH -> router -> selected Stock Token -> Trading TBA.
- exact gas estimation and `eth_call` simulation before wallet signing.

## Sell
The restricted Trading TBA intentionally cannot call arbitrary routers. A sell is therefore a transparent four-step owner-controlled lifecycle:

1. Trading TBA `withdrawToken()` -> Main Owner.
2. Main Owner transfers the selected Stock Token -> Vault.
3. Vault generic account approves SwapRouter02.
4. Vault swaps Stock Token -> WETH, retained in Vault.

Every step is separately simulated and separately confirmed in the wallet. There is no hidden batch signing or autonomous execution.

## Safety
- only canonical chain-4663 assets from the Robinhood catalog appear in the standard selector;
- the terminal does not recommend assets or trade direction;
- quotes expire after 60 seconds;
- simulations expire after 60 seconds;
- every mainnet transaction requires explicit owner-wallet confirmation;
- the existing policy/Registry autonomous path remains separate.
