# Rustee Portfolio Terminal v2.8.2 — Trade Handoff Fix

Fixes the v2.8.1 regression where a successfully simulated trade reached the REAL MAINNET TRADE STEP confirmation but could be stopped before the injected wallet request.

## Change
The pre-sign gate is now transaction-scoped. It still requires Robinhood Chain 4663, the connected Broker NFT owner, exact `from`, an allowlisted Rustee/canonical destination, and deployed bytecode on the exact destination. It no longer blocks a valid trade because an unrelated optional runtime contract fails the global health sweep.

The full runtime health sweep remains available as a diagnostic and is not removed. Existing amount, slippage, simulation-expiry, route, sell-recovery, and transaction fingerprint protections remain in place.
