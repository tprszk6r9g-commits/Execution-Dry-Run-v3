#!/usr/bin/env python3
"""Regenerate the published SHA-256 manifest after all deploy-time snapshots."""
from __future__ import annotations

import datetime as dt
import hashlib
import json
from pathlib import Path

TARGETS = [
    Path("index.html"),
    Path("data/robinhood-assets.json"),
    Path("data/robinhood-prices.json"),
    Path("data/rustee-history.json"),
]
OUT = Path("data/integrity.json")


def utc_now() -> str:
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def main() -> int:
    missing = [str(p) for p in TARGETS if not p.is_file()]
    if missing:
        raise SystemExit("missing integrity target(s): " + ", ".join(missing))
    hashes = {str(p).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest() for p in TARGETS}
    payload = {"generatedAt": utc_now(), "algorithm": "SHA-256", "sha256": hashes}
    OUT.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"[integrity] wrote {OUT}")
    for path, digest in hashes.items():
        print(f"[integrity] {path}: {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
