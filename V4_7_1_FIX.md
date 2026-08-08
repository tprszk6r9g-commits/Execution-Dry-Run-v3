# v4.7.1 isolation fix

This patch fixes the GitHub Actions failure caused by stale Solidity tests from prior phases.

Before generating the v4.7.1 Foundry project, the workflow now runs:

```bash
rm -rf src test out cache
mkdir -p src test data
```

Why: `forge test --match-test ...` still compiles every Solidity source under the configured
`src` and `test` directories. An old `test/RusteeFork.t.sol` therefore caused compilation
to fail before the v4.7 bidirectional test could run.

The v4.7.1 generated test keeps checksum-independent address literals using
`address(bytes20(hex"..."))`.

No mainnet writes are introduced.
