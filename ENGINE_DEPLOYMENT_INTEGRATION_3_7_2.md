# Rustee Broker v3.7.2 — Website + Deployment Integration

Adds a guided iPhone/Rabby installer for the v3.7.1 engine-authorized ERC-6551 Trading generation.

The installer deploys the account implementation, predicts the canonical ERC-6551 TBA, deploys Capability Registry V2 and Rustee Trading Engine, creates the TBA, configures core engine/registry bindings, optionally configures runner/adapter, and verifies all bindings.

## Safety invariants
- Existing Trading generations are not changed.
- Current Broker NFT holder must sign each configuration transaction.
- Every deployed address must have bytecode before it is trusted.
- Dynamic engine-stack destinations enter the wallet security allowlist only after deployment/binding verification.
- TBA engine path remains paused.
- Trading Engine remains paused.
- No funding or autonomous activation is part of v3.7.2.
