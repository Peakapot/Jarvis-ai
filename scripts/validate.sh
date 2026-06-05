#!/usr/bin/env bash
# =============================================================================
# validate.sh — Pre-installation environment validation framework
# -----------------------------------------------------------------------------
# Validates that the host meets every prerequisite BEFORE install.sh changes
# anything (Fail-safe defaults). Each check is independent and non-mutating;
# the script aggregates results and prints a readiness report.
#
# Checks (per Engineering Directives — Environment Validation / before install):
#   OS, WSL, Ubuntu, Docker, Docker Compose, RAM, CPU, Disk Space,
#   Network Access, Ollama Access.
#
# Exit codes:
#   0  all required checks passed (warnings allowed)
#   1  one or more required checks failed
#   2  usage error
#
# Usage:
#   scripts/validate.sh [--json] [--strict] [--quiet]
#     --json    emit a machine-readable JSON report to stdout
#     --strict  treat warnings as failures
#     --quiet   suppress the human-readable report (still sets exit code)
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
log_init "validate"
load_env

# ---------------------------------------------------------------------------
# Thresholds (Configuration over hard coding) — overridable via .env.
# ---------------------------------------------------------------------------
MIN_RAM_GB="${JARVIS_MIN_RAM_GB:-8}"
MIN_CPU_CORES="${JARVIS_MIN_CPU_CORES:-2}"
MIN_DISK_GB="${JARVIS_MIN_DISK_GB:-20}"
DOCKER_MIN_VERSION="${JARVIS_DOCKER_MIN_VERSION:-20.10}"
COMPOSE_MIN_VERSION="${JARVIS_COMPOSE_MIN_VERSION:-2.0}"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"
NETWORK_PROBE_URL="${JARVIS_NETWORK_PROBE_URL:-https://registry-1.docker.io/v2/}"

# ---------------------------------------------------------------------------
# Result accumulation.
# ---------------------------------------------------------------------------
PASS=0 WARN=0 FAIL=0
declare -a RESULTS=()   # "status|name|detail"

record() { # status name detail
  RESULTS+=("$1|$2|$3")
  case "$1" in
    PASS) PASS=$((PASS+1)) ;;
    WARN) WARN=$((WARN+1)) ;;
    FAIL) FAIL=$((FAIL+1)) ;;
  esac
}

# ---------------------------------------------------------------------------
# Individual checks. Each appends exactly one result.
# ---------------------------------------------------------------------------
check_os() {
  local os; os="$(uname -s)"
  if [[ "${os}" == "Linux" ]]; then
    record PASS "Operating System" "Linux ($(uname -r))"
  else
    record FAIL "Operating System" "Expected Linux, found ${os}"
  fi
}

check_wsl() {
  if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    record PASS "WSL" "Running under WSL"
  else
    record WARN "WSL" "Not WSL (native Linux is fine; informational)"
  fi
}

check_ubuntu() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *debian* ]]; then
      record PASS "Distribution" "${PRETTY_NAME:-${ID}}"
    else
      record WARN "Distribution" "${PRETTY_NAME:-unknown} (Ubuntu/Debian recommended)"
    fi
  else
    record WARN "Distribution" "/etc/os-release not readable"
  fi
}

check_docker() {
  if ! have_cmd docker; then
    record FAIL "Docker" "docker not installed"
    return
  fi
  local v
  v="$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)"
  [[ -z "${v}" ]] && v="$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  if ! docker info >/dev/null 2>&1; then
    record FAIL "Docker" "daemon not reachable (is it running / are you in the docker group?)"
    return
  fi
  if [[ -n "${v}" ]] && semver_ge "${v}" "${DOCKER_MIN_VERSION}"; then
    record PASS "Docker" "v${v} (>= ${DOCKER_MIN_VERSION})"
  else
    record WARN "Docker" "v${v:-unknown} (< ${DOCKER_MIN_VERSION} recommended)"
  fi
}

check_compose() {
  local v=""
  if docker compose version >/dev/null 2>&1; then
    v="$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  elif have_cmd docker-compose; then
    v="$(docker-compose version --short 2>/dev/null || true)"
  else
    record FAIL "Docker Compose" "not installed (need plugin v2 or docker-compose)"
    return
  fi
  if [[ -n "${v}" ]] && semver_ge "${v}" "${COMPOSE_MIN_VERSION}"; then
    record PASS "Docker Compose" "v${v} (>= ${COMPOSE_MIN_VERSION})"
  else
    record WARN "Docker Compose" "v${v:-unknown} (< ${COMPOSE_MIN_VERSION} recommended)"
  fi
}

