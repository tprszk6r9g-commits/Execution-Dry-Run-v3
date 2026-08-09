# Rustee Broker v3.1.2 — Mobile Wallet Handoff Hotfix

Scope: Rustee Broker #1 operator console only. **Not the factory.**

## Symptom fixed

On iPhone wallet browsers, read-only work could succeed — quote, route build, `eth_estimateGas`, and `eth_call` — while the final signing button failed to open the injected wallet.

## Handoff design

For simulation-based writes, all asynchronous security work now happens during the explicit **Simulate** step:

- owner-wallet check;
- Robinhood Chain 4663 check;
- destination allowlist check;
- contract-bytecode check when calldata is present;
- exact transaction simulation;
- optional SHA-256 transaction fingerprint.

A successful simulation arms the exact `{from,to,value,data}` transaction for a short TTL. The enabled final button changes to **Open wallet to sign**.

On that final tap, Rustee performs only synchronous cached checks and calls the selected injected provider's `eth_sendTransaction` immediately, before any `await`, network request, or JavaScript confirmation dialog. The wallet's own transaction confirmation remains the final authorization boundary.

## Flows using the prepared handoff

- Move Assets;
- Operations route steps;
- Trading BUY/SELL steps;
- legacy NVDA buy path;
- restricted Trading-TBA withdrawal;
- Vault ETH ↔ WETH conversion;
- Router allowance revoke;
- metadata `setTokenURI` write.

Non-simulated/legacy writes keep the prior hardened fallback path.

## Unchanged

- Solidity contracts;
- Foundry tests;
- deployed addresses;
- transaction calldata construction;
- owner-only authority model;
- quote/simulation logic;
- recovery design.

No seed phrase or private key is requested or stored.
