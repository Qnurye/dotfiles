#!/usr/bin/env python3
"""Strip text-indent declarations from an EPUB.

Chinese EPUBs commonly use `text-indent: 2em` for first-line indentation.
Kindle's renderer mishandles this on Chinese paragraphs, producing extra
blank space and broken alignment after inline links/footnotes. This script
removes those declarations while preserving the surrounding rule and any
other declarations on the same selector.

Usage:
    python3 strip-indent.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

# Match `text-indent: <value>` inside a CSS declaration block.
# Stops at `;` or before `}` (last declaration in a rule).
INDENT_DECL = re.compile(
    r'(?<![\w-])text-indent\s*:\s*[^;}]*;?',
    re.IGNORECASE,
)


def strip_css(content: str) -> tuple[str, int]:
    new_content, count = INDENT_DECL.subn('', content)
    # Tidy: collapse `{   }` to `{}` and `;;` to `;`
    new_content = re.sub(r';\s*;', ';', new_content)
    new_content = re.sub(r'{\s*}', '{}', new_content)
    return new_content, count


def strip_inline_style(content: str) -> tuple[str, int]:
    count = 0

    def fix(m):
        nonlocal count
        original = m.group(1)
        cleaned, n = INDENT_DECL.subn('', original)
        if n == 0:
            return m.group(0)
        count += n
        cleaned = cleaned.strip(' ;\t')
        cleaned = re.sub(r';\s*;', ';', cleaned)
        if not cleaned:
            return ''
        return f' style="{cleaned}"'

    new_content = re.sub(r'\s*style="([^"]*)"', fix, content)
    return new_content, count


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])

    if not src.is_file():
        print(f"Not a file: {src}", file=sys.stderr)
        sys.exit(1)

    total_css = 0
    total_inline = 0

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            name = info.filename.lower()

            if name == 'mimetype':
                # mimetype must be first, stored uncompressed
                zout.writestr(info, data, compress_type=zipfile.ZIP_STORED)
                continue

            if name.endswith('.css'):
                text = data.decode('utf-8', errors='replace')
                new_text, n = strip_css(text)
                if n:
                    print(f"  CSS  ({n:>2}): {info.filename}")
                    total_css += n
                data = new_text.encode('utf-8')
            elif name.endswith(('.html', '.xhtml', '.htm')):
                text = data.decode('utf-8', errors='replace')
                new_text, n = strip_inline_style(text)
                if n:
                    print(f"  HTML ({n:>2}): {info.filename}")
                    total_inline += n
                data = new_text.encode('utf-8')

            zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

    print(f"\nRemoved {total_css} CSS declaration(s), {total_inline} inline style(s).")
    print(f"Wrote {dst}")


if __name__ == '__main__':
    main()
