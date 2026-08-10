# Rustee Broker v3.7.6.5 — Stable Mobile Script Loader

This hotfix addresses the recurring iPhone/Rabby symptom where the page renders
but remains stuck at `Provider: Checking…` and Connect Wallet does nothing.

## Root cause class

Rustee previously used one very large inline application script protected by a
single CSP SHA-256 hash. Any byte-level change to the app required a new hash.
A stale/mismatched deployed copy could therefore render the HTML while blocking
the executable app script, leaving the static `Checking…` UI visible.

## Fix

- The executable application JavaScript is now `app.js`.
- CSP now allows only same-origin scripts with `script-src 'self'`.
- No `unsafe-inline` JavaScript was added.
- The service worker explicitly caches `app.js` and uses a new cache version.
- Rabby/EIP-6963 discovery is re-requested for up to 15 seconds after boot.
- Connect Wallet still performs active provider discovery before requesting accounts.
- The v3.7.6.4 Generation 10 promotion fix is preserved.

## Replace these THREE repository-root files

- `index.html`
- `app.js`
- `sw.js`

Do not change any Solidity contracts or YAML workflows.

## Test

1. Upload all three files to the repository root.
2. Wait for GitHub Pages deployment to finish.
3. Fully close the Rabby browser page.
4. Reopen Rustee.
5. Provider should move away from `Checking…`.
6. Press Connect Wallet.
7. Confirm the NFT-holder address and Robinhood Chain appear.
8. Then re-run the Generation 10 qualification and promotion test.

This release does not deploy, unpause, grant allowances, or execute trades.
