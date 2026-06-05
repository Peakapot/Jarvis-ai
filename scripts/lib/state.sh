#!/usr/bin/env bash
# =============================================================================
# state.sh — Idempotent task-state tracking for the bootstrap installer
# -----------------------------------------------------------------------------
# Backs the "Bootstrap Philosophy" requirement: install.sh must be re-runnable,
# detect existing state, skip completed tasks, repair broken tasks and continue
# safely.
#
# State is recorded as marker files under <repo>/state/tasks/. Each task has a
# single marker whose contents record the completion status and timestamp:
#
#   state/tasks/<task-id>   ->   "done 2026-06-05T12:00:00Z"
#
# This is deliberately filesystem-based (no database dependency) so recovery is
# trivial: delete a marker to force a step to re-run; delete the directory to
# start clean. Markers live outside Git (see .gitignore).
#
# Usage:
#   state_init
#   if state_is_done "docker-network"; then ... ; fi
#   state_mark_done "docker-network"
#   state_clear "docker-network"
#
# This file is a library: source it, do not execute it.
# =============================================================================

[[ -n "${__JARVIS_STATE_SH:-}" ]] && return 0
__JARVIS_STATE_SH=1

__state_dir_self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$(cd "${__state_dir_self}/../.." && pwd)}"
JARVIS_STATE_DIR="${JARVIS_STATE_DIR:-${JARVIS_ROOT}/state/tasks}"
export JARVIS_ROOT JARVIS_STATE_DIR

state_init() {
  mkdir -p "${JARVIS_STATE_DIR}" 2>/dev/null || true
}

# state_is_done <task-id>
state_is_done() {
  [[ -f "${JARVIS_STATE_DIR}/$1" ]] && grep -q '^done ' "${JARVIS_STATE_DIR}/$1" 2>/dev/null
}

# state_mark_done <task-id>
state_mark_done() {
  state_init
  printf 'done %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"${JARVIS_STATE_DIR}/$1"
}

# state_mark_failed <task-id> [reason]
state_mark_failed() {
  state_init
  printf 'failed %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${2:-}" >"${JARVIS_STATE_DIR}/$1"
}

# state_clear <task-id> — force a task to re-run on next invocation.
state_clear() {
  rm -f "${JARVIS_STATE_DIR}/$1"
}

# state_reset_all — wipe all task state (full clean re-install).
state_reset_all() {
  rm -rf "${JARVIS_STATE_DIR}"
  state_init
}

# state_status — print a summary table of known task states.
state_status() {
  state_init
  local f name status
  shopt -s nullglob
  for f in "${JARVIS_STATE_DIR}"/*; do
    name="$(basename "${f}")"
    status="$(cat "${f}" 2>/dev/null)"
    printf '  %-28s %s\n' "${name}" "${status}"
  done
  shopt -u nullglob
}

# ensure_task <task-id> "Description" command... — run a step only if not done,
# marking state appropriately. This is the workhorse for idempotent installs.
ensure_task() {
  local id="$1" desc="$2"; shift 2
  state_init
  if state_is_done "${id}"; then
    log_ok "${desc} (already complete — skipping)"
    return 0
  fi
  log_info "${desc}"
  if "$@"; then
    state_mark_done "${id}"
    log_ok "${desc}"
    return 0
  else
    local rc=$?
    state_mark_failed "${id}" "exit=${rc}"
    log_error "${desc} (exit ${rc})"
    return "${rc}"
  fi
}

export -f state_init state_is_done state_mark_done state_mark_failed \
  state_clear state_reset_all state_status ensure_task 2>/dev/null || true
