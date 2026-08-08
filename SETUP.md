# GitHub setup for v4.9

1. Upload this package's files to the repository root.
2. Confirm the workflow exists at `.github/workflows/main.yaml`.
3. In GitHub: Settings -> Secrets and variables -> Actions.
4. Add only the production variables you actually possess and can document.
5. Run `Rustee Broker Production Input Resolution v4.9`.
6. Read the generated report. Do not proceed to a live transaction unless the
   separate final preflight phase is built and all safety gates are green.

Important: `main.yaml` at the root is only an easy-to-find copy. GitHub Actions
uses `.github/workflows/main.yaml`.


## v4.9.1 correction

`ARCHIVE_RPC_URL` is read from **GitHub Actions Secrets**, not Variables:

- Secret name: `ARCHIVE_RPC_URL`
- Workflow expression: `${{ secrets.ARCHIVE_RPC_URL }}`

All non-sensitive configuration values may remain repository variables.
