# Workflow migrations

Ordered, **idempotent** migrations that evolve workflow JSON without manual
editing in the n8n UI (Workflow migration support). Mirrors database migration
tooling: each migration runs at most once per workflow file and is tracked in
`state/`.

## Authoring a migration

Create an executable script named `NNNN-short-description.sh` (zero-padded,
sequential). It receives **one workflow file path** as `$1` and must be safe to
run repeatedly:

```bash
#!/usr/bin/env bash
# 0001-rename-ollama-node.sh — example migration
set -euo pipefail
wf="$1"
# Use jq for safe, idempotent edits. Example: rename a node type.
tmp="$(mktemp)"
jq '(.nodes[] | select(.type=="old.type") | .type) = "new.type"' "$wf" >"$tmp" && mv "$tmp" "$wf"
```

## Running

```bash
scripts/workflows/workflow-migrate.sh --dry-run   # preview
scripts/workflows/workflow-migrate.sh             # apply (takes a backup first)
```

Applied migrations are recorded as `wf-migrate:<workflow>:<migration>` markers in
`state/` so they are never re-applied. Delete a marker to force re-run.
