# Rustee Broker

## Current Release — v3.6B.3 In-App Metadata Controller Deployer

v3.6B.3 adds an iPhone/Rabby deployment path for the already-qualified `RusteeMetadataController`.

### New website flow

`Prepare deployment → simulate → Open NFT-holder wallet → deploy → receipt → bytecode verification → Broker NFT/token binding verification → auto-fill controller address`

Deployment itself does **not** transfer NFT metadata administration. The existing v3.6B.2 Step 1 / Step 2 migration remains separately signed.

### Safety
- deployer must be the current Broker NFT holder;
- chain must be Robinhood Chain 4663;
- constructor is hard-bound to the live Broker NFT + token ID;
- deployment is simulated before the wallet button is enabled;
- receipt must contain a contract address;
- deployed bytecode must exist;
- controller `brokerNFT()` + `tokenId()` are verified before migration buttons are enabled.

---


## Current Release — v3.6B.2 NFT-Following Metadata Authority

v3.6B.2 fixes the metadata-authority mismatch that appears after Rustee Broker #1 is transferred to a different wallet.

The existing NFT contract uses a separate `owner()` role for `setTokenURI()` and `freezeMetadata()`, while Rustee's TBA authority follows `ownerOf(#1)`. v3.6B.2 adds `RusteeMetadataController`, which becomes the NFT contract's one-time metadata administrator and dynamically checks `ownerOf(#1)` for every future metadata action.

### Result after activation

`Broker NFT transfer → ownerOf(#1) changes → metadata authority changes automatically`

The Broker NFT address, token ID, four ERC-6551 TBAs, TBA assets, and existing metadata are not replaced.

### Added

- `src/RusteeMetadataController.sol`
- `test/RusteeMetadataController.t.sol`
- `script/DeployRusteeMetadataController.s.sol`
- Metadata Authority Migration panel in **NFT + Identity**
- automatic controller detection from the live NFT contract `owner()`
- Metadata Studio legacy direct-admin mode before migration
- Metadata Studio NFT-following controller mode after migration
- two-step migration:
  1. current NFT-contract metadata admin calls `transferOwnership(controller)`
  2. current Broker NFT holder calls `controller.acceptNFTAdministration()`
- current NFT holder can replace/recover the controller later
- no changes to Broker NFT ownership or TBA addresses

### Test qualification

- Full Rustee Foundry suite: **23/23 PASS**
- Metadata Controller suite: **7/7 PASS**
- Randomized NFT-transfer authority property: **5,000 fuzz runs PASS**
- Controller runtime bytecode: **4,096 bytes**
- JavaScript syntax: PASS
- CSP hash regenerated for the updated dashboard

### Important

The controller must be deployed before the migration panel can activate it. Deployment does not by itself change NFT metadata authority. The old admin and current NFT holder must complete the two explicit migration transactions in the dashboard.

Do **not** freeze metadata during migration.

---


## Current Release — v3.6B.1 Registry Hardening & Deployment Qualification

### Current-release features
- unique on-chain capability nonce per Broker NFT/token ID
- per-capability action-digest replay protection
- pinned authorized executor
- instant executor deauthorization kill path
- guardian emergency pause; owner-only unpause
- max 30-day validity and bounded uses
- stricter risk/policy validation
- v3.6A signed Capability Passport digest binding
- broader hash-chained audit events
- mainnet-blocked Foundry deployment script
- dedicated Foundry CI with 5,000-run fuzz gate
- no autonomous trade execution yet

### Stable features retained
v3.6A Capability Passport/ERC-1271 verification, rotating Trading TBAs, TBA Migration, STONKBROKER/Stock Token trading, Strategy Lab, Autopilot, Limits + Risk, Live Policy Controls, Metadata Studio, Transfer Readiness, Recovery Center, and the working iPhone/Rabby wallet handoff.

---
## v3.6B.1 Compilation Qualification

**Status: COMPILED + TESTED** with Forge v1.7.1 and solc 0.8.26.

- Full Rustee Foundry suite: **16/16 PASS**
- Capability Registry high-fuzz gate: **9/9 PASS with 5,000 fuzz runs**
- Registry runtime size: **10,227 bytes**
- Mainnet deployment remains explicitly gated.

See `Rustee_Broker_v3.6B.1_COMPILE_TEST_REPORT.md` and `evidence/` for exact logs/artifacts.

---



## Current Release

**v3.5 — Rotating Trading TBA Manager**  
**Network:** Robinhood Chain Mainnet  
**Architecture:** NFT-rooted ERC-6551 trading system  
**Immediate rollback:** v3.4.4 — Transfer Readiness  
**Earlier stable baseline:** v3.4.2 — Live Policy Controls

