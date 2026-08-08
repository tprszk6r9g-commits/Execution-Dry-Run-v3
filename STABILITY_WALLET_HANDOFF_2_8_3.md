# Rustee Portfolio Terminal v2.8.3 — Stability + Wallet Handoff Fix

This patch addresses two regressions introduced by the hardened background diagnostics.

## Wallet signing
- Transaction signing no longer waits for the broad runtime-contract health sweep.
- Frontend integrity is informational and never blocks wallet signing.
- Mandatory pre-sign checks are transaction-scoped:
  - injected wallet exists;
  - chain ID 4663;
  - connected owner wallet;
  - transaction `from` matches owner;
  - destination is permitted;
  - exact destination has bytecode for contract calls;
  - direct ETH destinations and Vault funding ceiling remain enforced.
- SHA-256 transaction fingerprinting has a 1.2-second timeout and becomes informational if WebCrypto is unavailable.
- The actual `eth_sendTransaction` wallet request has explicit UI status and a long signature timeout.

## Endless Refreshing fix
- Command Center refresh is single-flight; overlapping refreshes reuse one promise.
- RPC/balance/portfolio/history operations are bounded by timeouts.
- `finally` always clears the Refreshing indicator.
- Frontend integrity and broad runtime health checks run in the background with `Promise.allSettled`.
- Background security diagnostics cannot hold the UI spinner open.
- Global browser/promise errors are surfaced in the status pill for debugging.

All v2.7 remediation, v2.8 Evidence + Replay, v2.8.1 CSP/workflow hardening, amount ceilings,
allowance recovery, custody warnings, and Production Gate behavior are retained.
