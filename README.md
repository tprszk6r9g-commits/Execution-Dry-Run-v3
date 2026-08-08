# Rustee Broker Production Infrastructure Gate v4.8

This phase stays **read-only** and performs no mainnet writes.

## Important new finding

Chainlink **Data Feeds are live on Robinhood Chain mainnet**, and Chainlink's
July 2026 Robinhood Chain rollout explicitly lists **ETH / USD** among the
available feeds. This means the earlier assumption that only Data Streams were
available is obsolete.

The workflow still refuses to invent the ETH/USD contract address. Supply the
exact address and provenance from Chainlink's official Price Feed Addresses
surface, then v4.8 validates the contract on Robinhood Chain.

## Repository variables to set

- `ARCHIVE_RPC_URL`
  - Use a Robinhood Chain archive-capable endpoint.
  - Robinhood currently recommends Alchemy for production RPC, and its docs say
    historical reads should use an archive endpoint.
- `ETH_USD_FEED_ADDRESS`
  - Exact Chainlink ETH/USD Data Feed contract on Robinhood Chain mainnet.
- `ETH_USD_PROVENANCE_URL`
  - Official Chainlink URL showing that exact feed/address.
- `ETH_USD_HEARTBEAT_SECONDS`
  - Production staleness threshold chosen after reviewing the feed's trigger parameters.
- `SEQUENCER_UPTIME_FEED_ADDRESS`
  - Optional. Only set this if an AggregatorV3-compatible uptime feed for Robinhood
    Chain is independently documented. Do not put the websocket sequencer feed here.

## What v4.8 proves

1. Canonical STONKBROKER/WETH pool, Registry and TBA are still present.
2. Candidate ETH/USD feed has code and supports AggregatorV3 reads.
3. Feed answer is positive and fresh under the configured heartbeat.
4. Archive RPC supplies at least 8 historical 30-minute TWAP observations.
5. Historical pool liquidity remains nonzero and at least 50% of latest in the sampled window.
6. Current Registry sequencer compatibility is explicitly reported rather than guessed.

## What v4.8 does NOT authorize

No oracle deployment, adapter deployment, Registry mutation, funding, approval,
unpause, trade, or transaction broadcast is authorized.

After v4.8 is green with production inputs, the next phase is a security-review
and deployment-preflight package, followed by a separately authorized tiny
mainnet transaction.
