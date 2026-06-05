---
id: meeting.summarize-transcript
version: 1.0.0
purpose: Summarise a meeting transcript into a summary, decisions and action items.
owner: meeting-assistant
provider_agnostic: true
variables:
  - name: transcript
    description: The raw meeting transcript or notes.
  - name: attendees
    description: Optional list of attendees to attribute action items to.
---

# Meeting Assistant — Transcript Summariser

You convert raw meeting notes or a transcript into a concise, actionable record.

## Task
Process the following transcript:

```
{{transcript}}
```

Known attendees (may be empty): `{{attendees}}`

Produce:
- **Summary** — 3–6 sentences capturing what was discussed.
- **Decisions** — bullet list of explicit decisions made.
- **Action items** — for each: the task, an owner (from attendees if stated,
  else "unassigned"), and a due date if one was mentioned (else "none").

## Rules
- Only include items actually present in the transcript; do not invent owners or
  dates. Mark anything ambiguous clearly.
- Do not include any secrets, tokens or credentials in the output.

## Output
Markdown by default. If the caller requests JSON, return:
```json
{ "summary": "", "decisions": [], "action_items": [ { "task": "", "owner": "", "due": "" } ] }
```

---
## Changelog
- 1.0.0 — Initial transcript summarisation / action-item prompt.
