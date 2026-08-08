# Rustee Broker v4.9.3

Read/fork-only Data Streams + Registry V2 engineering gate.

## Public configuration
- Robinhood Chain: 4663
- ETH/USD candidate feed ID: `0x000362205e10b3a147d02792eccee483dca6c7b44ecce7012cb8c6e0b68b3ae9`
- Data Streams Verifier Proxy: `0xcE73c8ad08CBDEaCa6078BF0627C8fe0a9a536E7`

## Required GitHub secret
`ARCHIVE_RPC_URL` — your Alchemy Robinhood Chain archive-capable endpoint.

Do not commit API keys or Data Streams credentials.

## What this phase does
1. Confirms chain ID and verifier bytecode.
2. Validates the feed ID is bytes32-shaped.
3. Compiles and fork-tests a Robinhood-specific Registry V2 guard prototype.
4. Statistically rejects broadcast primitives.
5. Keeps all production writes disabled.

Signed Data Streams report retrieval/replay is intentionally not falsely marked PASS: it requires authenticated Chainlink Data Streams access and the exact report verification integration.
