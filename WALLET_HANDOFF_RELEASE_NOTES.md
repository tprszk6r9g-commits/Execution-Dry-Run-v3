# Rustee Broker v3.1.2 — Wallet Handoff Hotfix

Date: 2026-08-08
Scope: Rustee Broker #1 Operator Edition only. This is **not** the Factory.

## Symptom fixed

Read-only operations and simulations succeeded, but the final transaction action could fail to open the injected mobile wallet for signature. The affected boundary was the transition from an already-simulated Rustee transaction to the EIP-1193 `eth_sendTransaction` request.

## Wallet handoff design

v3.1.2 uses a prepared two-step signing path:

1. **Simulation / pre-sign preparation** performs the asynchronous checks: wallet provider selection, Robinhood Chain ID, Broker owner account, destination allowlist, destination bytecode when applicable, gas estimation/call simulation in the existing flow, and optional transaction digest.
2. The exact transaction is armed for 60 seconds. The provider that passed the checks is pinned to that prepared handoff.
3. The final **Open wallet to sign** tap synchronously validates the prepared transaction and immediately invokes the provider's `eth_sendTransaction` request. There is no additional asynchronous chain/account lookup or JavaScript confirmation dialog before the wallet request.
4. Receipt tracking, confirmation, accounting, and refreshes continue after the wallet has accepted the request.

The prepared key covers `from`, `to`, `value`, and `data`, allowing the already-simulated gas estimate to be padded for submission without changing the transaction intent.

## Flows moved to prepared wallet handoff

- Move Assets
- Operations route steps
- BUY/SELL trade execution steps
- ETH ↔ WETH converter
- Router allowance revocation
- Legacy NVDA buy execution
- Restricted Trading-TBA withdrawal
- Metadata tokenURI update

Legacy/non-simulated writes retain the existing hardened fallback signing path.

## Mobile/UI changes

When a simulation successfully arms a transaction, the execution control changes to **Open wallet to sign**. This makes the transition explicit and gives mobile wallet browsers a direct signing gesture.

The service-worker cache key was bumped to `rustee-broker-v3.1.2-operator-v1` so the signing hotfix is not hidden behind the previous PWA cache.

## Not changed

- Solidity contracts
- Foundry tests
- `foundry.toml`
- deployed contract addresses
- Broker NFT identity
- TBA topology
- transaction calldata construction
- custody rules
- security destination allowlists
- the Rustee Broker Factory (not included)

## Operations note

Operations still follows **Build route plan → Simulate plan → Open wallet to sign**. Building a route alone does not arm a transaction for signing.
