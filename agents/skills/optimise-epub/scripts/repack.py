#!/usr/bin/env python3
"""Repackage an extracted EPUB directory into a valid EPUB ZIP.

Guarantees the structural rules that the EPUB spec (and Kindle) require
but that ad-hoc `zip -r` invocations frequently get wrong:

  1. mimetype is the FIRST entry in the ZIP archive.
  2. mimetype is stored uncompressed (`compress_type=ZIP_STORED`) and
     carries no extra field.
  3. Already-compressed binaries (images, fonts) are STORED — no point
     re-compressing them and some readers prefer it.
  4. Everything else is DEFLATED.

Usage:
    python3 repack.py <extracted-dir> <output.epub>
"""
import os
import sys
import zipfile
from pathlib import Path

STORED_EXT = {
    '.jpg', '.jpeg', '.png', '.gif', '.webp',
    '.ttf', '.otf', '.woff', '.woff2',
}


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()

    if not src.is_dir():
        print(f"Not a directory: {src}", file=sys.stderr)
        sys.exit(1)

    mimetype = src / 'mimetype'
    if not mimetype.is_file():
        print(f"No mimetype file at {mimetype}", file=sys.stderr)
        sys.exit(1)

    if dst.exists():
        dst.unlink()

    with zipfile.ZipFile(dst, 'w') as zf:
        # mimetype first, stored uncompressed.
        zf.write(mimetype, 'mimetype', compress_type=zipfile.ZIP_STORED)

        for root, dirs, files in os.walk(src):
            dirs.sort()
            for name in sorted(files):
                full = Path(root) / name
                rel = str(full.relative_to(src))
                if rel == 'mimetype':
                    continue
                ext = full.suffix.lower()
                ct = zipfile.ZIP_STORED if ext in STORED_EXT else zipfile.ZIP_DEFLATED
                zf.write(full, rel, compress_type=ct)

    size = dst.stat().st_size
    print(f"Wrote {dst} ({size:,} bytes)")


if __name__ == '__main__':
    main()
