#!/usr/bin/env bash
# Scan an EPUB for likely ad / marketing content using ripgrep.
#
# Usage:
#   ad-filter.sh <epub-file>
#   ad-filter.sh <extracted-dir>
#
# Pass either a packed .epub (will be extracted to a temp dir) or an
# already-extracted directory. Output: file:line:matched-text for every
# hit. Edit the patterns=() array below to extend.

set -euo pipefail

input="${1:-}"
if [[ -z "$input" ]]; then
    echo "Usage: $0 <epub-file-or-dir>" >&2
    exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
    echo "ripgrep (rg) not found. Install with: brew install ripgrep" >&2
    exit 1
fi

target=""
if [[ -f "$input" ]]; then
    if ! command -v unzip >/dev/null 2>&1; then
        echo "unzip not found." >&2
        exit 1
    fi
    tmpdir=$(mktemp -d -t ad-filter.XXXXXX)
    trap 'rm -rf "$tmpdir"' EXIT
    unzip -q "$input" -d "$tmpdir"
    target="$tmpdir"
elif [[ -d "$input" ]]; then
    target="$input"
else
    echo "Not a file or directory: $input" >&2
    exit 1
fi

# Patterns target Chinese marketing footers commonly added to pirated /
# fan-distributed EPUBs. Each entry is a ripgrep regex (PCRE-lite).
patterns=(
    '公众号'
    '订阅号'
    '微信号'
    '微信群'
    '微信搜索'
    '微信扫一扫'
    '扫.{0,5}二维码'
    '扫码关注'
    '扫码加'
    '关注.{0,5}公众号'
    'QQ群'
    'QQ号'
    '更多.{0,10}请关注'
    '转载请注明'
    '盗版必究'
    '本书由.{0,30}整理'
    '本书.{0,10}制作'
    '本电子书.{0,20}制作'
    '本资源.{0,20}制作'
    '版权所有.{0,10}请勿'
)

# Join patterns with `|` for a single rg invocation.
alt=$(IFS='|'; echo "${patterns[*]}")

echo "Scanning: $input"
echo "Patterns: ${#patterns[@]}"
echo "---"

# Use --no-messages to swallow per-file errors (binary, etc.)
# Glob for typical EPUB content files.
if rg --color=always -n -H --no-messages \
      -g '*.{html,xhtml,htm,opf,ncx}' \
      "$alt" "$target"; then
    echo "---"
    echo "Review hits above. Then either:"
    echo "  - Edit the source HTML to remove the offending block, or"
    echo "  - If the file is dedicated to ads, drop it from manifest+spine."
else
    echo "No ad patterns matched."
fi
