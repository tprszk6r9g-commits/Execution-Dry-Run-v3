# Rustee Broker v4.9.4

Verifier + policy fork gate. This package builds on the green v4.9.3.3 baseline.

## Public inputs
- Chain: Robinhood Chain mainnet, chain ID 4663
- ETH/USD Data Streams feed candidate: `0x000362205e10b3a147d02792eccee483dca6c7b44ecce7012cb8c6e0b68b3ae9`
- Verifier Proxy: `0xcE73c8ad08CBDEaCa6078BF0627C8fe0a9a536E7`

## Required GitHub secret
- `ARCHIVE_RPC_URL`

## Tests
- Registry V2 starts paused and only owner can unpause.
- Fresh, verified, correct-feed report at <= $5 passes policy.
- > $5 rejects.
- Unverified report rejects.
- Stale report rejects.
- Wrong feed rejects.

## Security boundary
No live signed Data Streams report is fabricated. Authenticated report retrieval/replay remains a separate gate. There are no mainnet broadcast primitives in src/ or test/.
