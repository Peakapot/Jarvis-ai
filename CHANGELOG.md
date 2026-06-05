# Changelog

All notable changes to Jarvis are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-06-05

Initial platform foundation establishing the long-term architecture.

### Added

- **Bootstrap installer** (`install.sh`) — idempotent, re-runnable, state-tracked
  9-stage install (validate → config → scaffold → network → stack → model pull →
  workflows → health → readiness report). Flags: `--reset`, `--skip-validate`,
  `--yes`, `--no-pull`.
- **Validation framework** — `scripts/validate.sh` (pre-install: OS, WSL, Ubuntu,
  Docker, Compose, RAM, CPU, disk, network, Ollama), `scripts/healthcheck.sh`
  (post-install/runtime: n8n, Ollama, Telegram, email, RSS, workflows, disk),
  `scripts/status.sh` (operational dashboard), `scripts/diagnostics.sh` (redacted
  support bundle). All support `--json`.
- **Docker-first topology** (`docker-compose.yml`) — n8n + Ollama core, with
  Qdrant (vectordb) and Prometheus/Grafana (monitoring) behind Compose profiles
  for future expansion.
- **Provider abstraction** — declarative descriptors under `config/providers/`
  for AI (Ollama/Claude/OpenAI), email (SMTP/Gmail/Microsoft 365) and image
  (OpenAI) providers, resolved by `scripts/providers/resolve-provider.sh`.
  Ollama is the default AI provider; switching is configuration-only.
- **Workflows as source code** — core workflows (Telegram assistant, Cyber Brief,
  central Error Handler) plus full lifecycle tooling: export, import, validate,
  backup, restore and migrate (`scripts/workflows/`).
- **Prompt management** — versioned, first-class prompt assets under `prompts/`
  with a registry and per-prompt changelogs, decoupled from workflows.
- **Backup & recovery** — `backup.sh` / `restore.sh` with checksums, retention,
  optional data-volume capture, and a <15-minute recovery target. Secrets are
  excluded from backups by design.
- **Structured logging** — shared shell library (`scripts/lib/`) emitting
  human-readable + JSON logs per component, with a log-rotation strategy.
- **Plugin module architecture** — `modules/` with a template and scaffolds for
  knowledge, meeting, calendar, ISO 27001, mindhaven, dealforge, presentation and
  image assistants.
- **Security by default** — strict `.gitignore`, `.env.example`, locally
  generated secrets, no credentials in the repository.
- **Enterprise documentation** — architecture, installation, operations,
  administration, backup, recovery, troubleshooting, upgrade and development
  guides, plus runbooks, under `docs/`.
- **CI** — workflow & shell validation in `.github/workflows/`.

[Unreleased]: https://github.com/peakapot/jarvis-ai/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/peakapot/jarvis-ai/releases/tag/v0.1.0