Rustee Broker is an NFT-rooted trading operating system built around a Broker NFT and ERC-6551 token-bound accounts. It combines owner-authorized execution, Robinhood Stock Token and STONKBROKER trading, portfolio risk controls, supervised automation, strategy research, recovery tooling, editable on-chain metadata, ownership migration checks, and rotating Trading TBA generations.

---

# Features — Current Release

## v3.5 Rotating Trading TBA Manager

v3.5 adds multiple deterministic **Trading TBA generations** for the same Rustee Broker NFT.

```text
Rustee Broker NFT #1
        │
        ├── Vault TBA — permanent
        ├── Rewards TBA — permanent
        ├── Identity TBA — permanent
        │
        ├── Trading TBA Gen 1 — original
        ├── Trading TBA Gen 2 — optional
        ├── Trading TBA Gen 3 — optional
        └── Trading TBA Gen N — optional
```

### TBA Manager features

- Predict a future Trading TBA address before deployment.
- Deterministic generation salts.
- Create additional ERC-6551 Trading TBAs for the same Broker NFT.
- Verify the canonical ERC-6551 Registry.
- Verify the deployed StockTradingAccount implementation.
- Verify NFT contract, token ID, chain and account binding.
- Detect whether a predicted generation already exists.
- Simulate `createAccount()` before signing.
- Reuse Rustee's mobile-safe Rabby wallet handoff.
- Verify `token()` after deployment.
- Verify current account `owner()`.
- Verify StockTokenRegistry relationship.
- Explicitly activate a verified Trading generation.
- Keep prior generations available for recovery/rollback.
- Prevent unverified generations from becoming active.
- Preserve the original Generation 1 account.

### Recommended account model

**Permanent Vault + rotating Trading compartments.**

The Vault remains Rustee's stable treasury/settlement account. Trading accounts can change by generation without replacing the Broker NFT or permanent Vault identity.

### Rotation safety

Creating a generation does **not** automatically activate it or sweep assets. Assets should be inspected and deliberately migrated before retiring an older Trading account.

Rustee also retains protection against transferring the parent Broker NFT into one of its own known TBAs.

---

# Complete Current Feature Set

## Trading

- Robinhood Chain Stock Token trading.
- STONKBROKER community ERC-20 BUY/SELL.
- ETH → WETH wrapping.
- WETH → ETH unwrapping.
- Vault/Trading custody movement.
- Live route comparison.
- Uniswap V3 route probing.
- Configurable slippage.
- Minimum-output protection.
- Transaction simulation.
- Receipt confirmation.
- Post-trade balance verification.
- Allowance management and revocation.
- Interrupted-operation recovery.

## STONKBROKER

Configured community token:

`0xe934e36A439C94017B64a3FecE66AF12099aBF50`

STONKBROKER is intentionally classified separately from canonical Robinhood Stock Tokens.

Rustee performs live token/contract checks and route discovery before preparing execution.

## Limits + Portfolio Risk Engine

- Maximum BUY/trade size.
- Daily BUY budget.
- Daily realized-loss stop.
- Rolling 7-day realized-loss stop.
- Maximum trades/day.
- Maximum slippage.
- Maximum open positions.
- Maximum single-ticker allocation.
- Maximum deployed stock capital.
- Minimum Vault ETH reserve.
- Configurable native ETH-per-BUY ceiling.
- Autopilot cooldown.
- Monitoring interval.
- Fail-closed valuation option.
- Risk-reducing SELL override.
- Effective-limit calculation across applicable policy layers.

## Live Registry Policy Controls

Rustee can read and owner-sign changes to:

- maximum trade
- maximum daily amount
- maximum trades/day

The existing Registry paused/unpaused state is preserved when changing numeric limits.

Workflow:

`read → edit → simulate → arm → Open wallet to sign → Rabby → confirm → read back → verify`

## Supervised Autopilot

- Monitor configured assets.
- Evaluate BUY/SELL rules.
- Enforce centralized risk controls.
- Respect cooldowns and slippage.
- Generate trading candidates.
- Route and quote candidates.
- Simulate before execution.
- Maintain audit/decision information.
- Require explicit wallet authorization for real-money execution.

## Strategy Lab + Paper Twin

