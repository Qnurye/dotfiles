# EPUB 3.3 — What a Well-Formed EPUB Looks Like

Reference for producing spec-compliant, Kindle-compatible EPUB 3 files.
Based on W3C EPUB 3.3 (Recommendation, May 2025) and DAISY Accessible Publishing guidelines.

## File Structure

```
book.epub (ZIP archive)
├── mimetype                          # MUST be first entry, stored uncompressed
├── META-INF/
│   └── container.xml                 # Points to the package document
├── OEBPS/                            # (conventional name, any path works)
│   ├── content.opf                   # Package document
│   ├── toc.xhtml                     # EPUB 3 navigation document (replaces NCX)
│   ├── toc.ncx                       # Legacy NCX (optional, for EPUB 2 readers)
│   ├── css/
│   │   └── style.css
│   ├── images/
│   │   ├── cover.jpg
│   │   └── ...
│   ├── text/
│   │   ├── cover.xhtml
│   │   ├── titlepage.xhtml
│   │   ├── chapter01.xhtml
│   │   ├── chapter02.xhtml
│   │   ├── ...
│   │   └── endnotes.xhtml
│   └── fonts/                        # Optional embedded fonts
│       └── CustomFont.otf
```

## mimetype

```
application/epub+zip
```

- No trailing newline, no BOM.
- MUST be the first file in the ZIP archive.
- MUST be stored uncompressed (`ZIP_STORED`, compression method 0).
- MUST NOT have an extra field in its ZIP header.

## META-INF/container.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
              media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
```

## Package Document (content.opf)

### Minimal Complete Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf"
         version="3.0"
         unique-identifier="pub-id"
         xml:lang="zh">

  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <!-- === REQUIRED === -->
    <dc:identifier id="pub-id">urn:uuid:A1B2C3D4-E5F6-7890-ABCD-EF1234567890</dc:identifier>
    <dc:title>Book Title</dc:title>
    <dc:language>zh</dc:language>
    <meta property="dcterms:modified">2023-04-01T00:00:00Z</meta>

    <!-- === RECOMMENDED === -->
    <dc:creator id="creator1">Author Name</dc:creator>
    <meta refines="#creator1" property="role" scheme="marc:relators">aut</meta>
    <meta refines="#creator1" property="file-as">Last, First</meta>

    <dc:date>2023-04-01</dc:date>
    <dc:publisher>Publisher Name</dc:publisher>
    <dc:identifier id="isbn">urn:isbn:9787547744482</dc:identifier>
    <dc:subject>Fiction</dc:subject>
    <dc:description>Short description of the book.</dc:description>

    <!-- Cover image reference -->
    <meta name="cover" content="cover-img"/>
  </metadata>

  <manifest>
    <!-- Navigation -->
    <item id="nav" href="toc.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>

    <!-- Styles -->
    <item id="css" href="css/style.css" media-type="text/css"/>

    <!-- Images -->
    <item id="cover-img" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>

    <!-- Content -->
    <item id="cover" href="text/cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch01" href="text/chapter01.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch02" href="text/chapter02.xhtml" media-type="application/xhtml+xml"/>
    <item id="endnotes" href="text/endnotes.xhtml" media-type="application/xhtml+xml"/>

    <!-- Fonts (optional) -->
    <item id="font1" href="fonts/CustomFont.otf" media-type="font/otf"/>
  </manifest>

  <spine toc="ncx">
    <itemref idref="cover" linear="no"/>
    <itemref idref="ch01"/>
    <itemref idref="ch02"/>
    <itemref idref="endnotes"/>
  </spine>

  <guide>
    <reference type="cover" href="text/cover.xhtml" title="Cover"/>
    <reference type="toc" href="toc.xhtml" title="Table of Contents"/>
  </guide>
</package>
```

### Key Rules

| Element | Required | Notes |
|---------|----------|-------|
| `dc:identifier` | YES | Must have `id` matching `unique-identifier` on `<package>` |
| `dc:title` | YES | |
| `dc:language` | YES | BCP 47 tag: `zh`, `en`, `ja`, etc. |
| `dcterms:modified` | YES | `<meta property="dcterms:modified">` with ISO 8601 timestamp |
| `dc:creator` | No | Strongly recommended. Refine with `role` and `file-as` |
| `dc:date` | No | Publication date. Use `YYYY-MM-DD` or ISO 8601 |
| Navigation doc | YES | Exactly one `<item>` with `properties="nav"` |
| Cover image | No | Mark with `properties="cover-image"` on the `<item>` |

