# Rustee Broker v3.7.5 — Rehearsal Permission Gate

This release extends the verified v3.7.4 Generation 10 production execution layer without redeploying any v3.7.4 contracts.

## Purpose

Stage and verify a single exact directed ERC-20 trading path before any autonomous execution is unpaused.

The UI requires:
- exact token-in contract
- exact token-out contract
- exact venue/router contract
- exact 4-byte venue selector
- optional tiny exact rehearsal allowance

## Safety

The v3.7.5 UI does not contain any function that unpauses the Production Runner, Production Adapter, Trading Engine, or Generation 10 engine path. It does not execute a trade.

Permission staging uses the existing Adapter controls: `setToken`, `setPair`, `setVenue`, and `setVenueSelector`. Every write is pre-simulated and wallet signed.

The tiny allowance step routes the ERC-20 `approve(adapter, exactAmount)` call through the Generation 10 TBA owner execution path. It verifies the resulting allowance. A dedicated revoke button sets it back to zero and verifies revocation.

## Mainnet constants

Robinhood Chain mainnet chain ID: 4663.
Canonical WETH from Robinhood Chain docs: `0x0Bd7D308f8E1639FAb988df18A8011f41EAcAD73`.

No venue/router is hard-coded in v3.7.5. A venue must be independently verified before permissions are signed.

## Next checkpoint

After permission gate verification and (if desired) tiny exact allowance verification, keep every autonomous layer paused. The next release should construct and simulate one exact tiny trade intent, then provide a deliberate staged unpause/rehearsal/re-pause/revoke sequence.
