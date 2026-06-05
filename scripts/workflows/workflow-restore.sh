#!/usr/bin/env bash
# =============================================================================
# workflow-restore.sh — Restore workflows from a versioned archive
# -----------------------------------------------------------------------------
# Restores the workflows/ tree from a backup tarball produced by
# workflow-backup.sh, verifying SHA-256 integrity first, then (optionally)
# re-imports into the running n8n instance (Workflow restore tooling).
#
# Usage:
#   scripts/workflows/workflow-restore.sh [ARCHIVE] [--import] [--yes]
#     ARCHIVE   path to workflows-*.tar.gz (default: newest in backups/workflows)
#     --import  re-import workflows into n8n after restoring files
#     --yes     non-interactive (assume yes)
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"
load_env

BACKUP_DIR="${JARVIS_ROOT}/backups/workflows"
ARCHIVE=""
DO_IMPORT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --import) DO_IMPORT=1; shift ;;
    --yes) JARVIS_ASSUME_YES=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ARCHIVE="$1"; shift ;;
  esac
done

# Default to the most recent archive.
if [[ -z "${ARCHIVE}" ]]; then
  ARCHIVE="$(find "${BACKUP_DIR}" -name 'workflows-*.tar.gz' 2>/dev/null | sort | tail -n1)"
  [[ -z "${ARCHIVE}" ]] && log_fatal "No workflow backups found in ${BACKUP_DIR}"
fi
[[ -f "${ARCHIVE}" ]] || log_fatal "Archive not found: ${ARCHIVE}"

log_section "Restoring workflows from ${ARCHIVE}"

# Verify integrity.
if [[ -f "${ARCHIVE}.sha256" ]]; then
  ( cd "$(dirname "${ARCHIVE}")" && sha256sum -c "$(basename "${ARCHIVE}").sha256" >/dev/null 2>&1 ) \
    && log_ok "Checksum verified" \
    || log_fatal "Checksum verification FAILED — refusing to restore (possible corruption)"
else
  log_warn "No .sha256 manifest beside archive; cannot verify integrity"
fi

confirm "This will overwrite the current workflows/ directory. Continue?" \
  || { log_warn "Aborted by user"; exit 0; }

# Safety snapshot of current state before overwrite (Recoverability).
if [[ -d "${JARVIS_ROOT}/workflows" ]]; then
  safety="${BACKUP_DIR}/pre-restore-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
  tar -czf "${safety}" -C "${JARVIS_ROOT}" workflows 2>/dev/null || true
  log_info "Saved pre-restore snapshot: ${safety}"
fi

tar -xzf "${ARCHIVE}" -C "${JARVIS_ROOT}"
log_ok "Workflow files restored"

"${SCRIPT_DIR}/workflow-validate.sh" --quiet || log_warn "Restored workflows have integrity warnings"

if (( DO_IMPORT == 1 )); then
  "${SCRIPT_DIR}/workflow-import.sh" --include-exported \
    && log_ok "Workflows re-imported into n8n" \
    || log_error "Re-import into n8n failed (files are restored on disk)"
fi
log_ok "Workflow restore complete"
