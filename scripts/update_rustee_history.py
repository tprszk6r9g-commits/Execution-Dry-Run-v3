#!/usr/bin/env python3
"""Build a same-origin Blockscout ERC-20 history snapshot for Rustee.

The browser can fall back to Blockscout directly, but GitHub Pages publishes this
snapshot so Rabby/iOS embedded browsers do not depend on cross-origin access.
No wallet, private key, signature, or write RPC is used.
"""
from __future__ import annotations

import datetime as dt
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

BLOCKSCOUT = "https://robinhoodchain.blockscout.com"
OUT = Path("data/rustee-history.json")
TIMEOUT = 15
RETRIES = 3
MAX_PAGES = 40

ADDRESSES = {
    "OWNER": "0x8fC320c8582f812695b6f62b2b5d13B14475B955",
    "VAULT": "0x8ad8bd35d33dd7b4d0de81f809f5b7f92623956d",
    "TRADING": "0x522f5637f2c556aad9b2245f3b8e6bf4dfd9a654",
    "REWARDS": "0xfd0d881d73ec1476f5da0ab78283149ea21c3b32",
    "IDENTITY": "0x496d7d47ae69d65d714413f0dc78c712ed92158d",
}


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def get_json(url: str) -> dict:
    last = None
    for attempt in range(RETRIES):
        req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": "Rustee-History-Snapshot/2.8.8"})
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                if r.status != 200:
                    raise RuntimeError(f"HTTP {r.status}")
                return json.loads(r.read().decode("utf-8"))
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, RuntimeError) as exc:
            last = exc
            if attempt + 1 < RETRIES:
                time.sleep(0.6 * (2 ** attempt))
    raise RuntimeError(f"failed after {RETRIES} attempts: {url}: {last}")


def fetch_address(address: str) -> list[dict]:
    base = f"{BLOCKSCOUT}/api/v2/addresses/{address}/token-transfers"
    params: dict[str, str] = {"type": "ERC-20"}
    items: list[dict] = []
    seen_cursors: set[str] = set()
    for _ in range(MAX_PAGES):
        url = base + "?" + urllib.parse.urlencode(params)
        payload = get_json(url)
        page = payload.get("items") or []
        if not isinstance(page, list):
            raise RuntimeError("unexpected Blockscout items payload")
        items.extend(page)
        nxt = payload.get("next_page_params")
        if not isinstance(nxt, dict) or not nxt:
            break
        cursor = json.dumps(nxt, sort_keys=True)
        if cursor in seen_cursors:
            raise RuntimeError("Blockscout pagination cursor repeated")
        seen_cursors.add(cursor)
        params = {"type": "ERC-20", **{str(k): str(v) for k, v in nxt.items() if v is not None}}
    return items


def write_atomic(payload: dict) -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    tmp = OUT.with_suffix(OUT.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(OUT)


def main() -> int:
    generated = utc_now()
    by_address: dict[str, list[dict]] = {}
    failures: dict[str, str] = {}
    for label, address in ADDRESSES.items():
        try:
            rows = fetch_address(address)
            by_address[address.lower()] = rows
            print(f"[history] {label}: {len(rows)} ERC-20 transfers")
        except Exception as exc:
            failures[label] = str(exc)
            print(f"[history] WARNING {label}: {exc}")

    # Publishing a partial snapshot is safer than replacing the prior snapshot
    # with one that could not reach any indexed source at all.
    if not by_address:
        print("[history] ERROR: no address history could be fetched")
        return 2

    payload = {
        "generatedAt": generated,
        "chainId": 4663,
        "source": f"{BLOCKSCOUT}/api/v2/addresses/{{address}}/token-transfers?type=ERC-20",
        "byAddress": by_address,
        "failures": failures,
    }
    write_atomic(payload)
    print(f"[history] wrote {OUT}; addresses={len(by_address)}/{len(ADDRESSES)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
