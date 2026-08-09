# Rustee Broker v3.4.1 — Validation Plan

Release validation must prove all of the following:

- executable JavaScript parses with `node --check`;
- every HTML ID is unique;
- all tab buttons resolve to existing panes;
- CSP inline-script SHA-256 exactly matches the executable script;
- the bundled tokenURI equals `assets/tokenURI_utf8.txt`;
- bundled metadata JSON parses;
- embedded artwork remains valid base64 WebP data;
- old `Max Trade`, `Max Daily`, and `Trades Per Day` traits are absent from the recommended payload;
- the legacy personal owner wallet is absent from current `index.html` and operational scripts;
- `ownerOf(uint256)` selector `0x6352211e` is present;
- metadata-admin selector `owner()` remains separate;
- normal transaction signer selection resolves to current NFT holder;
- metadata signer selection resolves to current NFT contract administrator;
- prepared wallet handoff performs no asynchronous owner/network work after the final signing tap;
- Strategy Lab / Autopilot remain browser-local and are not inserted into NFT metadata;
- source Solidity contracts are byte-identical to v3.4;
- project ZIP passes archive integrity testing;
- GitHub workflow integrity target set remains aligned with `scripts/update_integrity.py`.

No mainnet transaction is broadcast during build validation.
