# Rustee Broker Trade ABI Recovery v3.7

v3.7 corrects the v3.6 interpretation of selector `0x523e3260`.
The successful context probes are consistent with ERC-6551
`isValidSigner(address,bytes)` returning its magic value.

The leading guarded trade candidate is `0x6c606ce7`, based on the actual
deployed runtime control flow: it enters a large owner-gated path with registry
reads, policy checks, balance accounting and external calls.

This phase sends only `eth_call` and optionally `debug_traceCall`.
It never sends a transaction.

The report is written to:

`data/trade-abi-recovery.json`

The page includes Copy JSON and Download JSON buttons.


## v3.7.1 Pages fix

GitHub Pages is now deployed from a dedicated `site/` directory.

The workflow explicitly copies:

- `index.html`
- `data/trade-abi-recovery.json`

into the Pages artifact and verifies both files exist before upload.

This fixes the prior green-workflow / 404-report mismatch.
