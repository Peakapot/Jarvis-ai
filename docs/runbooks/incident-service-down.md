# Runbook: Service Down (n8n / Ollama)

Use when a core service is down or unresponsive — the bot stops replying, or
`healthcheck.sh` reports `n8n` or `Ollama` as `Not responding`.

> Reference: [../troubleshooting.md](../troubleshooting.md) ·
> [../operations.md](../operations.md)

## 1. Detect

```bash
scripts/status.sh          # which service is DOWN
scripts/healthcheck.sh     # FAIL on n8n and/or Ollama
```

Optionally capture a bundle for the record:

```bash
scripts/diagnostics.sh
```

## 2. Diagnose

```bash
docker compose ps                      # container state / health
docker compose logs --tail=200 n8n     # or: ollama
```

Also check the relevant component logs: `logs/n8n.log`,
`logs/healthcheck.log`, and the structured `logs/workflow-execution.log` for
runtime errors.

Common causes:

- **n8n unhealthy** — missing/blank `N8N_ENCRYPTION_KEY`, container still in
  `start_period`, or a crash in the log.
- **Ollama down** — container stopped, network `jarvis-net` missing, or the
  default model not pulled.
- **Network** — services cannot resolve each other by container name.

## 3. Remediate

Restart the affected service first:

```bash
docker compose up -d              # recreate any missing/changed containers
docker compose restart n8n        # or: ollama
```

If the network is missing, recreate it (the installer is idempotent):

```bash
docker network inspect jarvis-net >/dev/null 2>&1 || ./install.sh
```

If n8n fails to start: confirm `N8N_ENCRYPTION_KEY` is set in `.env`, then
`docker compose up -d`.

If Ollama is up but the model is missing:

```bash
docker compose exec -T ollama ollama list
docker compose exec -T ollama ollama pull "$OLLAMA_DEFAULT_MODEL"
```

If a container is wedged, recreate it (volumes are preserved):

```bash
docker compose up -d --force-recreate n8n
```

## 4. Verify

```bash
docker compose ps          # services healthy
scripts/healthcheck.sh     # exits 0
scripts/status.sh          # all UP
```

Send the Telegram bot `/help` and confirm a reply. If the service still will not
recover, escalate with the diagnostics bundle from step 1 and consider
[restore-from-backup.md](restore-from-backup.md).
