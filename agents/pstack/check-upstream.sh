#!/bin/sh
set -eu

cd "$(dirname "$0")"
base=$(cat upstream-rev)
remote=https://github.com/backnotprop/pstack
result=$(GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$remote.git" HEAD)
head=${result%%[[:space:]]*}
for revision in "$base" "$head"; do
    case "$revision" in *[!0-9a-f]*|'') exit 1 ;; esac
    [ "${#revision}" -eq 40 ] || exit 1
done
[ "$base" != "$head" ] || exit 0
url="$remote/compare/$base...$head"
printf '%s\n' "$url"
[ "${1:-}" = --notify ] || exit 0
state="${XDG_STATE_HOME:-$HOME/.local/state}/pstack"
mkdir -p "$state"
pair="$base $head"
[ "$(cat "$state/notified" 2>/dev/null || true)" != "$pair" ] || exit 0
/usr/bin/osascript -e "display notification \"上游有新提交 $(printf '%.8s' "$head")，请 review。运行 check-upstream.sh 查看差异。\" with title \"pstack\""
tmp=$(mktemp "$state/notified.XXXXXX")
printf '%s\n' "$pair" > "$tmp"
mv "$tmp" "$state/notified"
