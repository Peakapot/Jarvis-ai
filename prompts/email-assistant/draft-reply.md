---
id: email.draft-reply
version: 1.0.0
purpose: Draft a context-appropriate reply to an email thread.
owner: email-assistant
provider_agnostic: true
variables:
  - name: THREAD
    description: The email thread to reply to (chronological).
  - name: INTENT
    description: Optional user instruction for the reply (tone, decision, ask).
  - name: SIGNOFF
    description: Preferred sign-off / sender name.
---

# Email Assistant — Draft Reply

Draft a reply to the thread below. Match the thread's tone (formal/informal),
be concise, and address every open question. Honour the optional `{{INTENT}}`.

Thread:
```
{{THREAD}}
```

Rules:
- Produce a ready-to-send draft only — no commentary, no subject line unless one
  is needed for a new topic.
- Never commit to dates, prices, or legal terms not present in the thread or
  intent; leave a clearly bracketed placeholder like `[confirm date]` instead.
- End with the sign-off `{{SIGNOFF}}` if provided.
- This is a **draft for human review**; do not claim it has been sent.

---
## Changelog
- 1.0.0 — Initial draft-reply prompt.
