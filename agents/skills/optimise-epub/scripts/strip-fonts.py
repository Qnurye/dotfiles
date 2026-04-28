#!/usr/bin/env python3
"""Strip embedded fonts (and Adobe obfuscation) from an EPUB.

Many "professionally produced" Chinese EPUBs ship 1–2 MB of fonts that
Kindle either can't decrypt (Adobe RC obfuscation, IDPF mangling) or
silently ignores (per-book embedded fonts on most Kindle firmwares).
The result: dead weight + dozens of @font-face rules + manifest noise.

This script removes:

  - Every font file (.ttf .otf .woff .woff2) anywhere in the ZIP
  - META-INF/encryption.xml entries that point at those fonts; the
    file itself if no entries remain
  - @font-face rules in every CSS file (whole `@font-face { … }` block)
  - <item> entries from the OPF manifest whose href points at fonts/
    or whose media-type is a font type
  - font-family declarations are LEFT INTACT — they fall back gracefully
    to the user-selected font on Kindle, and may still resolve on
    readers that ship the named system fonts

Usage:
    python3 strip-fonts.py <input.epub> <output.epub>
"""
import re
import sys
import zipfile
from pathlib import Path

FONT_EXT = {'.ttf', '.otf', '.woff', '.woff2'}
FONT_MEDIA_TYPES = {
    'application/vnd.ms-opentype',
    'application/x-font-truetype',
    'application/x-font-opentype',
    'application/x-font-ttf',
    'application/x-font-otf',
    'application/font-woff',
    'application/font-woff2',
    'font/ttf',
    'font/otf',
    'font/woff',
    'font/woff2',
}

# Whole @font-face { ... } block, including nested braces (CSS doesn't
# nest braces in @font-face so a simple non-greedy match suffices).
FONT_FACE_RE = re.compile(r'@font-face\s*\{[^}]*\}\s*', re.IGNORECASE)

# OPF <item> entries pointing at a font (by href extension or media-type).
# Use [^>]*? rather than [^/>]*? — hrefs and media-types contain `/`.
OPF_FONT_ITEM_RE = re.compile(
    r'\s*<item\b[^>]*?(?:'
    r'href="[^"]+\.(?:ttf|otf|woff2?|TTF|OTF|WOFF2?)"'
    r'|media-type="(?:' + '|'.join(re.escape(t) for t in FONT_MEDIA_TYPES) + r')"'
    r')[^>]*?/>\s*',
    re.IGNORECASE,
)

# Adobe obfuscation algorithm URI (and the IDPF font-mangling URI).
ENC_FONT_ALGORITHMS = (
    'http://ns.adobe.com/pdf/enc#RC',
    'http://www.idpf.org/2008/embedding',
)


def is_font_path(name: str) -> bool:
    suffix = Path(name).suffix.lower()
    return suffix in FONT_EXT


def detect_obfuscation(encryption_xml: str) -> list[str]:
    """Return list of obfuscated font URIs found in encryption.xml."""
    obfuscated = []
    # Pair each <CipherReference URI> with its containing <EncryptionMethod Algorithm>.
    for block in re.finditer(
        r'<EncryptedData\b.*?</EncryptedData>',
        encryption_xml,
        re.DOTALL | re.IGNORECASE,
    ):
        text = block.group(0)
        algo_m = re.search(r'<EncryptionMethod\s[^>]*Algorithm="([^"]+)"', text)
        ref_m = re.search(r'<CipherReference\s[^>]*URI="([^"]+)"', text)
        if algo_m and ref_m and any(a in algo_m.group(1) for a in ENC_FONT_ALGORITHMS):
            obfuscated.append(ref_m.group(1))
    return obfuscated


def strip_encryption_xml(content: str, removed_fonts: set[str]) -> str | None:
    """Remove EncryptedData blocks pointing at removed fonts.

    Returns updated XML, or None if the resulting file would be empty
    (no remaining EncryptedData entries) — caller should drop the file.
    """
    def block_targets_removed_font(m):
        text = m.group(0)
        ref = re.search(r'<CipherReference\s[^>]*URI="([^"]+)"', text)
        return ref and ref.group(1) in removed_fonts

    new_content = re.sub(
        r'\s*<EncryptedData\b.*?</EncryptedData>\s*',
        lambda m: '' if block_targets_removed_font(m) else m.group(0),
        content,
        flags=re.DOTALL | re.IGNORECASE,
    )

    # If no <EncryptedData> remains, the file is just a wrapper — drop it.
    if not re.search(r'<EncryptedData\b', new_content, re.IGNORECASE):
        return None
    return new_content


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    if not src.is_file():
        print(f"Not a file: {src}", file=sys.stderr)
        sys.exit(1)

    fonts_removed: list[str] = []
    css_rules_removed = 0
    opf_items_removed = 0
    enc_dropped = False
    obfuscation_detected: list[str] = []

    # First pass: detect obfuscation for the report.
    with zipfile.ZipFile(src) as zin:
        if 'META-INF/encryption.xml' in zin.namelist():
            enc_text = zin.read('META-INF/encryption.xml').decode('utf-8', errors='replace')
            obfuscation_detected = detect_obfuscation(enc_text)

    if obfuscation_detected:
        print(f"Adobe/IDPF font obfuscation detected ({len(obfuscation_detected)} entries).")

    with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, 'w') as zout:
        names = zin.namelist()
        font_paths = {n for n in names if is_font_path(n)}

        for info in zin.infolist():
            name = info.filename

            if name == 'mimetype':
                zout.writestr(info, zin.read(name), compress_type=zipfile.ZIP_STORED)
                continue

            # Drop font files entirely.
            if is_font_path(name):
                fonts_removed.append(name)
                continue

            data = zin.read(name)

            # Rewrite encryption.xml; drop if it becomes empty.
            if name == 'META-INF/encryption.xml':
                # Pass URI strings as encryption.xml stores them (relative to root).
                # Match against both bare names and full paths.
                removed = set(font_paths) | {Path(p).name for p in font_paths}
                new_text = strip_encryption_xml(data.decode('utf-8', errors='replace'), removed)
                if new_text is None:
                    enc_dropped = True
                    continue
                data = new_text.encode('utf-8')

            elif name.lower().endswith('.css'):
                text = data.decode('utf-8', errors='replace')
                new_text, n = FONT_FACE_RE.subn('', text)
                if n:
                    css_rules_removed += n
                data = new_text.encode('utf-8')

            elif name.lower().endswith('.opf'):
                text = data.decode('utf-8', errors='replace')
                new_text, n = OPF_FONT_ITEM_RE.subn('', text)
                if n:
                    opf_items_removed += n
                data = new_text.encode('utf-8')

            zout.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)

    print(f"  Removed {len(fonts_removed)} font file(s)")
    for f in fonts_removed:
        print(f"    - {f}")
    print(f"  Removed {css_rules_removed} @font-face rule(s) from CSS")
    print(f"  Removed {opf_items_removed} <item> entry(ies) from OPF manifest")
    if enc_dropped:
        print("  Dropped META-INF/encryption.xml (no remaining entries)")
    print(f"\nWrote {dst}")


if __name__ == '__main__':
    main()
