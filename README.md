# Rustee Broker Portfolio Executor v1.4 — Trading TBA Withdrawal Fix

## What was wrong in v1.2/v1.3

The standalone attempted to move ERC-20 assets out of the Trading TBA by calling the generic ERC-6551 `execute(address,uint256,bytes,uint8)` function.

That works on Rustee's generic Vault / Rewards / Identity accounts, but **the Trading TBA uses StockTradingAccount**, whose design deliberately does not expose generic `execute()`.

Therefore the simulation correctly reverted.

## Correct deployed method

The verified StockTradingAccount includes:

```solidity
function withdrawToken(address tokenAddress, uint256 amount)
    external
    nonReentrant
```

It verifies the caller is the current Broker NFT owner, then transfers the ERC-20 token to `owner()`.

Verified selectors from the compiled v0.6.1 ABI:

- `withdrawToken(address,uint256)` → `0x9e281a98`
- `withdrawETH(uint256)` → `0xf14210a6`

v1.4 now uses `withdrawToken()` directly.

## Safety

The real withdrawal remains locked until:

1. correct owner wallet is connected;
2. chain 4663 is active;
3. requested amount is <= Trading TBA balance;
4. `eth_estimateGas` succeeds;
5. the exact call succeeds under `eth_call`.

Only then is the real wallet-signature button enabled.

## GitHub Pages

Replace root `index.html` and `.github/workflows/main.yaml` with the files in this package.
