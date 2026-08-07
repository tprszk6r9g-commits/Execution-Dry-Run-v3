# Rustee Broker Execution Dry-Run v3

This is the final read-only execution gate before funding.

Important: Uniswap's own Robinhood Chain playbook currently says the V3 Dutch Reactor and OrderQuoter are deployed, but explorer verification and SDK/service wiring remain pending. Therefore this console intentionally will not call the system ready to fund or trade merely because the contracts have bytecode.

It checks:
- Rustee chain, ownership, paused policy, $5/$10/1-trade limits, owner/outsider authorization.
- Robinhood read-only NVDA asset metadata and price snapshot.
- NVDA canonical mainnet deployment.
- Chainlink verifier, UniswapX reactor, OrderQuoter, Permit2 bytecode.
- A $5 indicative NVDA intent based on Robinhood's read-only ask.
- Exact-route blockers before funding.

It NEVER:
- sends ETH or NVDA
- approves Permit2
- unpauses trading
- signs an order
- broadcasts a transaction
