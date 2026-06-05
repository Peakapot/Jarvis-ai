# Image Assistant (`image-assistant`)

> Image generation via the **Image Provider Abstraction**. Self-contained module
> (Plugin Architecture / Separation of concerns / every component replaceable).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Take a rough image request, refine it into a clear, provider-neutral generation
spec (subject, style, composition, constraints), then generate the image through
whichever provider `IMAGE_PROVIDER` selects — without hardcoding any provider's
specifics in the workflow.

## Capabilities

- `image.refine-spec` — refine a user request into a provider-neutral generation spec.
- `image.generate` — generate an image via the resolved image provider.

## Provider abstraction

The workflow does **not** call a specific vendor API directly. It resolves the
active provider descriptor under
[`config/providers/image/`](../../config/providers/image/) selected by
`IMAGE_PROVIDER` (default `openai` →
[`config/providers/image/openai.json`](../../config/providers/image/openai.json)).
The descriptor supplies the endpoint, auth env var, model and options, so
switching providers is a config change, not a workflow edit.

## Configuration

See [`config/config.example.env`](./config/config.example.env). Secret **values**
(API keys) live only in `.env`.

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `IMAGE_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `IMAGE_PROVIDER` | `openai` | no | Selects the provider descriptor. |
| `IMAGE_MODEL` | `gpt-image-1` | no | Model id (from descriptor). |
| `IMAGE_SIZE` | `1024x1024` | no | Default output size. |
| `OPENAI_IMAGE_API_KEY` | _(empty)_ | yes | OpenAI image key (falls back to `OPENAI_API_KEY`). |

Spec refinement (the text step) routes through the core **AI Provider
Abstraction**; image generation routes through the **Image Provider Abstraction**.

## How to enable

1. Set `IMAGE_PROVIDER` and the provider's API key (e.g. `OPENAI_IMAGE_API_KEY`) in `.env`.
2. Set `IMAGE_ASSISTANT_ENABLED=true`.
3. Register the prompt in `prompts/registry.json` (root) if shared.
4. Import the workflow: `scripts/workflows/workflow-import.sh modules/image-assistant/workflows`.
5. Run the health check (below).

## Health checks

```bash
modules/image-assistant/healthcheck.sh          # human-readable
modules/image-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