- Strategy drafting.
- Price-above / price-below triggers.
- Entry capital.
- Take-profit.
- Stop-loss.
- Maximum holding period.
- Assumed fees/slippage.
- Local market recorder.
- CSV/JSON historical import.
- Historical export.
- Deterministic backtesting.
- Total-return analytics.
- Maximum drawdown.
- Win rate.
- Profit factor.
- Average win/loss.
- Paper Twin.
- Strategy Tournament.
- Draft → Paper → Armed lifecycle.
- Promotion into supervised Autopilot.

Strategy parameters remain browser-local unless deliberately exported.

## Metadata Studio

- Read current on-chain `tokenURI`.
- Check `metadataFrozen()`.
- Resolve metadata administrator.
- Edit name, description and traits.
- Preserve embedded artwork.
- Preview proposed metadata.
- Compare current/proposed traits.
- Validate payload.
- Simulate `setTokenURI()`.
- Owner-sign metadata update.
- Verify new URI after confirmation.
- Separate irreversible `freezeMetadata()` workflow.

Metadata updates do **not** automatically freeze the NFT.

## Ownership Hardening

Trading authority is dynamically resolved from the current Broker NFT holder rather than a permanently hardcoded operator wallet.

Rustee distinguishes:

- **NFT-holder / trading authority**
- **NFT-contract metadata administrator**

It also verifies expected ERC-6551 ownership/binding state and fails closed on mismatches.

## Transfer Readiness

Read-only ownership migration preflight checks:

- Broker NFT relationship.
- Vault TBA binding.
- Trading TBA binding.
- Rewards TBA binding.
- Identity TBA binding.
- Current NFT owner.
- Proposed destination.
- EOA vs contract destination.
- Registry compatibility assumptions.
- Metadata-admin relationship.
- NFT/TBA ownership-cycle hazards.
- Browser-local state that will not transfer.

Transfer Readiness cannot transfer the NFT and does not request a signature.

## Portfolio + Accounting

- Live account balances.
- Trading holdings.
- Confirmed-trade ledger.
- Cost basis.
- Realized P&L.
- Unrealized P&L.
- Quoted vs actual output.
- Transaction receipts/hashes.
- Position/risk metrics.

## Recovery Center

- Interrupted multi-step operation detection.
- Stranded-asset checks.
- Pending-operation recovery.
- WETH recovery/conversion.
- Allowance inspection/revocation.
- Asset movement between owner and TBAs.
- Local backup/restore.

---

# ERC-6551 Account Architecture

Rustee Broker #1 uses four original role accounts:

| Account | Role |
| --- | --- |
| Vault TBA | Treasury, reserves and settlement |
| Trading TBA | Trading positions/execution |
| Rewards TBA | Rewards segregation |
| Identity TBA | Identity/utility |

v3.5 extends the Trading role to support multiple generations while leaving the permanent account roles intact.

A new Trading generation is a new deterministic ERC-6551 account. It does not erase the previous address.

---

# Mobile / Rabby Execution Invariant

The working iPhone wallet handoff is protected architecture.

```text
prepare
  ↓
validate
  ↓
quote
  ↓
simulate
  ↓
arm exact transaction
  ↓
USER TAP: Open wallet to sign
  ↓
eth_sendTransaction
  ↓
Rabby
```

Do **not** insert awaited RPC calls, quote refreshes, ownership refreshes, gas estimation, network checks, account requests or JavaScript confirmation dialogs between the final user tap and the wallet request.

The wallet-signing boundary should remain owner-authorized unless a separately reviewed execution architecture replaces it.

---

# Security Invariants

1. Never store private keys or seed phrases.
2. Simulate transaction plans before arming them.
3. Fail closed on unexpected chain, NFT, TBA, token, Registry, policy or route state.
4. Preserve the proven iPhone/Rabby handoff.
5. Do not advance accounting until transactions are confirmed and verified.
6. Do not classify STONKBROKER as a Robinhood Stock Token.
7. Do not publish private strategy parameters in NFT metadata.
8. Do not silently unpause trading when changing Registry limits.
9. Do not freeze metadata as a side effect of updating it.
10. Do not automatically activate newly created Trading TBAs.
11. Do not automatically abandon older Trading generations.
12. Do not transfer the Broker NFT to one of its own TBAs.
13. Keep asset migration explicit and verified.
14. Treat contract-wallet ownership destinations as requiring signing-compatibility review.
15. Keep rollback releases available.

---

# Release History — Newest to Oldest

## v3.5 — Rotating Trading TBA Manager — CURRENT

Adds deterministic Trading TBA generations, counterfactual address prediction, generation preflight, owner-signed ERC-6551 account creation, post-deployment verification, explicit activation, previous-generation recovery and the permanent-Vault/rotating-Trading architecture.

