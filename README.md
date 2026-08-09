# Rustee Broker v3.7.4 — Production Execution Layer Candidate

## Current release

v3.7.4 adds the missing execution layer around the already-deployed Generation 10 engine-authorized ERC-6551 TBA.

This release DOES NOT create another TBA generation.

Generation 10 remains the canonical engine-ready generation for this release.

## New in v3.7.4

### RusteeProductionRunner.sol
A narrow operator relay bound to:
- one Broker NFT
- one token ID
- one Trading Engine
- one production Adapter
- one expected chain ID

Security behavior:
- starts PAUSED
- holds no trading assets
- cannot make arbitrary calls
- only NFT-owner-authorized operators can submit
- Guardian may pause but cannot unpause
- configuration authority follows `ownerOf(tokenId)`
- only the standardized production Adapter selector is accepted
- BUY intents bind `intent.asset` to tokenOut
- SELL intents bind `intent.asset` to tokenIn
- amount fields are bound to the encoded adapter trade

### RobinhoodRestrictedTradeAdapter.sol
A fail-closed exact-input ERC-20 spot adapter bound to:
- Broker NFT
- token ID
- exact Generation 10 TBA
- exact generation
- expected Robinhood Chain ID

Security behavior:
- starts PAUSED
- accepts calls only from the exact bound TBA
- no native ETH trading path
- no tokens enabled by default
- no token pairs enabled by default
- no venues enabled by default
- no venue selectors enabled by default
- every token, pair, venue, and venue function must be explicitly authorized
- minimum-output enforcement
- fee-on-transfer inputs rejected
- venue ERC-20 allowance is reset to zero after use
- output is returned only to the bound TBA
- unused input is returned to the bound TBA
- reentrancy lock
- NFT ownership transfers configuration authority automatically

## Generation 10 integration

The app now contains a v3.7.4 execution-layer card inside Engine Setup.

The intended iPhone flow is:

1. Verify the existing Generation 10 core stack.
2. `A · Deploy restricted adapter`
3. `B · Deploy production runner`
4. Optionally enter a production operator address.
5. `C · Bind Runner + Adapter safely`
6. `Verify execution layer`

The app performs wallet simulation/confirmation using the same injected-wallet safety path as the existing Engine Setup deployment system.

### What binding does

Binding authorizes three exact edges:

- Generation 10 TBA -> Production Adapter
- Trading Engine -> Production Adapter
- Trading Engine -> Production Runner

If an operator address is supplied, the Runner also records it as an authorized operator.

### What binding DOES NOT do

It does not:
- unpause the Generation 10 TBA engine path
- unpause the Trading Engine
- unpause the Production Runner
- unpause the Production Adapter
- allow any trading token
- allow any token pair
- allow any DEX/venue
- allow any venue function selector
- fund the TBA
- execute a trade

The safe staging state should therefore remain inert after deployment.

## Required verification state after v3.7.4 deployment

Expected:

- Generation 10 TBA: unchanged
- TBA -> Adapter allowlist: PASS
- Engine -> Adapter allowlist: PASS
- Engine -> Runner allowlist: PASS
- Production Runner paused: true
- Production Adapter paused: true
- Trading Engine paused: true
- TBA engine path paused: true
- Adapter tokens: none
- Adapter pairs: none
- Adapter venues: none
- Adapter venue selectors: none

Do not fund or activate the autonomous path at this checkpoint.

## Test qualification

Local Foundry qualification using Solidity 0.8.26:

- Full Rustee suite: 53/53 PASS
- Production execution-layer unit/security suite: 14/14 PASS
- Full production execution integration tests: 2/2 PASS
- Minimum-output fuzz property: 5,000 runs PASS
- Full capability -> Runner -> Engine -> ERC-6551 TBA -> Adapter -> venue path PASS
- Venue/output failure atomic rollback PASS

### Important

Passing tests are not a substitute for an independent smart-contract security audit. This release should remain paused and low-risk until venue configuration and tiny-value rehearsal are separately completed.

## Deployment script

`script/DeployProductionExecutionLayer.s.sol`

The script attaches the execution layer to an EXISTING engine-authorized TBA generation.

It verifies:
- current NFT owner
- exact Broker NFT
- exact token ID
- exact Registry V2
- exact Trading TBA
- exact generation
- Trading Engine is paused
- TBA engine path is paused

It then deploys:
- `RobinhoodRestrictedTradeAdapter`
- `RusteeProductionRunner`

and binds the three allowlist edges while leaving every execution component paused.

## GitHub CI

New workflow:

`.github/workflows/production-execution-layer-ci.yaml`

It runs:
- formatting check for v3.7.4 files
- full build
- full Rustee test suite
- 5,000-run production execution-layer fuzz gate

## Files added

- `src/RusteeProductionRunner.sol`
- `src/RobinhoodRestrictedTradeAdapter.sol`
- `test/RusteeProductionExecutionLayer.t.sol`
- `script/DeployProductionExecutionLayer.s.sol`
- `.github/workflows/production-execution-layer-ci.yaml`
- `PRODUCTION_EXECUTION_LAYER_3_7_4.md`

## Files changed

- `index.html`
- `sw.js`
- `README.md`

The service-worker cache key was bumped for v3.7.4.

The CSP SHA-256 hash in `index.html` was regenerated after the JavaScript update so wallet JavaScript remains allowed on iPhone/Safari.

## Release history — newest first

### v3.7.4
Production Runner + restricted Robinhood execution Adapter candidate, complete integration tests, iPhone deployment controls, safe paused-by-default binding.

### v3.7.3.1
Wallet-connect CSP/cache hotfix after the Generation 10 Manager bridge.

### v3.7.3
Generation 10 TBA Manager bridge. Engine-authorized Generation 10 becomes visible as ENGINE READY without using old generation activation logic.

### v3.7.2
Website + deployment integration for the engine-authorized ERC-6551 TBA, Registry V2, and Trading Engine.

### v3.7.1
Engine-authorized ERC-6551 Trading Account contract qualification.

### v3.7
Capability-gated Trading Engine architecture and account execution boundary.

### v3.6
Capability Registry / signed capability hardening.

### v3.5
Rotating Trading TBA Manager and generation history.

## Next phase

Do not jump directly to live trading.

The next phase should configure and qualify an actual Robinhood Chain venue path:

1. choose the exact venue/router
2. verify its deployed contract
3. select the exact venue function selector
4. allow only required input/output tokens
5. allow only required directed token pairs
6. build the venue calldata encoder
7. simulate without state changes where possible
8. configure token approval from Generation 10 to the Adapter
9. run paused failure-path tests
10. tiny-value rehearsal
11. only then consider controlled activation

No production venue is hard-coded in v3.7.4.
