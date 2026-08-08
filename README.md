# Rustee NVDA Manual Trade Executor v1

A standalone, mobile-friendly Robinhood Chain mainnet executor for a tiny manually approved NVDA purchase.

## Architecture

Owner wallet -> Vault TBA -> Uniswap SwapRouter02 -> NVDA -> Trading TBA

- Owner: `0x8fC320c8582f812695b6f62b2b5d13B14475B955`
- Vault TBA executor: `0x8ad8bd35d33dd7b4d0de81f809f5b7f92623956d`
- Trading TBA recipient: `0x522f5637f2c556aad9b2245f3b8e6bf4dfd9a654`
- WETH: `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73`
- NVDA: `0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC`
- SwapRouter02: `0xCaf681a66D020601342297493863E78C959E5cb2`
- QuoterV2: `0x33e885ed0ec9bf04ecfb19341582aadcb4c8a9e7`

## Why Vault TBA?

The deployed restricted Trading TBA is intentionally governed by the StockTokenRegistry, which remains paused and has unresolved production sequencer/oracle configuration. For this one manual proof transaction, the generic Vault TBA performs the router call and sends NVDA directly to the Trading TBA.

This does not unpause or alter the Registry.

## Safety flow

1. Connect the NFT owner wallet.
2. Verify chain, TBA ownership, and contract code.
3. Get live on-chain quotes across fee tiers.
4. Fund the Vault TBA only if needed.
5. Simulate the exact transaction with `eth_call` and gas estimation.
6. The real trade button unlocks only after simulation.
7. Wallet confirmation is required for the real transaction.

No private keys or seed phrases are accepted.
