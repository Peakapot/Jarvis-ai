# mindhaven-assistant — Architecture & Notes

A supportive, non-clinical journaling companion. Safety comes first: crisis
indicators trigger escalation to professional resources rather than coaching.

## Where this module fits

```
Telegram / Webhook (journal entry)  ->  reflect.json
                                            |
                              Prompt: mindhaven.reflective-companion
                              (safety guardrails applied first)
                                            |
                                  AI Provider Abstraction
                                            |
              Supportive reflection  OR  Crisis escalation + resources
```

## Safety design
- The prompt enforces crisis screening *before* any coaching response.
- Crisis resources are configurable per region via `MINDHAVEN_CRISIS_RESOURCES`.
- The local-first Ollama default keeps sensitive entries on the host.
- The module never claims to be a clinician and always reminds the user it is not
  a substitute for professional help.

## Design principles followed
- **Separation of concerns** — config, prompt, workflow, docs, health checks isolated here.
- **Provider abstraction** — LLM steps route through the core AI abstraction.
- **Configuration over hard coding** — crisis resources are env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.

## Open questions for implementation
- Whether a deterministic keyword pre-filter should run before the LLM to catch
  crisis indicators even if the model is unavailable.
- Optional private, local-only journal history (would pair with the vector DB).
- Logging policy: minimise/avoid storing entry content given its sensitivity.
