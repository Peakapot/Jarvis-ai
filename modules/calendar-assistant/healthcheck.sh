#!/usr/bin/env bash
# =============================================================================
# calendar-assistant/healthcheck.sh — Module health check
# -----------------------------------------------------------------------------
# Self-contained health check for the calendar-assistant module (Observability by default).
# Sources the shared library via a robust relative path. A module that is not
# enabled reports SKIP, never FAIL (Fail-safe defaults).
#
# Usage: modules/calendar-assistant/healthcheck.sh [--json] [--quiet]
# Exit codes: 0 healthy, 1 one or more FAIL, 2 usage error.
# =============================================================================
set -o errexit -o nounset -o pipefail

MODULE_ID="calendar-assistant"
ENABLE_VAR="CALENDAR_ASSISTANT_ENABLED"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root is two levels up: modules/<module>/ -> repo root.
REPO_ROOT="$(cd "${MODULE_DIR}/../.." && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${REPO_ROOT}/scripts/lib/common.sh"
log_init "${MODULE_ID}-health"
load_env

PASS=0 WARN=0 FAIL=0 SKIP=0
declare -a RESULTS=()
record() {
  RESULTS+=("$1|$2|$3")
  case "$1" in
    PASS) PASS=$((PASS+1)) ;; WARN) WARN=$((WARN+1)) ;;
    FAIL) FAIL=$((FAIL+1)) ;; SKIP) SKIP=$((SKIP+1)) ;;
  esac
}

check_assets() {
  if [[ -d "${MODULE_DIR}/prompts" ]] && compgen -G "${MODULE_DIR}/prompts/*.md" >/dev/null; then
    record PASS "prompts" "Prompt asset(s) present"
  else
    record FAIL "prompts" "No prompt files found"
  fi
  if compgen -G "${MODULE_DIR}/workflows/*.json" >/dev/null; then
    record PASS "workflows" "Workflow asset(s) present"
  else
    record FAIL "workflows" "No workflow files found"
  fi
}

check_enabled() {
  local enabled="${!ENABLE_VAR:-false}"
  if [[ "${enabled}" != "true" ]]; then
    record SKIP "${MODULE_ID}" "Module not enabled (${ENABLE_VAR}!=true) — planned capability"
    return 1
  fi
  record PASS "${MODULE_ID}" "Module enabled"
  return 0
}

print_report() {
  log_section "${MODULE_ID} health"
  local entry status name detail
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail <<<"${entry}"
    printf '  %-5s %-16s %s\n' "${status}" "${name}" "${detail}" >&2
  done
  printf '\n  PASS=%d WARN=%d FAIL=%d SKIP=%d\n\n' "${PASS}" "${WARN}" "${FAIL}" "${SKIP}" >&2
}

print_json() {
  local entry status name detail first=1
  printf '{"module":"%s","results":[' "${MODULE_ID}"
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail <<<"${entry}"
    [[ "${first}" == 0 ]] && printf ','
    first=0
    printf '{"check":"%s","status":"%s","detail":"%s"}' \
      "${name}" "${status}" "$(printf '%s' "${detail}" | sed 's/"/\\"/g')"
  done
  printf '],"summary":{"pass":%d,"warn":%d,"fail":%d,"skip":%d}}\n' \
    "${PASS}" "${WARN}" "${FAIL}" "${SKIP}"
}

main() {
  local json=0 quiet=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)  json=1 ;;
      --quiet) quiet=1 ;;
      -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) log_error "Unknown option: $1"; exit 2 ;;
    esac
    shift
  done

  check_assets
  if check_enabled; then
    : # add live/connectivity checks here; report SKIP if deps unset
  fi

  [[ "${json}" == 1 ]] && print_json
  [[ "${quiet}" == 0 && "${json}" == 0 ]] && print_report

  (( FAIL > 0 )) && exit 1
  exit 0
}

main "$@"
