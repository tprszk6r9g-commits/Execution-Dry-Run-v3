# Rustee Broker v3.4.1 — Release Notes

## Release

**Metadata Studio + Ownership Hardening**

Built from the validated v3.4 Portfolio Risk Engine branch. No Broker NFT, TBA, Registry, execution-guard, or policy-gate redeployment is required for this frontend release.

## New: Metadata Studio

The NFT + Identity tab now loads the current on-chain tokenURI into an editable studio. It can preserve current artwork, edit name/description/traits, apply the recommended v3.4.1 capability preset, display a current-vs-proposed diff, simulate the exact `setTokenURI(string)` call, open the prepared wallet request, and verify the confirmed tokenURI byte-for-byte.

The recommended payload removes temporary descriptive traits:

- `Max Trade = $5`
- `Max Daily = $10`
- `Trades Per Day = 1`

and replaces them with durable capability traits including configurable risk policy, Portfolio Risk Engine, Strategy Lab, Paper Twin, Supervised Autopilot, required simulation, owner-authorized execution, recovery, ETH/WETH conversion, ERC-6551 architecture, and fully on-chain metadata.

No metadata transaction is broadcast by the packaged release itself.

## New: Dynamic NFT-holder authority

The live dashboard no longer contains the owner's personal wallet address as an operational constant.

Authority resolution is now:

`Trading TBA token()` → Broker NFT + token ID → `ownerOf(tokenId)` → current trading/TBA owner.

Rustee separately reads NFT contract `owner()` as the metadata administrator. This is important because metadata-administrator authority and ERC-721 holder authority are not assumed to be identical forever.

Vault, Trading, Rewards, and Identity TBA `owner()` values are cross-checked against the live ERC-721 holder. A mismatch fails closed.

The GitHub history snapshot builder also resolves the current owner from chain state rather than embedding the prior owner wallet.

## Wallet handoff

The proven v3.1.2 iPhone/Rabby handoff remains intact.

`secureSendTransaction()` and `executeNextTradeStep()` are unchanged from v3.4.

The prepared handoff's synchronous signer assertion is extended to select the proper live role:

- Broker/TBA transaction → current ERC-721 holder.
- `setTokenURI` / `freezeMetadata` → current NFT contract metadata administrator.

`sendPreparedWalletTransaction()` still contains no `await` before `wallet.request({method:'eth_sendTransaction', ...})`.

The Metadata Studio final signing action performs no RPC/quote/gas/account/network refresh before the prepared wallet handoff.

## Freeze hardening

Metadata update and metadata freeze are now explicitly separate operations.

The freeze button cannot be used merely because an update confirmed. It requires:

1. byte-for-byte proposal verification;
2. a separate irreversible-freeze preparation action;
3. exact `eth_estimateGas` + `eth_call` simulation;
4. prepared-wallet arming; and
5. another explicit final wallet tap.

Metadata remains unfrozen unless that separate flow is intentionally completed.

## Privacy

Metadata Studio explicitly warns that NFT metadata is public. Browser-local Strategy Lab and Autopilot parameters are not inserted into NFT metadata.

## PWA

Service-worker cache key bumped to:

`rustee-broker-v3.4.1-metadata-studio-v1`

This prevents an installed iPhone PWA from continuing to serve the older v3.4 JavaScript.
