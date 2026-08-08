# Rustee Broker Standalone v1.1

Adds a Trading TBA portfolio/withdrawal panel to the proven manual NVDA executor.

## New
- Shows NVDA in the Trading TBA and owner wallet.
- Accepts any ERC-20 contract address and reads symbol, decimals, Trading TBA balance, and owner balance.
- “Use full balance” helper.
- Simulates `Trading TBA -> ERC20.transfer(owner, amount)` with `eth_estimateGas` and `eth_call`.
- Real move button stays locked until simulation succeeds and always requires the owner wallet confirmation.

No seed phrase or private key is requested or stored.
