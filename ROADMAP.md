# Roadmap

This roadmap describes the planned evolution of Jarvis. It is intentionally
incremental: each phase builds on a stable foundation so that **no major
architectural refactoring is required** to reach the next. Dates are indicative;
priorities may shift.

## Guiding themes

- Keep every component **replaceable** and **configuration-driven**.
- Prefer adding **modules** over modifying the core.
- Maintain **recoverability, observability and security** as first-class
  concerns at every phase.

---

## Phase 0 — Foundation ✅ (v0.1.0)

- Idempotent installer, validation/health/status/diagnostics framework.
- Docker-first topology (n8n + Ollama; future services behind profiles).
- Provider abstraction (AI/email/image).
- Workflows-as-source-code with full lifecycle tooling.
- Prompt management, backup/recovery, structured logging.
- Plugin module architecture (scaffolds).
- Enterprise documentation.

## Intelligence products ✅ (v0.2.0)

A reusable, registry-driven intelligence framework plus two new daily briefs,
all built on the existing module/provider/branding frameworks with no core
refactoring (*Prefer adding modules over modifying the core*):

- **Intelligence Product Registry** (`config/intelligence/products.json`) as the
  single source of truth, consumed by install/validate/health/status/backup via
  `scripts/lib/intelligence.sh`.
- **Common branding framework** + **AI cover images** for a consistent premium
  style across every brief (HTML/PDF/email/cover).
- **Daily Cyber Opportunities Intelligence Brief** (`/opportunities`, GCC-first
  commercial opportunity radar).
- **Daily Energy Intelligence Brief** (`/energy`, UAE/ADNOC-focused).
- Future products (Defence, AI, Government, Healthcare, Market) follow the same
  recipe: module + registry entry + sources + template, no core code changes.
  See [`docs/intelligence-products.md`](docs/intelligence-products.md).

## Phase 1 — Core assistants hardening (next)

- Production-ready Telegram command set (`/help`, `/status`, `/research`,
  `/emails`, `/image`, `/cyber`) with rich responses and rate limiting.
- Cyber Brief: real PDF rendering pipeline, historical archive browser,
  expanded UAE/Gulf source set.
- Email assistant: inbox summaries, draft replies, categorisation &
  prioritisation wired end-to-end across Gmail/M365/SMTP.
- Credential validation surfaced in the readiness report.

## Phase 2 — Knowledge & memory

- Enable the Qdrant vector database (`vectordb` profile).
- `knowledge-assistant` module: document ingestion, RAG retrieval, research
  archives.
- Long-term memory and conversation history storage.
- Document storage abstraction.

## Phase 3 — Observability & operations

- Enable Prometheus/Grafana (`monitoring` profile) with dashboards for service
  health, workflow success/failure and resource usage.
- Alerting integrations (Telegram/email) for SLO breaches.
- Automated backup scheduling and restore drills.

## Phase 4 — Module expansion

- Promote scaffolded modules to GA as demand dictates:
  `meeting-assistant`, `calendar-assistant`, `iso27001-assistant`,
  `mindhaven-assistant`, `dealforge-assistant`, `presentation-assistant`,
  `image-assistant`.
- Module marketplace / discovery improvements.

## Phase 5 — Multi-user & scale

- Optional external Postgres for n8n; queue-mode execution.
- Per-user access control and quotas.
- Horizontal scaling guidance for stateless components.

---

## Contributing to the roadmap

Have an idea or need? Open a discussion or issue (see
[`CONTRIBUTING.md`](CONTRIBUTING.md)). Proposals that add capabilities as
**modules** and preserve the architectural principles are especially welcome.
