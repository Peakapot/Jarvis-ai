# Calendar Assistant (`calendar-assistant`)

> Schedule queries, natural-language event drafts, and a daily agenda summary.
> Self-contained module (Plugin Architecture / Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Ask about your schedule in plain language, turn "lunch with Sam next Tuesday at
1pm" into a structured event payload ready to create, and get a tidy summary of
the day's agenda.

## Capabilities

- `calendar.query` — answer questions about upcoming events.
- `calendar.draft-event` — natural language → structured event JSON.
- `calendar.daily-agenda` — summarise the day's events into a readable agenda.

## Configuration

See [`config/config.example.env`](./config/config.example.env). Calendar
**credentials** are configured in n8n, never stored in the repo.

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `CALENDAR_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflows. |
| `CALENDAR_PROVIDER` | `google` | no | Backend: `google`/`microsoft365`/`caldav`. |
| `CALENDAR_DEFAULT_TZ` | `Europe/London` | no | Default IANA timezone. |
| `CALENDAR_ID` | `primary` | no | Target calendar id. |

LLM steps route through the core **AI Provider Abstraction**.

## How to enable

1. Configure the calendar provider credentials in n8n.
2. Set `CALENDAR_ASSISTANT_ENABLED=true` and the `CALENDAR_*` vars in `.env`.
3. Register the prompts in `prompts/registry.json` (root) if shared.
4. Import the workflows: `scripts/workflows/workflow-import.sh modules/calendar-assistant/workflows`.
5. Run the health check (below).

## Health checks

```bash
modules/calendar-assistant/healthcheck.sh          # human-readable
modules/calendar-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
