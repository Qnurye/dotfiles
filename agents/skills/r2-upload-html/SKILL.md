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