## v3.4.4 — Transfer Readiness + Ownership Migration Check

Adds a strict read-only preflight for moving the Broker NFT to another wallet. Verifies TBA bindings and authority assumptions, detects dangerous NFT/TBA destination cycles, distinguishes metadata administration from NFT-holder authority, and identifies browser-local state that does not migrate with the NFT.

## v3.4.3 — STONKBROKER Trading

Adds STONKBROKER as a separate Community ERC-20 trading asset with live token verification and WETH route discovery while preserving Stock Token separation and the established wallet-signature boundary.

## v3.4.2 — Live Policy Controls

Adds owner-signed Registry policy editing, editable operational ceilings and centralized effective-limit behavior. Preserves Registry pause state when numeric limits are changed.

## v3.4.1 — Metadata Studio + Ownership Hardening

Adds editable on-chain metadata tooling, separate metadata freeze workflow, dynamic NFT-holder authority resolution and separation between trading authority and metadata administration.

## v3.4 — Portfolio Risk Engine

Centralizes operator trading limits and portfolio risk controls into one source of truth shared by manual trading, Autopilot and Strategy Lab.

## v3.3 — Strategy Lab + Paper Twin

Adds deterministic backtesting, historical import/export, market recording, Paper Twin, Strategy Tournament and Draft → Paper → Armed strategy lifecycle.

## v3.2 — Supervised Autopilot

Adds supervised market monitoring, trading rules, candidate generation, risk checks, route/quote preparation and owner-authorized execution handoff.

## v3.1.2 — Mobile Wallet Handoff Stability Release

Establishes the known-good iPhone/Rabby signing pattern used by subsequent releases.

## v3.1 / v3.1.1 — Operator + PWA Foundation

Adds operator-facing controls, PWA deployment improvements, workflow/integrity corrections and supporting dashboard functionality.

## v3.0 — All-in-One Architecture Foundation

Consolidates Rustee's dashboard/operator architecture and establishes the broader all-in-one project structure used by later releases.

---

# Future Roadmap

## Trading Engine

The next major intelligence subsystem should build on the now-stable account/risk/execution foundation.

### Signal Engine

Potential deterministic signals:

- momentum
- moving-average relationships
- breakout
- mean reversion
- volatility
- drawdown
- DCA/scheduled conditions
- compound AND/OR strategy conditions

### Decision Engine

- BUY / SELL / HOLD candidate generation
- explainable reasons
- conflicting-signal detection
- portfolio-aware sizing
- risk approval
- candidate scoring

### Execution Planner

- quote freshness
- route comparison
- slippage enforcement
- allowance planning
- transaction simulation
- transaction fingerprinting
- optional trade chunking
- exact wallet handoff

### Shadow Council

Multiple deterministic strategy agents can independently evaluate the same observation and vote while Paper Twin tracks each strategy's actual simulated performance.

---

# Cross-Chain Direction

Rustee can eventually become a cross-chain identity/control plane, but non-EVM networks should use native adapters.

```text
Rustee Broker NFT
       │
       └── Cross-Chain Identity / Control Plane
                │
                ├── Robinhood Chain
                │      └── ERC-6551 TBAs
                │
                ├── Bitcoin
                │      └── Bitcoin-native wallet/Taproot/PSBT module
                │
                └── Kaspa
                       └── Kaspa-native account/control module
```

Bitcoin and Kaspa accounts should **not** be falsely labeled ERC-6551 TBAs.

---

# Deployment Notes

GitHub Pages workflow:

`.github/workflows/main.yaml`

On iPhone, `.github` may appear hidden inside ZIP viewers, so releases should continue providing `main.yaml` as a separate visible file.

After deploying a release:

1. Wait for GitHub Pages deployment.
2. Fully close the old PWA/page.
3. Reopen Rustee.
4. Confirm the displayed release.
5. Connect Rabby.
6. Run read-only preflights.
7. Verify ownership/TBA state.
8. Use a deliberately small first live transaction for execution-sensitive changes.

---

# Current Status

**Current release:** v3.5 — Rotating Trading TBA Manager  
**Immediate rollback:** v3.4.4 — Transfer Readiness  
**Earlier stable baseline:** v3.4.2 — Live Policy Controls  
**Next major subsystem:** Rustee Trading Engine

Rustee is now an NFT-rooted, owner-authorized Robinhood Chain trading system with **rotating ERC-6551 Trading accounts, permanent treasury custody, Stock Token and STONKBROKER trading, supervised automation, strategy research, portfolio risk management, recovery tooling, editable metadata, and ownership-migration preflight**.
