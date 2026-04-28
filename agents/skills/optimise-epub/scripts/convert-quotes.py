#!/usr/bin/env python3
"""Convert curly quotes to Chinese corner brackets (opinionated).

  " (U+201C LEFT DOUBLE QUOTATION MARK)  → 「 (U+300C)
  " (U+201D RIGHT DOUBLE QUOTATION MARK) → 」 (U+300D)
  ' (U+2018 LEFT SINGLE QUOTATION MARK)  → 『 (U+300E)
  ' (U+2019 RIGHT SINGLE QUOTATION MARK) → 』 (U+300F)

All conversions are CJK-context-adjacent only. A quote converts iff its
inner-facing neighbour is in one of:

  - CJK Unified Ideographs (U+4E00-U+9FFF) and Extension A (U+3400-U+4DBF)
  - CJK Compatibility Ideographs (U+F900-U+FAFF)
  - CJK Symbols and Punctuation (U+3000-U+303F, includes 。、「」《》)
  - Halfwidth and Fullwidth Forms (U+FF00-U+FFEF, includes ！？，．)

This protects English passages embedded in Chinese books — `She said
"hello"` stays unchanged, while `他说"你好"` becomes `他说「你好」`.
The heuristic produces broken pairs in rare mixed-language quotes
(e.g. `他说"hello"` → `他说「hello"`); these are visible and easy to
spot.

This mutates the original text. Skips tag attributes and the bodies of
<pre>, <code>, <script>, <style>.

Usage:
    python3 convert-quotes.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

CJK_CTX = (
    r'[　-〿'   # CJK Symbols and Punctuation
    r'㐀-䶿'    # CJK Extension A
    r'一-鿿'    # CJK Unified Ideographs
    r'豈-﫿'    # CJK Compatibility Ideographs
    r'＀-￯]'   # Halfwidth and Fullwidth Forms
)

DOUBLE_OPEN = re.compile(f'“(?={CJK_CTX})')
DOUBLE_CLOSE = re.compile(f'(?<={CJK_CTX})”')
SINGLE_OPEN = re.compile(f'‘(?={CJK_CTX})')
SINGLE_CLOSE = re.compile(f'(?<={CJK_CTX})’')

SKIP_BLOCK = re.compile(
    r'<(pre|code|script|style)\b[^>]*>.*?</\1>',
    re.IGNORECASE | re.DOTALL,
)

SENTINEL = '\x00QUOTE{}\x00'


def convert(text: str) -> tuple[str, int]:
    n = 0
    for pattern, replacement in [
        (DOUBLE_OPEN, '「'),
        (DOUBLE_CLOSE, '」'),
        (SINGLE_OPEN, '『'),
        (SINGLE_CLOSE, '』'),
    ]:
        text, c = pattern.subn(replacement, text)
        n += c
    return text, n


def process_html(content: str) -> tuple[str, int]:
    skipped: list[str] = []

    def stash(m):
        skipped.append(m.group(0))
        return SENTINEL.format(len(skipped) - 1)

    content = SKIP_BLOCK.sub(stash, content)

    n_total = 0

    def fix_text(m):
        nonlocal n_total
        before = m.group(1)
        after, n = convert(before)
        n_total += n
        return '>' + after + '<'

    content = re.sub(r'>([^<]+)<', fix_text, content)

    def restore(m):
        return skipped[int(m.group(1))]

    content = re.sub(r'\x00QUOTE(\d+)\x00', restore, content)
    return content, n_total


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])

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

    print(f"\nConverted {total} quote(s) total.")
    print(f"Wrote {dst}")


if __name__ == '__main__':
    main()
