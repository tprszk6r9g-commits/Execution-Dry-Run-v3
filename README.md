# Rustee Broker Portfolio Executor v1.5

Adds an Account Center and Universal Asset Mover to the working v1.4 standalone.

## New
- Separate Accounts tab for Main Wallet, Vault, Trading, Rewards, Identity.
- Live ETH, NVDA and WETH balances across all five accounts.
- Custom ERC-20 support by contract address.
- Main wallet -> any TBA deposits.
- Vault / Rewards / Identity -> any account transfers through generic BrokerAccount execute.
- Trading TBA -> owner recovery through restricted withdrawToken / withdrawETH.
- Exact eth_estimateGas + eth_call simulation before every real move.
- 60-second simulation expiry and separate wallet confirmation.

Trading TBA intentionally cannot send arbitrary assets directly to another TBA: its recovery methods return assets to the current Broker NFT owner. To move Trading -> another TBA, withdraw to Owner first, then send Owner -> destination.
