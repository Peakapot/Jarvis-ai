# Administration

Administering a running **Jarvis** instance: configuration, switching providers,
managing feeds and credentials, access control, and log rotation.

> See also: [operations.md](operations.md) ·
> [architecture.md](architecture.md#provider-abstraction-layer) ·
> [backup.md](backup.md)

## Table of contents

- [Managing `.env` configuration](#managing-env-configuration)
- [Configuration reference](#configuration-reference)
- [Switching providers](#switching-providers)
- [Managing RSS feeds](#managing-rss-feeds)
- [Managing n8n credentials](#managing-n8n-credentials)
- [User / access control](#user--access-control)
- [Log rotation](#log-rotation)

## Managing `.env` configuration

All configuration lives in [`.env`](../.env.example) (*Configuration over hard
coding*). It is created by the installer from `.env.example`, stored mode `600`,
git-ignored, and holds **all secrets**.

Rules:

- Never commit `.env`. The repository is public; `.gitignore` blocks it.
- Edit `.env`, then restart the affected service to apply:
  `docker compose up -d` (recreates containers with new env) or
  `docker compose restart <service>`.
- After a change, validate it took effect with `scripts/healthcheck.sh`.
- Keep a record of which keys you set — `backup.sh` archives the **key names**
  (not values) to remind you what to repopulate after a restore.

## Configuration reference

Grouped highlights (full list in [`.env.example`](../.env.example)):

| Group | Key variables |
| --- | --- |
| Platform | `TZ`, `JARVIS_DOCKER_NETWORK`, `JARVIS_LOG_LEVEL` |
| Validation thresholds | `JARVIS_MIN_RAM_GB`, `JARVIS_MIN_CPU_CORES`, `JARVIS_MIN_DISK_GB` |
| Backups | `JARVIS_BACKUP_KEEP` (retention count) |
| n8n | `N8N_IMAGE`, `N8N_PORT`, `N8N_BASE_URL`, `N8N_ENCRYPTION_KEY`, `N8N_DATA_VOLUME`, `N8N_LOG_LEVEL`, `N8N_EXEC_MAX_AGE_HOURS` |
| AI provider | `AI_PROVIDER`, `OLLAMA_DEFAULT_MODEL`, `ANTHROPIC_API_KEY`/`CLAUDE_MODEL`, `OPENAI_API_KEY`/`OPENAI_MODEL` |
| Image provider | `IMAGE_PROVIDER`, `IMAGE_MODEL`, `IMAGE_SIZE`, `OPENAI_IMAGE_API_KEY` |
| Email provider | `EMAIL_PROVIDER`, `EMAIL_FROM`, `EMAIL_TO`, `SMTP_HOST`/`SMTP_PORT`/`SMTP_SECURE`/`SMTP_USER`/`SMTP_PASSWORD` |
| Telegram | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_CHAT_IDS` |
| Cyber brief | `CYBER_BRIEF_SCHEDULE_CRON`, `CYBER_BRIEF_REGION_FOCUS`, `CYBER_BRIEF_OUTPUT_FORMATS` |
| Docker logging | `DOCKER_LOG_MAX_SIZE`, `DOCKER_LOG_MAX_FILE` |
| Future services | `QDRANT_*`, `PROMETHEUS_PORT`, `GRAFANA_PORT`, `GRAFANA_ADMIN_PASSWORD` |

## Switching providers

Provider selection is a **configuration change, not a code change**. Each kind
(AI, image, email) is described by a JSON descriptor under
[`config/providers/`](../config/providers) and selected by an env var. Workflows
never hard-code endpoints — they go through
[`scripts/providers/resolve-provider.sh`](../scripts/providers/resolve-provider.sh).
See [architecture.md](architecture.md#provider-abstraction-layer) for the model.

### Switching the AI provider

Default is `ollama` (local-first, no key required).

```ini
# .env
AI_PROVIDER=ollama          # local-first default
# AI_PROVIDER=claude        # requires ANTHROPIC_API_KEY
# AI_PROVIDER=openai        # requires OPENAI_API_KEY
```

To switch to a remote provider:

1. Set `AI_PROVIDER` to `claude` or `openai`.
2. Supply the API key (`ANTHROPIC_API_KEY` / `OPENAI_API_KEY`) and, if desired,
   the model (`CLAUDE_MODEL` / `OPENAI_MODEL`).
3. `docker compose up -d` to apply.
4. Verify: `scripts/providers/resolve-provider.sh ai` shows the active provider.

### Switching the email provider

```ini
EMAIL_PROVIDER=smtp           # default, provider-neutral
# EMAIL_PROVIDER=gmail        # OAuth credential configured inside n8n
# EMAIL_PROVIDER=microsoft365 # OAuth credential configured inside n8n
```

For `smtp`, set `SMTP_HOST`/`SMTP_PORT`/`SMTP_SECURE` and (optionally)
`SMTP_USER`/`SMTP_PASSWORD`. For `gmail`/`microsoft365`, only the provider
selection and `EMAIL_FROM`/`EMAIL_TO` live in `.env`; the OAuth credential is
configured **inside n8n** (see below). Verify with
`scripts/providers/resolve-provider.sh email`.

### Switching the image provider

```ini
IMAGE_PROVIDER=openai
IMAGE_MODEL=gpt-image-1
IMAGE_SIZE=1024x1024
# OPENAI_IMAGE_API_KEY=    # falls back to OPENAI_API_KEY if unset
```

### Adding a new provider

Drop a new descriptor at `config/providers/<kind>/<id>.json` conforming to
[`provider.schema.json`](../config/providers/provider.schema.json), then select
it via the relevant `*_PROVIDER` variable. No workflow edits required. See
[development.md](development.md#adding-a-provider).

## Managing RSS feeds

The cyber brief's sources are in
[`config/rss-feeds.txt`](../config/rss-feeds.txt) — one URL per line, `#` for
comments. Add or remove feeds here **without touching any workflow** (the
workflow ingests this file; `healthcheck.sh` probes reachability).

```text
# config/rss-feeds.txt
https://www.cisa.gov/cybersecurity-advisories/all.xml
https://krebsonsecurity.com/feed/
# https://example-uae-cert.gov.ae/feed   # add regional sources here
```

After editing, confirm reachability:

```bash
scripts/healthcheck.sh    # "RSS Feeds  N/M reachable"
```

## Managing n8n credentials

Secrets that back n8n nodes (Telegram bot token, OAuth for Gmail/Microsoft 365,
remote AI API keys) are stored **encrypted inside n8n**, in the `n8n_data`
volume, protected by `N8N_ENCRYPTION_KEY`. They are **not** kept in workflow
JSON (validation rejects plaintext secrets in workflows).

Guidelines:

- Configure credentials in the n8n UI at `N8N_BASE_URL` → **Credentials**, or
  via env-driven values where supported.
- Keep `N8N_ENCRYPTION_KEY` safe: it is generated locally by the installer and
  is required to decrypt the credentials DB. Losing it means re-entering all
  credentials. It is **not** stored in backups.
- To carry credentials across a rebuild, back up with `./backup.sh --with-data`
  (captures the encrypted `n8n_data` volume) **and** preserve
  `N8N_ENCRYPTION_KEY` separately. See [backup.md](backup.md).

## User / access control

Access to the assistant is controlled by `TELEGRAM_ALLOWED_CHAT_IDS` — a
comma-separated allow-list of Telegram chat IDs. The Telegram workflow's
"Authorise Chat" gate drops any message whose `chat.id` is not in the list
(*Security by default*).

```ini
TELEGRAM_ALLOWED_CHAT_IDS=11111111,22222222
```

To find a chat ID, message the bot and inspect the update, or use a Telegram
ID-lookup bot. Leaving this empty means no chat is authorised — fail-closed.
Restart after changes: `docker compose up -d`.

Beyond Telegram, harden the n8n web UI by binding it to localhost / a reverse
proxy and enabling `N8N_SECURE_COOKIE=true` when served over HTTPS.

## Log rotation

Three layers of log volume are managed independently (*Observability* without
unbounded growth):

### 1. Docker container logs

The `json-file` driver is bounded in
[`docker-compose.yml`](../docker-compose.yml) via `.env`:

```ini
DOCKER_LOG_MAX_SIZE=10m    # per file
DOCKER_LOG_MAX_FILE=5      # rotated files kept
```

### 2. n8n execution data

n8n prunes its execution database automatically:

```ini
# applied as EXECUTIONS_DATA_PRUNE / EXECUTIONS_DATA_MAX_AGE
N8N_EXEC_MAX_AGE_HOURS=336   # 14 days
```

### 3. Host-side script logs (`logs/*.log`)

The structured JSON logs under `logs/` grow append-only. Rotate them with
`logrotate`. Sample config (`/etc/logrotate.d/jarvis`):

```conf
/path/to/Jarvis-ai/logs/*.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

`copytruncate` is used because the scripts hold the files open in append mode.
Run-marker files (`last-run-*.txt`) and the import-result file are small and do
not need rotation. The `backups/` and `reports/` directories are managed
separately (see [backup.md](backup.md) for backup retention via
`JARVIS_BACKUP_KEEP`).
