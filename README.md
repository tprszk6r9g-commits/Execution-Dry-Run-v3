# Rustee Portfolio Terminal v2.1 — Phase 2

Phase 2 builds on Phase 1 automatic Robinhood Stock Token discovery and valuation.

## Added in Phase 2
- Dedicated **History + P&L** tab.
- Read-only ERC-20 transfer-history retrieval for Main Wallet, Vault, Trading, Rewards, and Identity via Robinhood Chain Blockscout.
- Filters history to canonical Stock Tokens discovered from Robinhood metadata.
- De-duplicates transfers seen from multiple Rustee addresses.
- Account filter and direct transaction explorer links.
- Local per-position USD cost-basis ledger.
- Current value, tracked cost basis, and unrealized P&L.
- Exportable JSON ledger containing account map, local cost-basis entries, and indexed transfer history.

## Important accounting boundary
On-chain ERC-20 transfers prove movement, not purchase price. Transfers among Rustee accounts are not treated as buys or sells. Phase 2 therefore does **not invent historical cost basis**. Cost basis is entered locally by the operator until a later phase adds deterministic trade-receipt reconstruction.

## Preserved
The existing manual trade executor, exact simulation gate, Account Center, Trading-TBA withdrawal ABI, Universal Asset Mover, automatic Stock Token discovery, and portfolio valuation remain intact.
