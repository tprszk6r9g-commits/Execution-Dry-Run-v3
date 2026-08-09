# Rustee Broker v3.1.0 — Validation Notes

## Passed static/build checks

- Main inline JavaScript parses successfully with Node.js `--check`.
- Service worker parses successfully with Node.js `--check`.
- CSP SHA-256 for the executable inline script was recomputed and matches the shipped script exactly.
- HTML contains no duplicate element IDs.
- All 13 tab buttons resolve to existing panes, including the new ETH ↔ WETH pane.
- `manifest.webmanifest`, `AIO_MANIFEST.json`, and `data/integrity.json` parse as valid JSON.
- Published integrity hashes were regenerated for `index.html`, `manifest.webmanifest`, `sw.js`, and the three same-origin Robinhood snapshot files.
- `src/`, `test/`, and `foundry.toml` were verified byte-for-byte unchanged from the v3.0 milestone input.

## Safety / scope validation

- No NFT factory, Broker factory, deployment wizard, compiler UI, or clone/deploy workflow was added.
- Existing BUY/SELL execution construction remains the stable owner-signed path; v3.1 adds confirmed-state accounting/verification around it.
- Vault conversion and allowance revoke operations require the expected owner, Robinhood Chain 4663, successful `eth_estimateGas`, successful `eth_call`, and a wallet signature through the existing security gate.
- No private key or seed phrase storage was added. Backup exports only localStorage keys prefixed `rustee-`.
- No autonomous mainnet execution was enabled.

## Environment limitation

The build environment blocks Chromium navigation to local/file URLs, so an automated browser E2E smoke test could not be completed here. No mainnet transaction was broadcast during build/validation. Wallet/mainnet execution should therefore be tested first with a deliberately tiny amount, while the v3.0 milestone ZIP remains the rollback build.
