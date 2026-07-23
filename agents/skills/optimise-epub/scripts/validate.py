#!/usr/bin/env python3
"""Self-check an optimised EPUB against the skill's expected post-state.

Verifies the structural and stylistic invariants the optimise-epub
pipeline is supposed to leave behind. Each check prints PASS / FAIL.
Exit code is 0 if all PASS, 1 otherwise.

Checks:
  1. mimetype is the first ZIP entry, stored uncompressed, with the
     value "application/epub+zip".
  2. No CSS file contains a `text-indent:` declaration.
  3. No <p> in any HTML file starts with U+3000 (ideographic space).
  4. No empty paragraph patterns (`<p></p>`, `<p>&nbsp;</p>`,
     `<p><br/></p>`).
  5. No META-INF/encryption.xml (Adobe / IDPF font obfuscation).
  6. No font files (.ttf .otf .woff .woff2) anywhere in the ZIP.
  7. No remaining `"` `"` `'` `'` (U+2018-201D) in CJK-bearing text
     nodes — these would be quote-pair leftovers.
  8. Pangu spacing is reasonably present: report ratio of CJK↔ASCII
     boundaries that DO have a space between them. Warns (not fails)
     if < 90 %.

Usage:
    python3 validate.py <epub>
"""
import re
import sys
import zipfile
from pathlib import Path

CJK_CTX = (
    '[　-〿'   # CJK Symbols and Punctuation
    '㐀-䶿'    # CJK Extension A
    '一-鿿'    # CJK Unified Ideographs
    '豈-﫿'    # CJK Compatibility Ideographs
    '＀-￯]'   # Halfwidth and Fullwidth Forms
)
CJK = '[一-鿿㐀-䶿豈-﫿]'
ANS = '[A-Za-z0-9]'

HAS_CJK_RE = re.compile(CJK_CTX)

CHECKS_PASSED = 0
CHECKS_FAILED = 0


def report(name: str, ok: bool, detail: str = '') -> None:
    global CHECKS_PASSED, CHECKS_FAILED
    if ok:
        CHECKS_PASSED += 1
        print(f"  PASS  {name}")
    else:
        CHECKS_FAILED += 1
        print(f"  FAIL  {name}")
    if detail:
        for line in detail.splitlines():
            print(f"        {line}")


def warn(name: str, detail: str = '') -> None:
    print(f"  WARN  {name}")
    if detail:
        for line in detail.splitlines():
            print(f"        {line}")


def text_nodes(html: str):
    # Strip <pre>/<code>/<script>/<style> bodies so we don't false-positive on them.
    skipped = re.sub(
        r'<(pre|code|script|style)\b[^>]*>.*?</\1>', '',
        html, flags=re.IGNORECASE | re.DOTALL,
    )
    for m in re.finditer(r'>([^<]+)<', skipped):
        yield m.group(1)


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"Not a file: {path}", file=sys.stderr)
        sys.exit(2)

    print(f"Validating {path.name}\n")

    with zipfile.ZipFile(path) as z:
        infos = z.infolist()
        names = z.namelist()

        # 1. mimetype first/stored/correct value
        first = infos[0]
        ok = (
            first.filename == 'mimetype'
            and first.compress_type == zipfile.ZIP_STORED
            and first.header_offset == 0
            and z.read('mimetype').decode('ascii', errors='replace').strip()
                == 'application/epub+zip'
        )
        detail = '' if ok else (
            f"first={first.filename}, compress={first.compress_type}, "
            f"offset={first.header_offset}"
        )
        report("mimetype is first, stored, correct value", ok, detail)

        # 2. No text-indent in CSS
        offenders = []
        for name in names:
            if name.lower().endswith('.css'):
                text = z.read(name).decode('utf-8', errors='replace')
                if re.search(r'(?<![\w-])text-indent\s*:', text, re.IGNORECASE):
                    offenders.append(name)
        report("No `text-indent` in any CSS", not offenders,
               '\n'.join(offenders))

        # 3. No <p> starts with
        offenders = []
        for name in names:
            if name.lower().endswith(('.html', '.xhtml', '.htm')):
                text = z.read(name).decode('utf-8', errors='replace')
                hits = re.findall(r'<p\b[^>]*>　', text)
                if hits:
                    offenders.append(f"{name}: {len(hits)}")
        report("No paragraph starts with U+3000", not offenders,
               '\n'.join(offenders))

        # 4. No empty paragraphs
        offenders = []
        empty_re = re.compile(
            r'<p\b[^>]*>(?:[ \t\r\n]|&nbsp;|&#160;|<br\s*/?>)*</p>',
            re.IGNORECASE,
        )
        for name in names:
            if name.lower().endswith(('.html', '.xhtml', '.htm')):
                text = z.read(name).decode('utf-8', errors='replace')
                hits = empty_re.findall(text)
                if hits:
                    offenders.append(f"{name}: {len(hits)}")
        report("No empty <p> blocks", not offenders, '\n'.join(offenders))

        # 5. No encryption.xml
        report("No META-INF/encryption.xml",
               'META-INF/encryption.xml' not in names)

        # 6. No font files
        font_names = [n for n in names
                      if Path(n).suffix.lower() in {'.ttf', '.otf', '.woff', '.woff2'}]
        report("No embedded fonts", not font_names, '\n'.join(font_names))

        # 7. No curly quotes in CJK-bearing text nodes
        offenders = []
        curly = re.compile('[“”‘’]')
        for name in names:
            if not name.lower().endswith(('.html', '.xhtml', '.htm')):
                continue
            text = z.read(name).decode('utf-8', errors='replace')
            hit_count = 0
            for node in text_nodes(text):
                if HAS_CJK_RE.search(node) and curly.search(node):
                    hit_count += len(curly.findall(node))
            if hit_count:
                offenders.append(f"{name}: {hit_count}")
        report("No curly quotes in CJK-bearing text nodes", not offenders,
               '\n'.join(offenders))

        # 8. Pangu spacing coverage (warn-only)
        boundaries = 0
        unspaced = 0
        boundary_re = re.compile(f'{CJK}{ANS}|{ANS}{CJK}')
        spaced_re = re.compile(f'{CJK} {ANS}|{ANS} {CJK}')
        for name in names:
            if not name.lower().endswith(('.html', '.xhtml', '.htm')):
                continue
            text = z.read(name).decode('utf-8', errors='replace')
            for node in text_nodes(text):
                unspaced += len(boundary_re.findall(node))
                boundaries += len(spaced_re.findall(node))
        total = boundaries + unspaced
        if total == 0:
            print("  INFO  Pangu spacing: no CJK↔ASCII boundaries in document")
        else:
            ratio = boundaries / total
            line = f"{boundaries}/{total} CJK↔ASCII boundaries spaced ({ratio:.0%})"
            if ratio >= 0.9:
                report("Pangu spacing >=90%", True, line)
            else:
                warn("Pangu spacing <90%", line)

    print(f"\n{CHECKS_PASSED} passed, {CHECKS_FAILED} failed")
    sys.exit(0 if CHECKS_FAILED == 0 else 1)


if __name__ == '__main__':
    main()
