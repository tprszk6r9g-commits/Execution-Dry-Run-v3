# Rustee Broker v3.4.4 — Transfer Readiness + Ownership Migration Check

- Adds a read-only Transfer Readiness panel to NFT + Identity.
- Checks all four TBA `token()` bindings against Broker NFT #1.
- Checks all four live TBA `owner()` values against current `ownerOf(#1)`.
- Tests a proposed new owner address for zero/self/TBA hazards.
- Warns when the proposed owner is a contract wallet.
- Separates metadata administrator authority from trading/TBA ownership.
- Explains that browser-local Strategy Lab, Autopilot, receipts and cost-basis state do not transfer with the NFT.
- Does not encode or broadcast an NFT transfer.
- Preserves v3.4.3 STONKBROKER trading and the established mobile wallet handoff.
