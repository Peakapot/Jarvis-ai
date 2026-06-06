#!/usr/bin/env bash
# =============================================================================
# workflow-validate.sh — Workflow integrity validation
# -----------------------------------------------------------------------------
# Validates every workflow JSON file under workflows/ for structural integrity
# before it is imported, backed up or migrated (Workflow integrity validation).
#
# Checks per file:
#   - valid JSON (jq if available, python3 fallback)
#   - contains a "nodes" array and "connections" object (n8n shape)
#   - no embedded secrets in obvious credential-data fields (Security by default)
#
# Exit codes: 0 all valid, 1 one or more invalid, 2 usage error.
#
# Usage: scripts/workflows/workflow-validate.sh [--quiet] [DIR]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "workflow"

QUIET=0
EXPLICIT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=1; shift ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) EXPLICIT_DIR="$1"; shift ;;
  esac
done

# Default scope: the workflows/ tree PLUS every module-owned workflows directory
# (intelligence products, future modules) so module workflows are validated by
# the same integrity check (Modular, Observability). An explicit dir overrides.
declare -a ROOTS=()
if [[ -n "${EXPLICIT_DIR}" ]]; then
  ROOTS=("${EXPLICIT_DIR}")
else
  ROOTS=("${JARVIS_ROOT}/workflows")
  while IFS= read -r mdir; do
    [[ -n "${mdir}" ]] && ROOTS+=("${mdir}")
  done < <(jarvis_module_workflow_dirs)
fi

say() { [[ "${QUIET}" == 1 ]] || log_info "$@"; }

# JSON validity check using whatever is available.
json_valid() {
  if have_cmd jq; then jq -e . "$1" >/dev/null 2>&1
  elif have_cmd python3; then python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$1" >/dev/null 2>&1
  else
    log_warn "Neither jq nor python3 available; skipping strict JSON parse"
    return 0
  fi
}

n8n_shape() {
  if have_cmd jq; then
    jq -e 'has("nodes") and (.nodes|type=="array") and has("connections")' "$1" >/dev/null 2>&1
  else
    grep -q '"nodes"' "$1" && grep -q '"connections"' "$1"
  fi
}

# Detect plausible plaintext secrets accidentally committed in a workflow.
contains_secret() {
  grep -aEiq '("(apiKey|accessToken|password|clientSecret|privateKey)"\s*:\s*"[^"]{8,}")' "$1"
}

total=0 bad=0
while IFS= read -r wf; do
  [[ -z "${wf}" ]] && continue
  total=$((total+1))
  rel="${wf#"${JARVIS_ROOT}/"}"
  if ! json_valid "${wf}"; then
    log_error "Invalid JSON: ${rel}"; bad=$((bad+1)); continue
  fi
  if ! n8n_shape "${wf}"; then
    log_error "Not an n8n workflow (missing nodes/connections): ${rel}"; bad=$((bad+1)); continue
  fi
  if contains_secret "${wf}"; then
    log_error "Possible plaintext secret in: ${rel} (workflows must not contain credentials)"; bad=$((bad+1)); continue
  fi
  say "Valid: ${rel}"
done < <(find "${ROOTS[@]}" -name '*.json' 2>/dev/null | sort)

if (( total == 0 )); then
  say "No workflow files found under: ${ROOTS[*]}"
fi

if (( bad > 0 )); then
  log_error "Workflow validation failed: ${bad}/${total} file(s) invalid"
  exit 1
fi
[[ "${QUIET}" == 1 ]] || log_ok "Workflow validation passed: ${total} file(s)"
exit 0
