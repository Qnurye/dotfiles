---
name: optimise-epub
description: Diagnose and fix EPUB ebook issues — metadata, TOC, footnotes, Kindle compatibility, style optimization for Chinese books (Pangu spacing, indent removal, ad filtering), font management, and MTP file transfer. Use when user has an EPUB with broken formatting, missing footnotes, bad metadata, Chinese typography issues, or needs to transfer files to a Kindle.
---

# EPUB Fix & Kindle Toolkit

Accumulated recipes for diagnosing and repairing EPUB ebooks and managing Kindle devices.

## References

- `references/epub3-spec.md` — Complete EPUB 3.3 spec reference: required files, package document structure, navigation, footnote markup, embedded fonts, ZIP packaging rules, and a pre-ship validation checklist. Load when building an EPUB from scratch or validating against the spec.

## Scripts

- `scripts/strip-indent.py` — Remove `text-indent` declarations from CSS files and inline styles (Kindle renders Chinese first-line indent incorrectly).
- `scripts/strip-cruft.py` — Strip leading `　+` from paragraphs and remove empty `<p>` blocks (Word/Calibre conversion noise).
- `scripts/pangu-spacing.py` — Insert spaces between CJK and ASCII alphanumerics in HTML text nodes. Use as fallback when target reader does not support CSS `text-autospace` (e.g., Kindle).
- `scripts/responsive-images.py` — Append `img { max-width: 100%; height: auto; }` to all CSS files so fixed-pixel images don't overflow narrow Kindle screens.
- `scripts/convert-quotes.py` — Convert curly quotes (`""`/`''`) to Chinese corner brackets (`「」`/`『』`). Opinionated; mutates original text.
- `scripts/ad-filter.sh` — Scan an EPUB for marketing/ad patterns (公众号, 扫码, QQ群, etc.) using ripgrep.

## Quick Diagnosis

