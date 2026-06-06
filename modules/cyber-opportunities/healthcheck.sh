#!/usr/bin/env bash
# =============================================================================
# cyber-opportunities/healthcheck.sh — Intelligence module health check
# -----------------------------------------------------------------------------
# Thin wrapper over the shared intelligence library (scripts/lib/intelligence.sh)
# so every intelligence product checks the same things the same way (DRY,
# Observability by default). A disabled product reports SKIP, never FAIL
# (Fail-safe defaults). Additionally verifies source reachability when network
# is available.
#
# Usage: modules/cyber-opportunities/healthcheck.sh [--json] [--quiet]
# Exit: 0 healthy, 1 FAIL present, 2 usage error.
# =============================================================================
set -o errexit -o nounset -o pipefail

PRODUCT_ID="cyber-opportunities"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${MODULE_DIR}/../.." && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${REPO_ROOT}/scripts/lib/common.sh"
# shellcheck source=../../scripts/lib/intelligence.sh
source "${REPO_ROOT}/scripts/lib/intelligence.sh"
log_init "${PRODUCT_ID}-health"
load_env

PASS=0 WARN=0 FAIL=0 SKIP=0
declare -a RESULTS=()
record() {
  RESULTS+=("$1|$2|$3")
  case "$1" in PASS) PASS=$((PASS+1));; WARN) WARN=$((WARN+1));; FAIL) FAIL=$((FAIL+1));; SKIP) SKIP=$((SKIP+1));; esac
}

# Fold the shared registry-driven checks into our report.
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  IFS='|' read -r st nm dt <<<"${line}"
  record "${st}" "${nm}" "${dt}"
done < <(intel_checks "${PRODUCT_ID}")

# Optional connectivity probe of a few sources (only if enabled + curl present).
if intel_enabled "${PRODUCT_ID}" && have_cmd curl; then
  src="${REPO_ROOT}/$(intel_field "${PRODUCT_ID}" sourcesFile)"
  if [[ -f "${src}" ]]; then
    total=0 ok=0
    while IFS= read -r url; do
      [[ -z "${url}" || "${url}" == \#* ]] && continue
      total=$((total+1)); [[ "${total}" -gt 5 ]] && break
      curl -fsS --max-time 6 -o /dev/null "${url}" 2>/dev/null && ok=$((ok+1))
    done <"${src}"
    (( total > 0 )) && record "$([[ ${ok} -gt 0 ]] && echo PASS || echo WARN)" "${PRODUCT_ID}.reachability" "${ok}/${total} sampled sources reachable"
  fi
fi

print_report() {
  log_section "${PRODUCT_ID} health"
  local e s n d
  for e in "${RESULTS[@]}"; do IFS='|' read -r s n d <<<"${e}"; printf '  %-5s %-28s %s\n' "${s}" "${n}" "${d}" >&2; done
  printf '\n  PASS=%d WARN=%d FAIL=%d SKIP=%d\n\n' "${PASS}" "${WARN}" "${FAIL}" "${SKIP}" >&2
}
print_json() {
  local e s n d first=1; printf '{"module":"%s","results":[' "${PRODUCT_ID}"
  for e in "${RESULTS[@]}"; do IFS='|' read -r s n d <<<"${e}"; [[ "${first}" == 0 ]] && printf ','; first=0
    printf '{"check":"%s","status":"%s","detail":"%s"}' "${n}" "${s}" "$(printf '%s' "${d}" | sed 's/"/\\"/g')"; done
  printf '],"summary":{"pass":%d,"warn":%d,"fail":%d,"skip":%d}}\n' "${PASS}" "${WARN}" "${FAIL}" "${SKIP}"
}

main() {
  local json=0 quiet=0
  while [[ $# -gt 0 ]]; do case "$1" in
    --json) json=1;; --quiet) quiet=1;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) log_error "Unknown option: $1"; exit 2;; esac; shift; done
  [[ "${json}" == 1 ]] && print_json
  [[ "${quiet}" == 0 && "${json}" == 0 ]] && print_report
  (( FAIL > 0 )) && exit 1 || exit 0
}
main "$@"