### Manifest `properties` Values

| Value | Meaning |
|-------|---------|
| `nav` | This is the EPUB 3 navigation document (required, exactly one) |
| `cover-image` | Cover image resource |
| `svg` | Content document contains SVG |
| `mathml` | Content document contains MathML |
| `scripted` | Content document contains scripts |
| `remote-resources` | Content document references remote resources |

## Navigation Document (toc.xhtml)

The EPUB 3 replacement for toc.ncx. Required.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      xml:lang="zh">
<head>
  <title>Table of Contents</title>
</head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>目录</h1>
    <ol>
      <li><a href="text/chapter01.xhtml">第一章</a>
        <ol>
          <li><a href="text/chapter01.xhtml#sec1">1</a></li>
          <li><a href="text/chapter01.xhtml#sec2">2</a></li>
        </ol>
      </li>
      <li><a href="text/chapter02.xhtml">第二章</a></li>
      <li><a href="text/endnotes.xhtml">译者注</a></li>
    </ol>
  </nav>

  <!-- Optional: landmarks -->
  <nav epub:type="landmarks" hidden="">
    <h2>Landmarks</h2>
    <ol>
      <li><a epub:type="cover" href="text/cover.xhtml">Cover</a></li>
      <li><a epub:type="toc" href="#toc">Table of Contents</a></li>
      <li><a epub:type="bodymatter" href="text/chapter01.xhtml">Start of Content</a></li>
    </ol>
  </nav>
</body>
</html>
```

### Rules

- `<nav epub:type="toc">` is **required** — at least one.
- Must use nested `<ol>` lists with `<a>` links.
- `<nav epub:type="landmarks">` is recommended for reading system UI hints.
- `<nav epub:type="page-list">` is recommended when a print equivalent exists.

## Content Documents (XHTML)

### Minimal Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:epub="http://www.idpf.org/2007/ops"
      xml:lang="zh">
<head>
  <meta charset="UTF-8"/>
  <title>Chapter Title</title>
  <link rel="stylesheet" type="text/css" href="../css/style.css"/>
</head>
<body>
  <section epub:type="chapter" role="doc-chapter" aria-label="第一章">
    <h1>第一章</h1>
    <p>Content here.</p>
  </section>
</body>
</html>
```

### Semantic Inflection (`epub:type`)

Common values from the EPUB 3 Structural Semantics Vocabulary:

| Value | Usage |
|-------|-------|
| `cover` | Cover page |
| `frontmatter` | Front matter section |
| `bodymatter` | Main content |
| `backmatter` | Back matter |
| `chapter` | A chapter |
| `prologue` / `epilogue` | Prologue / epilogue |
| `footnote` | A footnote body |
| `noteref` | A footnote reference link |
| `endnotes` | Endnotes section |
| `toc` | Table of contents |
| `landmarks` | Landmarks navigation |
| `titlepage` | Title page |
| `copyright-page` | Copyright page |
| `epigraph` | Epigraph / inscription |

## Footnotes — The Spec-Correct Way

This is the pattern that works across Kindle, Apple Books, Kobo, and accessibility tools.

### In the chapter content:

```xml
<p>Some text that needs a note<a epub:type="noteref" role="doc-noteref"
   id="fnref1" href="endnotes.xhtml#fn1"><sup>[1]</sup></a> and continues.</p>
```

### In endnotes.xhtml:

```xml
<section epub:type="endnotes" role="doc-endnotes">
  <h1>译者注</h1>
  <ol>
    <li>
      <aside epub:type="footnote" role="doc-footnote" id="fn1">
        <p><a href="chapter01.xhtml#fnref1" role="doc-backlink">[1]</a>
           The translation note text here.</p>
      </aside>
    </li>
  </ol>
</section>
```

### Required attributes for Kindle popup footnotes:

1. **`epub:type="noteref"`** on the link — tells the reading system this is a note reference.
2. **`epub:type="footnote"`** on the target — tells the reading system to render as popup.
3. **`xmlns:epub="http://www.idpf.org/2007/ops"`** on the `<html>` element — namespace declaration.
4. **EPUB version 3.0** in the OPF `<package version="3.0">`.

All four are required. Missing any one causes Kindle to fall back to page navigation.

### ARIA roles (for accessibility):

| Role | Element | Purpose |
|------|---------|---------|
| `doc-noteref` | `<a>` | Marks the note reference |
| `doc-footnote` | `<aside>` | Marks the note body |
| `doc-backlink` | `<a>` | Marks a link back to the reference |
| `doc-endnotes` | `<section>` | Marks the endnotes section |

