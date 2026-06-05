# dealforge-assistant — Architecture & Notes

Sales pipeline helper: deal summaries, follow-up drafts, stage notes.

## Where this module fits

```
Telegram / Webhook / CRM event (deal context)  ->  deal-followup.json
                                                        |
                                  Prompt: dealforge.deal-summary-followup
                                                        |
                                            AI Provider Abstraction
                                                        |
                                  Summary + risks + follow-up draft
```

CRM integration is optional and abstracted via `DEALFORGE_CRM_PROVIDER`;
credentials live in n8n. With `none`, the module works on pasted deal context.

## Design principles followed
- **Separation of concerns** — config, prompt, workflow, docs, health checks isolated here.
- **Provider abstraction** — LLM steps route through the core AI abstraction; CRM is pluggable.
- **Configuration over hard coding** — pipeline stages and CRM provider are env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.

## Open questions for implementation
- Per-CRM record mapping (HubSpot vs. Pipedrive object models).
- Whether follow-ups are sent automatically or always drafted for review (default: review).
- Activity-history summarisation for long deals (chunked summarisation).
