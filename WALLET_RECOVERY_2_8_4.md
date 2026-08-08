# Rustee Portfolio Terminal v2.8.4 — Wallet Recovery

## Fixes
- Adds Connect Wallet directly to the first Command page.
- Detects injected wallet providers that appear after page load on iOS/WebView.
- Uses `window.ethereum` / provider discovery instead of relying on the bare `ethereum` global.
- Restores an already-approved session with `eth_accounts` without generating a signature prompt.
- Uses a user-clicked `eth_requestAccounts` only for the actual Connect button.
- Adds first-page provider, wallet, chain, and connection status.
- Installs wallet listeners only after the provider is discovered.
- Keeps balance/background refresh from racing wallet injection during page startup.
- The transaction handoff and security checks now use the same discovered provider instance.

All v2.7 remediation, v2.8 evidence/replay, spend ceilings, route simulation, custody warnings,
allowance recovery, CSP, and transaction security checks remain.
