# Rustee Portfolio Terminal v2.2 — Resilient Data Fix

This release fixes the iPhone/GitHub Pages **Load failed** errors shown in Phase 1/2.

## Cause
The static GitHub Pages frontend was attempting cross-origin browser requests to Robinhood's read-only REST APIs and Blockscout. Embedded/mobile browsers can reject those requests even when the endpoints themselves are healthy.

## Fix
The GitHub Actions workflow now retrieves the public read-only data server-side and publishes it beside the app:

- `data/robinhood-assets.json`
- `data/robinhood-prices.json`
- `data/rustee-history.json`

The browser loads these files from the **same GitHub Pages origin**, eliminating the cross-origin dependency for normal operation.

The workflow also runs every 15 minutes to refresh the public snapshots. The UI displays snapshot age. Direct live API requests remain a best-effort path for quote refresh, with same-origin snapshot fallback.

No credentials, wallet keys, or private data are stored in the generated snapshots.
