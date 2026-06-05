#!/usr/bin/env bash
# =============================================================================
# run-tests.sh — Repository self-test (no running stack required)
# -----------------------------------------------------------------------------
# Fast, dependency-light checks that the repository is internally consistent.
# Safe to run anywhere (CI, fresh clone). Does NOT require Docker or a running
# stack — those are covered by validate.sh / healthcheck.sh.
#
# Checks:
#   1. All shell scripts pass `bash -n` (syntax).
#   2. All shell scripts pass shellcheck (if installed).
#   3. All JSON files parse.
#   4. All n8n workflows pass integrity validation (shape + no secrets).
#   5. The shared library loads and core helpers behave.
#   6. No tracked file contains an obvious secret.
#
# Usage: tests/run-tests.sh
# Exit: 0 all passed, 1 failure.
# =============================================================================
set -o errexit -o nounset -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
# shellcheck source=scripts/lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
log_init "tests"

fails=0
pass() { log_ok "$1"; }
fail() { log_error "$1"; fails=$((fails+1)); }

log_section "1. Shell syntax (bash -n)"
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null && continue
  fail "syntax: $f"
done < <(find . -name '*.sh' -not -path './.git/*')
(( fails == 0 )) && pass "All shell scripts parse"

log_section "2. ShellCheck"
if have_cmd shellcheck; then
  if shellcheck -x -e SC1090,SC1091 $(find . -name '*.sh' -not -path './.git/*') ; then
    pass "shellcheck clean"
  else
    fail "shellcheck reported issues"
  fi
else
  log_warn "shellcheck not installed; skipping"
fi

log_section "3. JSON parses"
json_fail=0
while IFS= read -r f; do
  if have_cmd jq; then jq -e . "$f" >/dev/null 2>&1 || { fail "invalid JSON: $f"; json_fail=1; }
  elif have_cmd python3; then python3 -c 'import json,sys;json.load(open(sys.argv[1]))' "$f" 2>/dev/null || { fail "invalid JSON: $f"; json_fail=1; }
  fi
done < <(find . -name '*.json' -not -path './.git/*' -not -path './node_modules/*')
(( json_fail == 0 )) && pass "All JSON valid"

log_section "4. Workflow integrity"
scripts/workflows/workflow-validate.sh --quiet && pass "Workflows valid" || fail "Workflow validation failed"

log_section "5. Library behaviour"
( state_init; state_mark_done __selftest; state_is_done __selftest ) && pass "state helpers work" || fail "state helpers broken"
state_clear __selftest 2>/dev/null || true

log_section "6. Secret scan"
if git grep -nIE '(AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC) PRIVATE KEY-----|xox[baprs]-[0-9A-Za-z]{10,})' -- . ':!*.example' ':!tests/*' >/dev/null 2>&1; then
  fail "potential secret found in tracked files"
else
  pass "no obvious secrets in tracked files"
fi

echo
if (( fails == 0 )); then
  log_ok "ALL TESTS PASSED"
  exit 0
fi
log_error "${fails} test group(s) failed"
exit 1
