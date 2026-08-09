# Rustee Broker v3.4.3 — STONKBROKER Trading

Adds STONKBROKER (`0xe934e36A439C94017B64a3FecE66AF12099aBF50`) as an explicitly classified community ERC-20 in Rustee's existing manual owner-signed trading terminal. It is not inserted into the canonical Robinhood Stock Token catalog or Registry.

The same proven BUY/SELL execution state machine, risk profile, slippage checks, recovery flow, cost-basis ledger, receipt verification and Rabby handoff are reused. Live token identity checks occur before quoting. The Quoter probes direct WETH routes across V3 fee tiers and retains the existing USDG fallback.

No Solidity or Foundry execution-core files are changed. No autonomous broadcasting is added.
