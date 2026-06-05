---
id: email.categorize
version: 1.0.0
purpose: Categorise and prioritise an email for triage.
owner: email-assistant
provider_agnostic: true
variables:
  - name: EMAIL
    description: A single email (from, subject, date, body/snippet).
---

# Email Assistant — Categorise & Prioritise

Classify the email for automated triage. Use only `{{EMAIL}}`.

Return **only** JSON:

```json
{
  "category": "action_required | meeting | finance | newsletter | notification | personal | spam | other",
  "priority": "high | medium | low",
  "needs_reply": true,
  "summary": "one short sentence",
  "suggested_label": "short label for filing"
}
```

Rules:
- Be conservative with `high` priority — reserve it for genuine urgency.
- `spam` only when clearly unsolicited/malicious.
- Output valid JSON and nothing else.

---
## Changelog
- 1.0.0 — Initial categorisation prompt.
