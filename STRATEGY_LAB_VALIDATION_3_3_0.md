# Rustee Broker v3.3 Validation

- v3.2 supervised Autopilot retained.
- v3.1.2 wallet handoff retained.
- Strategy Lab has no `eth_sendTransaction` call and no real execution call.
- Strategy promotion creates rules only; Autopilot remains separately enabled/disabled.
- Promotion requires Paper stage and a backtest with at least 10 samples.
- Imported history is validated for symbol, timestamp and positive price.
- Backtests use only recorded/imported samples.
- No Solidity source/test/foundry changes.
- CSP inline-script hash regenerated.
- Frontend integrity manifest regenerated.
- PWA cache bumped to v3.3.
- GitHub Pages workflow snapshot assertion remains aligned with the six integrity targets.
