# DealForge Assistant (`dealforge-assistant`)

> Sales/deal pipeline assistant: lead and opportunity summaries, follow-up
> drafts, and deal-stage notes. Self-contained module (Plugin Architecture /
> Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Keep deals moving: summarise where an opportunity stands, draft the next
follow-up message in the right tone, and write a concise stage note for the
record.

## Capabilities

- `deal.summarize` — summarise a lead/opportunity (status, value, next step, risks).
- `deal.draft-followup` — draft a follow-up message tailored to the stage.
- `deal.stage-note` — write a short note for a pipeline stage change.

## Configuration

See [`config/config.example.env`](./config/config.example.env). Any CRM
**credentials** are configured in n8n, never in the repo.

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `DEALFORGE_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `DEALFORGE_CRM_PROVIDER` | `none` | no | Optional CRM backend (`none`/`hubspot`/`pipedrive`). |
| `DEALFORGE_PIPELINE_STAGES` | `lead,...,won,lost` | no | Pipeline stage names. |

LLM steps route through the core **AI Provider Abstraction**.

## How to enable

1. (Optional) Configure CRM credentials in n8n and set `DEALFORGE_CRM_PROVIDER`.
2. Set `DEALFORGE_ASSISTANT_ENABLED=true` in `.env`.
3. Register the prompt in `prompts/registry.json` (root) if shared.
4. Import the workflow: `scripts/workflows/workflow-import.sh modules/dealforge-assistant/workflows`.
5. Run the health check (below).

## Health checks

```bash
modules/dealforge-assistant/healthcheck.sh          # human-readable
modules/dealforge-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
