# Module Template (`_template`)

> Copy this directory to bootstrap a new Jarvis capability module.
> Every module is self-contained: configuration, prompts, workflows,
> documentation and health checks live together so the capability can be
> added, replaced or removed without touching the core platform
> (Plugin Architecture / Modular / Separation of concerns).

## Purpose

This is a non-functional placeholder that demonstrates the standard module
layout and contracts. Replace this section with a one-paragraph description of
what your module does and which problem it solves.

## Capabilities

- `example.capability` — placeholder capability (replace with real ones).

## Layout

```
_template/
├── module.json                 # manifest / contract (see below)
├── README.md                   # this file
├── config/
│   └── config.example.env      # module config; references .env keys, no secrets
├── prompts/
│   └── example.md              # versioned prompt with frontmatter + Changelog
├── workflows/
│   └── example.json            # valid n8n workflow JSON (placeholder)
├── healthcheck.sh              # bash health checks (PASS/WARN/FAIL/SKIP, --json)
└── docs/
    └── overview.md             # architecture & notes
```

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

## Configuration

Copy `config/config.example.env` and set values in the repository root `.env`.
Modules never store secrets in the repo — they reference env var **names** only.

## How to enable

1. Copy `_template/` to `modules/<your-module>/` and edit `module.json`.
2. Register prompts in `prompts/registry.json` (root) if they should be shared.
3. Import the workflow(s) with `scripts/workflows/workflow-import.sh`.
4. Set the module's env vars in `.env`.
5. Run the module health check (below).

## Health checks

```bash
modules/_template/healthcheck.sh          # human-readable report
modules/_template/healthcheck.sh --json   # machine-readable
```

Exits non-zero if any check is `FAIL`. A module that is not enabled reports
`SKIP` rather than `FAIL` (Fail-safe defaults).
