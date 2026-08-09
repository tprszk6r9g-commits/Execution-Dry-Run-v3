# Rustee Broker v3.7.5 Validation

## Scope
Rehearsal Permission Gate layered on the already-deployed v3.7.4 Production Runner + Restricted Adapter. No v3.7.4 contract redeployment is required.

## Frontend
- executable JavaScript syntax: PASS (`node --check`)
- CSP inline-script SHA-256: regenerated and exact
- PWA cache key: bumped to `rustee-broker-v3.7.5-rehearsal-permission-gate-v1`
- existing Generation 10 / v3.7.4 state is read from the same persistent local state

## Solidity
- Solidity compiler: 0.8.26
- full project build: PASS
- full regression: 57/57 PASS
- v3.7.5 permission-gate tests: 4/4 PASS
- exact allowance round-trip fuzz: 5,000 runs PASS

## v3.7.5 safety boundary
This release can stage exact Adapter permissions and an exact owner-approved tiny ERC-20 allowance from Generation 10 to the already-deployed Adapter.

It contains no v3.7.5 UI action that:
- unpauses the Production Runner,
- unpauses the Production Adapter,
- unpauses the Trading Engine,
- unpauses the Generation 10 engine path,
- executes a trade.

The next release remains a separate tiny-value execution rehearsal step.
