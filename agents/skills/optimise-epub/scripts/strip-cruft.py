#!/usr/bin/env python3
"""Strip leading ideographic spaces and empty paragraphs from EPUB HTML.

Two passes per HTML file:

  1. Remove leading `　+` (U+3000 IDEOGRAPHIC SPACE) immediately inside
     <p> tags. Chinese books that don't use CSS `text-indent` often
     prefix paragraphs with two `　` instead — Kindle renders these as
     visible blank squares, especially after font/style overrides.

  2. Remove empty paragraphs: `<p></p>`, `<p>&nbsp;</p>`,
     `<p><br/></p>`, mixes of whitespace and `<br/>`. These are common
     Word/Calibre conversion artefacts; they create uneven vertical
     rhythm on Kindle and inflate file size.

Pair with `strip-indent.py` for full first-line-indent cleanup.

Usage:
    python3 strip-cruft.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

# Strip ideographic spaces immediately after a <p> opening tag.
# Tolerates one inline opening tag (span/em/strong/b/i) in between,
# which covers common Calibre output like `<p><span class="…">　　text…`.
# NOTE: must use explicit ASCII whitespace [ \t\r\n] — Python \s matches
# U+3000 (IDEOGRAPHIC SPACE) and would greedily consume the very chars
# we want to strip, leaving behind a stray `　` per paragraph.
ASCII_WS = r'[ \t\r\n]*'
LEADING_SPACES = re.compile(
    rf'(<p\b[^>]*>{ASCII_WS}(?:<(?:span|em|strong|b|i)\b[^>]*>{ASCII_WS})?)　+',
    re.IGNORECASE,
)

# Empty paragraphs: nothing inside but ASCII whitespace, &nbsp;, &#160;,
# <br/>. Same \s caveat — keep ASCII-only so `<p>　　</p>` (intentional
# visual blank) is preserved.
EMPTY_PARA = re.compile(
    rf'<p\b[^>]*>(?:[ \t\r\n]|&nbsp;|&#160;|<br\s*/?>)*</p>{ASCII_WS}',
    re.IGNORECASE,
)


def process(content: str) -> tuple[str, int, int]:
    content, n_indent = LEADING_SPACES.subn(r'\1', content)
    content, n_empty = EMPTY_PARA.subn('', content)
    return content, n_indent, n_empty


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])

    total_indent = 0
    total_empty = 0

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            name = info.filename.lower()

            if name == 'mimetype':
                zout.writestr(info, data, compress_type=zipfile.ZIP_STORED)
                continue

            if name.endswith(('.html', '.xhtml', '.htm')):
                text = data.decode('utf-8', errors='replace')
                new_text, n_i, n_e = process(text)
                if n_i or n_e:
                    parts = []
                    if n_i:
                        parts.append(f"{n_i} indent")
                    if n_e:
                        parts.append(f"{n_e} empty")
                    print(f"  {info.filename}: {', '.join(parts)}")
                    total_indent += n_i
                    total_empty += n_e
                data = new_text.encode('utf-8')

            zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

    print(f"\nStripped {total_indent} leading-space block(s) "
          f"and {total_empty} empty paragraph(s).")
    print(f"Wrote {dst}")


if __name__ == '__main__':
    main()
