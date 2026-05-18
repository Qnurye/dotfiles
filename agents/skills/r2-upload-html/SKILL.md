## Configuration

Credentials and bucket info live outside this skill, in `~/.config/r2-upload/env`. The file must export five variables:

| Variable | Meaning | Example |
| --- | --- | --- |
| `AWS_ACCESS_KEY_ID` | R2 access key | `c2fd...` |
| `AWS_SECRET_ACCESS_KEY` | R2 secret | (32+ chars) |
| `R2_ENDPOINT` | S3 endpoint URL | `https://<account>.r2.cloudflarestorage.com` |
| `R2_BUCKET` | bucket name | `qnurye` |
| `R2_PUBLIC_HOST` | custom domain bound to the bucket (no scheme) | `bucket.qnury.es` |

## Prerequisites

- `aws` CLI installed. If absent, install via the OS package manager (e.g. `apt-get install -y awscli`, `brew install awscli`) or `pipx install awscli`.
- No `~/.aws/credentials` needed — env vars take precedence.

## Workflow

### 1. Load and validate config

```bash
set -a; [ -f ~/.config/r2-upload/env ] && . ~/.config/r2-upload/env; set +a
missing=()
for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY R2_ENDPOINT R2_BUCKET R2_PUBLIC_HOST; do
  [ -z "${!v:-}" ] && missing+=("$v")
done
printf 'missing: %s\n' "${missing[*]:-none}"
```

**If `missing` is non-empty (or the env file does not exist):** stop the upload flow and call `AskUserQuestion` to collect the missing values from the user. Use the table above as context in the question. After collecting answers, write them with secure perms:

```bash
mkdir -p ~/.config/r2-upload && chmod 700 ~/.config/r2-upload
umask 077
cat > ~/.config/r2-upload/env <<'EOF'
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export R2_ENDPOINT=<value>
export R2_BUCKET=<value>
export R2_PUBLIC_HOST=<value>
EOF
chmod 600 ~/.config/r2-upload/env
```

Then re-source and continue. Never echo the secret back in your reply, and never proceed with placeholder/invented values.

### 2. Decide the artifact

The skill handles two input shapes. Pick by inspecting the path the user gave you:

| Input | Action | Content-Type |
| --- | --- | --- |
| Single `.html` file | Upload as-is | `text/html; charset=utf-8` |
| Single other file | Upload as-is | infer from extension; fall back to `application/octet-stream` |
| Directory | `tar -czf` into `/tmp/<basename>.tar.gz` first | `application/gzip` |

For directories, exclude noise before tarring (`.git`, `node_modules`, `.DS_Store`):

```bash
SRC="/abs/path/to/dir"
BASE="$(basename "$SRC")"
ARCHIVE="/tmp/${BASE}.tar.gz"
tar -czf "$ARCHIVE" \
  --exclude='.git' --exclude='node_modules' --exclude='.DS_Store' \
  -C "$(dirname "$SRC")" "$BASE"
```

### 3. Build the object key

Use `<basename>-<UTC timestamp>.<ext>` so re-uploads never overwrite and the key is self-dating:

```bash
STAMP="$(date -u +%Y%m%d-%H%M%S)"
KEY="${BASE}-${STAMP}.${EXT}"   # e.g. report-20260518-160054.html
```

For HTML you may want a stable key the user can re-share — only do that when the user asks for it, and warn that re-uploads will replace the previous version.

### 4. Upload

```bash
aws s3 cp "$LOCAL_PATH" "s3://${R2_BUCKET}/${KEY}" \
  --endpoint-url "${R2_ENDPOINT}" \
  --content-type "$CONTENT_TYPE" \
  --cache-control "public, max-age=31536000, immutable"
```

The long `Cache-Control` is safe because the key is timestamped (immutable in practice). For stable/overwritable keys, drop `immutable` and lower `max-age` (e.g. `max-age=300`).

### 5. Return the public URL and verify

```bash
URL="https://${R2_PUBLIC_HOST}/${KEY}"
curl -sI "$URL" | head -3
echo "$URL"
```

Report the URL to the user. If `curl -I` returns anything other than `200`, surface the status line instead of pretending it worked.

### 6. Cleanup

If you created a tarball in `/tmp`, delete it after a successful upload. Leave the user's original files untouched.
