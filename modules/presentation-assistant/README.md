# Presentation Assistant (`presentation-assistant`)

> Turns a short brief into a structured slide outline with speaker notes.
> Self-contained module (Plugin Architecture / Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Give it the topic, audience and goal, and get back a slide-by-slide outline —
titles, bullet points, and speaker notes — ready to drop into your slide tool.

## Capabilities

- `presentation.outline` — brief → ordered slide outline (titles + bullets).
- `presentation.speaker-notes` — speaker notes per slide.

## Configuration

See [`config/config.example.env`](./config/config.example.env).

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `PRESENTATION_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `PRESENTATION_DEFAULT_SLIDES` | `10` | no | Default slide count when unspecified. |

LLM steps route through the core **AI Provider Abstraction**.

## How to enable

1. Set `PRESENTATION_ASSISTANT_ENABLED=true` in `.env`.
2. Register the prompt in `prompts/registry.json` (root) if shared.
3. Import the workflow: `scripts/workflows/workflow-import.sh modules/presentation-assistant/workflows`.
4. Run the health check (below).

## Health checks

```bash
modules/presentation-assistant/healthcheck.sh          # human-readable
modules/presentation-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