check_ram() {
  local kb gb
  kb="$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  gb=$(( kb / 1024 / 1024 ))
  if (( gb >= MIN_RAM_GB )); then
    record PASS "RAM" "${gb} GB (>= ${MIN_RAM_GB} GB)"
  else
    record WARN "RAM" "${gb} GB (< ${MIN_RAM_GB} GB recommended; LLMs may be slow)"
  fi
}

check_cpu() {
  local cores
  cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  if (( cores >= MIN_CPU_CORES )); then
    record PASS "CPU" "${cores} cores (>= ${MIN_CPU_CORES})"
  else
    record WARN "CPU" "${cores} cores (< ${MIN_CPU_CORES} recommended)"
  fi
}

check_disk() {
  local avail_gb
  avail_gb="$(df -BG --output=avail "${JARVIS_ROOT}" 2>/dev/null | tail -n1 | tr -dc '0-9')"
  avail_gb="${avail_gb:-0}"
  if (( avail_gb >= MIN_DISK_GB )); then
    record PASS "Disk Space" "${avail_gb} GB free (>= ${MIN_DISK_GB} GB)"
  else
    record FAIL "Disk Space" "${avail_gb} GB free (< ${MIN_DISK_GB} GB required)"
  fi
}

check_network() {
  if have_cmd curl; then
    if curl -fsS --max-time 8 -o /dev/null "${NETWORK_PROBE_URL}" 2>/dev/null \
       || curl -fsS --max-time 8 -o /dev/null "https://github.com" 2>/dev/null; then
      record PASS "Network Access" "Outbound HTTPS reachable"
    else
      record WARN "Network Access" "Could not reach ${NETWORK_PROBE_URL} (restricted network?)"
    fi
  else
    record WARN "Network Access" "curl not available to probe network"
  fi
}

check_ollama() {
  if have_cmd curl && curl -fsS --max-time 5 -o /dev/null "${OLLAMA_URL}/api/tags" 2>/dev/null; then
    record PASS "Ollama Access" "Reachable at ${OLLAMA_URL}"
  else
    record WARN "Ollama Access" "Not reachable at ${OLLAMA_URL} (will be started by installer)"
  fi
}

# ---------------------------------------------------------------------------
# Reporting.
# ---------------------------------------------------------------------------
print_report() {
  log_section "Environment Validation Report"
  local entry status name detail color sym
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail <<<"${entry}"
    case "${status}" in
      PASS) color="${C_GREEN}";  sym="${SYM_OK}"   ;;
      WARN) color="${C_YELLOW}"; sym="${SYM_WARN}" ;;
      FAIL) color="${C_RED}";    sym="${SYM_FAIL}" ;;
    esac
    printf '  %s%-6s%s %-20s %s\n' "${color}" "${sym}" "${C_RESET}" "${name}" "${detail}" >&2
  done
  printf '\n  %sPASS=%d  WARN=%d  FAIL=%d%s\n\n' "${C_BOLD}" "${PASS}" "${WARN}" "${FAIL}" "${C_RESET}" >&2
}

print_json() {
  local entry status name detail first=1
  printf '{"component":"validate","results":['
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r status name detail <<<"${entry}"
    [[ "${first}" == 0 ]] && printf ','
    first=0
    printf '{"check":"%s","status":"%s","detail":"%s"}' \
      "${name}" "${status}" "$(printf '%s' "${detail}" | sed 's/"/\\"/g')"
  done
  printf '],"summary":{"pass":%d,"warn":%d,"fail":%d}}\n' "${PASS}" "${WARN}" "${FAIL}"
}

main() {
  local json=0 strict=0 quiet=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json)   json=1 ;;
      --strict) strict=1 ;;
      --quiet)  quiet=1 ;;
      -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) log_error "Unknown option: $1"; exit 2 ;;
    esac
    shift
  done

  log_info "Validating environment for Jarvis installation"
  check_os
  check_wsl
  check_ubuntu
  check_docker
  check_compose
  check_ram
  check_cpu
  check_disk
  check_network
  check_ollama

  [[ "${json}" == 1 ]] && print_json
  [[ "${quiet}" == 0 && "${json}" == 0 ]] && print_report

  if (( FAIL > 0 )); then
    log_error "Validation failed: ${FAIL} required check(s) did not pass"
    exit 1
  fi
  if (( strict == 1 && WARN > 0 )); then
    log_error "Validation failed under --strict: ${WARN} warning(s)"
    exit 1
  fi
  log_ok "Environment validation passed"
  exit 0
}

main "$@"
