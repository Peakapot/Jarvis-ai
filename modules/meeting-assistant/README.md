# Meeting Assistant (`meeting-assistant`)

> Turns meeting notes and transcripts into a clean summary, a list of decisions,
> and tracked action items. Self-contained module (Plugin Architecture /
> Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Paste in raw notes or a transcript and get back a structured record: a short
summary, the decisions that were made, and the action items with owners and due
dates where they were stated.

## Capabilities

- `meeting.summarize` — condense a transcript/notes into a readable summary.
- `meeting.action-items` — extract decisions and action items (owner, due date).

## Configuration

See [`config/config.example.env`](./config/config.example.env).

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `MEETING_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `MEETING_OUTPUT_FORMAT` | `markdown` | no | Default output format (`markdown`/`json`). |

Summarisation runs through the core **AI Provider Abstraction** — no provider
specifics in the module.

## How to enable

1. Set `MEETING_ASSISTANT_ENABLED=true` in `.env`.
2. Register the prompt in `prompts/registry.json` (root) if shared.
3. Import the workflow: `scripts/workflows/workflow-import.sh modules/meeting-assistant/workflows`.
4. Run the health check (below).

## Health checks

```bash
modules/meeting-assistant/healthcheck.sh          # human-readable
modules/meeting-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
