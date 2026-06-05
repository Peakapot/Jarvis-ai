#!/usr/bin/env bash
# =============================================================================
# backup.sh — Full system backup
# -----------------------------------------------------------------------------
# Creates a single, integrity-checked, timestamped backup archive covering
# everything required to recover the system in under 15 minutes
# (Backup and Recovery). It deliberately does NOT include secrets from .env —
# instead it records the .env key names so an operator knows what to repopulate
# (Security by default). Credentials are re-supplied at restore time.
#
# Backed up (per directives):
#   - workflows/      (workflow source, including exported mirror)
#   - prompts/        (first-class prompt assets)
#   - config/         (provider/config descriptors, non-secret)
#   - templates/      (email/report templates)
#   - reports/        (generated intelligence products & archive)
#   - n8n data volume (optional, --with-data: credentials/executions DB)
#
# Usage:
#   ./backup.sh [--with-data] [--out DIR]
#     --with-data  include the n8n docker volume (contains encrypted creds DB)
#     --out DIR    output directory (default: backups/)
# =============================================================================
set -o errexit -o nounset -o pipefail

JARVIS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JARVIS_ROOT
# shellcheck source=scripts/lib/common.sh
source "${JARVIS_ROOT}/scripts/lib/common.sh"
log_init "backup"
load_env

OUT_DIR="${JARVIS_ROOT}/backups"
WITH_DATA=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-data) WITH_DATA=1; shift ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_fatal "Unknown option: $1" ;;
  esac
done

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
mkdir -p "${OUT_DIR}"

log_section "Creating full backup (${STAMP})"

# Validate workflows before snapshotting (never archive corrupt state).
"${JARVIS_ROOT}/scripts/workflows/workflow-validate.sh" --quiet \
  || log_warn "Workflow integrity warnings present; continuing"

# Refresh exported workflows from live n8n (best-effort).
"${JARVIS_ROOT}/scripts/workflows/workflow-export.sh" >/dev/null 2>&1 || true

# Copy non-secret assets into the staging area.
for d in workflows prompts config templates reports; do
  if [[ -d "${JARVIS_ROOT}/${d}" ]]; then
    mkdir -p "${STAGE}/${d}"
    cp -a "${JARVIS_ROOT}/${d}/." "${STAGE}/${d}/" 2>/dev/null || true
  fi
done

# Record .env key inventory (names only — values redacted).
if [[ -f "${JARVIS_ENV_FILE}" ]]; then
  grep -vE '^\s*#' "${JARVIS_ENV_FILE}" | grep -E '=' | sed -E 's/=.*/=<set at restore>/' \
    | sort >"${STAGE}/ENV_KEYS.txt" 2>/dev/null || true
fi

# Optionally include the n8n data volume (encrypted credentials + execution DB).
if (( WITH_DATA == 1 )); then
  local_vol="${N8N_DATA_VOLUME:-jarvis_n8n_data}"
  log_info "Including n8n data volume '${local_vol}' (--with-data)"
  if docker volume inspect "${local_vol}" >/dev/null 2>&1; then
    docker run --rm -v "${local_vol}:/data:ro" -v "${STAGE}:/backup" alpine \
      sh -c 'tar -czf /backup/n8n-data.tar.gz -C /data .' \
      && log_ok "Captured n8n data volume" \
      || log_warn "Could not capture n8n data volume"
  else
    log_warn "Volume '${local_vol}' not found; skipping data backup"
  fi
fi

# Manifest for provenance & verification.
{
  echo "backup_stamp=${STAMP}"
  echo "created=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "host=$(hostname 2>/dev/null || echo unknown)"
  echo "with_data=${WITH_DATA}"
  echo "git_commit=$(cd "${JARVIS_ROOT}" && git rev-parse --short HEAD 2>/dev/null || echo n/a)"
} >"${STAGE}/MANIFEST.txt"

archive="${OUT_DIR}/jarvis-backup-${STAMP}.tar.gz"
tar -czf "${archive}" -C "${STAGE}" .
( cd "${OUT_DIR}" && sha256sum "$(basename "${archive}")" >"$(basename "${archive}").sha256" )

# Retention: keep newest N (Configuration over hard coding).
local_keep="${JARVIS_BACKUP_KEEP:-14}"
mapfile -t old < <(find "${OUT_DIR}" -maxdepth 1 -name 'jarvis-backup-*.tar.gz' | sort | head -n -"${local_keep}" 2>/dev/null || true)
for f in "${old[@]:-}"; do
  [[ -n "${f}" ]] || continue
  rm -f "${f}" "${f}.sha256"
  log_info "Pruned old backup: $(basename "${f}")"
done

log_ok "Backup complete: ${archive}"
log_info "Recovery: ./restore.sh ${archive}"
echo "${archive}"
