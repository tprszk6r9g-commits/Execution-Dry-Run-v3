# Rustee Broker v3.5 — Rotating Trading TBA Manager

- Adds a dedicated TBA Manager tab.
- Preserves the Vault TBA as the permanent treasury account.
- Treats the deployed Trading TBA as Generation 1.
- Predicts deterministic Generation 2+ ERC-6551 Trading TBA addresses.
- Creates new generations through the canonical ERC-6551 Registry.
- Uses the already deployed restricted StockTradingAccount implementation.
- Simulates exact createAccount calldata before the wallet opens.
- Verifies token(), owner(), and StockTokenRegistry after deployment.
- Allows verified generations to become the active Trading TBA after reload.
- Keeps a local generation ledger and JSON export.
- Older generations are never deleted and can be reactivated for recovery.
- Does not automatically migrate assets during rotation.
- Preserves v3.4.4 Transfer Readiness and v3.4.3 STONKBROKER trading.
