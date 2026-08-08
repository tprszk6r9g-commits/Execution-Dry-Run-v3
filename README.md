# Rustee Broker Production Infrastructure Decision v4.8.1

This package is the next read-only phase after v4.8.

## What it does

- Re-verifies the canonical STONKBROKER/WETH pool, deployed Registry, trading TBA, and Robinhood Chain Data Streams verifier proxy.
- Accepts an optional archive-capable Robinhood Chain RPC through `ARCHIVE_RPC_URL`.
- Supports two non-invented ETH/USD candidate paths:
  1. an authoritative AggregatorV3 feed, if a real Robinhood Chain address + provenance are supplied;
  2. Chainlink Data Streams, if an authoritative bytes32 feed ID + provenance are supplied.
- Records Robinhood's documented sequencer websocket as a websocket/Nitro feed and explicitly refuses to treat it as an AggregatorV3 uptime oracle.
- Keeps every mainnet write gate disabled.

## GitHub repository variables

You may set:

- `ARCHIVE_RPC_URL`
- `ETH_USD_FEED_ADDRESS`
- `ETH_USD_PROVENANCE_URL`
- `ETH_USD_HEARTBEAT_SECONDS`
- `ETH_USD_DATA_STREAM_ID`
- `ETH_USD_DATA_STREAM_PROVENANCE_URL`

Do not invent values. Leave unavailable values blank.

## GitHub workflow location

The workflow must be committed at:

`.github/workflows/main.yaml`

A second `main.yaml` is included at the ZIP root only to make it easy to see/copy on iPhone.

## Safety boundary

v4.8.1 does not deploy contracts, modify the Registry, fund the TBA, approve a spender, unpause trading, or broadcast a trade.
