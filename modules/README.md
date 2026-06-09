# Jarvis Modules

> Every Jarvis capability is added as a **self-contained module**. A module
> bundles its own configuration, prompts, workflows, documentation and health
> checks so it can be added, replaced or removed without touching the core
> platform (Plugin Architecture / Modular / Separation of concerns / every
> component replaceable).

The core platform (n8n + Ollama, provider abstractions, scripts, logging) is
already built. Modules plug into it; the core never depends on a module.

## Standard module layout

Every module — and the copy-me [`_template/`](./_template/) — follows the same
shape:

```
modules/<module-id>/
├── module.json                 # manifest / contract (see below)
├── README.md                   # purpose, capabilities, config, enable, health
├── config/
│   └── config.example.env      # module config; references .env keys, no secrets
├── prompts/
│   └── *.md                    # versioned prompts (frontmatter + Changelog)
├── workflows/
│   └── *.json                  # valid n8n workflow JSON (nodes + connections)
├── healthcheck.sh              # bash health checks (PASS/WARN/FAIL/SKIP, --json)
└── docs/
    └── overview.md             # architecture & notes
```

## How modules are discovered

A module is any directory under `modules/` that contains a `module.json`
manifest (directories prefixed with `_`, such as `_template/`, are templates and
are ignored). Tooling discovers modules by globbing `modules/*/module.json`:

- **Workflows** are validated by `scripts/workflows/workflow-validate.sh` and
  imported by `scripts/workflows/workflow-import.sh`.
- **Prompts** that are shared across modules are registered in the root
  `prompts/registry.json` by `id`; the prompt body stays in the module so it can
  be versioned independently of any workflow.
- **Health checks** are each module's `healthcheck.sh`, runnable standalone and
  aggregatable by the core health check.

## Creating a new module from the template

1. Copy `modules/_template/` to `modules/<your-module>/`.
2. Edit every field in `module.json` (start with `id`, which must match the
   directory name; set `status` to `planned` until the workflow is real).
3. Rewrite `README.md`, `docs/overview.md`, the prompt(s) and the workflow(s).
4. Declare module env vars in `config/config.example.env` (names only — secret
   **values** live in the git-ignored root `.env`).
5. Add real prompts to `prompts/registry.json` (root) if they are shared.
6. Validate: `scripts/workflows/workflow-validate.sh modules/<your-module>/workflows`.
7. Run the health check: `modules/<your-module>/healthcheck.sh`.

## The `module.json` contract

| Field         | Type     | Meaning                                                        |
|---------------|----------|----------------------------------------------------------------|
| `id`          | string   | Unique module id (matches directory name).                     |
| `name`        | string   | Human-readable name.                                           |
| `version`     | semver   | Module version.                                                |
| `status`      | enum     | `scaffold` \| `planned` \| `beta` \| `stable` \| `deprecated`. |
| `description` | string   | One-line summary.                                              |
| `provides`    | string[] | Capability ids this module exposes.                            |
| `dependsOn`   | string[] | Other module ids or core services required.                    |
| `prompts`     | object[] | `{ id, file, version }` for each prompt asset.                 |
| `workflows`   | string[] | Relative paths to n8n workflow JSON files.                     |
| `envVars`     | object[] | `{ name, required, default, secret, description }`.            |
| `healthcheck` | string   | Relative path to the module health check script.               |

## Modules

| Module | Capability | Status |
|--------|------------|--------|
| [`_template`](./_template/) | Copy-me scaffold for new modules | scaffold |
| [`learning-hub`](./learning-hub/) | Magazine + e-learning derived from it, with a local Learning Dashboard (completion tracking, certificate library, 30-day deadlines) | active |
| [`knowledge-assistant`](./knowledge-assistant/) | RAG over a knowledge base / long-term memory (future Qdrant vector DB) | planned (scaffold) |
| [`meeting-assistant`](./meeting-assistant/) | Meeting note + transcript summarisation, action-item extraction | planned (scaffold) |
| [`calendar-assistant`](./calendar-assistant/) | Schedule queries, event-creation drafts, daily agenda | planned (scaffold) |
| [`iso27001-assistant`](./iso27001-assistant/) | ISO 27001 control guidance, gap analysis, policy drafting | planned (scaffold) |
| [`presentation-assistant`](./presentation-assistant/) | Brief → slide outline + speaker notes | planned (scaffold) |
| [`image-assistant`](./image-assistant/) | Image generation via the Image Provider Abstraction | planned (scaffold) |

> **Status legend.** `scaffold` = structure only (the template). `planned` =
> credible, structurally valid scaffold for a future capability; not yet wired
> into the live stack. Promote to `beta`/`stable` as the module is implemented.
