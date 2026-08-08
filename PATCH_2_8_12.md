# Rustee v2.8.12 — Interrupted Sell Recovery

Adds a custody-aware recovery path for interrupted SELL workflows.

- `Inspect sell custody` shows the selected stock-token balance in Trading TBA, Owner EOA, and Vault TBA, plus Vault WETH and native ETH.
- `Resume incomplete sell` never repeats the Trading-TBA withdrawal. It resumes from Owner -> Vault or directly from Vault depending on current on-chain custody.
- Recovery always obtains a fresh route quote and fresh minimum-output value before preparing the remaining swap.
- Sell state is persisted locally while a sell is incomplete and cleared after all required steps finish.
- Every recovery transaction still requires simulation and a separate owner-wallet signature.
- CSP script hash and frontend integrity manifest were regenerated for this build.
