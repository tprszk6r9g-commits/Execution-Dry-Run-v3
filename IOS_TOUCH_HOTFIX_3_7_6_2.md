# Rustee Broker v3.7.6.2 — iOS Touch Hotfix

Frontend-only hotfix. No smart-contract redeployment.

Changes:
- restores document vertical scrolling on iOS/WebView
- makes the sticky status and safety footer non-intercepting (`pointer-events:none`)
- explicitly restores pointer events and touch handling on buttons, inputs, links and tabs
- keeps the mobile tab strip horizontally scrollable
- removes sticky footer behavior on narrow screens to prevent it covering controls
- bumps the service-worker cache so GitHub Pages clients receive the fix

Install: replace root `index.html` and root `sw.js`. Then fully close/reopen the in-app browser or refresh twice so the new service worker takes control.
