# Rustee Broker Policy + Fork Gate v3.5

v3.5 adds a true forked funded execution test with **no real funds**.

GitHub Actions:
- fetches the current Robinhood NVDA ask;
- builds a conservative $4.975 NVDA target;
- forks Robinhood Chain mainnet;
- queries QuoterV2;
- temporarily impersonates the Trading TBA inside the fork only;
- gives that forked address simulated ETH/WETH;
- approves SwapRouter02 only inside the fork;
- executes the best 0.05% or 0.30% exact-output route;
- verifies NVDA arrived;
- writes `data/fork-simulation.json`.

This proves router/pool settlement mechanics, but it intentionally does **not**
claim the real Rustee policy path is complete. The fork impersonation bypasses
the Trading TBA's own execution wrapper, so the final owner → TBA → policy →
router call still must be identified and simulated.

No live-chain approval, funding, unpause, signature, or trade occurs.
