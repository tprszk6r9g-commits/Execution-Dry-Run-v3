# Rustee Broker v3.7.6.6 — Generation 10 Manual Recovery

## Fix

Generation 10 is an `EngineAuthorizedTradingAccount`. Its manual NFT-owner recovery
surface is:

`execute(address to, uint256 value, bytes data, uint8 operation)`

The Universal Asset Mover was still treating every active Trading TBA as the older
legacy Trading account and attempted `withdrawETH()` / `withdrawToken()`. Generation
10 does not expose those legacy withdrawal functions, so moves from Generation 10
could revert.

v3.7.6.6 makes the asset mover generation-aware.

### Engine-authorized Generation 10+

- Re-verifies the live ERC-6551 token binding.
- Re-verifies `owner()` equals the current Broker NFT `ownerOf()`.
- ETH recovery uses owner-signed ERC-6551 `execute(destination, value, 0x, 0)`.
- ERC-20 recovery uses owner-signed ERC-6551 `execute(token, 0, transfer(...), 0)`.
- A fresh `eth_estimateGas` and `eth_call` must pass before the wallet can sign.
- Trading Engine, Runner and Adapter can remain paused.

### Legacy Trading generations

The existing restricted `withdrawETH()` / `withdrawToken()` recovery behavior is
preserved.

## Safe test

1. Keep Generation 10 ACTIVE.
2. Keep TBA engine path, Trading Engine, Runner and Adapter PAUSED.
3. Open `Move Assets`.
4. Source: `Trading TBA`.
5. Destination: `Main owner wallet`.
6. Start with a tiny amount such as `0.000001 WETH` (or another token amount you
   are comfortable testing).
7. Press `Simulate exact move`.
8. Confirm the log says:
   - `PASS — exact move simulated`
   - `Recovery path: OWNER-SIGNED ERC-6551 execute()`
   - `Autonomous trading activation required: NO`
9. Only then press `Open wallet to sign`.
10. Confirm the transaction and wait for `CONFIRMED ✓`.
11. Refresh balances.

Do not test with the full balance first.

## Files changed

- `app.js`
- `index.html`
- `sw.js`
- `.github/workflows/generation-10-manual-recovery-ci.yaml`

No Solidity deployment is required.
