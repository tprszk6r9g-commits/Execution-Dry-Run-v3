# v4.9.2 Setup

Upload the package preserving:

`.github/workflows/main.yaml`

The root `main.yaml` is included for easy iPhone access.

Your existing `ARCHIVE_RPC_URL` secret remains unchanged.

When you obtain the full authoritative Chainlink ETH/USD Data Streams feed ID,
add it under:

GitHub -> Settings -> Secrets and variables -> Actions -> Variables

as:

`ETH_USD_DATA_STREAM_ID`

Also add its official provenance URL as:

`ETH_USD_DATA_STREAM_PROVENANCE_URL`

Do not enter an abbreviated ID such as `0x0003...xxxx`.
