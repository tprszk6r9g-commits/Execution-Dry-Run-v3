# Rustee Broker Differential ABI Recovery v3.8

v3.7 established that a six-word dynamic region is accepted by the
`0x6c606ce7` parser, with zero values reaching custom error `0x02b874a6`.

v3.8 performs differential probing of those six struct fields.

It changes one field at a time to:
- known addresses (WETH, NVDA, router, owner, registry, TBA)
- useful numeric values (1, fee 500, known $5-size target/output values,
  and a future deadline)

It then tests plausible field combinations.

A change in revert selector is treated only as evidence that execution moved
to another validation stage. It is not treated as proof of a complete ABI.

All calls are `eth_call`. No live transaction is sent.

Pages is deployed from a deterministic `site/` directory to avoid the
previous artifact-path 404 problem.
