# GitHub Repository Security Checklist

Recommended settings for the repository hosting this terminal:

1. Require two-factor authentication/passkeys on every collaborator account.
2. Protect `main`.
3. Require a pull request before merging to `main`.
4. Require at least one approving review.
5. Dismiss stale approvals when new commits are pushed.
6. Require status checks from the hardened build workflow.
7. Block force pushes and branch deletion.
8. Protect the `github-pages` environment and require approval for deployment if practical.
9. Keep Actions permissions at the minimum necessary.
10. Do not store wallet private keys or seed phrases in GitHub Secrets.
11. If API credentials are later added, scope them read-only where possible and never expose them to GitHub Pages/browser JavaScript.
12. Periodically re-resolve and review pinned GitHub Action SHAs before upgrading them.
