# Troubleshooting

Common **Jarvis** failures, each presented as **symptom → diagnosis → fix**, plus
how to capture a support bundle.

> See also: [operations.md](operations.md) · [recovery.md](recovery.md) ·
> [runbooks/README.md](runbooks/README.md)

## Table of contents

- [First response](#first-response)
- [Capturing a support bundle](#capturing-a-support-bundle)
- [Docker daemon not running](#docker-daemon-not-running)
- [Port conflicts](#port-conflicts)
- [n8n not healthy](#n8n-not-healthy)
- [Ollama not responding](#ollama-not-responding)
- [Model pull fails / offline](#model-pull-fails--offline)
- [Telegram token invalid](#telegram-token-invalid)
- [Email / SMTP failures](#email--smtp-failures)
- [RSS feeds unreachable](#rss-feeds-unreachable)
- [Disk full](#disk-full)
- [Workflow import failure](#workflow-import-failure)
- [Workflow runtime failures](#workflow-runtime-failures)

## First response

Run these three, in order. They identify almost everything:

```bash
scripts/status.sh         # what's up/down at a glance
scripts/healthcheck.sh    # pass/fail per component
scripts/validate.sh       # host prerequisites (if install-time)
```

Then read the relevant component log under `logs/` (see
[operations.md](operations.md#logs)) or the container log
(`docker compose logs <service>`).

## Capturing a support bundle

When you need to escalate or keep a record, generate a redacted diagnostics
bundle:

```bash
scripts/diagnostics.sh                # tarball under logs/diagnostics/
scripts/diagnostics.sh --no-archive   # leave files unbundled
```

It captures: `validate.sh`/`healthcheck.sh`/`status.sh` JSON, Docker + Compose
state and per-service log tails, system/resource snapshot, component log tails,
workflow inventory + integrity, and `.env` **key names only** (values redacted —
*Security by default*). The bundle is safe to share.

---

## Docker daemon not running

- **Symptom:** install/validate reports `Docker — daemon not reachable`;
  `docker compose` errors with "Cannot connect to the Docker daemon".
- **Diagnosis:** `scripts/validate.sh` Docker check FAILs;
  `logs/validate.log`. Run `docker info` — it errors.
- **Fix:** Start Docker (Docker Desktop on WSL, or `sudo systemctl start docker`
  on native Linux). Ensure your user is in the `docker` group
  (`sudo usermod -aG docker $USER`, then re-login). Re-run `./install.sh`.

## Port conflicts

- **Symptom:** `docker compose up` fails with "port is already allocated" /
  "address already in use" for `5678`, `11434`, `6333`, `9090` or `3000`.
- **Diagnosis:** `docker compose ps`; `ss -ltnp | grep <port>` to find the
  holder.
- **Fix:** Stop the conflicting process, or change the port in `.env`
  (`N8N_PORT`, `OLLAMA_PORT`, `QDRANT_PORT`, `PROMETHEUS_PORT`, `GRAFANA_PORT`)
  and `docker compose up -d`. Update `N8N_BASE_URL` if you change `N8N_PORT`.

## n8n not healthy

- **Symptom:** `healthcheck.sh` reports `n8n — Not responding`; the installer
  warns "n8n did not report healthy within timeout".
- **Diagnosis:** `docker compose ps` (state/health of `jarvis-n8n`);
  `docker compose logs n8n` and `logs/n8n.log`. Common cause: missing/blank
  `N8N_ENCRYPTION_KEY` (the container requires it).
- **Fix:** Confirm `N8N_ENCRYPTION_KEY` is set in `.env` (the installer
  generates it; if blank, set a value and `docker compose up -d`). Give it time
  (`start_period` is 30s). If it still fails, `docker compose restart n8n` and
  re-check the log.

## Ollama not responding

- **Symptom:** `healthcheck.sh` reports `Ollama — Not responding`; AI replies in
  Telegram return the graceful failure notice.
- **Diagnosis:** `docker compose ps` for `jarvis-ollama`;
  `curl -fsS $OLLAMA_BASE_URL/api/tags`; `docker compose logs ollama`.
- **Fix:** `docker compose up -d ollama`. Verify the container is healthy. If the
  network is the issue, confirm `jarvis-net` exists
  (`docker network inspect jarvis-net`); re-run `./install.sh` to recreate it.

## Model pull fails / offline

- **Symptom:** installer stage 6 warns "Could not pull '<model>' (offline?)";
  AI replies fail with a model-not-found error.
- **Diagnosis:** `docker compose exec -T ollama ollama list` shows the model is
  absent; check outbound network with `scripts/validate.sh` (Network Access).
- **Fix:** When back online, pull manually:
  ```bash
  docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"
  ```
  For deliberate offline installs, run `./install.sh --no-pull` and pull later.
  Stage 6 is allowed to fail without blocking the rest of the install.

## Telegram token invalid

- **Symptom:** `healthcheck.sh` reports `Telegram — getMe failed`; the bot does
  not respond.
- **Diagnosis:** the check calls Telegram's `getMe`. If `TELEGRAM_BOT_TOKEN` is
  unset it reports **SKIP** (not a failure); if set but invalid it **FAIL**s.
  Test directly:
  ```bash
  curl -fsS "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"
  ```
- **Fix:** Re-issue/copy the token from BotFather into `TELEGRAM_BOT_TOKEN`,
  ensure outbound network to `api.telegram.org`, and `docker compose up -d`. If
  authorised users get no reply, check `TELEGRAM_ALLOWED_CHAT_IDS` includes
  their chat ID (see [administration.md](administration.md#user--access-control)).

## Email / SMTP failures

- **Symptom:** email digests/notifications do not send; `healthcheck.sh` Email
  check WARNs.
- **Diagnosis:** the check TCP-probes `SMTP_HOST:SMTP_PORT` (when
  `EMAIL_PROVIDER=smtp`). A WARN means unset/unverified host, not necessarily
  broken. Confirm reachability:
  ```bash
  nc -z -w5 "$SMTP_HOST" "${SMTP_PORT:-587}"
  ```
- **Fix:** Set `SMTP_HOST`/`SMTP_PORT`/`SMTP_SECURE` and credentials in `.env`.
  For `gmail`/`microsoft365`, re-check the OAuth credential in the n8n UI. Verify
  the active provider with `scripts/providers/resolve-provider.sh email`.

## RSS feeds unreachable

- **Symptom:** cyber brief misses sources; `healthcheck.sh` RSS check WARNs/FAILs
  (`N/M reachable`).
- **Diagnosis:** the check reads
  [`config/rss-feeds.txt`](../config/rss-feeds.txt) and probes each URL. WARN =
  some reachable; FAIL = none reachable (likely network/DNS).
- **Fix:** Verify outbound HTTPS, fix or remove dead feed URLs in
  `config/rss-feeds.txt`, then re-run `scripts/healthcheck.sh`. No workflow edit
  needed (*Configuration over hard coding*).

## Disk full

- **Symptom:** `healthcheck.sh` Disk Usage **WARN** (≥ `JARVIS_DISK_WARN_PCT`,
  default 85%) or **FAIL** (≥ `JARVIS_DISK_FAIL_PCT`, default 95%); writes fail.
- **Diagnosis:** `scripts/status.sh` storage section; `df -h`;
  `du -sh logs backups reports`.
- **Fix:** See [runbooks/incident-disk-full.md](runbooks/incident-disk-full.md).
  Quick wins: lower `JARVIS_BACKUP_KEEP` and re-run `./backup.sh` to prune;
  rotate `logs/` ([administration.md](administration.md#log-rotation)); prune
  Docker (`docker system prune`); archive old `reports/`.

## Workflow import failure

- **Symptom:** installer stage 7 warns "Some workflows failed to import"; n8n is
  missing a capability.
- **Diagnosis:** read `logs/workflow-import-result.txt` (per-file `OK`/`FAIL`)
  and `logs/workflow.log`. Import runs validation first; if a file is invalid the
  import aborts. Check integrity:
  ```bash
  scripts/workflows/workflow-validate.sh
  ```
- **Fix:** Repair the offending JSON (valid JSON, has `nodes`/`connections`, no
  plaintext secrets), ensure the `n8n` container is running, then re-import:
  ```bash
  scripts/workflows/workflow-import.sh
  ```

## Workflow runtime failures

- **Symptom:** a Telegram request returns "Jarvis hit an error… it has been
  logged"; `status.sh` shows a recent "Last failed run".
- **Diagnosis:** every workflow routes errors to the central
  [error handler](../workflows/core/error-handler.json), which writes a
  structured record to `logs/workflow-execution.log` and updates
  `logs/last-run-failed.txt`. Inspect:
  ```bash
  tail -n 20 logs/workflow-execution.log | jq .
  ```
  The record names the workflow, failing node and error message.
- **Fix:** Address the named node (often a provider being down — see the Ollama
  / email sections above), then retry. n8n keeps full error executions
  (`saveDataErrorExecution: all`) viewable in the UI for deeper inspection.
