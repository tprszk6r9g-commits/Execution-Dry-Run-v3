# Rustee Broker Execution Dry-Run v3.1

v3.1 fixes the iPhone/GitHub Pages `Load failed` problem by moving Robinhood REST
reads into GitHub Actions.

The workflow fetches:

- `https://api.robinhood.com/rhj/assets`
- `https://api.robinhood.com/rhj/prices/NVDA`

and publishes them as same-origin static JSON files under `/data/`.

The browser then reads those local snapshot files, avoiding CORS/browser-policy
failures while remaining completely read-only.

The workflow also refreshes the snapshot every 15 minutes and on every push or
manual workflow run.

Important: UniswapX contracts are deployed on Robinhood Chain, but the official
UniswapX Robinhood playbook still says SDK/service wiring is pending. Therefore
the final execution gate intentionally remains locked until a genuine chain-4663
quote/order path can be demonstrated and simulated.

No approvals, funding, unpause, signatures, or trades are sent by this site.
