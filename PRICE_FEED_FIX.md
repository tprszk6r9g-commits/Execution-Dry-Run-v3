# Price Feed Fix

Copy these files into the repository:

- `.github/workflows/main.yaml`
- `scripts/update_robinhood_snapshots.py`

The workflow fetches the official Robinhood Chain Stock Token asset catalog and per-symbol price quotes before deploying GitHub Pages. It refreshes on every push, manual run, and approximately every 15 minutes via GitHub Actions schedule.

The generated runtime files are:

- `data/robinhood-assets.json`
- `data/robinhood-prices.json`

No wallet key, seed phrase, API key, or authenticated Robinhood account is used.
