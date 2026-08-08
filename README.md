# Rustee Broker Portfolio Executor — GitHub Pages Fix v1.3

This package fixes the stale GitHub Pages deployment for:

`https://tprszk6r9g-commits.github.io/Execution-Dry-Run-v3/`

## Upload these files to the repository

The required files are:

- `index.html` — current Portfolio Executor v1.2
- `.github/workflows/main.yaml` — active GitHub Pages deployment workflow
- `.nojekyll` — disables Jekyll processing

A duplicate `main.yaml` is included at the root only for easy copying. GitHub Actions does **not** use the root copy. The workflow must exist at:

`.github/workflows/main.yaml`

## What the workflow verifies before deploying

It refuses to deploy unless root `index.html` contains:

- `Portfolio Executor v1.2`
- `Trading TBA portfolio + move assets to owner`

This prevents an old Rustee homepage from silently being republished.

## GitHub mobile folder trick

If you cannot create folders directly:

1. Choose **Add file → Create new file**.
2. In the filename box type exactly:
   `.github/workflows/main.yaml`
3. GitHub automatically creates the folders.
4. Paste the contents of the included `main.yaml`.
5. Commit to `main`.

Then make sure the supplied `index.html` replaces the existing root `index.html`.

After commit, open **Actions** and wait for **Deploy Rustee Broker Portfolio Executor** to turn green.
