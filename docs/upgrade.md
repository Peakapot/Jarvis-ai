# Upgrade

How to upgrade **Jarvis** safely: pulling new images, migrating workflows, and
rolling back if needed.

> See also: [backup.md](backup.md) · [recovery.md](recovery.md) ·
> [development.md](development.md)

## Table of contents

- [Upgrade principles](#upgrade-principles)
- [Backup before upgrade](#backup-before-upgrade)
- [Upgrading container images](#upgrading-container-images)
- [Workflow migrations](#workflow-migrations)
- [Rollback](#rollback)
- [Version pinning](#version-pinning)

## Upgrade principles

- **Always back up first** — an upgrade is only safe if you can roll back.
- **Pin versions** — reproducible upgrades, no surprise drift.
- **Migrate workflows with the tooling** — ordered, idempotent, state-tracked.
- **Verify after** — `scripts/healthcheck.sh` must pass.

## Backup before upgrade

```bash
./backup.sh --with-data
```

This captures workflows, prompts, config, templates, reports and the encrypted
n8n data volume, with a checksum. Note where `N8N_ENCRYPTION_KEY` is stored — you
need it to decrypt a `--with-data` restore. See [backup.md](backup.md).

## Upgrading container images

Image tags are configuration (*Configuration over hard coding*), set in `.env`.
The standard flow:

1. **Pin the new tags** in `.env` (see [version pinning](#version-pinning)):
   ```ini
   N8N_IMAGE=docker.n8n.io/n8nio/n8n:1.XX.X
   OLLAMA_IMAGE=ollama/ollama:0.X.X
   # QDRANT_IMAGE / PROMETHEUS_IMAGE / GRAFANA_IMAGE if those profiles are used
   ```
2. **Pull and recreate:**
   ```bash
   docker compose pull
   docker compose up -d
   ```
   Compose recreates only the services whose image changed.
3. **Run workflow migrations** (if the release notes call for them — see below).
4. **Verify:**
   ```bash
   scripts/healthcheck.sh
   scripts/status.sh
   ```

If you use optional profiles, include them when pulling/upgrading, e.g.
`COMPOSE_PROFILES=vectordb,monitoring docker compose pull`.

## Workflow migrations

When the workflow schema evolves (renamed nodes, bumped provider references,
retargeted env placeholders), use
[`workflow-migrate.sh`](../scripts/workflows/workflow-migrate.sh) rather than
hand-editing in the n8n UI.

How it works (mirrors database migration tools):

- Migrations are executable scripts in `scripts/workflows/migrations/` named
  `NNNN-description.sh`, applied in lexical (ordered) sequence.
- Each receives a single workflow file path as `$1` and must be **idempotent**
  (safe to run repeatedly).
- Applied migrations are recorded per file in state
  (`wf-migrate:<workflow>:<migration>`) so each runs exactly once.
- The tool takes a **safety backup** (`workflow-backup.sh --no-export`) before
  mutating files, and **re-validates** afterward.

```bash
scripts/workflows/workflow-migrate.sh --dry-run   # preview what would apply
scripts/workflows/workflow-migrate.sh             # apply pending migrations
```

After migrating, re-import the updated workflows into n8n:

```bash
scripts/workflows/workflow-import.sh
```

To author a migration, see
[development.md](development.md#adding-a-workflow).

## Rollback

If an upgrade misbehaves:

1. **Revert image tags** in `.env` to the previous pinned versions, then:
   ```bash
   docker compose pull
   docker compose up -d
   ```
2. **Restore workflows/data** from the pre-upgrade backup if the data layer
   changed:
   ```bash
   ./restore.sh backups/jarvis-backup-<pre-upgrade-stamp>.tar.gz --with-data
   ```
   For a workflow-only revert, use
   `scripts/workflows/workflow-restore.sh --import` against the pre-migration
   snapshot the migrator created.
3. **Verify:** `scripts/healthcheck.sh`.

See [recovery.md](recovery.md) for the full restore procedure.

## Version pinning

- **Pin every image to an explicit tag** in `.env` before going to production.
  The defaults in `.env.example` use `:latest` for convenience, which is fine for
  first install but not for reproducible operations.
- **Record the working set** — keep the `.env` image tags and the backup
  `MANIFEST.txt` `git_commit` together so any version is reproducible.
- **Upgrade one layer at a time** where possible (images, then migrations) so a
  failure is easy to isolate and roll back.
