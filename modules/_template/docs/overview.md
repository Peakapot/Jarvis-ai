# _template — Architecture & Notes

This document is the template for per-module architecture notes. Replace it with
a description of how your module is built and how it fits the Jarvis platform.

## Where this module fits

```
Telegram / Schedule / Webhook  ->  Module Workflow  ->  AI Provider Abstraction
                                          |
                                  Prompt Registry (versioned prompts)
                                          |
                                  Core services (Ollama, vector DB, etc.)
```

## Design principles followed

- **Separation of concerns** — config, prompts, workflows, docs and health
  checks are isolated in this directory.
- **Configuration over hard coding** — behaviour is driven by env vars declared
  in `module.json` and documented in `config/config.example.env`.
- **Provider abstraction** — AI/image calls route through the core provider
  abstraction; no provider specifics are hardcoded in workflows.
- **Fail-safe defaults** — disabled or unconfigured features SKIP, not FAIL.
- **Observability** — `healthcheck.sh` emits structured, machine-readable output.

## Notes
- Replace this file when copying the template.
