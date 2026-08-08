# Rustee Broker Production Input Resolution v4.9

v4.9 is the production-input resolution phase after v4.8.1.

It remains strictly read-only and cannot broadcast any mainnet transaction.

## Repository variables

Set only values you can document authoritatively. `ARCHIVE_RPC_URL` must be a GitHub Actions **secret**; the remaining non-sensitive inputs may be repository variables:

- `ARCHIVE_RPC_URL`
- `ETH_USD_FEED_ADDRESS`
- `ETH_USD_PROVENANCE_URL`
- `ETH_USD_HEARTBEAT_SECONDS`
- `ETH_USD_DATA_STREAM_ID`
- `ETH_USD_DATA_STREAM_PROVENANCE_URL`
- `SEQUENCER_PRODUCTION_OPTION`
- `ORACLE_AUDIT_URL`
- `ADAPTER_AUDIT_URL`

Allowed sequencer options:

- `REGISTRY_V2_CHAIN_SPECIFIC_GUARD`
- `KEEP_CURRENT_REGISTRY_PAUSED`

Do not invent feed addresses, Data Streams feed IDs, provenance, or audit evidence.

## Completion condition

v4.9 reports `readyForFinalMainnetPreflight: true` only when:

1. archive evidence passes with at least 8 successful historical samples;
2. liquidity continuity passes;
3. an authoritative ETH/USD candidate path is configured;
4. a production sequencer design is explicitly selected;
5. independent oracle and adapter review evidence is present.

Even then, every mainnet write flag remains false. The next phase is a separate final preflight.
