#!/usr/bin/env bash
# =============================================================================
# workflow-import.sh — Import Git-tracked workflows into n8n (idempotent)
# -----------------------------------------------------------------------------
# Loads workflow JSON from the repository into the running n8n instance. Used by
# install.sh and for restores/migrations. Re-running is safe: n8n upserts by
# workflow id, so existing workflows are updated rather than duplicated
# (Idempotent operations).
#
# Source order (later overrides earlier on id collision):
#   workflows/core/        core assistant workflows
#   workflows/modules/     per-plugin module workflows
#   workflows/exported/    round-trip mirror (only with --include-exported)
#
# Writes a per-file result so install/healthcheck can confirm
# "Workflow imports successful".
#
# Usage:
#   scripts/workflows/workflow-import.sh [--dir DIR ...] [--include-exported]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"
load_env

N8N_SERVICE="${N8N_SERVICE_NAME:-n8n}"
declare -a DIRS=("${JARVIS_ROOT}/workflows/core" "${JARVIS_ROOT}/workflows/modules")
INCLUDE_EXPORTED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIRS+=("$2"); shift 2 ;;
    --include-exported) INCLUDE_EXPORTED=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_fatal "Unknown option: $1" ;;
  esac
done
[[ "${INCLUDE_EXPORTED}" == 1 ]] && DIRS+=("${JARVIS_ROOT}/workflows/exported")

log_section "Importing workflows into n8n"

# Validate integrity before mutating anything (Fail-safe defaults).
if ! "${SCRIPT_DIR}/workflow-validate.sh" --quiet; then
  log_fatal "Workflow integrity validation failed; aborting import"
fi

cid="$( cd "${JARVIS_ROOT}" && compose ps -q "${N8N_SERVICE}" )"
[[ -z "${cid}" ]] && log_fatal "n8n container '${N8N_SERVICE}' is not running"

total=0 ok=0 fail=0
result_log="${JARVIS_ROOT}/logs/workflow-import-result.txt"
: >"${result_log}"

for dir in "${DIRS[@]}"; do
  [[ -d "${dir}" ]] || continue
  while IFS= read -r wf; do
    [[ -z "${wf}" ]] && continue
    total=$((total+1))
    base="$(basename "${wf}")"
    # Copy into container then import (decoupled from host paths).
    if docker cp "${wf}" "${cid}:/tmp/${base}" 2>/dev/null \
       && ( cd "${JARVIS_ROOT}" && compose exec -T "${N8N_SERVICE}" n8n import:workflow --input="/tmp/${base}" >/dev/null 2>&1 ); then
      ok=$((ok+1)); echo "OK   ${wf}" >>"${result_log}"; log_ok "Imported ${base}"
    else
      fail=$((fail+1)); echo "FAIL ${wf}" >>"${result_log}"; log_error "Failed to import ${base}"
    fi
    ( cd "${JARVIS_ROOT}" && compose exec -T "${N8N_SERVICE}" rm -f "/tmp/${base}" ) >/dev/null 2>&1 || true
  done < <(find "${dir}" -maxdepth 1 -name '*.json' | sort)
done

log_info "Import summary: ${ok}/${total} succeeded, ${fail} failed"
if (( fail > 0 )); then
  log_error "Some workflow imports failed (see ${result_log})"
  exit 1
fi
log_ok "All ${ok} workflow import(s) successful"
