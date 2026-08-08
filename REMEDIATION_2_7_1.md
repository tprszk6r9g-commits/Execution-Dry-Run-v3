# Rustee Portfolio Terminal v2.7.1 — Remediation Applied

Applied from the Phase 6.1 remediation review to the latest Phase 7 terminal.

## R-1 High — spend-control bypass
- `MAX_TRADE_USD = 5`
- `MAX_AMOUNT_IN_WEI = 0.005 ETH`
- optional ±25% snapshot ETH/USD cross-check when a usable ETH/WETH quote exists
- hard wei ceiling applied to both the multi-asset BUY flow and legacy NVDA sizing/funding flow

The wei ceiling is authoritative even when no ETH/USD snapshot exists.

## R-2 Medium — Owner EOA custody gap
- SELL_WITHDRAW now displays a custody warning.
- confirmation dialog explicitly warns that stock tokens are outside TBA custody until SELL_STAGE confirms.
- Policy & Security preflight reports canonical Stock Tokens held by Owner as a possible interrupted sell lifecycle.

Architectural constraint: deployed `withdrawToken(address,uint256)` has no recipient argument. Single-transaction Trading → Vault recovery is deferred to Registry V2 / future implementation review.

## R-3 Low — allowance residue
- Added optional SELL_REVOKE recovery step.
- Successful SELL_SWAP marks recovery revoke SKIPPED.
- Failed SELL_SWAP exposes the revoke as a recoverable next step.
- Policy & Security preflight reads Vault → Router allowance for canonical Stock Tokens and warns on non-zero residue.

## R-4 Low — misleading freshness identifier
Renamed `freshest` to `oldestSnapshot`. Behavior remains deliberately conservative.

## R-5 Decision — deadline
Current manual route uses SwapRouter02 with `minOut` plus 60-second quote/simulation expiry. This risk acceptance is scoped only to the manual ≤$5 path. Contract-level deadline enforcement is a Registry V2 production requirement before autonomous or larger-notional operation.
