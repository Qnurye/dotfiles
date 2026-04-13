---
name: epub-fix
description: Diagnose and fix EPUB ebook issues — metadata, TOC, footnotes, Kindle compatibility, font management, and MTP file transfer. Use when user has an EPUB with broken formatting, missing footnotes, bad metadata, or needs to transfer files to a Kindle.
---

# EPUB Fix & Kindle Toolkit

Accumulated recipes for diagnosing and repairing EPUB ebooks and managing Kindle devices.

## References

- `references/epub3-spec.md` — Complete EPUB 3.3 spec reference: required files, package document structure, navigation, footnote markup, embedded fonts, ZIP packaging rules, and a pre-ship validation checklist. Load when building an EPUB from scratch or validating against the spec.

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

**Batch transfer script:** `scripts/kindle-push.py` — push multiple files in one connection:

```bash
# Push books
calibre-debug scripts/kindle-push.py -- book1.epub book2.epub
# Push fonts
calibre-debug scripts/kindle-push.py -- font.ttf --dest fonts
```

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
