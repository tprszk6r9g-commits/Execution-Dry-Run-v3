# Rustee Broker v3.7.6.7 — Generation-Aware Sweep

One-Tap Sweep now shares the same Generation 10 recovery behavior proven in Move Assets.

For the active engine-authorized Trading TBA:
- ETH uses NFT-owner-signed ERC-6551 execute(destination, value, 0x, 0).
- WETH/ERC-20/stock tokens use NFT-owner-signed ERC-6551 execute(token, 0, transfer(...), 0).
- The live TBA owner/token binding is verified before the plan is armed.
- Trading Engine, Runner and Adapter remain paused.

Legacy Trading generations preserve withdrawETH()/withdrawToken().

## First test
1. Generation 10 ACTIVE.
2. Autonomous layers PAUSED.
3. One-Tap Sweep Planner → Scope: Trading TBA.
4. Check only WETH for the first test.
5. Build sweep plan.
6. Confirm the route says OWNER-SIGNED ERC-6551 execute().
7. Simulate all.
8. Execute next sweep step.
9. Sign the single Rabby request and wait for confirmation.
10. Refresh balances.

Then test ETH separately, then discovered stock tokens. Do not start with All TBAs + all assets.
