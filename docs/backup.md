# Backup

How **Jarvis** backups work, what they include, and how to schedule them.
Backups are designed so the system can be recovered in under 15 minutes (see
[recovery.md](recovery.md)).

> See also: [recovery.md](recovery.md) ·
> [administration.md](administration.md) ·
> [runbooks/restore-from-backup.md](runbooks/restore-from-backup.md)

## Table of contents

- [What gets backed up](#what-gets-backed-up)
- [What is deliberately excluded](#what-is-deliberately-excluded)
- [Creating a backup](#creating-a-backup)
- [Archive layout](#archive-layout)
- [Integrity checksums](#integrity-checksums)
- [Retention](#retention)
- [Scheduling backups](#scheduling-backups)
- [Workflow-specific backup tooling](#workflow-specific-backup-tooling)

## What gets backed up

[`backup.sh`](../backup.sh) creates a single, integrity-checked, timestamped
archive covering everything required to recover the system. Before snapshotting
it validates workflows and refreshes the exported mirror from live n8n
(best-effort). Captured trees:

| Tree | Contents |
| --- | --- |
| `workflows/` | Workflow source, including the exported mirror. |
| `prompts/` | First-class versioned prompt assets. |
| `config/` | Provider/config descriptors, RSS feeds, templates (non-secret). |
| `templates/` | Email / report templates. |
| `reports/` | Generated intelligence products and archive. |
| n8n data volume | **Optional** (`--with-data`): the encrypted credentials + execution DB. |

An `ENV_KEYS.txt` (key **names** only) and a `MANIFEST.txt` (stamp, host,
git commit, `with_data` flag) are included for provenance.

## What is deliberately excluded

- **Secrets / `.env` values.** Never archived (*Security by default*). Only the
  key names are recorded, so an operator knows what to repopulate at restore
  time. Credentials are re-supplied during recovery.
- **`N8N_ENCRYPTION_KEY`.** Not in backups. If you take `--with-data`, store
  this key separately — it is required to decrypt the credentials DB.
- **Ollama models.** Not archived (re-pullable). Re-pull after restore.
- **Transient state.** `logs/`, `state/` are not part of the archive.

## Creating a backup

```bash
./backup.sh                       # non-secret assets only (default)
./backup.sh --with-data           # also capture the encrypted n8n data volume
./backup.sh --out /mnt/backups    # write to a custom directory
```

On success the script prints the archive path (and a recovery hint). Output goes
to `backups/` by default. `--with-data` is recommended if you want credentials
and execution history to survive a full rebuild — pair it with safe storage of
`N8N_ENCRYPTION_KEY`.

## Archive layout

Each run produces a UTC-stamped tarball plus its checksum:

```text
backups/
├── jarvis-backup-20260605T060000Z.tar.gz
└── jarvis-backup-20260605T060000Z.tar.gz.sha256
```

Inside the archive:

```text
workflows/  prompts/  config/  templates/  reports/
ENV_KEYS.txt        # env var names, values redacted as "<set at restore>"
MANIFEST.txt        # backup_stamp, created, host, with_data, git_commit
n8n-data.tar.gz     # only present when created with --with-data
```

## Integrity checksums

A `.sha256` manifest is written beside every archive. `restore.sh` verifies it
before restoring and **refuses to restore** on mismatch (*Fail-safe defaults*).
Verify manually any time:

```bash
cd backups
sha256sum -c jarvis-backup-20260605T060000Z.tar.gz.sha256
```

## Retention

Old backups are pruned automatically, keeping the newest N (*Configuration over
hard coding*):

```ini
# .env
JARVIS_BACKUP_KEEP=14   # number of full backups to keep (default 14)
```

After writing a new archive, `backup.sh` deletes the oldest archives (and their
`.sha256`) beyond the keep count. Backups stored under a custom `--out`
directory are also subject to retention within that directory.

## Scheduling backups

Run `backup.sh` from cron. Example — a daily data-inclusive backup at 02:30:

```cron
30 2 * * * cd /path/to/Jarvis-ai && ./backup.sh --with-data >> logs/backup.log 2>&1
```

Recommendations:

- Schedule **before** the daily cyber brief and before any planned upgrade.
- Periodically copy `backups/*.tar.gz` (and `N8N_ENCRYPTION_KEY`) off-host.
- Test a restore regularly (see
  [recovery.md](recovery.md)) — an unverified backup is not a backup.

## Workflow-specific backup tooling

For finer-grained, workflow-only snapshots there is dedicated tooling under
[`scripts/workflows/`](../scripts/workflows) that produces versioned,
checksum-verified archives of just the `workflows/` tree:

```bash
scripts/workflows/workflow-backup.sh              # export from n8n, then archive
scripts/workflows/workflow-backup.sh --no-export  # archive tracked files only
```

These land in `backups/workflows/workflows-<stamp>.tar.gz` (+ `.sha256`) and are
restored with
[`workflow-restore.sh`](../scripts/workflows/workflow-restore.sh). The migration
tool takes one of these automatically before mutating workflow files
([upgrade.md](upgrade.md#workflow-migrations)).
