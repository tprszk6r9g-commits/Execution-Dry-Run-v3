# Rustee Broker Data Streams + Sequencer Resolution v4.9.2

This phase locks in two production architecture decisions:

1. **ETH/USD:** Chainlink Data Streams through Robinhood Chain's verified
   verifier proxy.
2. **Sequencer protection:** `REGISTRY_V2_CHAIN_SPECIFIC_GUARD`.

The current deployed Registry remains paused.

## Required GitHub inputs

`ARCHIVE_RPC_URL` remains a GitHub Actions **secret** and is already expected to
be configured.

Add these repository variables only when you have authoritative values:

- `ETH_USD_DATA_STREAM_ID`
- `ETH_USD_DATA_STREAM_PROVENANCE_URL`
- `ETH_USD_SIGNED_REPORT_EVIDENCE_URL`
- `ORACLE_AUDIT_URL`
- `ADAPTER_AUDIT_URL`

Do not invent or abbreviate the feed ID.

## What v4.9.2 does

- rechecks deployed Rustee/Robinhood bindings;
- reconfirms archive historical-state access;
- validates a full bytes32 Data Streams feed ID if supplied;
- pins Robinhood's Data Streams verifier proxy;
- selects the Registry V2 chain-specific guard architecture;
- generates `REGISTRY_V2_GUARD_SPEC.md`;
- records audit evidence inputs;
- keeps every mainnet write permission false.

## Next phase

`v4.9.3` should replay a real signed ETH/USD Data Streams report through the
Robinhood verifier path and implement/test the Registry V2 guard on a fork.

No live transaction is authorized here.
