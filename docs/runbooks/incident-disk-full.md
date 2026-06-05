# Runbook: Disk Full / Disk Pressure

Use when disk usage is high or full — `healthcheck.sh` reports Disk Usage
**WARN** (≥ `JARVIS_DISK_WARN_PCT`, default 85%) or **FAIL**
(≥ `JARVIS_DISK_FAIL_PCT`, default 95%), or writes (backups, reports, logs) start
failing.

> Reference: [../troubleshooting.md](../troubleshooting.md#disk-full) ·
> [../administration.md](../administration.md#log-rotation) ·
> [../backup.md](../backup.md#retention)

## 1. Detect

```bash
scripts/healthcheck.sh     # Disk Usage WARN/FAIL
scripts/status.sh          # Storage section: disk % and dir sizes
df -h
```

## 2. Diagnose

Find what is consuming space:

```bash
du -sh logs backups reports state 2>/dev/null
du -sh backups/* | sort -h | tail
docker system df            # image/container/volume usage
```

Usual culprits, largest-first: `backups/` (archives), `reports/` (HTML/PDF
products), `logs/` (append-only JSON + container logs), Docker
images/build cache.

## 3. Remediate

Reclaim in order of safety:

1. **Prune old backups** — lower retention and let `backup.sh` clean up:
   ```ini
   # .env
   JARVIS_BACKUP_KEEP=7
   ```
   ```bash
   ./backup.sh        # writes one new archive, prunes older than keep count
   ```
   (Or remove specific old `backups/*.tar.gz` and their `.sha256` by hand.)

2. **Rotate / truncate host logs** — set up logrotate
   ([../administration.md](../administration.md#log-rotation)) or, as a one-off:
   ```bash
   : > logs/workflow-execution.log     # truncate a large structured log
   ```

3. **Cap container logs** — confirm bounds are set in `.env`
   (`DOCKER_LOG_MAX_SIZE`, `DOCKER_LOG_MAX_FILE`) and recreate to apply:
   ```bash
   docker compose up -d
   ```

4. **Archive or remove old reports** — move `reports/archive/` off-host, then
   delete locally.

5. **Prune Docker** — reclaim dangling images, stopped containers, build cache
   (does **not** touch named volumes without `--volumes`):
   ```bash
   docker system prune
   ```

6. **Trim n8n execution history** — ensure pruning is configured
   (`N8N_EXEC_MAX_AGE_HOURS`) and recreate n8n.

## 4. Verify

```bash
df -h
scripts/healthcheck.sh     # Disk Usage back to PASS, exits 0
scripts/status.sh
```

If still under pressure after reclaiming, expand the volume / move the repo to a
larger disk, and lower thresholds only as a temporary measure.
