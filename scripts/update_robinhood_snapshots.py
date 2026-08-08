#!/usr/bin/env python3
"""
Build same-origin Robinhood Chain Stock Token snapshots for GitHub Pages.

Inputs:
  https://api.robinhood.com/rhj/assets
  https://api.robinhood.com/rhj/prices/{symbol}

Outputs:
  data/robinhood-assets.json
  data/robinhood-prices.json

No wallet, private key, RPC write, or authenticated Robinhood account is used.
"""

from __future__ import annotations

import concurrent.futures
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "https://api.robinhood.com/rhj"
CHAIN_ID = 4663
OUT_DIR = Path("data")
ASSETS_OUT = OUT_DIR / "robinhood-assets.json"
PRICES_OUT = OUT_DIR / "robinhood-prices.json"

# Keep well below Robinhood's documented 60 requests/sec limit.
MAX_WORKERS = 8
TIMEOUT = 15
RETRIES = 3


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def get_json(url: str) -> dict:
    last_error = None
    for attempt in range(RETRIES):
        req = urllib.request.Request(
            url,
            headers={
                "Accept": "application/json",
                "User-Agent": "Rustee-Portfolio-Terminal-Snapshot/2.8.7",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                if r.status != 200:
                    raise RuntimeError(f"HTTP {r.status} from {url}")
                return json.loads(r.read().decode("utf-8"))
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, RuntimeError) as exc:
            last_error = exc
            if attempt + 1 < RETRIES:
                time.sleep(0.6 * (2 ** attempt))
    raise RuntimeError(f"Failed after {RETRIES} attempts: {url}: {last_error}")


def has_chain_deployment(asset: dict) -> bool:
    return any(int(d.get("chainId", -1)) == CHAIN_ID for d in (asset.get("deployments") or []))


def active_assets(payload: dict) -> list[dict]:
    rows = payload.get("assets") or []
    return [
        a for a in rows
        if a.get("status") == "ASSET_STATUS_ACTIVE"
        and a.get("tokenSymbol")
        and has_chain_deployment(a)
    ]


def fetch_quote(symbol: str) -> tuple[str, dict | None, str | None]:
    url = f"{BASE}/prices/{urllib.parse.quote(symbol, safe='')}"
    try:
        payload = get_json(url)
        quotes = payload.get("quotes") or []
        quote = next((q for q in quotes if q.get("tokenSymbol") == symbol), quotes[0] if quotes else None)
        if not quote:
            return symbol, None, "response contained no quote"
        return symbol, quote, None
    except Exception as exc:
        return symbol, None, str(exc)


def write_json_atomic(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)


def main() -> int:
    generated_at = utc_now()
    print(f"[snapshot] fetching Robinhood assets at {generated_at}")
    raw_assets = get_json(f"{BASE}/assets")
    assets = active_assets(raw_assets)

    if not assets:
        print("[snapshot] ERROR: Robinhood returned zero active Chain 4663 assets", file=sys.stderr)
        return 2

    assets_snapshot = {
        "generatedAt": generated_at,
        "chainId": CHAIN_ID,
        "source": f"{BASE}/assets",
        "assets": assets,
    }

    symbols = sorted({a["tokenSymbol"] for a in assets})
    print(f"[snapshot] {len(assets)} active Chain {CHAIN_ID} assets; fetching {len(symbols)} symbols")

    quotes_by_symbol: dict[str, dict] = {}
    failures: dict[str, str] = {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {pool.submit(fetch_quote, sym): sym for sym in symbols}
        for i, future in enumerate(concurrent.futures.as_completed(futures), 1):
            sym, quote, error = future.result()
            if quote is not None:
                quotes_by_symbol[sym] = quote
            else:
                failures[sym] = error or "unknown error"
            if i % 10 == 0 or i == len(symbols):
                print(f"[snapshot] prices {i}/{len(symbols)} complete; ok={len(quotes_by_symbol)} fail={len(failures)}")

    prices_snapshot = {
        "generatedAt": generated_at,
        "chainId": CHAIN_ID,
        "source": f"{BASE}/prices/{{symbol}}",
        "quoteCount": len(quotes_by_symbol),
        "requestedCount": len(symbols),
        "quotesBySymbol": quotes_by_symbol,
        "failures": failures,
    }

    # Do not overwrite a deployment with a totally unusable quote snapshot.
    if not quotes_by_symbol:
        print("[snapshot] ERROR: zero price quotes were returned", file=sys.stderr)
        return 3

    write_json_atomic(ASSETS_OUT, assets_snapshot)
    write_json_atomic(PRICES_OUT, prices_snapshot)

    coverage = len(quotes_by_symbol) / max(1, len(symbols))
    print(f"[snapshot] wrote {ASSETS_OUT} ({len(assets)} assets)")
    print(f"[snapshot] wrote {PRICES_OUT} ({len(quotes_by_symbol)}/{len(symbols)} quotes, {coverage:.1%} coverage)")

    # Fail if the upstream API is broadly broken instead of publishing misleading data.
    if coverage < 0.80:
        print("[snapshot] ERROR: quote coverage below 80%; refusing Pages deploy", file=sys.stderr)
        return 4

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
