#!/usr/bin/env python3
"""Insert spaces between CJK characters and ASCII alphanumerics (盘古之白).

Required for Kindle: its KF8/KFX renderer does NOT support CSS
`text-autospace` (not in Amazon's documented KF8 CSS subset). Apple
Books (WebKit 18.4+), Calibre viewer, and Koodo Reader honour the CSS
property — for those targets you can skip this script and use:

    html { text-autospace: ideograph-numeric ideograph-alpha; }

This script mutates HTML text nodes only. It does not touch tag
attributes (URLs, class names) or the contents of <pre>, <code>,
<script>, <style>. Idempotent — safe to re-run.

Usage:
    python3 pangu-spacing.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

# CJK Unified Ideographs (BMP), Extension A, plus common compatibility ranges.
CJK = r'[㐀-䶿一-鿿豈-﫿]'
ANS = r'[A-Za-z0-9]'

CJK_THEN_ANS = re.compile(f'({CJK})({ANS})')
ANS_THEN_CJK = re.compile(f'({ANS})({CJK})')

# Element bodies whose text we must not modify.
SKIP_BLOCK = re.compile(
    r'<(pre|code|script|style)\b[^>]*>.*?</\1>',
    re.IGNORECASE | re.DOTALL,
)

SENTINEL = '\x00PANGU{}\x00'


def pangu(text: str) -> str:
    text = CJK_THEN_ANS.sub(r'\1 \2', text)
    text = ANS_THEN_CJK.sub(r'\1 \2', text)
    return text


def process_html(content: str) -> tuple[str, int]:
    skipped: list[str] = []

    def stash(m):
        skipped.append(m.group(0))
        return SENTINEL.format(len(skipped) - 1)

    content = SKIP_BLOCK.sub(stash, content)

    inserts = 0

    def fix_text(m):
        nonlocal inserts
        before = m.group(1)
        after = pangu(before)
        # Count actual insertions (excluding pre-existing spaces)
        inserts += (len(after) - len(before))
        return '>' + after + '<'

    content = re.sub(r'>([^<]+)<', fix_text, content)

    def restore(m):
        return skipped[int(m.group(1))]

    content = re.sub(r'\x00PANGU(\d+)\x00', restore, content)
    return content, inserts


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])

    if not src.is_file():
        print(f"Not a file: {src}", file=sys.stderr)
        sys.exit(1)

    total = 0
    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            name = info.filename.lower()

            if name == 'mimetype':
                zout.writestr(info, data, compress_type=zipfile.ZIP_STORED)
                continue

            if name.endswith(('.html', '.xhtml', '.htm')):
                text = data.decode('utf-8', errors='replace')
                new_text, n = process_html(text)
                if n:
                    print(f"  ({n:>4}) {info.filename}")
                    total += n
                data = new_text.encode('utf-8')

            zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

    print(f"\nInserted {total} space(s) total.")
    print(f"Wrote {dst}")


if __name__ == '__main__':
    main()
