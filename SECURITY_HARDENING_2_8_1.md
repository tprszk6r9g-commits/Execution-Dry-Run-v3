# Rustee Portfolio Terminal v2.8.1 — Security Hardening

## Implemented in this build

- GitHub Actions are pinned to immutable commit SHAs:
  - `actions/checkout`: `11d5960a326750d5838078e36cf38b85af677262`
  - `actions/upload-pages-artifact`: `56afc609e74202658d3ffba0e8f6dda462b719fa`
  - `actions/deploy-pages`: `d6db90164ac5ed86f2b6aed7e0febac5b3c0c03e`
- Workflow permissions are split:
  - build: `contents: read`
  - deploy: `pages: write`, `id-token: write`
- No third-party JavaScript or external script tags.
- Inline JavaScript is CSP hash-locked:
  - `sha256-ncG3kMoWFXH56HAd8gUWMg6P8ZsUtvL+kOFuEefdNoc=`
- Inline event handlers were removed.
- CSP blocks plugins/objects, frames, forms, workers, external scripts, and unexpected network destinations.
- Snapshot workflow enforces HTTPS + an explicit host allowlist, response byte ceilings, schema sanity checks, and chain-4663 address validation.
- Workflow publishes a SHA-256 integrity manifest for the standalone HTML and the three public data snapshots.
- Browser verifies the integrity manifest and surfaces the result in Command Center.
- Runtime contract presence is checked for Vault, Trading, Rewards, Identity, Router, Quoter, WETH, USDG, Policy Registry, and Broker NFT.
- Every terminal-originated `eth_sendTransaction` now passes through `secureSendTransaction()`.
- Pre-sign transaction guard re-checks:
  - Robinhood Chain ID 4663
  - connected owner wallet
  - transaction `from`
  - allowed/fixed/dynamically selected contract destination
  - contract bytecode presence
  - direct ETH destination restrictions
  - direct Vault funding ceiling
- A SHA-256 fingerprint of the exact transaction payload is displayed before wallet signing.

## Important limitation

No frontend can protect against every compromise. A malicious actor with sufficient repository/admin control could modify both the application and its workflow. Use GitHub branch protection, required reviews, protected Pages environment rules, strong MFA/passkeys, and minimal repository collaborators.

The CSP/integrity seal is strongest against accidental modification, injected external scripts, stale/mismatched artifacts, and partial/CDN tampering. It does not replace repository security or smart-contract review.
