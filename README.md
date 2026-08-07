# Rustee Broker Execution Dry-Run v3.2

v3.2 adds a fail-closed Classic Uniswap route probe.

Why:
- Official UniswapX Robinhood documentation says the V3 Dutch Reactor and OrderQuoter are deployed, but SDK/service wiring is still pending.
- The same official playbook says classic routing surfaces are deployed on Robinhood Chain, including Uniswap v3/v4 and SwapRouter02.
- This verifier therefore checks both paths without sending transactions.

New read-only checks:
- WETH bytecode
- SwapRouter02 bytecode
- V3 QuoterV2 bytecode
- V4 PoolManager bytecode
- SwapRouter02.factory() discovery
- Direct NVDA/WETH V3 pool discovery at fee tiers 0.01%, 0.05%, 0.30%, and 1.00%

Important:
A discovered pool is NOT treated as an executable quote. Funding remains locked until an actual route quote and full eth_call simulation from the Trading TBA context succeed.

No approvals, funding, unpause, signatures, or trades are sent.
