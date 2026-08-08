# Rustee Portfolio Terminal v2.3 — Phase 3 Operations

Phase 3 adds a top-tier **Operations Center** while preserving the working resilient-data Portfolio, History + P&L, Account Center, Universal Asset Mover, NVDA trade executor, and Trading-TBA withdrawal path.

## New in Phase 3

### Smart Route Planner
- Main Wallet ↔ Vault / Trading / Rewards / Identity
- Vault / Rewards / Identity → any Rustee account through generic `BrokerAccount.execute`
- Trading TBA → Owner through restricted `withdrawToken()` / `withdrawETH()`
- Trading TBA → another TBA automatically becomes a two-step route:
  1. Trading → Owner
  2. Owner → destination
- ETH, NVDA, WETH, and custom ERC-20 support
- exact amount/balance validation
- per-step `eth_estimateGas` + `eth_call`
- 60-second simulation expiry
- explorer links for confirmed transactions

### One-Tap Sweep Planner
- Sweep Vault, Trading, Rewards, Identity, or all four
- optional ETH
- optional WETH
- optional automatically discovered canonical Robinhood Stock Tokens
- never auto-sweeps unknown tokens or NFTs
- creates one controlled plan but preserves one wallet confirmation per transaction
- per-step status: Pending / Ready / Submitted / Done / Failed

## Safety boundary
Phase 3 does **not** create a bot signer or bypass wallet confirmation. Each real transaction is explicitly confirmed by the Broker NFT owner.

The Trading TBA remains restricted: when routing Trading → another TBA, assets first recover to the current NFT owner and then move to the destination in a separately simulated transaction.
