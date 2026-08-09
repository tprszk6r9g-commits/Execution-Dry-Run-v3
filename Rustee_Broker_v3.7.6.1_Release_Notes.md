# Rustee Broker v3.7.6.1 Release Notes

## Scope
Frontend-only qualification checkpoint and safe primary-TBA promotion.

## Added
- Persistent local receipt when the v3.7.6 safe-start preflight passes.
- Fresh re-verification before promotion.
- Live ERC-6551 binding check before promotion.
- Generation 10 can be selected as Rustee's primary app TBA.
- TBA Manager surfaces the engine-authorized generation as REHEARSAL PASSED when a matching receipt exists.

## Safety invariants
- No contract deployment.
- No automatic unpause.
- No trade broadcast.
- No allowance grant.
- Promotion is blocked unless the exact safe-start preflight still passes.
- Autonomous execution remains paused after primary-TBA selection.
