# Installation

How to install **Jarvis** from a clean host using the idempotent bootstrap
installer, [`install.sh`](../install.sh).

> See also: [architecture.md](architecture.md) · [operations.md](operations.md)
> · [troubleshooting.md](troubleshooting.md)

## Table of contents

- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Configuration via `.env`](#configuration-via-env)
- [Installer flags](#installer-flags)
- [What each stage does](#what-each-stage-does)
- [Idempotency: re-running the installer](#idempotency-re-running-the-installer)
- [Verifying the installation](#verifying-the-installation)
- [The readiness report](#the-readiness-report)
- [Next steps](#next-steps)

## Prerequisites

Pre-flight checks are enforced by
[`scripts/validate.sh`](../scripts/validate.sh) before the installer changes
anything (*Fail-safe defaults*). Thresholds are configurable in `.env`.

| Requirement | Default threshold | `.env` override | Severity if unmet |
| --- | --- | --- | --- |
| Operating System | Linux | — | **FAIL** |
| WSL | informational | — | WARN (native Linux is fine) |
| Distribution | Ubuntu / Debian-like | — | WARN |
| Docker | ≥ 20.10, daemon reachable | `JARVIS_DOCKER_MIN_VERSION` | **FAIL** if missing/unreachable |
| Docker Compose | ≥ 2.0 (plugin v2) | `JARVIS_COMPOSE_MIN_VERSION` | **FAIL** if missing |
| RAM | ≥ 8 GB | `JARVIS_MIN_RAM_GB` | WARN |
| CPU | ≥ 2 cores | `JARVIS_MIN_CPU_CORES` | WARN |
| Disk (free) | ≥ 20 GB | `JARVIS_MIN_DISK_GB` | **FAIL** |
| Network access | outbound HTTPS | `JARVIS_NETWORK_PROBE_URL` | WARN |
| Ollama access | reachable | `OLLAMA_BASE_URL` | WARN (installer starts it) |

A **FAIL** aborts the install; **WARN**s are allowed unless you run validation
with `--strict`. Run validation independently any time:

```bash
scripts/validate.sh            # human-readable report
scripts/validate.sh --json     # machine-readable
scripts/validate.sh --strict   # treat warnings as failures
```

Your host user must be able to run Docker (in the `docker` group or via a
rootless setup). On WSL, ensure Docker Desktop integration (or a native daemon)
is running.

## Quick start

```bash
git clone <your-fork-or-origin-url> Jarvis-ai
cd Jarvis-ai
./install.sh
```

For an unattended / CI install that accepts defaults:

```bash
./install.sh --yes
```

The installer is **safe to interrupt and re-run** — completed stages are skipped
on the next run.

## Configuration via `.env`

All configuration lives in `.env` (*Configuration over hard coding*). You do not
create it by hand: stage 2 of the installer copies
[`.env.example`](../.env.example) to `.env` (mode `600`) and generates a strong
`N8N_ENCRYPTION_KEY` locally. It **never** overwrites an existing `.env`.

After the first run, edit `.env` to add credentials, then re-run `./install.sh`
(or restart the stack) to pick them up. Common values to set:

```ini
# Telegram (primary interface)
TELEGRAM_BOT_TOKEN=123456:abc...
TELEGRAM_ALLOWED_CHAT_IDS=11111111,22222222   # access control

# Email (default provider is generic SMTP)
EMAIL_PROVIDER=smtp
EMAIL_FROM=jarvis@example.com
EMAIL_TO=you@example.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587

# AI provider (Ollama is the local-first default; no key required)
AI_PROVIDER=ollama
OLLAMA_DEFAULT_MODEL=llama3.1:8b
```

`.env` is git-ignored and must **never** be committed. See
[administration.md](administration.md) for the full configuration reference and
[architecture.md](architecture.md#provider-abstraction-layer) for provider
switching.

## Installer flags

```text
./install.sh [--reset] [--skip-validate] [--yes] [--no-pull]
```

| Flag | Effect |
| --- | --- |
| `--reset` | Clear all task state and start fresh. **Does not delete data** (volumes/`.env` remain). |
| `--skip-validate` | Skip pre-flight validation (not recommended). |
| `--yes` | Non-interactive; accept defaults (CI-friendly; sets `JARVIS_ASSUME_YES`). |
| `--no-pull` | Do not pull the Ollama model (offline installs). |
| `-h`, `--help` | Print usage and exit. |

## What each stage does

`install.sh` runs nine stages, each tracked as an idempotent task (see
[architecture.md](architecture.md#state-and-idempotency-model)):

| # | Stage | Action | May fail without blocking re-run? |
| --- | --- | --- | --- |
| 1 | Validate environment | Runs `scripts/validate.sh` (unless `--skip-validate`). A FAIL aborts. | No |
| 2 | Bootstrap configuration | Creates `.env` from `.env.example` (chmod 600), generates `N8N_ENCRYPTION_KEY`. Leaves an existing `.env` untouched. | No |
| 3 | Create directories | Scaffolds `logs/`, `backups/`, `reports/` (+ `cyber-brief`, `archive`), `state/`, `logs/diagnostics/`, `data/` with safe perms. | No |
| 4 | Provision Docker network | Creates the external `jarvis-net` network if absent. | No |
| 5 | Start stack | `docker compose up -d`, then waits (bounded) for n8n to report healthy. | No |
| 6 | Pull default model | `ollama pull $OLLAMA_DEFAULT_MODEL` inside the container (skipped with `--no-pull`). | **Yes** (offline-tolerant) |
| 7 | Import workflows | Runs `scripts/workflows/workflow-import.sh` (validates first, then imports `core/` + `modules/`). | **Yes** |
| 8 | Health check | Runs `scripts/healthcheck.sh`. | No (reports only) |
| 9 | Readiness report | Writes `reports/readiness-<stamp>.txt` and prints it. | No |

Stages 6 and 7 are allowed to fail without blocking a later re-run, so an
offline install (no model pull) or a transient n8n hiccup will not stop you from
completing the rest and finishing the import later.

## Idempotency: re-running the installer

`install.sh` is designed to be run repeatedly:

- Completed stages are detected via markers under `state/tasks/` and skipped
  (you will see `… (already complete — skipping)`).
- If a previous run failed partway, just run `./install.sh` again — it resumes
  where it left off. No manual cleanup required.
- To force a single stage to re-run, delete its marker, e.g.
  `rm state/tasks/06-ollama-pull`.
- To start completely fresh (keeping data and `.env`):

  ```bash
  ./install.sh --reset
  ```

## Verifying the installation

```bash
scripts/healthcheck.sh          # human-readable PASS/WARN/FAIL/SKIP report
scripts/healthcheck.sh --json   # machine-readable
scripts/status.sh               # operational dashboard
```

`healthcheck.sh` validates: n8n responding, Ollama responding, Telegram token
(if configured), email/SMTP reachability, RSS feed reachability, workflow files
present, and disk usage. Unconfigured features report **SKIP**, not FAIL
(*Fail-safe defaults*). Exit code is non-zero only if something genuinely
**FAIL**ed.

## The readiness report

Stage 9 writes a timestamped report to `reports/readiness-<stamp>.txt`
containing the task-state summary, the JSON health check, and next steps. It is
also printed to the terminal at the end of the install. Keep it as a record of
what the installer concluded about the host.

## Next steps

- Open n8n at `http://localhost:5678` (or your `N8N_BASE_URL`).
- Add credentials in `.env` (Telegram/email) and re-run `./install.sh`.
- Send your Telegram bot a `/help` message.
- Read [operations.md](operations.md) for day-to-day running, then
  [administration.md](administration.md) for configuration and provider
  switching.
