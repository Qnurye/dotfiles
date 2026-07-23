#!/usr/bin/env python3
"""Convert curly quotes to Chinese corner brackets (opinionated).

  " (U+201C LEFT DOUBLE QUOTATION MARK)  → 「 (U+300C)
  " (U+201D RIGHT DOUBLE QUOTATION MARK) → 」 (U+300D)
  ' (U+2018 LEFT SINGLE QUOTATION MARK)  → 『 (U+300E)
  ' (U+2019 RIGHT SINGLE QUOTATION MARK) → 』 (U+300F)

DOUBLE quotes use a per-text-node heuristic: if a text node contains
any CJK character, every "" in that node is converted. This handles
mixed-script Chinese sentences correctly:

  双11"特价"           → 双11「特价」
  S 公司"不算什么"      → S 公司「不算什么」
  top sales 的"标杆"   → top sales 的「标杆」

Per-character adjacency (the previous heuristic) would have left the
opening " untouched in each case because its right neighbour is ASCII,
producing broken pairs. The per-node rule fixes that without affecting
purely-English text nodes (which have no CJK and so leave "" alone).

SINGLE quotes use per-character CJK adjacency. U+2019 is also the
English typographic apostrophe ("don't"), and per-node conversion would
corrupt every contraction in a Chinese book that quotes English. The
trade-off: a Chinese passage where a single-quoted phrase ends at a
Latin token (like 'top') will leave the closing 』 unconverted — rare
and visible.

CJK context characters include CJK ideographs, CJK punctuation
(。、「」《》…), and Halfwidth/Fullwidth forms (！？，．…).

Mutates the original text. Skips tag attributes and the bodies of
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
    r'豈-﫿'    # CJK Compatibility Ideographs
    r'＀-￯]'   # Halfwidth and Fullwidth Forms
)
HAS_CJK = re.compile(CJK_CTX)

# Doubles: unconditional within a text node that contains any CJK.
DOUBLE_OPEN_GLOBAL = re.compile('“')
DOUBLE_CLOSE_GLOBAL = re.compile('”')

# Singles: per-character CJK adjacent (apostrophe protection).
SINGLE_OPEN_CTX = re.compile(f'‘(?={CJK_CTX})')
SINGLE_CLOSE_CTX = re.compile(f'(?<={CJK_CTX})’')

SKIP_BLOCK = re.compile(
    r'<(pre|code|script|style)\b[^>]*>.*?</\1>',
    re.IGNORECASE | re.DOTALL,
)

SENTINEL = '\x00QUOTE{}\x00'


def convert_text_node(text: str) -> tuple[str, int]:
    n = 0
    if HAS_CJK.search(text):
        # CJK present → convert all doubles unconditionally in this node.
        text, c = DOUBLE_OPEN_GLOBAL.subn('「', text)
        n += c
        text, c = DOUBLE_CLOSE_GLOBAL.subn('」', text)
        n += c
    # Singles always use per-character adjacency.
    text, c = SINGLE_OPEN_CTX.subn('『', text)
    n += c
    text, c = SINGLE_CLOSE_CTX.subn('』', text)
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
        after, n = convert_text_node(before)
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
