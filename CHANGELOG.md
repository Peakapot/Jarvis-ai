# Changelog

All notable changes to Jarvis are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] — 2026-06-06

Phase 2 — a reusable intelligence framework and two new daily intelligence
products, added entirely on the existing workflow, prompt, provider, branding,
backup and documentation frameworks (no core refactoring).

### Added

- **Intelligence Product Registry** (`config/intelligence/products.json`) — the
  single source of truth for all daily briefs, consumed by a shared library
  (`scripts/lib/intelligence.sh`: `intel_ids`, `intel_field`, `intel_enabled`,
  `intel_checks`). Install, validate, health, status and backup all iterate it,
  so future products are a registry + module change, never a core code change.
- **Common branding framework** (`config/intelligence/branding.json`,
  `config/intelligence/regions.json`, `templates/report/intelligence-base.html.tpl`)
  — one consistent premium style (deep navy + gold) across every brief and output
  format (HTML/PDF/email/cover), plus reusable region groupings.
- **AI cover images** — every brief opens with an AI-generated premium cover,
  built from the day's top stories via `prompts/intelligence/cover-image.md` and
  the Image Provider Abstraction (`IMAGE_PROVIDER`). Fail-safe: the brief still
  renders without a cover if image generation is unavailable.
- **Daily Cyber Opportunities Intelligence Brief** (`modules/cyber-opportunities/`)
  — commercial cybersecurity opportunity radar (RFPs, RFIs, tenders, MSS, GRC,
  SOC, vuln mgmt, OT/CNI, AI & cloud security) with a GCC-first focus
  (UK/Europe/Global secondary). Default schedule 06:15
  (`CYBER_OPPS_SCHEDULE_CRON`); Telegram `/opportunities`.
- **Daily Energy Intelligence Brief** (`modules/energy-intelligence/`) —
  UAE/ADNOC-focused energy intelligence (ADNOC ecosystem, then regional & global
  oil & gas). Default schedule 06:30 (`ENERGY_BRIEF_SCHEDULE_CRON`); Telegram
  `/energy`.
- **Telegram commands** `/opportunities` and `/energy`, served by a shared,
  registry-driven Latest Intelligence Brief handler (latest edition / history /
  org-or-date search) in `workflows/core/telegram-assistant.json`.
- **Documentation** — new `docs/intelligence-products.md` guide (framework,
  products, cover-image/branding system, monitoring, add-a-new-product recipe,
  troubleshooting, data-flow diagram).

### Changed

- **Installer** — Stage 8 (`stage_intelligence`) registers products and ensures
  each product's report/archive directories; module workflows with
  `"autoImport": true` are imported automatically.
- **Validation / health / status** — `validate.sh` adds an Intelligence Config
  check; `healthcheck.sh` adds per-product checks plus an Image Provider check;
  `status.sh` adds an Intelligence Products panel.
- **Backup / restore** — now include the `modules/` tree (capturing intelligence
  products' workflows, prompts and config) alongside `reports/`/`reports/archive`.
- **Docs** — README capabilities/commands, architecture (Intelligence Product
  Framework section), operations (briefs, commands, monitoring), backup and
  recovery updated accordingly.

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

[Unreleased]: https://github.com/peakapot/jarvis-ai/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/peakapot/jarvis-ai/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/peakapot/jarvis-ai/releases/tag/v0.1.0
