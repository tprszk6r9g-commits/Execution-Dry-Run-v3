# Rustee Broker v3.2 — Supervised Autopilot

Built on the verified v3.1.2 Wallet Handoff Hotfix.

## Added
- Dedicated Autopilot tab.
- Operator-defined BUY/SELL trigger rules.
- Price-at/above, price-at/below, position-P&L-at/above, and position-P&L-at/below triggers.
- BUY sizing in USD and SELL sizing as a percentage of the Trading TBA position.
- Continuous evaluation while the Rustee page is active.
- Automatic candidate queueing.
- Optional automatic quote + route-plan build + exact first-step simulation.
- Daily BUY budget, per-candidate cap, realized-loss stop, cooldown, slippage ceiling, pending-transaction/recovery locks.
- Single active candidate lock to prevent duplicate orders.
- Decision/risk audit log and local kill switch.
- Candidate is cleared after the matching trade confirms on-chain.

## Deliberate execution boundary
The Autopilot does **not** autonomously call `eth_sendTransaction` and does not bypass the wallet. A prepared candidate stops at the existing v3.1.2 **Open wallet to sign** boundary. Every real transaction still requires the owner wallet authorization.

## iPhone note
Browser/PWA timers may be suspended by iOS while the app is backgrounded or the screen is locked. Monitoring resumes and re-evaluates when Rustee becomes visible again.

## Stability
No Solidity contract, Foundry configuration, or contract test was modified for v3.2.
