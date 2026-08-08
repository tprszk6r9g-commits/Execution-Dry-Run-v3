# v4.7.2 compiler fix

This patch addresses the Solidity `Stack too deep` failure in
`test/BidirectionalStress.t.sol`.

Changes:
- Enables optimizer + `via_ir = true` in generated `foundry.toml`.
- Stops accumulating the entire CSV report in one Solidity string.
- Adds `vm.writeLine(...)`.
- Moves CSV row construction into `appendRow(...)`.
- Preserves the v4.7.1 stale-test isolation cleanup.
- Introduces no mainnet writes.

The workflow remains fork/read-only analysis.
