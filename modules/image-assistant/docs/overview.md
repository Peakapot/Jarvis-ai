# image-assistant — Architecture & Notes

Image generation routed entirely through the Image Provider Abstraction so the
provider is a config choice, not a code change.

## Where this module fits

```
Telegram (/image request)  ->  generate.json
                                   |
                  AI Provider Abstraction (refine-spec, text)
                                   |
                  Provider-neutral generation spec (JSON)
                                   |
                  Image Provider Abstraction (IMAGE_PROVIDER)
                  -> resolves config/providers/image/<provider>.json
                  -> endpoint + auth env + model + size
                                   |
                            Generated image
```

## Provider abstraction details
- `IMAGE_PROVIDER` selects a descriptor under `config/providers/image/`
  (default `openai` → `openai.json`).
- The descriptor declares the endpoint, the auth env var name
  (`OPENAI_IMAGE_API_KEY` → fallback `OPENAI_API_KEY`), the model and size.
- The workflow references env var **names** only — no keys, no vendor-specific
  request fields hardcoded. Switching providers means changing `IMAGE_PROVIDER`
  and supplying that provider's descriptor + key.

## Design principles followed
- **Separation of concerns** — config, prompt, workflow, docs, health checks isolated here.
- **Provider abstraction** — both the text refine step and image generation route
  through their respective core abstractions.
- **Configuration over hard coding** — provider, model and size are env-driven.
- **Security by default** — API keys referenced by name only; never committed.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.

## Open questions for implementation
- How the descriptor is resolved at runtime in n8n (env-driven request build vs.
  a small resolver sub-workflow).
- Storage/return of generated images (inline vs. object storage URL).
- Content-safety policy enforcement location (prompt vs. provider).
