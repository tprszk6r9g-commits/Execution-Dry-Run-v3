# Rustee Phase 8 — Evidence & Signed-Report Replay Guide

Phase 8 remains read-only.

## Signed replay evidence expected
Provide a JSON artifact or report that, at minimum, identifies:
- the ETH/USD Data Streams feed ID;
- the Robinhood Chain verifier proxy;
- whether the signed report replay/verification succeeded;
- timestamp / report context;
- transaction or fork-run evidence if applicable.

The UI accepts common boolean fields such as:
- `verified: true`
- `signedReportReplayVerified: true`
- `productionVerified: true`

This is structural evidence only. A human reviewer must still inspect provenance and scope.

## Audit evidence expected
Provide:
- Registry V2 / oracle integration audit URL;
- adapter / execution-path audit URL;
- reviewed commit SHA or artifact hash;
- remediation summary.

The final evidence bundle never authorizes mainnet writes. It marks the package ready for final human/auditor review only.
