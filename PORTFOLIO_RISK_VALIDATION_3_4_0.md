# Rustee Broker v3.4 — Validation Report

## Result
PASS for static/package validation and deterministic risk-engine unit semantics.

## Frontend integrity
- 16 tab buttons / 16 matching tab panes.
- Executable JavaScript passes `node --check`.
- CSP SHA-256 exactly matches the executable inline script.
- Frontend integrity manifest regenerated successfully.
- GitHub Actions `Verify snapshots` expected-file set exactly matches the six integrity targets.
- Static secret scan passed.
- ZIP archive passed `unzip -t` with no compressed-data errors.
- The only repeated HTML id is the pre-existing embedded SVG id `wallet`, identical to v3.3; v3.4 introduced no new duplicate id.

## Wallet handoff invariant
The following functions are text-for-text identical to v3.3:
- `armPreparedWalletHandoff`
- `secureSendTransaction`
- `executeNextTradeStep`

The v3.4 Portfolio Risk Engine block contains none of:
- `eth_sendTransaction`
- `secureSendTransaction(`
- `executeNextTradeStep(`
- `armPreparedWalletHandoff(`

Risk evaluation therefore happens before route/simulation and does not move asynchronous work into the final iPhone/Rabby user-gesture signing boundary.

## Contract/core stability
Byte-for-byte identical to v3.3:
- entire `src/` tree
- entire `test/` tree
- `foundry.toml`

The current hard safeguards remain:
- frontend BUY/trade ceiling: `$5`
- computed BUY input ceiling: `0.005 ETH`
- unchanged `DataStreamsPolicyGateV2.sol` compiled `$5` constant

## Centralized limits wiring
Verified in the built `index.html`:
- Manual BUY quote calls centralized `riskPreflightTrade(...)` before route construction.
- Manual SELL quote calls centralized risk preflight with recovery-mode awareness.
- Autopilot max trade, daily budget, loss stop, cooldown, refresh interval, and slippage are read-only mirrors of the Limits + Risk profile.
- Autopilot BUY rule sizing uses the effective maximum.
- Autopilot candidate sizing uses the effective maximum.
- Strategy Lab entry sizing uses the effective maximum.
- Strategy promotion rejects entries above the current effective maximum.
- Manual Trade and Strategy Lab HTML max values are dynamically updated from the central profile.
- Rustee full backup automatically captures the v3.4 risk keys because it exports all `rustee-*` localStorage state.

## Risk-engine behavior test
The actual v3.4 risk block was executed in a Node VM with deterministic stubs. PASS cases included:
- operator / hard / Registry-reference minimum calculation
- daily BUY budget enforcement
- effective per-trade maximum enforcement
- maximum open-position enforcement
- deployed-stock-cap enforcement
- one-ticker allocation enforcement
- risk-reducing SELL override remains available after loss/trade-count stops
- disabling the exit override makes SELL obey the trade-count ceiling

## Registry semantics
The UI explicitly labels the Registry as a read-only production-policy reference. A Registry `PAUSED` result is surfaced as a warning and is not falsely represented as gating the existing supervised swap route unless that Registry is explicitly wired into that route.

## Not performed
No live mainnet transaction was broadcast as part of validation. First deployment should be tested with the same tiny owner-approved transaction workflow used for the prior stable releases.
