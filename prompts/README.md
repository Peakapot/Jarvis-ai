# Prompts

Prompts are **first-class, versioned assets** in Jarvis. They are stored here,
**separately from workflows**, so they can be reviewed, versioned and updated
**without editing any workflow** (Prompt Management).

## Layout

```
prompts/
├── registry.json          # id -> file + version map (the index of record)
├── system/                # global persona & guardrails shared by all assistants
├── telegram/              # Telegram interface prompts (routing, etc.)
├── cyber-brief/           # cyber intelligence analyst prompts
└── email-assistant/       # inbox summary / draft reply / categorise prompts
```

Module-specific prompts also live under each module: `modules/<name>/prompts/`.

## Prompt file format

Each prompt is a Markdown file with YAML frontmatter:

```markdown
---
id: cyber-brief.analyst        # globally unique, dot-namespaced
version: 1.0.0                  # semver — bump on every meaningful change
purpose: One-line description of what the prompt does.
owner: cyber-brief             # owning module/area
provider_agnostic: true        # works across AI providers
variables:                     # documented template variables ({{NAME}})
  - name: SOURCES
    description: ...
---

# Title

...prompt body, using {{VARIABLE}} placeholders...

---
## Changelog
- 1.0.0 — Initial version.
```

## Adding or updating a prompt

1. Create/edit the `.md` file under the appropriate folder.
2. Add or update its entry in [`registry.json`](registry.json).
3. Bump the `version` (semver) and append a `Changelog` line.
4. Reference it from a workflow by its `id` (never paste prompt text into a
   workflow node).

This keeps prompts decoupled from workflows and supports future prompt updates
without workflow redesign.
