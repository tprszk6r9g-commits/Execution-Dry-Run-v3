## v3.4.1 Metadata Studio + Ownership Hardening

See `METADATA_STUDIO_3_4_1.md`. v3.4.1 adds an editable on-chain Metadata Studio, capability-oriented metadata, dynamic ERC-721 `ownerOf(tokenId)` trading authority, separate live metadata-admin `owner()` resolution, four-TBA ownership cross-checks, and removal of the operational hardcoded owner wallet. Metadata remains unfrozen unless the administrator separately prepares and signs the irreversible freeze flow.

## v3.4 Portfolio Risk Engine + Limits Control Center

See `PORTFOLIO_RISK_ENGINE_3_4_0.md`. v3.4 centralizes operator limits and applies them to manual BUYs, Supervised Autopilot and Strategy Lab without changing the owner-signature execution boundary.

## v3.3 Strategy Lab + Paper Twin

See `STRATEGY_LAB_3_3_0.md`. This release adds local data recording/import, deterministic backtesting, paper twins, strategy tournament ranking and explicit promotion into the existing supervised Autopilot. Real transaction broadcast remains owner-signed.

## v3.2 Supervised Autopilot

See `AUTOPILOT_3_2_0.md`. This release adds rule monitoring, risk gates, candidate queueing and automatic pre-signature preparation. Autonomous transaction broadcast remains disabled; real trades still stop at the owner wallet signature boundary.

# Rustee Broker v3.1.2 Operator Edition

One deployable GitHub Pages project for the stable Rustee Broker #1 operator console. This branch is **not** the Broker Factory.

## What is unified

- **Rustee Command Center** — wallet/provider state, system health, portfolio summary, recent activity.
- **NFT + Identity / Metadata Studio** — runtime ERC-6551 binding, dynamic NFT-holder + metadata-admin authority, four-TBA owner cross-check, current metadata loader, editable capability traits, exact update simulation, verification, and separately prepared optional freeze.
- **Portfolio Terminal** — canonical Robinhood Stock Token discovery, balances, valuations, allocation view.
- **Trading** — guarded BUY and SELL workflows with fresh quotes, simulations, owner-wallet confirmations, recovery for interrupted sells, optional **WETH → native ETH** sell proceeds, confirmed-trade verification, and automatic local operator accounting.
- **Vault Converter** — dedicated ETH ↔ WETH wrapping/unwrapping inside the Vault with simulation, owner signing, receipts, and balance verification.
- **Recovery Center + Allowance Manager** — interrupted-sell/custody checks and simulated owner-signed Vault→Router allowance revocation.
- **Local Backup + PWA** — export/restore Rustee browser state and an installable app shell for iPhone/desktop.
- **History + P&L** — transaction history, local cost basis, realized/unrealized calculations, ledger export.
- **Account Center / Move Assets / Operations** — ETH/ERC-20 movement, TBA recovery and sweeps.
- **Policy + Security / Production Gate / Evidence + Replay** — existing v2.8.x safety and production-readiness layers.
- **Contracts + tests** — `src/`, `test/`, and `foundry.toml` from the execution project.
- **Snapshots + automation** — Robinhood asset/price/history builders and Pages deployment workflow.
- **Metadata source** — Rustee WebP assets, exact tokenURI payloads, tokenURI builder, and installer guide.

## Stable core provenance

The execution layer comes from the uploaded `Execution-Dry-Run-v3-main (6).zip`, including the v2.8.12 interrupted-sell recovery patch. The NFT/metadata layer comes from `RusteeBroker1-main (2).zip`.

The original uploaded root HTML files are preserved unchanged in `archive/` for rollback.

## Deploy

1. Upload the **contents of this folder** to the root of a GitHub repository.
2. Keep `.github/workflows/main.yaml`, `index.html`, `assets/`, `data/`, `scripts/`, `src/`, and `test/` in their existing paths.
3. In GitHub: **Settings → Pages → Source → GitHub Actions**.
4. Run the workflow or push to `main`.
5. Open the GitHub Pages URL in Rabby/MetaMask or another browser with an injected EVM wallet.

The workflow refreshes same-origin Robinhood snapshots, regenerates the integrity manifest, checks the AIO metadata payload, and deploys the site.

## Safety model

- No private key or seed phrase input exists.
- Trading/TBA writes require the current live `ownerOf(tokenId)` holder on Robinhood Chain 4663; metadata writes require the live NFT contract `owner()` administrator.
- Trade, move, converter, allowance, and metadata writes require fresh `eth_estimateGas` + `eth_call` simulation before signing.
- On mobile wallet browsers, the simulation also arms the exact transaction. The final **Open wallet to sign** tap calls `eth_sendTransaction` immediately so the injected wallet receives a fresh user-gesture handoff.
- Destination/authority/chain checks are completed during simulation for prepared writes; the Broker NFT is resolved from the ERC-6551 TBA, the current ERC-721 holder is read with `ownerOf(tokenId)`, the metadata administrator is read separately with `owner()`, and all four TBA owners must match the current NFT holder.
- `freezeMetadata()` remains optional and irreversible; v3.4.1 requires a separate simulated freeze preparation before the final wallet-signing tap.

## Key addresses

- Broker NFT #1: `0x4523467C4DDC6D775C7EaD4Dce7656DCe54e7F60`
- Vault TBA: `0x8ad8bd35d33dd7b4d0de81f809f5b7f92623956d`
- Trading TBA: `0x522f5637f2c556aad9b2245f3b8e6bf4dfd9a654`
- Rewards TBA: `0xfd0d881d73ec1476f5da0ab78283149ea21c3b32`
- Identity TBA: `0x496d7d47ae69d65d714413f0dc78c712ed92158d`
- WETH: `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73`

## Important files

- `index.html` — complete AIO frontend.
- `wallet-diagnostic.html` — injected-wallet diagnostics.
- `assets/tokenURI_utf8.txt` — exact metadata payload embedded in the AIO.
- `docs/METADATA_INSTALL_GUIDE.md` — metadata write/freeze guide.
- `AIO_ARCHITECTURE.md` — module map and execution boundaries.
- `OPERATOR_3_1_0.md` — v3.1 additions, guarantees, and non-factory scope.
- `WALLET_HANDOFF_3_1_2.md` — mobile signing hotfix and validation notes.
- `archive/` — untouched rollback copies of both uploaded apps.
