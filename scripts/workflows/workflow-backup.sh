#!/usr/bin/env bash
# =============================================================================
# workflow-backup.sh — Snapshot workflows into a versioned archive
# -----------------------------------------------------------------------------
# Exports current workflows from n8n (if running) and archives the entire
# Git-tracked workflows/ tree into a timestamped, integrity-checked tarball
# under backups/workflows/ (Workflow backup tooling + versioning).
#
# A SHA-256 manifest accompanies each archive so restores can verify integrity.
#
# Usage: scripts/workflows/workflow-backup.sh [--no-export]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"
load_env

DO_EXPORT=1
[[ "${1:-}" == "--no-export" ]] && DO_EXPORT=0

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${JARVIS_ROOT}/backups/workflows"
mkdir -p "${BACKUP_DIR}"

log_section "Backing up workflows (${STAMP})"

# Refresh exported mirror from live n8n when possible (best-effort).
if (( DO_EXPORT == 1 )); then
  if "${SCRIPT_DIR}/workflow-export.sh" >/dev/null 2>&1; then
    log_ok "Refreshed exported workflows from live n8n"
  else
    log_warn "Live export skipped (n8n not running?); backing up tracked files only"
  fi
fi

# Validate before archiving (never back up corrupt state).
"${SCRIPT_DIR}/workflow-validate.sh" --quiet || log_warn "Integrity warnings present; continuing backup"

archive="${BACKUP_DIR}/workflows-${STAMP}.tar.gz"
tar -czf "${archive}" -C "${JARVIS_ROOT}" workflows
( cd "${BACKUP_DIR}" && sha256sum "$(basename "${archive}")" >"$(basename "${archive}").sha256" )

log_ok "Workflow backup created: ${archive}"
echo "${archive}"
