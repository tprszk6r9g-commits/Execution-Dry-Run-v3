# Rustee Broker v3.3 — Strategy Lab Validation

Validation date: 2026-08-08 (user-local release date)

## Result

**PASS — release package validated for deployment testing.**

## Stability invariants

- `src/RobinhoodExecutionGuardV2.sol`: byte-for-byte unchanged from v3.2.
- `src/DataStreamsPolicyGateV2.sol`: byte-for-byte unchanged from v3.2.
- `test/RegistryV2Fork.t.sol`: byte-for-byte unchanged from v3.2.
- `test/DataStreamsPolicyGateV2.t.sol`: byte-for-byte unchanged from v3.2.
- `foundry.toml`: byte-for-byte unchanged from v3.2.
- The v3.1.2 mobile/Rabby wallet-handoff implementation is not modified by Strategy Lab.

## Strategy Lab execution boundary

The v3.3 Strategy Lab JavaScript section was statically checked to contain no calls to:

- `eth_sendTransaction`
- `executeNextTradeStep(...)`
- `executeRealMove(...)`
- `executeOperationStep(...)`

Strategy promotion creates supervised Autopilot rules only. It does not enable Autopilot and does not broadcast a transaction.

## Frontend validation

- Executable JavaScript: `node --check` PASS.
- Tab buttons: 15.
- Tab panes: 15.
- All tab targets resolve to a pane.
- Duplicate HTML IDs: 0.
- CSP inline-script SHA-256 regenerated and verified against the executable script.
- Static key/secret scan: PASS.
- PWA cache version bumped to `rustee-broker-v3.3-strategy-lab-v1`.

## Integrity / workflow validation

The integrity manifest contains exactly:

1. `index.html`
2. `manifest.webmanifest`
3. `sw.js`
4. `data/robinhood-assets.json`
5. `data/robinhood-prices.json`
6. `data/rustee-history.json`

Every SHA-256 in `data/integrity.json` was recomputed and matched the file bytes. The GitHub Actions `Verify snapshots` assertion contains the same six-file set.

## Backtester deterministic unit check

A known synthetic seven-point price series was replayed with zero fees/slippage and a deterministic bracket strategy. Expected behavior was observed:

- Closed trades: 2
- First exit: TAKE_PROFIT
- Second exit: STOP_LOSS
- Ending equity: 1001.959595959596 from a 1000 starting balance
- Total return: 0.19595959595959583%
- Max drawdown: 0.4016306203184932%
- Win rate: 50%

This verifies the replay engine's entry, take-profit, stop-loss, P&L, equity and drawdown path on a controlled dataset.

## Packaging

- ZIP archive test: PASS — no compressed-data errors.
- SHA-256 is supplied alongside the ZIP.

## Runtime caveat

No mainnet transaction is broadcast by this validation. Historical/backtest quality depends entirely on the price observations the operator records or imports. iOS may suspend timers while the PWA/browser is backgrounded, so the local recorder is intended for while Rustee is active; import/export exists for larger historical datasets.
