#!/usr/bin/env bash
# =============================================================================
# intelligence.sh — Shared helpers for Jarvis intelligence products
# -----------------------------------------------------------------------------
# Single place that understands the Intelligence Product Registry
# (config/intelligence/products.json). The installer, validation, health,
# status and backup frameworks all consume these helpers so that adding a new
# intelligence product is a *registry* change, never a code change in those
# frameworks (Configuration over hard coding, Future expansion).
#
# Provided functions:
#   intel_registry_file              -> path to products.json
#   intel_ids                        -> newline list of product ids
#   intel_field <id> <jq-path>       -> read a field (e.g. .name, .scheduleDefault)
#   intel_enabled <id>               -> 0 if the product is enabled in env, else 1
#   intel_checks <id>                -> emit "STATUS|check|detail" lines (no side effects)
#
# intel_checks output uses the platform-wide STATUS vocabulary
# (PASS|WARN|FAIL|SKIP) so any caller can fold it into its own report.
#
# This file is a library: source it, do not execute it.
# =============================================================================

[[ -n "${__JARVIS_INTELLIGENCE_SH:-}" ]] && return 0
__JARVIS_INTELLIGENCE_SH=1

__intel_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_ROOT="${JARVIS_ROOT:-$(cd "${__intel_dir}/../.." && pwd)}"
export JARVIS_ROOT

intel_registry_file() {
  echo "${JARVIS_INTEL_REGISTRY:-${JARVIS_ROOT}/config/intelligence/products.json}"
}

# intel_ids — list product ids (requires jq; degrades to empty).
intel_ids() {
  local f; f="$(intel_registry_file)"
  [[ -f "${f}" ]] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r '.products[].id' "${f}" 2>/dev/null
  fi
}

# intel_field <id> <jq-path-without-leading-dot-ok> — e.g. intel_field energy-intelligence name
intel_field() {
  local id="$1" field="$2" f; f="$(intel_registry_file)"
  [[ -f "${f}" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  jq -r --arg id "${id}" ".products[] | select(.id==\$id) | .${field} // \"\"" "${f}" 2>/dev/null
}

# intel_enabled <id> — consults the product's enabledEnv against the environment.
intel_enabled() {
  local id="$1" var def val
  var="$(intel_field "${id}" enabledEnv)"
  def="$(intel_field "${id}" enabledDefault)"
  [[ -z "${var}" ]] && return 0
  val="${!var:-${def:-true}}"
  [[ "${val,,}" == "true" ]]
}

# intel_checks <id> — print "STATUS|check|detail" lines for one product.
# Non-mutating and dependency-light; safe to call from any health/status code.
intel_checks() {
  local id="$1"
  local name sources reportdir archivedir sched_var sched_def
  name="$(intel_field "${id}" name)"; name="${name:-${id}}"

  # Enablement.
  if intel_enabled "${id}"; then
    printf 'PASS|%s|enabled\n' "${id}"
  else
    printf 'SKIP|%s|disabled via %s\n' "${id}" "$(intel_field "${id}" enabledEnv)"
    return 0
  fi

  # Workflow file present (source of truth).
  local wf; wf="$(intel_field "${id}" workflow)"
  if [[ -n "${wf}" && -f "${JARVIS_ROOT}/${wf}" ]]; then
    printf 'PASS|%s.workflow|%s\n' "${id}" "${wf}"
  else
    printf 'FAIL|%s.workflow|missing %s\n' "${id}" "${wf}"
  fi

  # Sources file present (if the product uses one).
  sources="$(intel_field "${id}" sourcesFile)"
  if [[ -n "${sources}" ]]; then
    if [[ -f "${JARVIS_ROOT}/${sources}" ]]; then
      local n
      n="$(grep -cvE '^\s*(#|$)' "${JARVIS_ROOT}/${sources}" 2>/dev/null || echo 0)"
      printf 'PASS|%s.sources|%s source(s) in %s\n' "${id}" "${n}" "${sources}"
    else
      printf 'WARN|%s.sources|missing %s\n' "${id}" "${sources}"
    fi
  fi

  # Report/archive directories.
  reportdir="$(intel_field "${id}" reportDir)"
  archivedir="$(intel_field "${id}" archiveDir)"
  if [[ -n "${reportdir}" && -d "${JARVIS_ROOT}/${reportdir}" ]]; then
    printf 'PASS|%s.reports|%s ready\n' "${id}" "${reportdir}"
  elif [[ -n "${reportdir}" ]]; then
    printf 'WARN|%s.reports|%s not created yet\n' "${id}" "${reportdir}"
  fi

  # Latest archived edition (Historical Archive observability).
  if [[ -n "${archivedir}" && -d "${JARVIS_ROOT}/${archivedir}" ]]; then
    local latest
    latest="$(find "${JARVIS_ROOT}/${archivedir}" -type f -name '*.html' 2>/dev/null | sort | tail -n1)"
    if [[ -n "${latest}" ]]; then
      printf 'PASS|%s.archive|latest %s\n' "${id}" "$(basename "${latest}")"
    else
      printf 'SKIP|%s.archive|no editions archived yet\n' "${id}"
    fi
  fi

  # Schedule (informational).
  sched_var="$(intel_field "${id}" scheduleEnv)"
  sched_def="$(intel_field "${id}" scheduleDefault)"
  printf 'PASS|%s.schedule|%s (%s)\n' "${id}" "${!sched_var:-${sched_def}}" "${sched_var}"
}

export -f intel_registry_file intel_ids intel_field intel_enabled intel_checks 2>/dev/null || true
