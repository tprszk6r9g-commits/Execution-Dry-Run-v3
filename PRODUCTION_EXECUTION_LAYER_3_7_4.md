# Rustee Broker v3.7.4 — Production Execution Layer

## Architecture

Operator EOA / automation key
        |
        v
RusteeProductionRunner  [PAUSED]
        |
        v
RusteeTradingEngine     [PAUSED]
        |
        v
Generation 10 ERC-6551 TBA  [ENGINE PATH PAUSED]
        |
        v
RobinhoodRestrictedTradeAdapter [PAUSED]
        |
        v
Explicitly allowlisted venue + selector
        |
        v
Output returned to Generation 10 TBA

Every control plane follows the Broker NFT owner where applicable.

## Defense layers

1. Capability Registry lifecycle and policy.
2. Trading Engine Runner allowlist.
3. Production Runner operator allowlist.
4. Runner standardized adapter-call decoding.
5. Runner intent asset/data binding.
6. Engine Adapter allowlist.
7. TBA engine-target allowlist.
8. Adapter exact-TBA caller binding.
9. Adapter token allowlist.
10. Adapter directed-pair allowlist.
11. Adapter venue allowlist.
12. Adapter venue-selector allowlist.
13. Exact-input pull.
14. Minimum-output check.
15. Venue allowance reset to zero.
16. Output/refund returned to exact TBA.
17. Independent pause controls.
18. NFT-following configuration authority.

## Safe default

Deployment alone cannot trade. All four execution gates remain paused and the Adapter has zero venue/token permissions.
