#!/usr/bin/env bash
# =============================================================================
# workflow-migrate.sh — Workflow schema migration support
# -----------------------------------------------------------------------------
# Applies ordered, idempotent migrations to workflow JSON so the repository can
# evolve (rename nodes, bump provider references, retarget env placeholders)
# without manual editing in the n8n UI (Workflow migration support).
#
# Migrations live in scripts/workflows/migrations/ as executable scripts named
# NNNN-description.sh. Each receives a single workflow file path as $1 and must
# be idempotent (safe to run repeatedly). Applied migrations are recorded per
# file in state so they are not re-applied (mirrors database migration tools).
#
# Usage:
#   scripts/workflows/workflow-migrate.sh [--dry-run]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"
load_env

MIGRATIONS_DIR="${SCRIPT_DIR}/migrations"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

mkdir -p "${MIGRATIONS_DIR}"
log_section "Running workflow migrations"

mapfile -t migrations < <(find "${MIGRATIONS_DIR}" -maxdepth 1 -name '*.sh' | sort)
if (( ${#migrations[@]} == 0 )); then
  log_info "No migrations defined yet (add scripts to ${MIGRATIONS_DIR})"
  exit 0
fi

# Take a safety backup before mutating workflow files.
if (( DRY_RUN == 0 )); then
  "${SCRIPT_DIR}/workflow-backup.sh" --no-export >/dev/null 2>&1 \
    && log_ok "Pre-migration backup taken" \
    || log_warn "Could not take pre-migration backup; continuing"
fi

applied=0
while IFS= read -r wf; do
  [[ -z "${wf}" ]] && continue
  wf_id="$(basename "${wf}" .json)"
  for m in "${migrations[@]}"; do
    mig_id="$(basename "${m}" .sh)"
    marker="wf-migrate:${wf_id}:${mig_id}"
    if state_is_done "${marker}"; then continue; fi
    if (( DRY_RUN == 1 )); then
      log_info "[dry-run] would apply ${mig_id} to ${wf_id}"
      continue
    fi
    if bash "${m}" "${wf}"; then
      state_mark_done "${marker}"
      applied=$((applied+1))
      log_ok "Applied ${mig_id} to ${wf_id}"
    else
      log_error "Migration ${mig_id} failed on ${wf_id}"
    fi
  done
done < <(find "${JARVIS_ROOT}/workflows" -name '*.json' | sort)

# Re-validate after migrating.
"${SCRIPT_DIR}/workflow-validate.sh" --quiet || log_warn "Post-migration validation reported issues"
log_ok "Migrations complete (${applied} applied)"
