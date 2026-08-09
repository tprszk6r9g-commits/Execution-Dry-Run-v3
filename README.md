# Rustee Broker v3.7.3.1 — Wallet Connect Hotfix

## Status
This is the current iPhone/GitHub Pages hotfix package following the Generation 10 TBA Manager update.

## What this release fixes
The Generation 10 Manager update changed the executable inline JavaScript in `index.html`, but the Content Security Policy (CSP) still contained the previous script hash.

Result:
- The Rustee Broker interface rendered normally.
- Wallet detection remained at `Checking...`.
- Connected wallet and chain stayed blank.
- `Connect wallet` could not execute correctly because the browser blocked the updated inline script.

v3.7.3.1 regenerates the CSP SHA-256 hash for the current inline JavaScript.

The service-worker cache key is also bumped so iPhone/Safari/GitHub Pages does not continue serving the previously cached broken page.

## Files changed
Only these files need to be replaced in the deployed repository:

1. `index.html`
2. `sw.js`

No YAML/workflow replacement is required for this hotfix.

## Generation 10 state retained
This hotfix keeps the Generation 10 Manager work already added to the application.

Current verified core-stack state from the preceding deployment:
- ERC-6551 token binding: PASS
- TBA owner follows `ownerOf()`: PASS
- TBA engine binding: PASS
- Registry -> engine executor: PASS
- Engine -> exact TBA/generation: PASS
- TBA engine path: PAUSED
- Trading Engine: PAUSED
- Generation: 10
- Optional Runner/Adapter: NOT CONFIGURED

The safe default remains intentional: autonomous execution layers stay paused until the production execution layer is completed and rehearsed.

## Runner + Adapter
Do **not** enter mock Runner or Adapter addresses into Step 6.

The repository authorization infrastructure and Step 6 UI exist, but `MockTradeAdapterV371` is a test-suite mock and is not the production trading adapter.

Runner and Adapter should remain blank until the production execution layer is built and validated.

The planned execution-layer release should include:
- Production Runner contract
- Tightly restricted Robinhood Chain trading Adapter
- Explicit target/token/router allowlisting
- Capability and authorization enforcement
- Pause/emergency controls
- Replay/nonce protections where applicable
- Deployment scripts
- Unit tests
- Negative authorization tests
- Fuzz/invariant testing
- CI
- Frontend deployment/configuration controls suitable for iPhone deployment

Only after those contracts pass should their deployed addresses be entered into Step 6.

## Installation from iPhone / GitHub
1. Open the `Execution-Dry-Run-v3` repository.
2. Replace the root `index.html` with the `index.html` in this ZIP.
3. Replace the root `sw.js` with the `sw.js` in this ZIP.
4. Commit both files to `main`.
5. Wait for GitHub Pages deployment to complete.
6. Fully close the Rustee Broker page/browser tab.
7. Reopen the deployed GitHub Pages site.
8. Tap `Connect wallet`.

## Expected wallet test
After the new deployment loads:
- Provider should stop showing `Checking...`.
- The injected wallet should be detected.
- Tapping `Connect wallet` should invoke the wallet provider.
- Connected wallet should populate.
- Chain should populate.
- Robinhood Chain switching should remain available.

If an old cached page is still displayed, close the browser tab/app and reopen the GitHub Pages URL after deployment.

## Next regression tests
Once wallet connection works again, verify in this order:

1. Wallet connection and Robinhood Chain detection.
2. NFT identity and current NFT holder.
3. Generation 10 appears in TBA Manager.
4. Generation 10 TBA address matches the Engine Setup verified TBA.
5. `owner()` / authority follows the current NFT holder.
6. Core stack verification still returns PASS/PAUSED exactly as expected.
7. Runner and Adapter remain unconfigured.
8. No asset funding or autonomous activation until the production execution layer is tested.

## Security note
Rustee Broker should never request a seed phrase or private key. Wallet signatures remain with the injected wallet provider.

## Release
`Rustee Broker v3.7.3.1`

Purpose: restore wallet JavaScript execution after the Generation 10 Manager update without rolling back the Generation 10 functionality.
