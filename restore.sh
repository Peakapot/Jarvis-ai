#!/usr/bin/env bash
# =============================================================================
# restore.sh — Full system recovery
# -----------------------------------------------------------------------------
# Restores a backup produced by backup.sh. Designed for a recovery time under
# 15 minutes (Backup and Recovery). Verifies archive integrity, restores
# non-secret assets, optionally restores the n8n data volume, reminds the
# operator which credentials to re-supply, then re-imports workflows.
#
# Usage:
#   ./restore.sh [ARCHIVE] [--with-data] [--yes]
#     ARCHIVE      jarvis-backup-*.tar.gz (default: newest in backups/)
#     --with-data  also restore the n8n data volume if present in the archive
#     --yes        non-interactive
# =============================================================================
set -o errexit -o nounset -o pipefail

JARVIS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JARVIS_ROOT
# shellcheck source=scripts/lib/common.sh
source "${JARVIS_ROOT}/scripts/lib/common.sh"
log_init "backup"
load_env

ARCHIVE=""
WITH_DATA=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-data) WITH_DATA=1; shift ;;
    --yes) export JARVIS_ASSUME_YES=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ARCHIVE="$1"; shift ;;
  esac
done

if [[ -z "${ARCHIVE}" ]]; then
  ARCHIVE="$(find "${JARVIS_ROOT}/backups" -maxdepth 1 -name 'jarvis-backup-*.tar.gz' 2>/dev/null | sort | tail -n1)"
  [[ -z "${ARCHIVE}" ]] && log_fatal "No backups found in backups/ — provide an archive path"
fi
[[ -f "${ARCHIVE}" ]] || log_fatal "Archive not found: ${ARCHIVE}"

log_section "Restoring from ${ARCHIVE}"

# Integrity verification (Fail-safe defaults).
if [[ -f "${ARCHIVE}.sha256" ]]; then
  ( cd "$(dirname "${ARCHIVE}")" && sha256sum -c "$(basename "${ARCHIVE}").sha256" >/dev/null 2>&1 ) \
    && log_ok "Checksum verified" \
    || log_fatal "Checksum verification FAILED — refusing to restore"
else
  log_warn "No checksum manifest; cannot verify integrity"
fi

confirm "Restore will overwrite workflows/, prompts/, config/, templates/, reports/. Continue?" \
  || { log_warn "Aborted"; exit 0; }

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
tar -xzf "${ARCHIVE}" -C "${STAGE}"

[[ -f "${STAGE}/MANIFEST.txt" ]] && { log_info "Backup manifest:"; sed 's/^/    /' "${STAGE}/MANIFEST.txt" >&2; }

# Pre-restore safety snapshot of current state (Recoverability).
"${JARVIS_ROOT}/backup.sh" --out "${JARVIS_ROOT}/backups/pre-restore" >/dev/null 2>&1 \
  && log_ok "Saved pre-restore safety backup" \
  || log_warn "Could not take pre-restore safety backup; continuing"

# Restore non-secret asset trees.
for d in workflows prompts config templates reports; do
  if [[ -d "${STAGE}/${d}" ]]; then
    mkdir -p "${JARVIS_ROOT}/${d}"
    cp -a "${STAGE}/${d}/." "${JARVIS_ROOT}/${d}/"
    log_ok "Restored ${d}/"
  fi
done

# Optionally restore the n8n data volume.
if (( WITH_DATA == 1 )) && [[ -f "${STAGE}/n8n-data.tar.gz" ]]; then
  vol="${N8N_DATA_VOLUME:-jarvis_n8n_data}"
  log_info "Restoring n8n data volume '${vol}'"
  docker volume create "${vol}" >/dev/null 2>&1 || true
  docker run --rm -v "${vol}:/data" -v "${STAGE}:/backup:ro" alpine \
    sh -c 'rm -rf /data/* && tar -xzf /backup/n8n-data.tar.gz -C /data' \
    && log_ok "Restored n8n data volume" \
    || log_error "Failed to restore n8n data volume"
fi

# Remind operator about secrets that must be re-supplied.
if [[ -f "${STAGE}/ENV_KEYS.txt" ]]; then
  log_warn "Re-supply these credentials in .env (values are intentionally NOT in backups):"
  sed 's/^/    /' "${STAGE}/ENV_KEYS.txt" >&2
fi

# Bring the stack up and re-import workflows.
log_info "Starting stack and re-importing workflows"
( cd "${JARVIS_ROOT}" && compose up -d ) || log_warn "compose up reported an issue"
"${JARVIS_ROOT}/scripts/workflows/workflow-import.sh" --include-exported \
  && log_ok "Workflows re-imported" \
  || log_warn "Workflow re-import had failures (files are on disk)"

"${JARVIS_ROOT}/scripts/healthcheck.sh" || log_warn "Post-restore health check reported issues"
log_ok "Restore complete. Target recovery time < 15 minutes."
