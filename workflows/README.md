# Workflows

Workflows are treated as **source code**. No workflow may exist only inside the
n8n UI — everything is exported to JSON and versioned here (Workflow Management).

## Layout

```
workflows/
├── core/        # platform workflows shipped with Jarvis
│   ├── telegram-assistant.json   # primary interface + command router
│   ├── cyber-brief.json          # daily intelligence product
│   └── error-handler.json        # central failure path for all workflows
├── modules/     # workflows contributed by plugin modules
└── exported/    # round-trip mirror of live n8n state (git-ignored by default)
```

## Lifecycle tooling (`scripts/workflows/`)

| Action | Script |
|--------|--------|
| Export from live n8n into `workflows/exported/` | `workflow-export.sh` |
| Import repo workflows into n8n (idempotent upsert) | `workflow-import.sh` |
| Validate integrity (JSON, n8n shape, no secrets) | `workflow-validate.sh` |
| Backup workflows to a checksummed archive | `workflow-backup.sh` |
| Restore workflows from an archive | `workflow-restore.sh` |
| Apply ordered, idempotent schema migrations | `workflow-migrate.sh` |

## Conventions

- Every workflow sets `settings.errorWorkflow` to **"Jarvis · Error Handler"**
  and gives external calls a **failure path** (`onError` branches) so a single
  outage never breaks the flow (Error Handling).
- A `meta` block documents the owning module, version, referenced prompts and
  required environment variable **names**.
- **No credentials** are embedded — workflows reference n8n credentials and env
  var names only. `workflow-validate.sh` enforces this.
- Prompts are referenced by `id` from `prompts/registry.json`, never pasted in.

## Typical edit cycle

```bash
# 1. Edit in the n8n UI, then pull the change into the repo:
scripts/workflows/workflow-export.sh

# 2. Review and validate:
git diff workflows/
scripts/workflows/workflow-validate.sh

# 3. Commit. To push back into a fresh n8n instance:
scripts/workflows/workflow-import.sh
```
