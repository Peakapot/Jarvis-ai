#!/usr/bin/env bash
# =============================================================================
# status.sh — Operational status dashboard
# -----------------------------------------------------------------------------
# Single-pane view of the Jarvis stack for day-to-day operations
# (Monitoring and Observability). Reports:
#   Service status, Workflow status, Last successful/failed run,
#   Email/Telegram/Ollama status, Disk usage, Storage usage.
#
# Lightweight and read-only; safe to run any time. For deep pass/fail health
# use healthcheck.sh; for incident capture use diagnostics.sh.
#
# Usage: scripts/status.sh [--json]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=scripts/lib/intelligence.sh
source "${SCRIPT_DIR}/lib/intelligence.sh"
log_init "status"
load_env

N8N_URL="${N8N_BASE_URL:-http://localhost:5678}"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"

http_ok() { curl -fsS --max-time "${2:-5}" -o /dev/null "$1" 2>/dev/null; }
up_down() { if "$@"; then printf '%sUP%s' "${C_GREEN}" "${C_RESET}"; else printf '%sDOWN%s' "${C_RED}" "${C_RESET}"; fi; }

# Compose service states, if the stack is defined.
compose_services() {
  if [[ -f "${JARVIS_ROOT}/docker-compose.yml" ]] && have_cmd docker; then
    ( cd "${JARVIS_ROOT}" && compose ps --format '  {{.Name}}\t{{.Service}}\t{{.Status}}' 2>/dev/null ) || true
  fi
}

# Last run markers, written by workflow execution logging.
last_run() { # success|failed
  local f="${JARVIS_ROOT}/logs/last-run-$1.txt"
  [[ -f "${f}" ]] && cat "${f}" || echo "n/a"
}

human_size() { du -sh "$1" 2>/dev/null | awk '{print $1}' || echo "n/a"; }

print_text() {
  log_section "Jarvis Status — $(date -u +%Y-%m-%dT%H:%M:%SZ)"

  printf '\n%sServices%s\n' "${C_BOLD}" "${C_RESET}" >&2
  printf '  %-12s %s\n' "n8n"      "$(up_down http_ok "${N8N_URL}/healthz" || up_down http_ok "${N8N_URL}")" >&2
  printf '  %-12s %s\n' "Ollama"   "$(up_down http_ok "${OLLAMA_URL}/api/tags")" >&2
  if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    printf '  %-12s %s\n' "Telegram" "$(up_down http_ok "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe")" >&2
  else
    printf '  %-12s %sNOT CONFIGURED%s\n' "Telegram" "${C_GREY}" "${C_RESET}" >&2
  fi
  printf '  %-12s %s\n' "Email"    "${EMAIL_PROVIDER:-not configured}" >&2

  local svc; svc="$(compose_services)"
  if [[ -n "${svc}" ]]; then
    printf '\n%sContainers%s\n%s\n' "${C_BOLD}" "${C_RESET}" "${svc}" >&2
  fi

  printf '\n%sWorkflows%s\n' "${C_BOLD}" "${C_RESET}" >&2
  printf '  %-22s %s\n' "Files under VCS" "$(find "${JARVIS_ROOT}/workflows" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')" >&2
  printf '  %-22s %s\n' "Last successful run" "$(last_run success)" >&2
  printf '  %-22s %s\n' "Last failed run"     "$(last_run failed)" >&2

  # Intelligence products — registry-driven (Future expansion).
  local ids id name sv sd enabled latest adir
  ids="$(intel_ids)"
  if [[ -n "${ids}" ]]; then
    printf '\n%sIntelligence Products%s\n' "${C_BOLD}" "${C_RESET}" >&2
    while IFS= read -r id; do
      [[ -z "${id}" ]] && continue
      name="$(intel_field "${id}" name)"
      sv="$(intel_field "${id}" scheduleEnv)"; sd="$(intel_field "${id}" scheduleDefault)"
      adir="$(intel_field "${id}" archiveDir)"
      if intel_enabled "${id}"; then enabled="${C_GREEN}enabled${C_RESET}"; else enabled="${C_GREY}disabled${C_RESET}"; fi
      latest="n/a"
      [[ -n "${adir}" && -d "${JARVIS_ROOT}/${adir}" ]] && latest="$(find "${JARVIS_ROOT}/${adir}" -name '*.html' 2>/dev/null | sort | tail -n1 | xargs -r basename)"
      printf '  %-26s %-8b sched %-12s latest %s\n' "${id}" "${enabled}" "${!sv:-${sd}}" "${latest:-n/a}" >&2
    done <<<"${ids}"
  fi

  printf '\n%sStorage%s\n' "${C_BOLD}" "${C_RESET}" >&2
  printf '  %-22s %s used\n' "Disk (repo volume)" "$(df --output=pcent "${JARVIS_ROOT}" 2>/dev/null | tail -n1 | tr -d ' ')" >&2
  printf '  %-22s %s\n' "logs/"    "$(human_size "${JARVIS_ROOT}/logs")" >&2
  printf '  %-22s %s\n' "backups/" "$(human_size "${JARVIS_ROOT}/backups")" >&2
  printf '  %-22s %s\n' "reports/" "$(human_size "${JARVIS_ROOT}/reports")" >&2
  printf '\n' >&2
}

print_json() {
  printf '{"ts":"%s","n8n":"%s","ollama":"%s","email_provider":"%s","workflows":%s,"last_success":"%s","last_failed":"%s","disk_pct":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$(http_ok "${N8N_URL}/healthz" && echo up || echo down)" \
    "$(http_ok "${OLLAMA_URL}/api/tags" && echo up || echo down)" \
    "${EMAIL_PROVIDER:-none}" \
    "$(find "${JARVIS_ROOT}/workflows" -name '*.json' 2>/dev/null | wc -l | tr -d ' ')" \
    "$(last_run success)" "$(last_run failed)" \
    "$(df --output=pcent "${JARVIS_ROOT}" 2>/dev/null | tail -n1 | tr -dc '0-9')"
}

main() {
  require_cmd curl
  if [[ "${1:-}" == "--json" ]]; then print_json; else print_text; fi
}
main "$@"
