# Rustee Broker v3.2 Validation

Validation targets for this build:

- v3.1.2 wallet handoff path retained.
- No Solidity source/test/foundry changes.
- Autopilot cannot invoke `eth_sendTransaction`; it only calls the existing quote/build/simulate functions.
- One active candidate maximum.
- Candidate preparation stops at the existing wallet-signature button.
- Kill switch clears the queued candidate and disables monitoring.
- Daily budget, daily realized-loss, cooldown, pending-receipt and incomplete-SELL locks are enforced before queueing.
- CSP inline-script hash regenerated.
- Frontend integrity manifest regenerated.
- PWA cache bumped to v3.2.
- GitHub Pages workflow retained.
