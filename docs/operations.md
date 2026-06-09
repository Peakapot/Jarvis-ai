# Operations

Day-to-day running of the **Jarvis** stack: checking status and health, reading
logs, starting/stopping services, enabling optional profiles, and interacting
with the assistant.

> See also: [administration.md](administration.md) ·
> [troubleshooting.md](troubleshooting.md) ·
> [runbooks/README.md](runbooks/README.md)

## Table of contents

- [Daily checks](#daily-checks)
- [Status dashboard](#status-dashboard)
- [Health checks](#health-checks)
- [Logs](#logs)
- [The structured JSON log format](#the-structured-json-log-format)
- [Starting and stopping the stack](#starting-and-stopping-the-stack)
- [Compose profiles](#compose-profiles)
- [The scheduled cyber brief](#the-scheduled-cyber-brief)
- [Intelligence products](#intelligence-products)
- [Telegram commands](#telegram-commands)
- [Diagnostics](#diagnostics)

## Daily checks

A quick, read-only morning check:

```bash
scripts/status.sh        # one-pane operational view
scripts/healthcheck.sh   # pass/fail health (non-zero exit if anything FAILs)
```

Both are safe to run any time and as often as you like (*Idempotent*,
*Observability by default*).

## Status dashboard

[`scripts/status.sh`](../scripts/status.sh) is a lightweight, read-only
dashboard. It reports service up/down (n8n, Ollama, Telegram), the configured
email provider, container states (`docker compose ps`), workflow file count,
last successful / failed run markers, an **Intelligence Products** panel
(per-product enabled state, effective schedule and latest archived edition), and
storage usage for `logs/`, `backups/` and `reports/`.

```bash
scripts/status.sh           # human-readable
scripts/status.sh --json    # machine-readable single line
```

JSON shape:

```json
{"ts":"2026-06-05T06:00:00Z","n8n":"up","ollama":"up","email_provider":"smtp","workflows":3,"last_success":"...","last_failed":"...","disk_pct":"42"}
```

For deep pass/fail use `healthcheck.sh`; for incident capture use
`diagnostics.sh`.

## Health checks

[`scripts/healthcheck.sh`](../scripts/healthcheck.sh) performs runtime validation
and is safe to run from cron for continuous monitoring.

```bash
scripts/healthcheck.sh           # report
scripts/healthcheck.sh --json    # machine-readable
scripts/healthcheck.sh --quiet   # set exit code only
```

Checks: **n8n** responding, **Ollama** responding, **Telegram** token valid
(if set), **Email** reachability (SMTP TCP probe / OAuth providers reported as
configured), **RSS feeds** reachability, **Workflows** present, **Image
Provider** (configured + credentials present, used by intelligence cover
images), **Intelligence** products (registry-driven per-product checks via
`scripts/lib/intelligence.sh`: enablement, workflow present, sources count,
report/archive dirs, latest archived edition, schedule), and **Disk usage**.

Status meanings:

- **PASS** — healthy.
- **WARN** — degraded but not broken (e.g. partial RSS reachability).
- **FAIL** — broken; the script exits non-zero.
- **SKIP** — feature not configured (e.g. no `TELEGRAM_BOT_TOKEN`). A SKIP is
  never a failure (*Fail-safe defaults*).

Disk thresholds are tunable: `JARVIS_DISK_WARN_PCT` (default 85),
`JARVIS_DISK_FAIL_PCT` (default 95).

Run it from cron, e.g. every 15 minutes, logging JSON:

```cron
*/15 * * * * cd /path/to/Jarvis-ai && scripts/healthcheck.sh --json >> logs/healthcheck.jsonl 2>&1
```

## Logs

Logs live under [`logs/`](../logs). There are two kinds:

- **Per-component script logs** (`logs/<component>.log`) — structured JSON
  written by the shell library, one file per component:
  `installer.log`, `validate.log`, `healthcheck.log`, `status.log`,
  `backup.log`, `workflow.log`, `providers.log`, `diagnostics.log`.
- **Workflow / runtime logs** — `logs/n8n.log` (n8n's own log, also visible via
  `docker compose logs n8n`), `logs/workflow-execution.log` (structured records
  from the central error workflow), `logs/last-run-success.txt` /
  `logs/last-run-failed.txt` (run markers surfaced by `status.sh`), and
  `logs/workflow-import-result.txt` (per-file import outcome).

Container logs are also available directly:

```bash
docker compose logs -f n8n
docker compose logs --tail=200 ollama
```

Log retention is covered in [administration.md](administration.md#log-rotation).

## The structured JSON log format

Every script log line is a single JSON object with a stable, machine-parseable
shape so it can be shipped to an aggregator unchanged:

```json
{"ts":"2026-06-05T12:00:00Z","level":"info","component":"installer","msg":"Stack started","pid":1234,"host":"jarvis"}
```

Fields: `ts` (UTC ISO-8601), `level` (`debug|info|warn|error`), `component`,
`msg`, `pid`, `host`. The verbosity threshold is `JARVIS_LOG_LEVEL`. Tail and
filter with `jq`:

```bash
tail -f logs/healthcheck.log | jq 'select(.level=="error")'
```

## Starting and stopping the stack

The stack is plain Docker Compose. Run these from the repo root.

```bash
docker compose up -d         # start core services (n8n + ollama)
docker compose ps            # show service states
docker compose stop          # stop without removing containers
docker compose start         # start stopped containers
docker compose restart n8n   # restart a single service
docker compose down          # stop and remove containers (volumes are kept)
```

`docker compose down` keeps named volumes (`n8n_data`, `ollama_data`), so your
workflows, credentials and models survive. Do **not** pass `-v` unless you
intend to destroy data.

The scripts resolve the right Compose command automatically (plugin v2 or legacy
`docker-compose`) via the shared library.

## Compose profiles

Optional services are gated behind profiles
([architecture.md](architecture.md#docker-service-topology)). Enable them with
`COMPOSE_PROFILES`:

```bash
# Future vector database (knowledge base / long-term memory)
COMPOSE_PROFILES=vectordb docker compose up -d

# Future monitoring stack (Prometheus + Grafana)
COMPOSE_PROFILES=monitoring docker compose up -d

# Both
COMPOSE_PROFILES=vectordb,monitoring docker compose up -d
```

To make a profile permanent, set `COMPOSE_PROFILES` in your shell environment or
in `.env`. Grafana defaults to admin password `admin` — set
`GRAFANA_ADMIN_PASSWORD` before enabling monitoring.

## The scheduled cyber brief

The [`cyber-brief`](../workflows/core/cyber-brief.json) workflow produces a
daily threat-intelligence product. It is configured in `.env`:

| Variable | Default | Meaning |
| --- | --- | --- |
| `CYBER_BRIEF_SCHEDULE_CRON` | `0 6 * * *` | Schedule (daily 06:00). |
| `CYBER_BRIEF_REGION_FOCUS` | `UAE` | Regional emphasis. |
| `CYBER_BRIEF_OUTPUT_FORMATS` | `html,pdf,email` | Output formats. |

Sources are listed in [`config/rss-feeds.txt`](../config/rss-feeds.txt) — add or
remove feeds there without touching the workflow (see
[administration.md](administration.md#managing-rss-feeds)). Generated briefs land
in `reports/cyber-brief/` and are archived under `reports/archive/`. You can
also trigger it on demand from Telegram with `/cyber`.

The cyber brief is one of three **intelligence products** — see below.

## Intelligence products

Jarvis runs a **registry-driven intelligence framework**
([architecture.md](architecture.md#intelligence-product-framework)). Four
briefs (three daily, one weekly) share one pipeline, schedules, archive and
premium branding; each is
declared in [`config/intelligence/products.json`](../config/intelligence/products.json).
Full detail is in [intelligence-products.md](intelligence-products.md).

| Product | Default schedule | Schedule env | Telegram | Outputs |
| --- | --- | --- | --- | --- |
| Cyber Threat Brief (`cyber-brief`) | `0 6 * * *` (06:00) | `CYBER_BRIEF_SCHEDULE_CRON` | `/cyber` | `reports/cyber-brief/` + archive |
| Cyber Opportunities Brief (`cyber-opportunities`) | `15 6 * * *` (06:15) | `CYBER_OPPS_SCHEDULE_CRON` | `/opportunities` | `reports/cyber-opportunities/` + archive |
| Energy Intelligence Brief (`energy-intelligence`) | `30 6 * * *` (06:30) | `ENERGY_BRIEF_SCHEDULE_CRON` | `/energy` | `reports/energy-intelligence/` + archive |
| Cyber Defence Watch (`defence-cyber`) | `30 5 * * 1` (Mon 05:30) | `DEFENCE_BRIEF_SCHEDULE_CRON` | `/defence` | `reports/defence-cyber/` + archive |

Running and scheduling:

- **On a schedule.** Each brief runs from its own cron trigger; change the time
  by editing the relevant `*_SCHEDULE_CRON` in `.env` (e.g.
  `ENERGY_BRIEF_SCHEDULE_CRON=0 7 * * *`).
- **On demand.** Trigger the workflow in n8n, or send the Telegram command
  (`/opportunities`, `/energy`).
- **Enable / disable.** Set the product's `*_ENABLED` flag (e.g.
  `CYBER_OPPS_ENABLED=false`); a disabled product reports `SKIP` in health and
  status, never `FAIL`.
- **Sources.** Edit the per-product source list — `config/rss-feeds.txt`,
  `config/cyber-opportunities-sources.txt`, `config/energy-sources.txt` — without
  touching any workflow.
- **Cover images.** All three open with an AI-generated cover via
  `IMAGE_PROVIDER`; if it is unset or fails, the brief renders without a cover.

Monitor them with the standard tooling:

```bash
scripts/status.sh                              # Intelligence Products panel
scripts/healthcheck.sh --json                  # per-product + Image Provider checks
modules/cyber-opportunities/healthcheck.sh     # one product, including source reachability
modules/energy-intelligence/healthcheck.sh --json
```

## Telegram commands

Telegram is the primary interface. Only chat IDs in
`TELEGRAM_ALLOWED_CHAT_IDS` are served (*access control*). Supported commands:

| Command | Action |
| --- | --- |
| `/help` | List available commands. |
| `/status` | System status. |
| `/research <topic>` | Run a research task. |
| `/emails` | Inbox summary / digest. |
| `/image <prompt>` | Generate an image (image provider). |
| `/cyber` | Return the latest cyber threat brief. |
| `/opportunities [org\|date]` | Latest cyber opportunities brief (plus history / search by organisation or date). |
| `/energy [org\|date]` | Latest energy intelligence brief (plus history / search, e.g. ADNOC, TAQA, Masdar). |
| _free text_ | Falls back to the AI assistant for natural-language intent. |

Every external call in the workflow has a failure path: if a request errors, the
user receives a graceful failure notice and the incident is logged via the
central error workflow ([architecture.md](architecture.md#request-flow-a-telegram-message-round-trip)).
New commands are added by extending the Command Router switch — see
[development.md](development.md#adding-a-workflow).

## Diagnostics

When something is wrong and you need a shareable snapshot:

```bash
scripts/diagnostics.sh                # writes a tarball under logs/diagnostics/
scripts/diagnostics.sh --no-archive   # leave the files unbundled
```

The bundle is redacted — `.env` **values are never included**, only key names
(*Security by default*). See
[troubleshooting.md](troubleshooting.md#capturing-a-support-bundle).
