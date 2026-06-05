# Runbook: Restore From Backup

Use to recover the platform from a backup archive — after data loss, a corrupted
volume, a bad change, or a host rebuild. Target recovery time: **under 15
minutes**.

> Reference: [../recovery.md](../recovery.md) · [../backup.md](../backup.md)

## 1. Detect

You need a restore if any of: the host was rebuilt/wiped, `n8n_data` is
corrupted, workflows were lost or badly edited, or `healthcheck.sh` shows
unrecoverable component failures.

```bash
scripts/status.sh
scripts/healthcheck.sh
```

## 2. Diagnose — choose the right scope

| Situation | Use |
| --- | --- |
| Full host rebuild / data loss | Full restore **with** `--with-data` (this runbook). |
| Volume corrupt, repo intact | `./restore.sh <archive> --with-data`. |
| Bad workflow edit only | `scripts/workflows/workflow-restore.sh --import` (skip the rest). |
| Config/prompt mistake | Restore from any archive, or revert in Git. |

Identify the archive to use and verify its integrity:

```bash
ls -1 backups/jarvis-backup-*.tar.gz
cd backups && sha256sum -c jarvis-backup-<stamp>.tar.gz.sha256 && cd ..
```

`restore.sh` re-verifies this and **refuses to restore on mismatch**. If the
newest archive is corrupt, use an earlier one.

## 3. Remediate

On a fresh host, scaffold and start first:

```bash
./install.sh --yes
```

Then restore (omit `--with-data` if you only need non-secret assets):

```bash
./restore.sh backups/jarvis-backup-<stamp>.tar.gz --with-data --yes
```

`restore.sh` will: verify the checksum, take a pre-restore safety backup,
restore `workflows/ prompts/ config/ templates/ reports/`, restore the
`n8n_data` volume (with `--with-data`), print the `ENV_KEYS.txt` checklist, bring
the stack up, re-import workflows, and run a health check.

Re-supply secrets using the printed checklist:

```bash
# edit .env: TELEGRAM_BOT_TOKEN, SMTP/OAuth, remote AI keys,
# and N8N_ENCRYPTION_KEY (required to decrypt a --with-data volume)
docker compose up -d
```

Re-pull the AI model (models are not in backups):

```bash
docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"
```

## 4. Verify

```bash
scripts/healthcheck.sh     # exits 0
scripts/status.sh          # services UP, workflows present
```

Send the Telegram bot `/help` and confirm a reply. Trigger `/cyber` or `/status`
to confirm end-to-end behaviour. If credentials fail to decrypt, the original
`N8N_ENCRYPTION_KEY` was not restored — re-enter credentials in the n8n UI (see
[../recovery.md](../recovery.md#disaster-scenarios)).
