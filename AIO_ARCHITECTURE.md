# Rustee Broker AIO v3.0.0 — Architecture

## 1. Root authority

Rustee Broker #1 is the NFT identity/root authority. The frontend derives its Broker NFT binding from the deployed Trading TBA via ERC-6551 `token()` and then cross-checks it against the expected Rustee Broker #1 contract before enabling metadata writes.

## 2. ERC-6551 account plane

- Vault TBA — funding, swap execution, WETH/native ETH proceeds.
- Trading TBA — stock-token custody and controlled withdrawal path.
- Rewards TBA — reward/account compartment.
- Identity TBA — identity/account compartment.

## 3. Execution plane

The existing v2.8.12 execution core remains the transaction engine. It covers quote discovery, buy/sell plans, simulation, execution, interrupted-sell recovery, custody inspection, allowance cleanup, and optional WETH-to-native-ETH unwrap after a sell.

## 4. Identity + metadata plane

The NFT tab now contains the v3.4.1 Metadata Studio. Rustee resolves the Broker NFT from the Trading TBA, reads current trading authority from ERC-721 `ownerOf(tokenId)`, reads metadata authority separately from NFT `owner()`, verifies all four TBA owners against the NFT holder, loads the current tokenURI, and can build an edited proposal. Metadata writes require unfrozen state, the live metadata administrator, gas estimation, exact `eth_call`, and a prepared owner-signed wallet handoff.

## 5. Security boundary

`secureSendTransaction()` remains the signature handoff. The destination allowlist is extended only for the Broker NFT resolved at runtime. Arbitrary NFT destinations are not enabled.

## 6. Observability and evidence

The Command Center, transaction receipts, history/P&L, security pane, production gate, evidence/replay tools, and deployment integrity manifest remain in the same application.

## 7. Deployment plane

GitHub Actions refreshes the Robinhood same-origin snapshots every 15 minutes, refreshes Rustee history, regenerates the frontend integrity manifest, validates the bundled metadata payload, and deploys the repository to GitHub Pages.

## Rollback

Untouched copies of both uploaded root HTML applications are in `archive/`. If an AIO-specific regression is found, the stable execution core can be restored without reconstructing it.
