# Rustee Broker v3.5 — Rotating TBA Manager

Rustee keeps the original Vault TBA permanent and supports additional Trading TBA generations for Broker NFT #1.

Generation 1 is the original deployed Trading TBA. Generation 2+ is created through the canonical ERC-6551 Registry using the deployed Rustee `StockTradingAccount` implementation and deterministic domain-labelled bytes32 salts (`RUSTEE_TRADING_GEN_00000002`, etc.).

The dashboard predicts each counterfactual address, checks Registry and implementation bytecode, simulates `createAccount`, preserves the mobile wallet handoff, waits for confirmation, then verifies `token()`, `owner()`, and the StockTokenRegistry binding before a generation can become active.

Activation is dashboard/operator state, not an on-chain deletion or transfer. Old TBAs remain on-chain and remain controlled by the current Broker NFT holder. Switch back to an older verified generation for recovery if needed. Creating or activating a generation does not automatically migrate assets.
