#!/usr/bin/env python3
"""Download explicitly selected free scan assets.

Create assets/scans/downloads.json:
[
  {"name":"stone_ruin", "url":"https://example.com/model.zip", "license":"CC0", "credit":"Creator / source"}
]
"""
from __future__ import annotations
import argparse, json, zipfile
from pathlib import Path
from urllib.request import Request, urlopen

def safe_name(name: str) -> str:
    return ''.join(c if c.isalnum() or c in '._-' else '_' for c in name).strip('._') or 'asset'

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--manifest', default='assets/scans/downloads.json')
    ap.add_argument('--output', default='assets/scans/source')
    args = ap.parse_args()
    manifest = Path(args.manifest)
    out = Path(args.output); out.mkdir(parents=True, exist_ok=True)
    if not manifest.exists():
        raise SystemExit(f'Manifest not found: {manifest}')
    credits = []
    for entry in json.loads(manifest.read_text(encoding='utf-8')):
        name = safe_name(entry['name']); url = entry['url']
        suffix = Path(url.split('?')[0]).suffix or '.bin'
        target = out / f'{name}{suffix}'
        req = Request(url, headers={'User-Agent':'CrownAndCinderAssetFetcher/1.0'})
        with urlopen(req, timeout=90) as r:
            target.write_bytes(r.read())
        if suffix.lower() == '.zip':
            d = out / name; d.mkdir(exist_ok=True)
            with zipfile.ZipFile(target) as zf: zf.extractall(d)
        credits.append(f"{entry.get('name', name)}\nLicense: {entry.get('license','UNKNOWN')}\nCredit: {entry.get('credit','UNKNOWN')}\nSource: {url}\n")
    (out / 'DOWNLOADED_CREDITS.txt').write_text('\n'.join(credits), encoding='utf-8')

if __name__ == '__main__': main()
