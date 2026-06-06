# Jarvis Documentation

Welcome to the documentation set for **Jarvis** — a Docker-first personal AI
assistant platform built on [n8n](https://n8n.io) (workflow orchestration) and
[Ollama](https://ollama.com) (local-first LLM runtime).

This documentation is written **as code**: it lives in the repository next to
the system it describes, is reviewed in pull requests, and is kept accurate to
the actual scripts, flags and paths that ship in this repo (*Documentation as
code*).

## Engineering principles

Every document here reflects the principles the platform is built on:

- **Infrastructure as Code** — the whole stack is declared in
  [`docker-compose.yml`](../docker-compose.yml) and stood up by
  [`install.sh`](../install.sh).
- **Configuration over hard coding** — all tunables live in `.env`; nothing
  host-specific is baked into code.
- **Modular architecture** & **Separation of concerns** — decoupled services,
  a shared shell library, swappable provider descriptors, prompts kept out of
  workflows.
- **Idempotent operations** — installs, imports and migrations are re-runnable
  and resume safely.
- **Fail-safe defaults** — strict bash mode, integrity checks before mutation,
  graceful degradation.
- **Security by default** — secrets never leave `.env`, never enter Git, never
  enter backups or diagnostics.
- **Observability by default** — structured JSON logs, health checks, status
  dashboard, diagnostics bundles.

## Documentation index

| Document | Description |
| --- | --- |
| [architecture.md](architecture.md) | System architecture: service topology, provider abstraction, workflows-as-code, storage and observability, with diagrams. |
| [installation.md](installation.md) | Prerequisites and the `./install.sh` flow, stage by stage, with all flags. |
| [operations.md](operations.md) | Day-to-day running: status, health, logs, starting/stopping, Compose profiles, Telegram commands. |
| [intelligence-products.md](intelligence-products.md) | The registry-driven intelligence framework: the Cyber, Cyber Opportunities and Energy briefs, cover-image/branding system, monitoring, and the add-a-new-product recipe. |
| [administration.md](administration.md) | Configuration management, provider switching, RSS feeds, credentials, access control, log rotation. |
| [backup.md](backup.md) | What `backup.sh` captures, retention, checksums, scheduling, workflow-specific backup tooling. |
| [recovery.md](recovery.md) | `restore.sh` usage, integrity verification, the < 15 minute recovery runbook, disaster scenarios. |
| [troubleshooting.md](troubleshooting.md) | Common failures with symptom → diagnosis → fix, and how to capture a support bundle. |
| [upgrade.md](upgrade.md) | Pulling new images, backup-before-upgrade, workflow migrations, rollback, version pinning. |
| [development.md](development.md) | Repo layout, conventions, adding workflows/prompts/providers/modules, ShellCheck, CI, testing. |
| [diagrams/README.md](diagrams/README.md) | Why diagrams are kept as Mermaid source. |
| [runbooks/README.md](runbooks/README.md) | Operational runbooks index. |
| [runbooks/incident-service-down.md](runbooks/incident-service-down.md) | A service (n8n/Ollama) is down — detect → diagnose → remediate → verify. |
| [runbooks/incident-disk-full.md](runbooks/incident-disk-full.md) | Disk pressure / full disk runbook. |
| [runbooks/restore-from-backup.md](runbooks/restore-from-backup.md) | Restore the platform from a backup archive. |

## Where to start

- **First time installing?** → [installation.md](installation.md)
- **Running it day to day?** → [operations.md](operations.md)
- **Something broke?** → [troubleshooting.md](troubleshooting.md) then the
  [runbooks](runbooks/README.md)
- **Want to understand how it fits together?** → [architecture.md](architecture.md)
- **Contributing?** → [development.md](development.md)
