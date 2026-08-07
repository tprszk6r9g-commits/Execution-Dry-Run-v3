# Rustee Broker Execution Dry-Run v3.3

This release hardens the Robinhood NVDA snapshot pipeline.

The workflow:
1. Fetches Robinhood's official read-only `/rhj/assets`.
2. Fetches `/rhj/prices/NVDA`.
3. Validates the canonical chain-4663 NVDA address.
4. Requires active status, a valid bid/ask, and no trading halt.
5. Writes one atomic `data/nvda-snapshot.json`.
6. Deploys that exact generated file with GitHub Pages.

The browser no longer falls back to a cross-origin Robinhood fetch. It fails closed
if the generated snapshot is missing, invalid, or over 20 minutes old.

The 20-minute threshold is for this read-only dry-run UI only. It is NOT suitable
as a future execution-price freshness standard. A real execution path should use
a fresh executable DEX quote/simulation immediately before signing.

No approvals, funding, unpause, signatures, or trades are sent.
