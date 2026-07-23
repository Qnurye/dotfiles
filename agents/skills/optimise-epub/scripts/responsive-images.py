#!/usr/bin/env python3
"""Append responsive image sizing CSS to an EPUB.

Adds `img { max-width: 100%; height: auto; }` to every CSS file in the
EPUB. Prevents fixed-width images (e.g. `width="600"`) from overflowing
narrow Kindle screens. Idempotent — files that already contain an `img`
rule with `max-width: 100%` are left alone.

Usage:
    python3 responsive-images.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

CSS_RULE = (
    "\n\n/* responsive image sizing — added by optimise-epub */\n"
    "img { max-width: 100%; height: auto; }\n"
)

ALREADY = re.compile(
    r'\bimg\b[^{}]*\{[^}]*max-width\s*:\s*100\s*%',
    re.IGNORECASE | re.DOTALL,
)


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])

    appended = 0
    skipped = 0

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            name = info.filename.lower()

            if name == 'mimetype':
                zout.writestr(info, data, compress_type=zipfile.ZIP_STORED)
                continue

            if name.endswith('.css'):
                text = data.decode('utf-8', errors='replace')
                if ALREADY.search(text):
                    print(f"  skip (already responsive): {info.filename}")
                    skipped += 1
                else:
                    text += CSS_RULE
                    print(f"  appended: {info.filename}")
                    appended += 1
                data = text.encode('utf-8')

            zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

    if appended + skipped == 0:
        print("WARNING: no .css files found. Image rule not injected.", file=sys.stderr)
    print(f"\nAppended to {appended} CSS file(s); skipped {skipped}.")
    print(f"Wrote {dst}")


if __name__ == '__main__':
    main()
