# Rustee STONKBROKER Production Oracle Analysis v4.5

v4.5 is read-only.

It analyzes the canonical STONKBROKER/WETH Uniswap V3 pool at:

- 5 minutes
- 15 minutes
- 30 minutes
- 60 minutes

It computes arithmetic-mean ticks, derives WETH-per-STONKBROKER, measures
cross-window dispersion, and nominates a candidate production window only when
the snapshot is sufficiently stable.

It also validates optional production inputs:

- `WETH_USD_FEED_ADDRESS`
- `WETH_USD_FEED_PROVENANCE_URL`
- `WETH_HEARTBEAT_SECONDS`

Missing values remain blockers. The workflow does not guess a feed address.

Authoritative Robinhood documentation recorded by the phase:

- https://docs.robinhood.com/chain/data-streams/
- https://docs.robinhood.com/chain/connecting/
- https://docs.robinhood.com/chain/contracts/

Important: snapshot dispersion is not a complete manipulation-cost analysis.
Historical liquidity/depth analysis and independent security review remain
required before any production deployment or Registry write.

No mainnet writes, approvals, funding, unpause, trade, or broadcast are enabled.


## v4.5.1 display fix

The analysis logic is unchanged.

v4.5.1 removes the browser-side `fetch('./stonkbroker-v45.json')` dependency.
After the workflow generates and validates the JSON report, GitHub Actions
embeds that report directly into `index.html` before publishing Pages.

This avoids iOS/in-app-browser URL parsing failures such as:

`The string did not match the expected pattern.`

A green workflow now publishes a self-contained report page.


## v4.5.2 TWAP math correction

v4.5.2 replaces the fragile parser that extracted integers from Foundry `cast`
pretty-printed output. That formatting can include human-readable numeric
annotations, causing the second parsed integer to be something other than the
second tick cumulative.

The corrected workflow:

- calls `observe([window,0])` through raw JSON-RPC `eth_call`;
- ABI-decodes the returned `int56[]` and `uint160[]` directly;
- sign-decodes each `int56`;
- computes `tickDelta = cumulativeNow - cumulativePast`;
- divides by the requested window;
- applies Uniswap OracleLibrary-compatible negative rounding;
- rejects any mean tick outside [-887272, 887272];
- rejects NaN/Infinity/non-finite outputs;
- records raw cumulatives, tick delta, corrected mean tick, human WETH/STONK,
  and WETH/STONK scaled to 1e18.

This is still read-only/fork-analysis infrastructure and authorizes no mainnet
deployment, Registry write, funding, approval, unpause, trade, or broadcast.
