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


## v3.4.2 — Live Policy Controls
Limits + Risk can now edit the deployed Registry numeric trading policy through an NFT-owner-signed, simulated transaction. The current Registry pause state is preserved. Operator trade size, daily budget, trades/day, slippage and native-input cap are locally configurable. See `LIVE_POLICY_CONTROLS_3_4_2.md`.


## v3.4.4 — Transfer Readiness
Adds a read-only proposed-owner migration check for Broker NFT #1. It verifies all four ERC-6551 token bindings and current ownership, blocks self/TBA destination cycles, distinguishes metadata administration from NFT ownership, and explains which browser-local state does not move with the NFT. It cannot transfer the NFT or request a signature.


# Current Release — v3.5

## Rotating Trading TBA Manager

v3.5 adds real ERC-6551 **Trading TBA generations** while preserving Rustee's permanent Broker NFT identity and permanent Vault architecture.

### Architecture

```text
Rustee Broker NFT #1
        │
        ├── Vault TBA — permanent
        ├── Rewards TBA — permanent
        ├── Identity TBA — permanent
        │
        ├── Trading TBA Generation 1 — original / recoverable
        ├── Trading TBA Generation 2 — optional
        ├── Trading TBA Generation 3 — optional
        └── Trading TBA Generation N — optional
```

A Trading TBA generation does not replace or destroy an earlier ERC-6551 account. Each generation is a separate deterministic token-bound account associated with the same Broker NFT.

### TBA Manager

The v3.5 **TBA Manager** can:

- select a proposed Trading TBA generation
- derive the deterministic generation salt
- predict the ERC-6551 account address before deployment
- verify the canonical ERC-6551 Registry
- verify Rustee's deployed StockTradingAccount implementation
- verify the Broker NFT and token ID binding
- detect whether the predicted account already exists
- simulate the exact account-creation transaction
- use Rustee's existing mobile-safe Rabby wallet handoff
- verify the deployed account after confirmation
- verify `token()` binding
- verify current `owner()`
- verify the StockTokenRegistry relationship
- activate a verified generation as Rustee's current Trading TBA
- retain prior generations for recovery/rollback

### Generation salts

Trading generations use deterministic, human-auditable generation identifiers such as:

`RUSTEE_TRADING_GEN_00000002`

The salt is part of the ERC-6551 account derivation, allowing the same NFT and implementation to have multiple distinct Trading TBAs.

### Rotation workflow

```text
Choose generation
      ↓
Predict deterministic address
      ↓
Read-only preflight
      ↓
Verify Registry + implementation + NFT binding
      ↓
Simulate createAccount()
      ↓
Open wallet to sign
      ↓
Rabby confirmation
      ↓
Verify deployed account
      ↓
Verify token() / owner() / policy binding
      ↓
Optional asset migration
      ↓
Activate new Trading generation
```

Deployment and activation are deliberately separate operations.

Rustee must never automatically mark an unverified account as active.

### Asset migration

v3.5 deliberately does **not** automatically sweep assets merely because a new generation is created.

Before retiring an old Trading TBA, the operator should verify and move any required:

- ETH
- WETH
- Robinhood Stock Tokens
- STONKBROKER
- other supported ERC-20 balances

using Rustee's existing asset movement/recovery tools.

The old TBA continues to exist on-chain and can remain available for recovery.

### Permanent Vault model

The recommended architecture is:

**permanent Vault + rotating Trading compartments**

The Vault remains Rustee's stable capital/settlement account while Trading TBAs can be replaced as operational compartments.

This avoids unnecessary Vault churn while allowing trading-account isolation, recovery, experimentation and future security policies.

### Safety rules

v3.5 preserves the following rules:

1. Generation 1 is never destroyed.
2. Creating a new TBA does not automatically activate it.
3. Activating a new TBA does not automatically destroy or invalidate the previous one.
4. A generation must pass binding/ownership verification before activation.
5. The Broker NFT must never be transferred into one of its own TBAs.
6. Rustee must fail closed on unexpected NFT, chain, Registry, implementation or account-binding state.
7. Private keys are never embedded or requested.
8. Real on-chain creation remains owner wallet signed.
9. Existing mobile wallet execution behavior must not regress.
10. Bitcoin and Kaspa accounts are not falsely represented as ERC-6551 TBAs.

### Why rotation matters

Trading TBA generations create a foundation for future features such as:

- compromised-account retirement
- hot/cold trading compartments
- strategy-specific accounts
- per-generation accounting
- experimental execution environments
- restricted session accounts
- emergency migration
- clean operational epochs
- future Trading Engine isolation

### Cross-chain direction

v3.5 is an EVM/ERC-6551 feature.

Future Bitcoin and Kaspa support should use chain-native account adapters under Rustee's cross-chain identity/control layer rather than claiming those networks natively support ERC-6551.

---

