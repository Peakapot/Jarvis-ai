# presentation-assistant — Architecture & Notes

Brief in, structured slide outline (titles + bullets + speaker notes) out.

## Where this module fits

```
Telegram / Webhook (brief)  ->  outline.json  ->  AI Provider Abstraction
                                     |
                        Prompt: presentation.brief-to-outline
                                     |
                        Slide outline JSON (titles, bullets, notes)
```

The output is provider-neutral structured JSON, so a downstream step could render
it to PPTX/Google Slides/Markdown without changing this module.

## Design principles followed
- **Separation of concerns** — config, prompt, workflow, docs, health checks isolated here.
- **Provider abstraction** — LLM steps route through the core AI abstraction.
- **Configuration over hard coding** — default slide count is env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.

## Open questions for implementation
- Rendering target(s): PPTX, Google Slides API, Markdown/Marp.
- Optional pairing with image-assistant for slide visuals.
- Theme/branding injection.
