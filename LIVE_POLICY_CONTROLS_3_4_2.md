# Live Policy Controls 3.4.2

The deployed StockTokenRegistry exposes `setTradingPolicy((uint128,uint128,uint32,bool))`. Rustee v3.4.2 edits only the first three numeric fields and preserves the live `paused` boolean read immediately before simulation.

Workflow:
1. Open **Limits + Risk**.
2. Tap **Load current policy into editor**.
3. Edit Registry max trade, daily maximum, and trades/day.
4. Tap **Prepare + simulate policy update**.
5. Review the exact current → proposed diff.
6. Tap **Open wallet to sign policy update**.
7. Rustee waits for the receipt, re-reads the Registry, and requires an exact match.
8. If **Sync operator profile** is checked, the local profile is updated only after confirmed read-back.

The final signing tap is the same iPhone/Rabby prepared-wallet pattern used by the stable trade flow.

## Concurrency note
The `paused` state is preserved exactly as read during policy preparation. The prepared transaction expires after 120 seconds. If another wallet or tool changes Registry policy during that window, discard the prepared request and prepare again so the signed transaction is based on fresh state.

## Separate Data Streams gate
The included `DataStreamsPolicyGateV2.sol` is reference/production-gate code and remains unchanged in this release. Its independent compiled `$5` ceiling is not altered by the dashboard policy editor. If that gate becomes part of a production execution path, its ceiling must be handled in a separately reviewed contract upgrade rather than silently bypassed from the UI.
