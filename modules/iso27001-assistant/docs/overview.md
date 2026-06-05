# iso27001-assistant — Architecture & Notes

Defensive/compliance helper for ISO/IEC 27001: control guidance, gap analysis,
and policy drafting. Advisory only.

## Where this module fits

```
Telegram / Webhook (control + current state)  ->  gap-analysis.json
                                                        |
                                          Prompt: iso27001.gap-analysis
                                                        |
                                            AI Provider Abstraction
                                                        |
                                  Rating + gaps + remediation + evidence (JSON)
```

`control-guidance` and the policy-draft capability reuse the same provider-
abstracted call pattern with their own prompts.

## Design principles followed
- **Separation of concerns** — config, prompts, workflow, docs, health checks isolated here.
- **Provider abstraction** — all LLM steps route through the core AI abstraction.
- **Configuration over hard coding** — standard edition is env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.
- **Defensive framing** — factual, compliance-oriented; advisory disclaimer always included.

## Open questions for implementation
- Whether to ground responses in a stored copy/summary of the controls (would
  pair well with the knowledge-assistant module and the future vector DB).
- Statement of Applicability (SoA) generation and tracking.
- Evidence repository integration.
