# Rustee Portfolio Terminal v2.6 — Phase 6 Policy & Security

Phase 6 adds a read-only Policy & Security Console.

It reads the deployed StockTokenRegistry trading policy and the allowlist state for the
current router, checks bytecode for the Registry, Trading TBA, and Data Streams verifier,
shows snapshot freshness and wallet/chain integrity, and clearly separates:

- deployed/manual owner-signed execution — proven
- Registry V2 architecture — fork tested
- signed Data Streams replay — incomplete
- independent security review — incomplete
- Registry V2 production migration — not deployed
- autonomous mainnet execution — locked

No setter, unpause, approval, funding, or policy-broadcast controls are introduced in
Phase 6. The console is intentionally read-only.
