# Rustee Broker v3.1.0 — Operator Edition

This release is the **stable Rustee Broker #1 operating console branch**, not the Broker Factory. It is additive around the v3.0.0 / v2.8.12 execution core.

## Added

- Dedicated Vault **ETH ↔ WETH** converter with 25/50/75/MAX sizing, simulation, owner signature, receipt tracking, and post-transaction balance verification.
- Confirmed-trade verification report: quoted vs actual output, custody check, gas used, primary transaction, and local accounting result.
- Automatic local operator trade ledger and Trading-TBA cost-basis updates for trades executed by this dashboard.
- Realized and unrealized P&L surfaced in Command Center and History.
- Expanded Command Center with Vault WETH and recovery-state status.
- Portfolio search plus one-tap handoff from a holding into the Trade ticket.
- Recovery Center for interrupted sell state, owner/Vault stock custody, WETH, pending receipts, and router allowances.
- Router Allowance Manager with separate simulation and owner-signed zero-allowance revoke.
- Rustee local backup/restore for browser-side `rustee-*` state. No private key or seed phrase is stored or exported.
- PWA application shell, icons, service worker, and expanded frontend-integrity manifest coverage.

## Deliberately unchanged

- Existing BUY/SELL route construction and v2.8.12 interrupted-SELL sequence.
- Owner-signature requirement and transaction pre-sign security gate.
- Four deployed Rustee TBAs and Broker NFT identity.
- Autonomous execution remains locked.
- No contract factory, NFT factory, deployment wizard, compiler UI, or clone/deploy tooling is included in this branch.

## iPhone note

The PWA provides an installable/readable app shell. Live signing still requires a browser context that exposes the injected EVM wallet provider used by this project (for example the wallet browser). A home-screen PWA should not be assumed to inherit Rabby/MetaMask injection.
