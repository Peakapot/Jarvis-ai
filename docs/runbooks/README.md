# Runbooks

Concise, numbered operational runbooks for **Jarvis** incidents. Each follows
the same shape: **Detect → Diagnose → Remediate → Verify**. They are intended to
be executed top-to-bottom under time pressure.

> See also: [../troubleshooting.md](../troubleshooting.md) (symptom → fix
> reference) · [../operations.md](../operations.md) ·
> [../recovery.md](../recovery.md)

## Index

| Runbook | Use when |
| --- | --- |
| [incident-service-down.md](incident-service-down.md) | n8n or Ollama is down or unresponsive. |
| [incident-disk-full.md](incident-disk-full.md) | Disk usage is high or full and writes are failing. |
| [restore-from-backup.md](restore-from-backup.md) | You need to recover the platform from a backup archive. |

## Conventions

- Run all commands from the repository root.
- Triage tooling: `scripts/status.sh`, `scripts/healthcheck.sh`,
  `scripts/diagnostics.sh`.
- Capture a diagnostics bundle (`scripts/diagnostics.sh`) at the start of any
  non-trivial incident — it is redacted and safe to share
  (*Observability by default*, *Security by default*).
- "Verify" always ends with `scripts/healthcheck.sh` returning success.
