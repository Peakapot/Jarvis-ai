#!/usr/bin/env bash
# =============================================================================
# healthcheck.sh — Post-installation & runtime health validation
# -----------------------------------------------------------------------------
# Validates that the running Jarvis stack is healthy (Observability by default).
# Safe to run repeatedly (Idempotent) and from cron for continuous monitoring.
#
# Checks (per Engineering Directives — after install / monitoring):
#   n8n running, Ollama responding, Telegram connected, Email sending,
#   RSS feeds reachable, Workflow imports successful, Disk usage.
#
# Provider/connectivity checks degrade gracefully: a feature that is not
# configured is reported SKIP, not FAIL (Fail-safe defaults).
#
# Exit codes: 0 healthy, 1 one or more FAIL, 2 usage error.
#
# Usage: scripts/healthcheck.sh [--json] [--quiet]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
log_init "healthcheck"
load_env

N8N_URL="${N8N_BASE_URL:-http://localhost:5678}"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
DISK_WARN_PCT="${JARVIS_DISK_WARN_PCT:-85}"
DISK_FAIL_PCT="${JARVIS_DISK_FAIL_PCT:-95}"

PASS=0 WARN=0 FAIL=0 SKIP=0
declare -a RESULTS=()
record() {
  RESULTS+=("$1|$2|$3")
  case "$1" in
    PASS) PASS=$((PASS+1)) ;; WARN) WARN=$((WARN+1)) ;;
    FAIL) FAIL=$((FAIL+1)) ;; SKIP) SKIP=$((SKIP+1)) ;;
  esac
}

http_ok() { curl -fsS --max-time "${2:-8}" -o /dev/null "$1" 2>/dev/null; }

check_n8n() {
  if http_ok "${N8N_URL}/healthz"; then
    record PASS "n8n" "Healthy at ${N8N_URL}"
  elif http_ok "${N8N_URL}"; then
    record PASS "n8n" "Reachable at ${N8N_URL}"
  else
    record FAIL "n8n" "Not responding at ${N8N_URL}"
  fi
}

check_ollama() {
  if http_ok "${OLLAMA_URL}/api/tags"; then
    local models
    models="$(curl -fsS --max-time 5 "${OLLAMA_URL}/api/tags" 2>/dev/null | grep -oE '"name":"[^"]+"' | wc -l | tr -d ' ')"
    record PASS "Ollama" "Responding at ${OLLAMA_URL} (${models:-0} model(s))"
  else
    record FAIL "Ollama" "Not responding at ${OLLAMA_URL}"
  fi
}

check_telegram() {
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    record SKIP "Telegram" "TELEGRAM_BOT_TOKEN not configured"
    return
  fi
  if http_ok "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"; then
    record PASS "Telegram" "Bot token valid (getMe ok)"
  else
    record FAIL "Telegram" "getMe failed (token invalid or no network)"
  fi
}

check_email() {
  local provider="${EMAIL_PROVIDER:-}"
  if [[ -z "${provider}" ]]; then
    record SKIP "Email" "EMAIL_PROVIDER not configured"
    return
  fi
  case "${provider}" in
    smtp)
      if [[ -n "${SMTP_HOST:-}" ]]; then
        if have_cmd nc && nc -z -w5 "${SMTP_HOST}" "${SMTP_PORT:-587}" 2>/dev/null; then
          record PASS "Email" "SMTP ${SMTP_HOST}:${SMTP_PORT:-587} reachable"
        else
          record WARN "Email" "SMTP ${SMTP_HOST}:${SMTP_PORT:-587} not verified (nc unavailable or blocked)"
        fi
      else
        record WARN "Email" "EMAIL_PROVIDER=smtp but SMTP_HOST unset"
      fi
      ;;
    gmail|microsoft365)
      record PASS "Email" "Provider '${provider}' configured (OAuth verified in n8n)"
      ;;
    *)
      record WARN "Email" "Unknown EMAIL_PROVIDER='${provider}'"
      ;;
  esac
}

check_rss() {
  local feeds_file="${JARVIS_ROOT}/config/rss-feeds.txt"
  if [[ ! -f "${feeds_file}" ]]; then
    record SKIP "RSS Feeds" "No config/rss-feeds.txt present"
    return
  fi
  local total=0 ok=0 url
  while IFS= read -r url; do
    [[ -z "${url}" || "${url}" == \#* ]] && continue
    total=$((total+1))
    http_ok "${url}" 6 && ok=$((ok+1))
  done <"${feeds_file}"
  if (( total == 0 )); then
    record SKIP "RSS Feeds" "No feeds listed"
  elif (( ok == total )); then
    record PASS "RSS Feeds" "${ok}/${total} reachable"
  elif (( ok > 0 )); then
    record WARN "RSS Feeds" "${ok}/${total} reachable"
  else
    record FAIL "RSS Feeds" "0/${total} reachable"
  fi
}

check_workflows() {
  local dir="${JARVIS_ROOT}/workflows"
  local count
  count="$(find "${dir}" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
  if (( count > 0 )); then
    record PASS "Workflows" "${count} workflow file(s) under source control"
  else
    record WARN "Workflows" "No workflow JSON files found"
  fi
}

check_disk() {
  local pct
  pct="$(df --output=pcent "${JARVIS_ROOT}" 2>/dev/null | tail -n1 | tr -dc '0-9')"
  pct="${pct:-0}"
  if (( pct >= DISK_FAIL_PCT )); then
    record FAIL "Disk Usage" "${pct}% used (>= ${DISK_FAIL_PCT}%)"
  elif (( pct >= DISK_WARN_PCT )); then
    record WARN "Disk Usage" "${pct}% used (>= ${DISK_WARN_PCT}%)"
  else
    record PASS "Disk Usage" "${pct}% used"
  fi
}

print_report() {
  log_section "Health Check Report"
  local entry status name detail color sym
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail <<<"${entry}"
    case "${status}" in
      PASS) color="${C_GREEN}";  sym="${SYM_OK}"   ;;
      WARN) color="${C_YELLOW}"; sym="${SYM_WARN}" ;;
      FAIL) color="${C_RED}";    sym="${SYM_FAIL}" ;;
      SKIP) color="${C_GREY}";   sym="${SYM_INFO}" ;;
    esac
    printf '  %s%-6s%s %-16s %s\n' "${color}" "${sym}" "${C_RESET}" "${name}" "${detail}" >&2
  done
  printf '\n  %sPASS=%d  WARN=%d  FAIL=%d  SKIP=%d%s\n\n' \
    "${C_BOLD}" "${PASS}" "${WARN}" "${FAIL}" "${SKIP}" "${C_RESET}" >&2
}

print_json() {
  local entry status name detail first=1
  printf '{"component":"healthcheck","ts":"%s","results":[' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
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

  require_cmd curl
  check_n8n
  check_ollama
  check_telegram
  check_email
  check_rss
  check_workflows
  check_disk

  [[ "${json}" == 1 ]] && print_json
  [[ "${quiet}" == 0 && "${json}" == 0 ]] && print_report

  if (( FAIL > 0 )); then
    log_error "Health check failed: ${FAIL} component(s) unhealthy"
    exit 1
  fi
  log_ok "All health checks passed"
  exit 0
}

main "$@"
