# Rustee Broker v3.4.1 — Metadata Studio + Ownership Hardening

## Purpose

v3.4.1 upgrades the NFT + Identity layer without changing Rustee's trading contracts or the supervised owner-signature execution model.

The release has two goals:

1. make Rustee Broker #1 metadata editable and safely updatable from the dashboard while metadata remains unfrozen; and
2. remove the operational dependency on a hardcoded owner wallet from the live dashboard.

## Ownership model

Rustee now resolves authority from chain state:

```text
Trading TBA token()
  -> chain ID
  -> Broker NFT contract
  -> token ID

Broker NFT ownerOf(tokenId)
  -> current NFT holder
  -> trading / TBA authority

Broker NFT owner()
  -> metadata administrator
  -> setTokenURI / freezeMetadata authority
```

These are intentionally treated as separate roles. They may currently be the same address, but the UI no longer assumes they must remain the same forever.

The dashboard also reads `owner()` from Vault, Trading, Rewards and Identity TBAs. All four must match the current `ownerOf(tokenId)` result before Rustee accepts the NFT-rooted authority binding.

## Hardcoded owner removal

The prior dashboard embedded one wallet address in `index.html` and compared every connected account against it.

v3.4.1 removes that personal owner address from the live dashboard. `OWNER` is now runtime state populated from `ownerOf(tokenId)`. The history snapshot builder also resolves the owner dynamically from the Trading TBA -> NFT binding before fetching owner history.

Historical rollback files and a unit-test fixture may still contain the historical address because they are preserved evidence / non-operational fixtures. They are not used by the current dashboard authority decision.

## Metadata Studio

The NFT + Identity tab now supports:

- load current on-chain `tokenURI`;
- parse inline JSON metadata;
- preserve the current artwork by default;
- edit name and description;
- edit traits using `Trait=Value` rows;
- optionally replace the image URI;
- apply a v3.4.1 capability-oriented metadata preset;
- preview the proposed JSON;
- compare current vs proposed traits;
- run an authority / frozen-state preflight;
- estimate gas and `eth_call` the exact `setTokenURI(string)` transaction;
- arm the exact wallet provider + transaction;
- open the wallet only after the explicit final tap;
- re-read `tokenURI` and verify the proposal byte-for-byte.

The recommended v3.4.1 preset removes stale descriptive limits such as `Max Trade=$5`, `Max Daily=$10`, and `Trades Per Day=1`. Operational limits remain in Limits + Risk and contract policy rather than NFT traits.

The preset includes capability traits such as:

- Architecture = ERC-6551
- Risk Policy = Configurable
- Portfolio Risk Engine = Enabled
- Strategy Lab = Enabled
- Paper Twin = Enabled
- Supervised Autopilot = Enabled
- Trade Simulation = Required
- Execution = Owner Authorized
- Recovery Engine = Enabled
- ETH / WETH Conversion = Enabled
- Metadata = Fully on-chain

## Metadata privacy boundary

NFT metadata is public blockchain data. Strategy thresholds, stop losses, take-profit values, private notes, wallet secrets, and credentials must not be copied into metadata.

Strategy Lab and Autopilot configuration remain browser-local.

## Mobile wallet handoff invariant

The v3.1.2 iPhone/Rabby rule remains mandatory.

During simulation Rustee performs chain/account/code checks and arms the exact transaction and exact wallet provider. The final signing tap must not perform new asynchronous reads before `eth_sendTransaction` is handed to the wallet.

v3.4.1 extends the synchronous signer check so:

- normal Rustee/TBA transactions require the current `ownerOf(tokenId)` holder;
- metadata transactions to the resolved Broker NFT require the current contract `owner()` metadata administrator.

This role selection is synchronous at final handoff time.

## Freeze behavior

Metadata remains writable unless the on-chain `metadataFrozen()` value is true.

v3.4.1 does **not** freeze metadata as part of an update.

Freeze requires:

1. a last-proposal byte-for-byte verification;
2. a separate `Prepare irreversible freeze` action;
3. exact gas estimation and `eth_call` simulation;
4. an armed prepared wallet handoff; and
5. a separate final `Open wallet to freeze forever` tap.

`freezeMetadata()` is permanent.

## Contracts

v3.4.1 does not modify:

- `src/RobinhoodExecutionGuardV2.sol`
- `src/DataStreamsPolicyGateV2.sol`
- `foundry.toml`

The release is a frontend / metadata / ownership-resolution upgrade.
