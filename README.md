# Rustee Broker Fork Policy Path v3.9

## Key correction from v3.8

`0x02b874a6` is the custom error selector for `TradingPaused()` in the deployed
`StockTradingAccount`.

The v3.8 probes all reached that same error because `executeTrade` checks the
registry pause flag *before* request validity, asset allowlists, adapter
allowlists, quotes, balances, or venue execution.

Therefore ABI recovery is no longer the blocker.

Exact function ABI:

`executeTrade(address,(address,address,uint256,uint256,uint256,bytes))`

Selector:

`0x6c606ce7`

TradeRequest:

1. `address tokenIn`
2. `address tokenOut`
3. `uint256 amountIn`
4. `uint256 minAmountOut`
5. `uint256 deadline`
6. `bytes venueData`

## What v3.9 does

The GitHub Action runs a **Foundry mainnet fork only**. It:

- verifies a live NVDA target,
- deploys fork-local mock price/sequencer feeds,
- configures WETH and NVDA in the deployed registry on the fork,
- deploys a fork-local adapter that targets the live router,
- allows adapter / venue / spender on the fork,
- unpauses the existing $5 / $10 / 1-trade policy on the fork,
- simulates WETH funding of the trading TBA,
- calls the actual deployed `StockTradingAccount.executeTrade`,
- verifies NVDA receipt,
- verifies WETH spend stays within the request maximum,
- verifies router allowance is cleared back to zero.

It writes:

`data/v39-policy-path.json`

## Safety gate

This package does **not** authorize or perform live-mainnet funding, approvals,
registry configuration, unpausing, or trade broadcasting. Those remain false in
the report's execution gate.

## v3.9.1 compile correction

The first v3.9 GitHub run stopped during Solidity compilation because Solidity
0.8.26 treated the all-lowercase 20-byte Quoter literal as an address literal
with an invalid checksum. v3.9.1 encodes the same Quoter address as a numeric
`uint160` literal and casts it to `address`. No protocol logic or safety gate
was changed.

## v3.9.2 compile correction

The v3.9.1 run exposed the same Solidity 0.8.26 checksum enforcement on the TBA
literal. v3.9.2 eliminates the entire class of failures by encoding **all**
hard-coded 20-byte addresses in the generated Solidity harness as numeric
`uint160` literals explicitly cast to `address`.

This changes no address values, protocol logic, policy settings, fork behavior,
or safety gates.

## v3.9.3 compile correction

Solidity 0.8.26 also applies address-literal checksum rules to a 40-hex-digit
literal even when it appears inside `uint160(...)`.

v3.9.3 removes hexadecimal address literals from the generated Solidity
entirely. Every hard-coded address is represented as its exact **decimal
160-bit integer** and then converted with `address(uint160(...))`.

This preserves the exact address bytes while avoiding Solidity's address
checksum parser altogether. No protocol behavior or safety gate changed.