Extract and inspect an EPUB (it's just a ZIP):

```python
import zipfile, re
epub = zipfile.ZipFile("book.epub")

# 1. Check mimetype (must be first entry, stored uncompressed)
info = epub.getinfo("mimetype")
assert info.header_offset == 0 and info.compress_type == 0

# 2. Read OPF for metadata + manifest + spine
opf = epub.read("content.opf").decode()

# 3. Read NCX for table of contents
ncx = epub.read("toc.ncx").decode()

# 4. Find files in spine but missing from NCX (common with MOBI conversions)
spine_files = re.findall(r'<itemref idref="([^"]+)"', opf)
ncx_refs = set(re.findall(r'src="([^"#]+)', ncx))
```

## Common Issues & Fixes

### 1. Bad Metadata (MOBI-to-EPUB conversion artifacts)

**Symptoms:** `dc:date` is `0101-01-01`, leftover `MOBI-ASIN` identifier.

**Fix:** Edit `content.opf` — correct the date, remove MOBI-ASIN `<dc:identifier>`.

### 2. Incomplete NCX Table of Contents

**Symptoms:** Calibre splits large MOBI files into multiple HTML chunks. Continuation files end up in the spine but not in the NCX. Content is still readable linearly, but chapter navigation skips over these files.

**Fix:** Continuation splits do NOT need NCX entries (they flow naturally in spine order). Only add NCX entries for genuinely missing *logical* sections (e.g., an epigraph before Chapter 1). Renumber all `playOrder` and `id` attributes sequentially after changes.

### 3. Empty / Orphan Files

**Symptoms:** Files with near-zero text content (just the book title), or a plain-text TOC page with no hyperlinks.

**Fix:** Remove from the ZIP, the OPF manifest, and the OPF spine. Update `<guide>` references if needed.

### 4. Language Tag Inconsistency

**Symptoms:** `titlepage.xhtml` says `xml:lang="en"` on a Chinese book; NCX says `xml:lang="zho"` while OPF says `dc:language` `zh`.

**Fix:** Unify to `zh` everywhere.

### 5. Missing Footnotes (WeRead / MOBI source)

**Symptoms:** Empty `<sup><small></small></sup>` tags in calibre-converted EPUBs. The MOBI source lost footnote content during conversion.

**Diagnosis:** Check if another EPUB version (e.g., from WeRead/微信读书) has footnotes stored in `data-wr-footernote` HTML attributes:

```python
# WeRead stores footnotes as data attributes on span elements
notes = re.findall(r'data-wr-footernote="([^"]*)"', content)
# CSS class: .reader_footer_note with .pcalibre1:hover to show on hover
```

**Fix — extract and re-inject as standard EPUB footnotes:**

1. Extract all `data-wr-footernote` values with their anchor context from the WeRead EPUB.
2. In the target EPUB, replace each empty `<sup>` with a numbered link:
   ```html
   <sup><a epub:type="noteref" id="fnref1" href="endnotes.html#fn1">[1]</a></sup>
   ```
3. Create `endnotes.html` with each note wrapped in:
   ```html
   <aside epub:type="footnote" id="fn1">
     <p><a href="source_file.html#fnref1">[1]</a> Note text here.</p>
   </aside>
   ```
4. Add `endnotes.html` to the OPF manifest and spine.
5. Add a "译者注" entry to the NCX.

### 6. Kindle Footnote Popups Not Working

**Symptoms:** Footnote links navigate to endnotes page instead of showing a popup.

**Root cause:** Kindle requires EPUB 3 semantic attributes for popup footnotes.

**Fix — three required changes:**

1. **OPF:** Change `version="2.0"` to `version="3.0"`.
2. **Source links:** Add `epub:type="noteref"` and the `epub` XML namespace:
   ```html
   <html xmlns="http://www.w3.org/1999/xhtml"
         xmlns:epub="http://www.idpf.org/2007/ops">
   ...
   <a epub:type="noteref" id="fnref1" href="endnotes.html#fn1">[1]</a>
   ```
3. **Target notes:** Wrap in `<aside epub:type="footnote">`:
   ```html
   <aside epub:type="footnote" id="fn1">
     <p><a href="chapter.html#fnref1">[1]</a> Translation note.</p>
   </aside>
   ```

All three are required. Missing any one will cause Kindle to fall back to page navigation.

### 7. Broken EPUB 3 Upgrade (Missing Nav Document)

**Symptoms:** Calibre conversion fails or Kindle shows errors after upgrading `version="2.0"` to `version="3.0"`.

**Root cause:** EPUB 3 requires two things that EPUB 2 does not:
1. A navigation document (`<item properties="nav">` pointing to a `toc.xhtml` with `<nav epub:type="toc">`)
2. `<meta property="dcterms:modified">` timestamp in metadata

**Rule:** Do NOT upgrade to EPUB 3 unless the book needs EPUB 3 features (footnote popups with `epub:type`). If it only needs metadata/NCX fixes, stay on EPUB 2. Only upgrade when you also create the nav document and add the modified timestamp.

## Style Optimization (Chinese EPUBs)

### 8. Strip Chinese first-line indent

**Symptoms:** Kindle renders `text-indent: 2em` (and similar) on Chinese paragraphs incorrectly — extra blank space before paragraphs, broken alignment after inline links/footnotes.

**Rule:** Chinese EPUBs targeting Kindle must NOT carry `text-indent` declarations. Remove from every CSS rule and every inline `style="…"` attribute.

**Fix:**

```bash
python3 scripts/strip-indent.py book.epub book-fixed.epub
```

The script walks the ZIP and rewrites:
- `.css` files — strips `text-indent: <length>;` declarations (keeps the surrounding rule and other declarations intact).
- `.xhtml` / `.html` files — removes `text-indent` from inline `style` attributes; drops the attribute entirely if it becomes empty.

Class names and selectors are preserved so other rules on the same class still apply.

> Manual `　　` (two ideographic spaces) at paragraph start is *content*, not style — this script does not touch it. Strip those with a separate pass if needed.

### 9. Pangu spacing (盘古之白)

Insert a regular space between Chinese characters and adjacent ASCII letters/digits (e.g., `Python代码` → `Python 代码`).

**Choose by target reader:**

| Reader | CSS `text-autospace` | Recommendation |
|--------|----------------------|----------------|
| Kindle (KF8 / AZW3 / KFX) | ✗ silently ignored | **Must use script** |
| Apple Books (iOS 18+ / macOS Sequoia+) | ✓ via WebKit 18.4+ | CSS works |
| Calibre viewer, Koodo Reader | ✓ Chromium-based | CSS works |
| 微信读书 web | ✓ where browser supports | CSS works |
| Older devices / unknown targets | ✗ unreliable | Use script |

Kindle uses a custom restricted renderer (not WebKit/Chromium). `text-autospace` is not in Amazon's documented KF8 CSS support list and is dropped silently. For any EPUB that may end up on a Kindle, **bake the spacing into the text**.

**Script (required for Kindle):**

```bash
python3 scripts/pangu-spacing.py book.epub book-spaced.epub
```

The script inserts U+0020 between CJK and ASCII alphanumerics in HTML text nodes only. Skips:
- Tag attributes (won't break URLs or class names).
- `<pre>`, `<code>`, `<script>`, `<style>` element bodies.
- Already-spaced boundaries (idempotent — safe to re-run).

**Optional CSS for non-Kindle readers** — costs nothing, no harm if also using the script:

```css
html { text-autospace: ideograph-numeric ideograph-alpha; }
```

Note: `-ms-text-autospace` was IE-era; `-webkit-text-spacing` is not a real property. Modern WebKit/Blink use the unprefixed form.

### 10. Ad / marketing content detection

**Symptoms:** Pirated or fan-distributed Chinese EPUBs often carry promotional footers — 公众号 二维码, 扫码关注, QQ群, 转载请注明出处, 「本书由 XX 整理」 etc. Common in books sourced from telegram/网盘 shares.

**Scan with ripgrep:**

```bash
scripts/ad-filter.sh book.epub
```

Output: `file:line:matched-text` for every hit, color-coded. Patterns covered out of the box:

| Pattern | Targets |
|---------|---------|
| `公众号`, `订阅号`, `微信号`, `微信群`, `微信搜索` | WeChat marketing |
| `扫.{0,5}二维码`, `扫码关注`, `扫码加`, `微信扫一扫` | QR-code prompts |
| `QQ群`, `QQ号` | Legacy IM groups |
| `更多.{0,10}请关注`, `转载请注明`, `盗版必究` | Generic redistribution notices |
| `本书由.{0,30}整理`, `本书.{0,10}制作`, `本电子书.{0,20}制作` | Self-attribution footers |

Edit the `patterns=()` array in the script to extend. After review:
- If the ad sits inside a chapter, edit the source HTML and remove the offending block.
- If the ad occupies a dedicated file (a "thank you" page), remove that file from the ZIP, OPF manifest, and spine (see issue #3 above).

### 11. Responsive image sizing

**Symptoms:** Illustrations or chapter dividers authored at fixed pixel widths (`<img width="600">` or CSS `width: 600px`) overflow the right edge on Kindle Paperwhite / Oasis.

**Fix:** Append a single CSS rule to every stylesheet:

```bash
python3 scripts/responsive-images.py book.epub book-out.epub
```

Adds `img { max-width: 100%; height: auto; }`. Idempotent — files that already contain the rule are skipped. The override wins because it targets the bare `img` selector and sits at the end of the cascade; existing classes that set explicit widths get capped.

### 12. Strip leading ideographic spaces & empty paragraphs

**Symptoms:**
- Paragraphs that start with `　　` (two U+3000 ideographic spaces) — manual indent. After font/style overrides on Kindle, these render as visible blank squares before the first character.
- Hundreds of `<p>&nbsp;</p>`, `<p></p>`, `<p><br/></p>` left over from Word/Calibre conversions, creating uneven vertical rhythm and inflating file size.

**Fix:**

```bash
python3 scripts/strip-cruft.py book.epub book-out.epub
```

Pairs naturally with `strip-indent.py` (#8) — that one removes the CSS `text-indent` declarations; this one removes the manual character-based equivalent and the empty-paragraph noise.

### 13. Chinese corner brackets (opinionated)

**Replace** Western curly quotes with Chinese corner brackets:

| From | To |
|------|----|
| `"` (U+201C) | `「` |
| `"` (U+201D) | `」` |
| `'` (U+2018) | `『` |
| `'` (U+2019) | `』` |

```bash
python3 scripts/convert-quotes.py book.epub book-out.epub
```

All four conversions require a CJK-context neighbour on the inner-facing side (CJK ideograph, CJK punctuation `。、…`, or fullwidth form `！？`). Rationale:
- U+2019 is also the English typographic apostrophe (`don't`); unconditional conversion would corrupt every contraction.
- English passages embedded in a Chinese book — `She said "hello"` — would otherwise pick up `「」` too, which usually isn't wanted.

Edge case: a mixed-language quote like `他说"hello"` produces a broken pair (`他说「hello"`) because the closing `"` has no CJK neighbour. These are visible and rare; spot-check after running.

This **mutates the original text**. Personal preference transformation, not a rendering fix — only run on books you intend to read yourself.

## Repackaging an EPUB

```python
import zipfile

with zipfile.ZipFile("output.epub", 'w') as zf:
    # mimetype MUST be first, stored (no compression), no extra field
    zf.writestr('mimetype', 'application/epub+zip', compress_type=zipfile.ZIP_STORED)

    # Everything else: deflated
    zf.write('META-INF/container.xml', compress_type=zipfile.ZIP_DEFLATED)
    zf.write('content.opf', compress_type=zipfile.ZIP_DEFLATED)
    # ... HTML, CSS, NCX ...

    # Images: stored (already compressed)
    zf.write('cover.jpeg', compress_type=zipfile.ZIP_STORED)
```

## Kindle Font Management

### Install custom fonts

Place `.ttf` or `.otf` files in the Kindle's `fonts/` folder (root level). All books can then select the font via `Aa` menu.

### macOS + Kindle MTP Transfer

Newer Kindles (2024+) use MTP protocol. macOS does not natively mount MTP devices in Finder. Calibre can access them.

**Transfer files via calibre-debug (Calibre GUI must be closed first):**

```python
calibre-debug -c "
from calibre.devices.mtp.driver import MTP_DEVICE
from calibre.devices.scanner import DeviceScanner
from io import BytesIO

s = DeviceScanner()
s.scan()

dev = MTP_DEVICE(None)
dev.startup()
devs = dev.detect_managed_devices(s.devices, force_refresh=True)
dev.open(devs, 'calibre')

storage = list(dev.filesystem_cache.entries)[0]
target_folder = dev.create_folder(storage, 'fonts')

with open('/path/to/font.ttf', 'rb') as f:
    stream = BytesIO(f.read())
dev.put_file(target_folder, 'font.ttf', stream, stream.getbuffer().nbytes)

dev.shutdown()
"
```

**Important:** Close Calibre GUI before running — MTP device can only be claimed by one process. If the device disconnects, re-plug USB.

For batch transfers (multiple files in one connection), wrap the same logic in a `.py` file and run via `calibre-debug script.py -- <args>` — see *MTP Connection Stability* below for why bundling matters.

### Do NOT push raw EPUBs to Kindle

Kindle does not natively read EPUB files. Pushing `.epub` directly via MTP will cause errors. Always use Calibre to convert to AZW3/KFX first, then let Calibre handle the transfer. MTP scripts should only be used for non-book files (fonts, etc.) or for cleanup.

### MTP Raw Filesystem Access & Cleanup

Calibre's MTP driver filters out `documents/`, `fonts/`, `system/` from its filesystem cache. To list or delete files in those folders, use the raw `libmtp.Device` API:

```python
raw = dev.dev
sid = list(dev.filesystem_cache.entries)[0].object_id

objs = []
# callback signature: (entry_dict, level) -> bool
# entry_dict keys: name, id, parent_id, storage_id, size, modified, is_folder
# return True to recurse into folders
raw.get_filesystem(sid, lambda e, l: objs.append(e) or True)

# Delete by object id
for e in objs:
    if e['name'].endswith('.epub'):
        raw.delete_object(e['id'])
```

**Warning:** `calibre-debug -c "..."` inlines code as a single scope — lambdas referencing outer variables may fail with `NameError`. Write a `.py` file and run with `calibre-debug script.py` instead.

### MTP Connection Stability

- Each failed `calibre-debug` call kills the USB connection — must physically re-plug.
- `dev.shutdown()` also releases the device — next call requires re-plug.
- Cannot maintain persistent connections across separate `calibre-debug` invocations.
- Bundle all operations into a single script for reliability.

## Chinese Font Recommendations for E-ink

| Font | Style | Notes |
|------|-------|-------|
| HYXuanSong 45S (汉仪玄宋) | Sharp serif | Tight structure, high contrast, distinctive |
| FZYouSong (方正悠宋) | Modern serif | Even stroke weight, best for small sizes on low-res screens |
| FZPingXianYaSong (方正屏显雅宋) | Screen-optimized serif | Softened serifs, designed for screen reading |
| FZQingKeBenYueSong (方正清刻本悦宋) | Classical woodblock serif | Strong literary character, good for translated fiction |
| Source Han Serif (思源宋体) | Standard serif | Free/open-source, Medium weight recommended |
