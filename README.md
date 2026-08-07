# Rustee Broker Execution Dry-Run v3.4

Fixes the v3.2 classic infrastructure false-fail and adds live read-only V3
QuoterV2 exact-output quote competition.

Canonical selectors used:
- QuoterV2 `quoteExactOutputSingle((address,address,uint256,uint24,uint160))`
  = `0xbd21704a`
- SwapRouter02 `exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))`
  = `0x5023b4df`

The app builds a conservative $4.975 NVDA target, quotes all discovered direct
NVDA/WETH pools, selects the route requiring the least WETH, and constructs the
candidate SwapRouter02 calldata.

Because the Trading TBA is intentionally unfunded and unapproved, the exact
funded router simulation is not yet proven. Funding remains locked.

No approvals, funding, unpause, signatures, or transactions are sent.
