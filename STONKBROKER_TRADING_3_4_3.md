# STONKBROKER Trading 3.4.3

## Asset identity
- Token: STONKBROKER
- Contract: `0xe934e36A439C94017B64a3FecE66AF12099aBF50`
- Chain: Robinhood Chain mainnet (4663)
- Classification: community ERC-20; **not** a canonical Robinhood Stock Token.

## Execution
Rustee reuses the stable owner-signed trading state machine. It verifies the token contract and `symbol()` live, probes Uniswap V3 WETH routes at 0.01%, 0.05%, 0.30% and 1.00%, selects the best successful quote, applies the Limits + Risk slippage ceiling, simulates the exact next transaction, and stops at **Open wallet to sign**.

BUY: Vault native ETH -> Router (WETH-compatible input) -> STONKBROKER -> Trading TBA.

SELL: Trading TBA -> Owner -> Vault -> exact Router approval -> STONKBROKER/WETH swap -> Vault WETH -> optional WETH unwrap to Vault ETH -> allowance revoke.

The existing wallet handoff, live policy controls, Metadata Studio, and Solidity/Foundry core are not modified.
