# MindHaven Assistant (`mindhaven-assistant`)

> A supportive, reflective journaling companion for everyday wellbeing.
> Self-contained module (Plugin Architecture / Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

> **Safety note — please read.** MindHaven is a **non-clinical** wellbeing and
> journaling companion. It does **not** provide medical, psychological, or
> crisis care, and it is **not a substitute for professional help**. If a
> message indicates crisis, self-harm, harm to others, or a medical emergency,
> the assistant must stop coaching, respond with care, and surface the crisis
> resources in `MINDHAVEN_CRISIS_RESOURCES`, encouraging contact with a
> qualified professional or emergency services.

## Purpose

A gentle space to reflect: open questions, light journaling prompts, and
supportive, non-judgemental responses that help the user think things through in
their own words.

## Capabilities

- `wellbeing.reflect` — supportive, reflective responses to a journal entry or thought.
- `wellbeing.journal-prompt` — offer a thoughtful prompt to start journaling.

## Configuration

See [`config/config.example.env`](./config/config.example.env).

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `MINDHAVEN_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflow. |
| `MINDHAVEN_CRISIS_RESOURCES` | _(region resources)_ | no | Crisis resources surfaced on crisis indicators. Set to your region. |

LLM steps route through the core **AI Provider Abstraction**. Running on the
local-first Ollama default keeps sensitive journal content on the host.

## How to enable

1. Set `MINDHAVEN_ASSISTANT_ENABLED=true` and set `MINDHAVEN_CRISIS_RESOURCES` for your region in `.env`.
2. Register the prompt in `prompts/registry.json` (root) if shared.
3. Import the workflow: `scripts/workflows/workflow-import.sh modules/mindhaven-assistant/workflows`.
4. Run the health check (below).

## Health checks

```bash
modules/mindhaven-assistant/healthcheck.sh          # human-readable
modules/mindhaven-assistant/healthcheck.sh --json   # machine-readable
```

Disabled → `SKIP`, never `FAIL` (Fail-safe defaults).
