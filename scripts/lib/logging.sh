#!/usr/bin/env bash
# =============================================================================
# logging.sh — Structured logging for all Jarvis shell scripts
# -----------------------------------------------------------------------------
# Implements the project's structured logging contract (Observability by
# default). Every log line is emitted twice:
#
#   1. Human-readable, colorised line to the terminal (stderr).
#   2. Structured JSON line appended to a per-component log file under logs/.
#
# The JSON shape is stable and machine-parseable so it can later be shipped to
# a log aggregator without changing callers:
#
#   {"ts":"2026-06-05T12:00:00Z","level":"info","component":"installer",
#    "msg":"Docker detected","pid":1234,"host":"jarvis"}
#
# Usage:
#   source scripts/lib/logging.sh
#   log_init "installer"        # selects logs/installer.log
#   log_info "Starting"          # -> terminal + JSON
#   log_warn "Low disk space"
#   log_error "Docker missing"
#   log_debug "value=$x"         # only when JARVIS_LOG_LEVEL=debug
#
# Configuration (Configuration over hard coding):
#   JARVIS_LOG_DIR    Directory for log files          (default: <repo>/logs)
#   JARVIS_LOG_LEVEL  debug|info|warn|error            (default: info)
#   JARVIS_LOG_JSON   1 to also echo JSON to terminal  (default: 0)
#
# This file is a library: source it, do not execute it.
# =============================================================================

[[ -n "${__JARVIS_LOGGING_SH:-}" ]] && return 0
__JARVIS_LOGGING_SH=1

# Resolve the directory this library lives in so we can find siblings/repo root
# regardless of the caller's working directory (Stateless / relocatable).
__logging_self="${BASH_SOURCE[0]}"
__logging_dir="$(cd "$(dirname "${__logging_self}")" && pwd)"
# repo root is two levels up from scripts/lib
JARVIS_ROOT="${JARVIS_ROOT:-$(cd "${__logging_dir}/../.." && pwd)}"
export JARVIS_ROOT

# shellcheck source=scripts/lib/colors.sh
source "${__logging_dir}/colors.sh"

JARVIS_LOG_DIR="${JARVIS_LOG_DIR:-${JARVIS_ROOT}/logs}"
JARVIS_LOG_LEVEL="${JARVIS_LOG_LEVEL:-info}"
JARVIS_LOG_JSON="${JARVIS_LOG_JSON:-0}"

# Map level names to numeric severities for threshold comparison.
__log_level_num() {
  case "${1,,}" in
    debug) echo 10 ;;
    info)  echo 20 ;;
    warn)  echo 30 ;;
    error) echo 40 ;;
    *)     echo 20 ;;
  esac
}

# The component label that prefixes every line for the current script.
JARVIS_LOG_COMPONENT="${JARVIS_LOG_COMPONENT:-jarvis}"

# log_init <component> — choose the log file/component for subsequent calls.
log_init() {
  JARVIS_LOG_COMPONENT="${1:-jarvis}"
  mkdir -p "${JARVIS_LOG_DIR}" 2>/dev/null || true
  JARVIS_LOG_FILE="${JARVIS_LOG_DIR}/${JARVIS_LOG_COMPONENT}.log"
  export JARVIS_LOG_COMPONENT JARVIS_LOG_FILE
}

# JSON-escape a string for safe embedding in a log line.
__json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

# Core emitter: __log <level> <color> <symbol> <message...>
__log() {
  local level="$1" color="$2" symbol="$3"; shift 3
  local msg="$*"

  # Threshold check.
  local want got
  want="$(__log_level_num "${JARVIS_LOG_LEVEL}")"
  got="$(__log_level_num "${level}")"
  (( got < want )) && return 0

  local ts pid host
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  pid="$$"
  host="$(hostname 2>/dev/null || echo unknown)"

  # Structured JSON line for the log file.
  local json
  json="{\"ts\":\"${ts}\",\"level\":\"${level}\",\"component\":\"${JARVIS_LOG_COMPONENT}\",\"msg\":\"$(__json_escape "${msg}")\",\"pid\":${pid},\"host\":\"$(__json_escape "${host}")\"}"

  # Append to the per-component log file when available.
  if [[ -n "${JARVIS_LOG_FILE:-}" ]]; then
    printf '%s\n' "${json}" >>"${JARVIS_LOG_FILE}" 2>/dev/null || true
  fi

  # Human-readable to stderr (so stdout stays usable for data/pipelines).
  if [[ "${JARVIS_LOG_JSON}" == "1" ]]; then
    printf '%s\n' "${json}" >&2
  else
    printf '%s%s%s %s%s%s %s\n' \
      "${C_GREY}" "${ts}" "${C_RESET}" \
      "${color}" "${symbol}" "${C_RESET}" \
      "${msg}" >&2
  fi
}

log_debug() { __log debug "${C_GREY}"   "${SYM_INFO}" "$@"; }
log_info()  { __log info  "${C_BLUE}"   "${SYM_INFO}" "$@"; }
log_ok()    { __log info  "${C_GREEN}"  "${SYM_OK}"   "$@"; }
log_warn()  { __log warn  "${C_YELLOW}" "${SYM_WARN}" "$@"; }
log_error() { __log error "${C_RED}"    "${SYM_FAIL}" "$@"; }

# log_section <title> — visual separator for grouped output.
log_section() {
  [[ "$(__log_level_num "${JARVIS_LOG_LEVEL}")" -gt 20 ]] && return 0
  printf '\n%s%s== %s ==%s\n' "${C_BOLD}" "${C_CYAN}" "$*" "${C_RESET}" >&2
}

# log_fatal <message> — log an error then exit non-zero.
log_fatal() {
  log_error "$@"
  exit 1
}

export -f log_init log_debug log_info log_ok log_warn log_error log_section log_fatal 2>/dev/null || true
