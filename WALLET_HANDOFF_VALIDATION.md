# Rustee Broker v3.1.2 — Validation Report

Date: 2026-08-08

## Passed

- Main executable JavaScript passes `node --check`.
- Executable inline-script SHA-256 exactly matches the CSP hash in `index.html`.
- 289 HTML element IDs are unique.
- All 13 navigation tabs resolve to real panes.
- `Move Assets`, `Operations`, `Trade`, `Convert`, and `Allowance Revoke` have no completed asynchronous wait or JavaScript confirmation before the prepared wallet handoff call.
- The prepared signing helper invokes `wallet.request({method:'eth_sendTransaction', ...})` before any asynchronous wait in that final handoff function.
- The provider that passes simulation-time owner/chain checks is retained for the final prepared signing call.
- Prepared handoffs expire after 60 seconds and require a fresh simulation after expiry.
- PWA service-worker cache version bumped to v3.1.2.
- Frontend integrity manifest regenerated for the changed `index.html` and `sw.js`.
- `AIO_MANIFEST.json` hashes updated.
- GitHub Pages workflow contains the corrected six-file integrity snapshot set.
- `src/`, `test/`, and `foundry.toml` are byte-for-byte identical to the Rustee Broker stable milestone reference used for this patch.

## Environment limitations

- No mainnet transaction was broadcast during validation.
- A genuine Rabby/iPhone signature sheet cannot be reproduced in this build sandbox.
- An attempted local Chromium interaction test could not navigate to local/file URLs because the execution environment blocks browser navigation by administrator policy. Static signing-boundary checks and JavaScript syntax/CSP checks therefore serve as the automated validation here.

## Recommended first live check

Use the smallest intended Move Assets transaction. Simulate it and confirm that the button changes to **Open wallet to sign**. Tap it and verify that Rabby opens a transaction confirmation. You can cancel the wallet prompt for the first check; cancellation is enough to prove the handoff is restored without moving funds.
