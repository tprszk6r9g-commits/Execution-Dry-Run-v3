# Rustee Broker v3.4 — Portfolio Risk Engine + Limits Control Center

Built directly on v3.3 Strategy Lab / Paper Twin, v3.2 Supervised Autopilot, and the verified v3.1.2 mobile wallet handoff.

## Added
- New **Limits + Risk** tab as the single operator source of truth for trade/risk limits.
- Editable maximum BUY/trade, daily BUY budget, daily and rolling-7-day realized-loss stops, trades/day, cooldown, max slippage, max open positions, one-ticker allocation, deployed stock cap, Vault ETH reserve, and monitor interval.
- Explicit **effective-limit calculation**: operator ceiling vs current hard engine ceiling vs readable Registry reference ceiling; Rustee takes the lowest applicable positive value.
- Read-only Registry policy refresh: max trade, daily max, trades/day, paused state, venue and spender allowlist status.
- Correct labeling that the Registry is a production-policy reference; the current supervised swap route is not falsely represented as Registry-gated.
- Live risk preflight: current BUY spend, realized P&L, rolling-7-day P&L, trade count, Trading TBA position count, valued deployed stock capital, and Vault native ETH.
- Portfolio controls for new BUYs: maximum positions, maximum deployed stock capital, one-ticker share of deployed cap, optional fail-closed behavior when an existing Trading position cannot be valued, and minimum Vault ETH reserve after a BUY.
- Risk-reducing SELL override (default ON): exits can remain available after loss/trade-count stops while transaction safety/slippage checks still apply.
- Manual Trade, Autopilot sizing, Autopilot rule creation, Strategy Lab entry sizing, and Strategy promotion all consume the centralized profile.
- Autopilot duplicates are now read-only mirrors of Limits + Risk instead of independent settings.
- Risk profile export; Rustee full backup automatically includes risk state because all Rustee localStorage keys are captured.

## Current hard ceilings retained
- `$5` BUY/trade frontend engine ceiling.
- `0.005 ETH` maximum computed BUY input ceiling.
- `DataStreamsPolicyGateV2.sol` remains byte-for-byte unchanged and still contains its compiled `$5` policy constant.

## Wallet/signing invariant
No v3.4 risk function calls `eth_sendTransaction`. Candidate and risk checks happen before route/simulation; the final real transaction still crosses the v3.1.2 direct **Open wallet to sign** user-gesture boundary.

## Contract stability
No Solidity source, Foundry configuration, or contract tests were modified.
