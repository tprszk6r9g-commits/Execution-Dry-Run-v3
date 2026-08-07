# Rustee Broker ABI + Policy Recovery v3.6

This phase does not trade.

It reads the deployed Trading TBA and implementation on Robinhood Chain
mainnet and generates `data/abi-recovery.json`.

The primary target is selector `0x523e3260`. Although that selector is widely
associated with `isValidSigner(address,bytes)`, Rustee's deployed runtime
behind the selector exhibits a substantially larger policy/accounting/external
call path. v3.6 therefore records observed behavior rather than trusting a
public selector label.

The workflow also probes the remaining dispatcher selectors and sends
ABI-correct `address,bytes` calls with zero-filled contexts of increasing
length to expose parser/revert boundaries.

All probes use `eth_call`. There are no approvals, funding, unpause calls,
signatures, or transaction broadcasts.
