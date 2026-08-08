# Rustee 2.8.8 — command-center plumbing patch

This patch leaves the working Rabby / EIP-6963 / Robinhood Chain wallet path intact and fixes the three diagnostics visible in the mobile Command Center.

- Suppresses Rabby Mobile's harmless `not found rainbowkit` unhandled-rejection message in both global rejection handlers. Rustee continues to use injected/EIP-6963 wallet providers and does not add RainbowKit.
- Adds a deploy-time Blockscout ERC-20 history snapshot for the five Rustee addresses. The browser still falls back to live Blockscout if a same-origin snapshot is absent.
- Makes a successful live history load change Command Center history health to `LIVE ✓`; if every history source fails, it now reports a real history-source error instead of silently treating an empty result as success.
- Adds deploy-time SHA-256 integrity regeneration after the price and history snapshots, preventing `index.html` or refreshed data from being compared with stale hashes.
- Extends the Pages workflow verification to require valid history and integrity outputs before deployment.

No private key, seed phrase, authenticated Robinhood account, wallet signature, or write RPC is used by the new scripts.
