# Rustee Registry V2 Production Migration Rehearsal

This document is intentionally non-broadcast.

## Required evidence before any production migration
1. Authenticated signed Data Streams report replay.
2. Independent review of Registry V2 and oracle integration.
3. Independent review of venue adapter and approval semantics.
4. Reviewed production deployment bytecode/commit.
5. Archive-fork replay of the exact proposed deployment/configuration calldata.
6. Emergency pause/recovery procedure.

## Rehearsal sequence
1. Snapshot deployed Registry, Trading TBA, owner, balances, policy, venues and spenders.
2. Deploy Registry V2 on a recent Robinhood Chain archive fork.
3. Configure all production inputs while paused.
4. Replay approved tiny-trade path on the fork.
5. Verify stale oracle, wrong asset, wrong venue, wrong spender, over-limit, outsider, and paused-state rejections.
6. Verify token approvals are cleared after trade.
7. Export addresses, bytecode hashes, calldata and expected post-state.
8. Human/auditor review.
9. Only after all evidence is green may a separate mainnet migration package be prepared.

This Phase 7 package does not contain a mainnet deployment or unpause button.
