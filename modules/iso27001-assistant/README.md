# ISO 27001 Assistant (`iso27001-assistant`)

> Guidance on ISO/IEC 27001 controls, assisted gap analysis, and policy
> drafting. Self-contained module (Plugin Architecture / Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

> **Advisory note.** This module is a productivity aid for information-security
> work. It is **defensive/compliance** in framing and is **not** a substitute
> for a qualified ISMS lead, internal auditor, or certification body. Always
> have outputs reviewed by a competent person before relying on them.

## Purpose

Explain what an Annex A control actually means in practice, run a structured gap
analysis of your current state against the standard, and produce first-draft
policy text you can refine.

## Capabilities

- `iso27001.control-explain` — plain-language explanation of a control, with intent and typical evidence.
- `iso27001.gap-analysis` — compare a described current state to a control and rate the gap.
- `iso27001.policy-draft` — draft policy text aligned to one or more controls.

## Configuration

See [`config/config.example.env`](./config/config.example.env).

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `ISO27001_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `ISO27001_STANDARD_VERSION` | `2022` | no | ISO/IEC 27001 edition to reference. |

LLM steps route through the core **AI Provider Abstraction**.

## How to enable

1. Set `ISO27001_ASSISTANT_ENABLED=true` in `.env`.
2. Register the prompts in `prompts/registry.json` (root) if shared.
3. Import the workflow: `scripts/workflows/workflow-import.sh modules/iso27001-assistant/workflows`.
4. Run the health check (below).

## Health checks

```bash
modules/iso27001-assistant/healthcheck.sh          # human-readable
modules/iso27001-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
