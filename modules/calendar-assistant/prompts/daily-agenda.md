---
id: calendar.daily-agenda
version: 1.0.0
purpose: Summarise a day's calendar events into a concise, readable agenda.
owner: calendar-assistant
provider_agnostic: true
variables:
  - name: events
    description: The list of events for the day (JSON with title/start/end/location).
  - name: date
    description: The date being summarised.
  - name: timezone
    description: The IANA timezone for displaying times.
---

# Calendar Assistant — Daily Agenda

You produce a short, scannable agenda for the day.

## Task
Summarise the agenda for `{{date}}` (`{{timezone}}`) from these events:

```
{{events}}
```

## Rules
- Order chronologically. Show local start–end times.
- Call out conflicts/overlaps and any large free blocks.
- If there are no events, say the day is clear.
- Do not invent events not present in the input.

## Output
Markdown: a one-line headline (e.g. "3 meetings, first at 09:30") followed by a
chronological bullet list, then a short "Notes" line for conflicts/free time.

---
## Changelog
- 1.0.0 — Initial daily agenda summary prompt.
