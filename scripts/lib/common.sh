#!/usr/bin/env bash
# =============================================================================
# common.sh — Shared helpers for all Jarvis shell scripts
# -----------------------------------------------------------------------------
# Centralises behaviour that would otherwise be copy-pasted across scripts:
# strict mode, repo-root resolution, .env loading, command/version checks,
# comparison helpers and small UX utilities.
#
# Sourcing this file also sources logging.sh and colors.sh, so a script needs
# only one line of boilerplate:
#
#   source "$(dirname "$0")/lib/common.sh"
#
# This file is a library: source it, do not execute it.
# =============================================================================

[[ -n "${__JARVIS_COMMON_SH:-}" ]] && return 0
__JARVIS_COMMON_SH=1

# ---------------------------------------------------------------------------
# Strict mode (Fail-safe defaults). Callers may opt out by setting
# JARVIS_NO_STRICT=1 before sourcing (rarely needed).
# ---------------------------------------------------------------------------
if [[ -z "${JARVIS_NO_STRICT:-}" ]]; then
  set -o errexit
  set -o nounset
  set -o pipefail
fi

__common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$(cd "${__common_dir}/../.." && pwd)}"
export JARVIS_ROOT

# shellcheck source=scripts/lib/logging.sh
source "${__common_dir}/logging.sh"
# shellcheck source=scripts/lib/state.sh
source "${__common_dir}/state.sh"

# ---------------------------------------------------------------------------
# Environment / configuration loading (Configuration over hard coding).
# Loads <repo>/.env if present. Never fails if absent so validation can run on
# a fresh checkout.
# ---------------------------------------------------------------------------
JARVIS_ENV_FILE="${JARVIS_ENV_FILE:-${JARVIS_ROOT}/.env}"

load_env() {
  local file="${1:-${JARVIS_ENV_FILE}}"
  if [[ -f "${file}" ]]; then
    log_debug "Loading environment from ${file}"
    set -o allexport
    # shellcheck disable=SC1090
    source "${file}"
    set +o allexport
    return 0
  fi
  log_debug "No env file at ${file} (this is expected before install)"
  return 0
}

# require_env VAR [VAR...] — fail if any named variable is empty/unset.
require_env() {
  local missing=0 var
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      log_error "Required configuration '${var}' is not set"
      missing=1
    fi
  done
  return "${missing}"
}

# ---------------------------------------------------------------------------
# Command / dependency helpers.
# ---------------------------------------------------------------------------
have_cmd() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  local cmd
  for cmd in "$@"; do
    if ! have_cmd "${cmd}"; then
      log_fatal "Required command '${cmd}' not found in PATH"
    fi
  done
}

# semver_ge A B — true (0) if version A >= version B. Tolerant of prefixes.
semver_ge() {
  local a="${1//[^0-9.]/}" b="${2//[^0-9.]/}"
  [[ "$(printf '%s\n%s\n' "$b" "$a" | sort -V | tail -n1)" == "$a" ]]
}

# ---------------------------------------------------------------------------
# UX helpers.
# ---------------------------------------------------------------------------
# confirm "Question?" — returns 0 for yes. Honours JARVIS_ASSUME_YES for
# non-interactive / CI runs (Idempotent, automatable).
confirm() {
  local prompt="${1:-Are you sure?}" reply
  if [[ "${JARVIS_ASSUME_YES:-0}" == "1" || ! -t 0 ]]; then
    return 0
  fi
  read -r -p "${prompt} [y/N] " reply
  [[ "${reply}" =~ ^[Yy] ]]
}

# prompt_default VAR "Prompt" "default" — read a value with a default fallback.
prompt_default() {
  local __var="$1" __prompt="$2" __default="${3:-}" __reply
  if [[ "${JARVIS_ASSUME_YES:-0}" == "1" || ! -t 0 ]]; then
    printf -v "${__var}" '%s' "${__default}"
    return 0
  fi
  read -r -p "${__prompt} [${__default}] " __reply
  printf -v "${__var}" '%s' "${__reply:-${__default}}"
}

# run_step "Description" command... — log, execute, and report a step.
run_step() {
  local desc="$1"; shift
  log_info "${desc}"
  if "$@"; then
    log_ok "${desc}"
    return 0
  else
    local rc=$?
    log_error "${desc} (exit ${rc})"
    return "${rc}"
  fi
}

# retry N command... — retry with exponential backoff (2,4,8,...).
retry() {
  local max="$1"; shift
  local attempt=1 delay=2
  while true; do
    if "$@"; then return 0; fi
    if (( attempt >= max )); then
      log_error "Command failed after ${max} attempts: $*"
      return 1
    fi
    log_warn "Attempt ${attempt}/${max} failed; retrying in ${delay}s"
    sleep "${delay}"
    delay=$(( delay * 2 ))
    attempt=$(( attempt + 1 ))
  done
}

# ---------------------------------------------------------------------------
# Module workflow discovery (Plugin Architecture). Lets the workflow framework
# treat module-owned workflows as first-class without hardcoding module names.
# ---------------------------------------------------------------------------
# jarvis_module_workflow_dirs — every existing modules/*/workflows directory
# (excludes the _template). Used for validation/backup scope.
jarvis_module_workflow_dirs() {
  local d
  for d in "${JARVIS_ROOT}"/modules/*/workflows; do
    [[ -d "${d}" ]] || continue
    [[ "${d}" == *"/_template/"* ]] && continue
    printf '%s\n' "${d}"
  done
}

# jarvis_autoimport_module_workflow_dirs — only modules whose module.json sets
# "autoImport": true (active products). Used by the importer so planned/scaffold
# modules are not pushed into n8n.
jarvis_autoimport_module_workflow_dirs() {
  local mj dir
  for mj in "${JARVIS_ROOT}"/modules/*/module.json; do
    [[ -f "${mj}" ]] || continue
    dir="$(dirname "${mj}")"
    [[ -d "${dir}/workflows" ]] || continue
    if have_cmd jq; then
      [[ "$(jq -r '.autoImport // false' "${mj}" 2>/dev/null)" == "true" ]] || continue
    else
      grep -q '"autoImport"[[:space:]]*:[[:space:]]*true' "${mj}" || continue
    fi
    printf '%s\n' "${dir}/workflows"
  done
}

# Resolve the docker compose command (plugin v2 preferred, legacy fallback).
compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif have_cmd docker-compose; then
    docker-compose "$@"
  else
    log_fatal "Neither 'docker compose' nor 'docker-compose' is available"
  fi
}

export JARVIS_ENV_FILE
export -f load_env require_env have_cmd require_cmd semver_ge confirm \
  prompt_default run_step retry compose \
  jarvis_module_workflow_dirs jarvis_autoimport_module_workflow_dirs 2>/dev/null || true