### CSS for superscript references:

```css
a[role~='doc-noteref'] {
  vertical-align: super;
  line-height: normal;
  font-size: smaller;
}
```

## Embedded Fonts

### In CSS:

```css
@font-face {
  font-family: "CustomFont";
  src: url("../fonts/CustomFont.otf");
  font-weight: normal;
  font-style: normal;
}

body {
  font-family: "CustomFont", serif;
}
```

### In OPF manifest:

```xml
<item id="font1" href="fonts/CustomFont.otf" media-type="font/otf"/>
```

Supported types: `font/otf`, `font/ttf`, `font/woff`, `font/woff2`.

**Note:** Embedding large CJK fonts (10-20MB) significantly increases file size. For Kindle, installing fonts to the device `fonts/` folder is preferred.

## Legacy NCX (toc.ncx)

Optional in EPUB 3, but recommended for backward compatibility with EPUB 2 reading systems. Referenced via `<spine toc="ncx">`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="zh">
  <head>
    <meta name="dtb:uid" content="urn:uuid:A1B2C3D4-E5F6-7890-ABCD-EF1234567890"/>
    <meta name="dtb:depth" content="2"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle><text>Book Title</text></docTitle>
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>第一章</text></navLabel>
      <content src="text/chapter01.xhtml"/>
    </navPoint>
    <!-- ... -->
  </navMap>
</ncx>
```

### Rules

- `dtb:uid` must match the `dc:identifier` in the OPF.
- `playOrder` must be sequential starting from 1.
- `id` must be unique within the NCX.
- Nesting `<navPoint>` inside another `<navPoint>` creates hierarchy.

## ZIP Packaging Rules

```python
import zipfile

with zipfile.ZipFile("book.epub", 'w') as zf:
    # 1. mimetype: MUST be first, MUST be stored (not compressed)
    zf.writestr('mimetype', 'application/epub+zip',
                compress_type=zipfile.ZIP_STORED)

    # 2. META-INF: deflated
    zf.write('META-INF/container.xml', compress_type=zipfile.ZIP_DEFLATED)

    # 3. OPF, NCX, navigation: deflated
    zf.write('OEBPS/content.opf', compress_type=zipfile.ZIP_DEFLATED)

    # 4. Content, CSS: deflated
    # ... all .xhtml, .css files ...

    # 5. Images: stored (already compressed formats)
    zf.write('OEBPS/images/cover.jpg', compress_type=zipfile.ZIP_STORED)

    # 6. Fonts: stored
    zf.write('OEBPS/fonts/CustomFont.otf', compress_type=zipfile.ZIP_STORED)
```

## Validation Checklist

Before shipping an EPUB:

- [ ] `mimetype` is first ZIP entry, stored, no extra field
- [ ] `META-INF/container.xml` exists and points to OPF
- [ ] OPF has `version="3.0"`
- [ ] OPF has required metadata: `dc:identifier`, `dc:title`, `dc:language`, `dcterms:modified`
- [ ] `dc:identifier` `id` matches `unique-identifier` on `<package>`
- [ ] Navigation document exists with `properties="nav"` in manifest
- [ ] Navigation document has `<nav epub:type="toc">` with nested `<ol>`
- [ ] All manifest `href` values point to files that exist in the ZIP
- [ ] All spine `idref` values reference valid manifest `id` values
- [ ] All content documents are well-formed XHTML with correct namespace
- [ ] `xml:lang` is consistent and correct across all files
- [ ] Cover image marked with `properties="cover-image"`
- [ ] Footnotes use `epub:type="noteref"` and `epub:type="footnote"`
- [ ] No broken internal links (href targets exist)
- [ ] No orphan files (files in ZIP but not in manifest)
- [ ] `dc:date` is a real date (not `0101-01-01`)

## Sources

- [W3C EPUB 3.3 Specification](https://www.w3.org/TR/epub-33/)
- [EPUB 3.3 Updated Recommendation (2025)](https://www.w3.org/news/2025/updated-w3c-recommendation-epub-3-3/)
- [DAISY Accessible Publishing — Notes](https://kb.daisy.org/publishing/docs/html/notes.html)
- [IDPF EPUB 3 Accessibility Guidelines — Notes](https://idpf.github.io/a11y-guidelines/content/xhtml/notes.html)
- [EPUB 3 Overview](https://www.w3.org/TR/epub-overview-33/)
- [Schema.org Metadata Integration Guide](https://idpf.github.io/epub-guides/schema-org-integration/)
