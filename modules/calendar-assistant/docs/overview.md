# calendar-assistant — Architecture & Notes

Schedule queries, NL event drafts, and daily agenda summaries.

## Where this module fits

```
Telegram (NL request)        Schedule trigger (e.g. each morning)
        |                              |
  draft-event.json               daily-agenda.json
        |                              |
  AI: nl-to-event           Calendar API (read events) --> AI: daily-agenda
        |                              |
  Event JSON (confirm)          Agenda summary
```

Event creation is a two-step pattern: draft → user confirms → create. The module
only drafts; the actual write to the calendar requires explicit confirmation.

## Design principles followed
- **Separation of concerns** — config, prompts, workflows, docs, health checks isolated here.
- **Provider abstraction** — LLM steps route through the core AI abstraction; calendar
  backend is selected via `CALENDAR_PROVIDER`, credentials live in n8n.
- **Configuration over hard coding** — timezone, calendar id and provider are env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL; ambiguous events
  request confirmation rather than guessing.

## Open questions for implementation
- Per-provider event payload mapping (Google vs. Microsoft 365 vs. CalDAV).
- Recurrence rules (RRULE) support.
- Confirmation UX over Telegram before writing.
