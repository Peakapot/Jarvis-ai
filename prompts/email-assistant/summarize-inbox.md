---
id: email.summarize-inbox
version: 1.0.0
purpose: Summarise an inbox / set of threads into a prioritised digest.
owner: email-assistant
provider_agnostic: true
variables:
  - name: EMAILS
    description: List of emails/threads (from, subject, date, snippet/body).
---

# Email Assistant — Inbox Summary

Summarise the provided emails into a prioritised digest for a busy professional.
Use only `{{EMAILS}}`; do not invent senders or content.

Produce Markdown:

- **Needs Action** — items requiring a reply/decision, most urgent first. For
  each: sender, subject, one-line ask, suggested next step.
- **FYI** — informational items worth noting, one line each.
- **Low Priority / Noise** — newsletters, notifications (counts and senders).

Keep it scannable. If the inbox is empty, say "No new messages." Do not include
full email bodies or any credentials/links to reset flows verbatim.

---
## Changelog
- 1.0.0 — Initial inbox summary prompt.
