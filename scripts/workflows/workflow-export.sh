#!/usr/bin/env bash
# =============================================================================
# workflow-export.sh — Export workflows from n8n into the Git-tracked tree
# -----------------------------------------------------------------------------
# Enforces the rule "No workflow may exist only inside the n8n UI". Exports all
# workflows from the running n8n container into workflows/ as pretty-printed
# JSON, one file per workflow, so changes are reviewable and versioned.
#
# Files are written to:   workflows/exported/<name>.json
# (Curated, hand-maintained workflows live under workflows/core and
#  workflows/modules; exported/ is the round-trip mirror of live state.)
#
# Usage: scripts/workflows/workflow-export.sh [--dest DIR]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"
load_env

DEST="${JARVIS_ROOT}/workflows/exported"
N8N_SERVICE="${N8N_SERVICE_NAME:-n8n}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_fatal "Unknown option: $1" ;;
  esac
done

mkdir -p "${DEST}"
log_section "Exporting workflows from n8n"

# Export inside the container to a temp dir, then copy out (separated, decoupled).
tmp_in_container="/tmp/jarvis-export-$$"
if ! ( cd "${JARVIS_ROOT}" && compose exec -T "${N8N_SERVICE}" \
        n8n export:workflow --all --separate --pretty --output="${tmp_in_container}" ); then
  log_fatal "n8n export failed (is the '${N8N_SERVICE}' container running?)"
fi

cid="$( cd "${JARVIS_ROOT}" && compose ps -q "${N8N_SERVICE}" )"
[[ -z "${cid}" ]] && log_fatal "Could not resolve container id for ${N8N_SERVICE}"

# Copy exported files out and normalise names.
rm -f "${DEST}"/*.json 2>/dev/null || true
docker cp "${cid}:${tmp_in_container}/." "${DEST}/" 2>/dev/null \
  || log_fatal "Failed to copy exported workflows out of container"
( cd "${JARVIS_ROOT}" && compose exec -T "${N8N_SERVICE}" rm -rf "${tmp_in_container}" ) || true

count="$(find "${DEST}" -name '*.json' | wc -l | tr -d ' ')"
log_ok "Exported ${count} workflow(s) to ${DEST}"
log_info "Review with 'git diff' then commit (Workflows as source code)"
