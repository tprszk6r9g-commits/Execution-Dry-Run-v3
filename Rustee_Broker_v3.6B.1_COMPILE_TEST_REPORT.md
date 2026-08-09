# Rustee Broker v3.6B.1 — Compilation & Test Qualification

## Toolchain used

- Foundry / Forge: **v1.7.1**
- Forge commit: `4072e48705af9d93e3c0f6e29e93b5e9a40caed8`
- Solidity compiler: **solc 0.8.26**
- EVM version: `cancun`
- Optimizer: enabled
- Optimizer runs: 10,000
- Foundry local chain ID: **4663** (Robinhood Chain), so the existing RobinhoodExecutionGuardV2 tests execute in their intended environment.

## Compile result

**PASS**

`forge build --sizes`

RusteeCapabilityRegistry:
- Runtime size: **10,227 bytes**
- Initcode size: **10,829 bytes**
- Runtime margin below EIP-170 limit: **14,349 bytes**
- Initcode margin: **38,323 bytes**

The original v3.6B.1 source required two compile corrections before qualification:

1. Renamed the custom error `CapabilityRevoked()` to `CapabilityIsRevoked()` because Solidity does not permit an error and event with the same identifier.
2. Refactored `capabilityId()` into identity/policy/lifecycle sub-hashes to remove a `Stack too deep` compiler error without enabling global `viaIR`.

## Full Rustee Foundry suite

**PASS — 16 / 16 tests**

- `RegistryV2ForkTest`: 2 / 2
- `DataStreamsPolicyGateV2Test`: 5 / 5
- `RusteeCapabilityRegistryTest`: 9 / 9

The two existing RobinhoodExecutionGuardV2 tests initially reverted with `WrongChain()` under Foundry's default local chain ID. Setting `chain_id = 4663` in `foundry.toml` correctly matches the contract's Robinhood Chain requirement and the entire repository passes.

## High-fuzz Capability Registry gate

**PASS — 9 / 9 tests**

`forge test --match-contract RusteeCapabilityRegistryTest --fuzz-runs 5000 -vv`

The fuzzed use-count property completed **5,000 runs** successfully.

Verified behaviors include:

- one-time capability exhaustion
- action-digest replay rejection
- nonce-reuse rejection
- nonce-floor invalidation
- executor deauthorization
- executor pinning
- guardian pause-only authority
- owner-only unpause
- expiry enforcement
- bounded use accounting

## Lint warnings

Foundry reports `block.timestamp` warnings in the capability validity checks and the existing DataStreamsPolicyGate. These are expected because expiration/freshness policies necessarily use timestamps. They are warnings, not build/test failures.

## Deployment status

**COMPILED + TESTED, NOT DEPLOYED.**

The deployment script still blocks Robinhood Chain mainnet unless `ALLOW_MAINNET_DEPLOY=YES` is explicitly set.

This release does not authorize an autonomous executor and does not connect `RusteeCapabilityRegistry` to trade execution. Atomic consume-and-execute remains a later phase.
