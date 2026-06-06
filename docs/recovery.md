# Recovery

How to restore **Jarvis** from a backup. The system is designed for a recovery
time of **under 15 minutes** (*Backup and Recovery*).

> See also: [backup.md](backup.md) ·
> [runbooks/restore-from-backup.md](runbooks/restore-from-backup.md) ·
> [troubleshooting.md](troubleshooting.md)

## Table of contents

- [Overview](#overview)
- [Restoring from a backup](#restoring-from-a-backup)
- [Integrity verification](#integrity-verification)
- [The < 15 minute recovery runbook](#the--15-minute-recovery-runbook)
- [Re-supplying secrets](#re-supplying-secrets)
- [Workflow-only restore](#workflow-only-restore)
- [Disaster scenarios](#disaster-scenarios)

## Overview

[`restore.sh`](../restore.sh) restores an archive produced by
[`backup.sh`](../backup.sh). It verifies integrity, takes a pre-restore safety
backup, restores non-secret assets, optionally restores the n8n data volume,
reminds you which credentials to re-supply, brings the stack up, re-imports
workflows, and runs a health check.

## Restoring from a backup

```bash
# Restore the newest archive in backups/ (non-secret assets only)
./restore.sh

# Restore a specific archive
./restore.sh backups/jarvis-backup-20260605T060000Z.tar.gz

# Also restore the encrypted n8n data volume (if the archive has it)
./restore.sh backups/jarvis-backup-20260605T060000Z.tar.gz --with-data

# Non-interactive
./restore.sh --yes
```

What `restore.sh` does, in order:

1. Resolves the archive (newest in `backups/` if none given).
2. **Verifies the SHA-256 checksum** — refuses to restore on mismatch.
3. Prints the backup manifest and asks for confirmation.
4. Takes a **pre-restore safety backup** to `backups/pre-restore/`.
5. Restores `workflows/`, `prompts/`, `config/`, `templates/`, `reports/` and
   `modules/` (so intelligence products' workflows, prompts and config return).
6. With `--with-data`, restores the `n8n_data` volume from `n8n-data.tar.gz`.
7. Prints `ENV_KEYS.txt` — the credentials you must re-supply in `.env`.
8. `docker compose up -d` and re-imports workflows (`--include-exported`),
   including auto-imported module workflows for the intelligence products.
9. Runs `scripts/healthcheck.sh`.

After restore, the **intelligence products** (Cyber, Cyber Opportunities, Energy
and any future product) resume on their configured schedules — nothing further is
needed beyond re-supplying any secrets. Verify they are healthy with
`scripts/healthcheck.sh` (per-product + Image Provider checks) and
`scripts/status.sh` (Intelligence Products panel); see
[intelligence-products.md](intelligence-products.md).

## Integrity verification

Restore is fail-safe: if a `.sha256` manifest exists beside the archive and
verification fails, `restore.sh` **aborts before touching anything**. If no
manifest exists, it warns that integrity cannot be verified and continues. To
check an archive yourself before restoring:

```bash
cd backups
sha256sum -c jarvis-backup-20260605T060000Z.tar.gz.sha256
```

## The < 15 minute recovery runbook

A step-by-step recovery on a fresh or wiped host:

1. **Clone / restore the repository** to the host and `cd` into it.
2. **Place the backup archive** (and its `.sha256`) into `backups/` if it is not
   already there.
3. **Run the installer** to scaffold and start the stack:
   ```bash
   ./install.sh --yes
   ```
4. **Restore the backup** (use `--with-data` to recover credentials/executions):
   ```bash
   ./restore.sh backups/jarvis-backup-<stamp>.tar.gz --with-data --yes
   ```
5. **Re-supply secrets.** Edit `.env` using the printed `ENV_KEYS.txt` list as a
   checklist (Telegram token, SMTP/OAuth, remote AI keys). If you restored
   `--with-data`, also restore `N8N_ENCRYPTION_KEY` to its original value so the
   encrypted credentials decrypt.
6. **Apply config and re-import:**
   ```bash
   docker compose up -d
   scripts/workflows/workflow-import.sh --include-exported
   ```
7. **Re-pull the AI model** (models are not backed up):
   ```bash
   docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"
   ```
8. **Verify:**
   ```bash
   scripts/healthcheck.sh
   scripts/status.sh
   ```
   Send the bot `/help` and confirm a reply.

Steps 3–6 are the time-critical path; the model re-pull (step 7) can run in the
background and is not required for non-AI capabilities.

## Re-supplying secrets

Secrets are intentionally absent from backups (*Security by default*).
`restore.sh` prints the inventory of expected keys from `ENV_KEYS.txt` — work
through it in `.env`:

- `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_CHAT_IDS`
- Email: `SMTP_USER`/`SMTP_PASSWORD` (SMTP) or OAuth credentials re-entered in
  the n8n UI (Gmail / Microsoft 365)
- Remote AI: `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` (only if `AI_PROVIDER` is
  not `ollama`)
- `N8N_ENCRYPTION_KEY` — required to decrypt a restored `--with-data` volume

After editing, `docker compose up -d` to apply.

## Workflow-only restore

To restore just the workflows (e.g. after a bad edit) from a workflow archive:

```bash
# Newest workflow backup, restore files only
scripts/workflows/workflow-restore.sh

# A specific archive, and re-import into n8n
scripts/workflows/workflow-restore.sh backups/workflows/workflows-<stamp>.tar.gz --import
```

It verifies the checksum, takes a pre-restore snapshot of the current
`workflows/`, restores the tree, re-validates, and (with `--import`) re-imports
into n8n. See [backup.md](backup.md#workflow-specific-backup-tooling).

## Disaster scenarios

| Scenario | Recovery |
| --- | --- |
| Host lost / rebuilt | Follow the [< 15 minute runbook](#the--15-minute-recovery-runbook) with `--with-data`. |
| `n8n_data` volume corrupted | `./restore.sh <archive> --with-data` (restores the volume), then re-import. |
| Bad workflow edit / accidental delete | `scripts/workflows/workflow-restore.sh --import`. |
| Lost `N8N_ENCRYPTION_KEY` | Encrypted credentials cannot be decrypted — re-enter all credentials in n8n; generate a new key. |
| Corrupt backup (checksum fails) | Restore aborts; use an earlier archive. Test backups regularly. |
| Config-only mistake | Restore `config/`/`prompts/` from any archive, or revert in Git. |

After any recovery, run `scripts/healthcheck.sh` and review
[troubleshooting.md](troubleshooting.md) for residual issues.
