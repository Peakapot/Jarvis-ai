#!/usr/bin/env bash
# =============================================================================
# diagnostics.sh — Incident diagnostics bundle generator
# -----------------------------------------------------------------------------
# Collects a redacted, self-contained snapshot of the system for
# troubleshooting and support (Observability by default). Produces a single
# timestamped tarball under logs/diagnostics/ that can be safely shared:
# secrets from .env are NEVER included; only key names are listed.
#
# Captured:
#   - validate.sh and healthcheck.sh JSON output
#   - status.sh JSON
#   - docker/compose state, container logs (tail), versions
#   - disk/memory/cpu snapshot
#   - tails of each component log
#   - workflow inventory and integrity summary
#   - .env key names (values redacted)
#
# Usage: scripts/diagnostics.sh [--no-archive]
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
log_init "diagnostics"
load_env

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${JARVIS_ROOT}/logs/diagnostics/${STAMP}"
mkdir -p "${OUT_DIR}"

capture() { # filename description command...
  local file="$1" desc="$2"; shift 2
  log_info "Capturing ${desc}"
  { echo "### ${desc}"; echo "### \$ $*"; echo; "$@" 2>&1 || echo "(command failed: $*)"; } \
    >"${OUT_DIR}/${file}" 2>&1 || true
}

log_section "Generating diagnostics bundle: ${STAMP}"

# System.
capture "system.txt"   "System info"     bash -c 'uname -a; echo; cat /etc/os-release 2>/dev/null'
capture "resources.txt" "Resources"      bash -c 'echo "== memory =="; free -h; echo; echo "== cpu =="; nproc; echo; echo "== disk =="; df -h'

# Docker.
if have_cmd docker; then
  capture "docker-version.txt" "Docker versions" bash -c 'docker version; echo; docker compose version 2>/dev/null'
  capture "docker-ps.txt"      "Docker ps"       docker ps -a
  ( cd "${JARVIS_ROOT}" && capture "compose-ps.txt" "Compose ps" compose ps )
  # Per-service log tails (bounded).
  if [[ -f "${JARVIS_ROOT}/docker-compose.yml" ]]; then
    while IFS= read -r svc; do
      [[ -z "${svc}" ]] && continue
      # </dev/null so 'compose logs' can't consume the loop's stdin (the
      # services list) and skip the remaining services.
      ( cd "${JARVIS_ROOT}" && compose logs --tail=200 "${svc}" >"${OUT_DIR}/compose-log-${svc}.txt" 2>&1 </dev/null || true )
    done < <( cd "${JARVIS_ROOT}" && compose config --services 2>/dev/null || true )
  fi
else
  echo "docker not installed" >"${OUT_DIR}/docker-version.txt"
fi

# Validation + health snapshots (best-effort; never abort the bundle).
( "${SCRIPT_DIR}/validate.sh"   --json >"${OUT_DIR}/validate.json"   2>/dev/null ) || true
( "${SCRIPT_DIR}/healthcheck.sh" --json >"${OUT_DIR}/healthcheck.json" 2>/dev/null ) || true
( "${SCRIPT_DIR}/status.sh"     --json >"${OUT_DIR}/status.json"     2>/dev/null ) || true

# Component log tails.
mkdir -p "${OUT_DIR}/logs"
shopt -s nullglob
for lf in "${JARVIS_ROOT}/logs/"*.log; do
  tail -n 300 "${lf}" >"${OUT_DIR}/logs/$(basename "${lf}")" 2>/dev/null || true
done
shopt -u nullglob

# Workflow inventory + integrity.
( "${SCRIPT_DIR}/workflows/workflow-validate.sh" >"${OUT_DIR}/workflow-integrity.txt" 2>&1 ) || true
find "${JARVIS_ROOT}/workflows" -name '*.json' 2>/dev/null | sort >"${OUT_DIR}/workflow-inventory.txt" || true

# .env key names ONLY (values redacted — Security by default).
if [[ -f "${JARVIS_ENV_FILE}" ]]; then
  { echo "### .env keys (values redacted)";
    grep -vE '^\s*#' "${JARVIS_ENV_FILE}" | grep -E '=' | sed -E 's/=.*/=<redacted>/' | sort; } \
    >"${OUT_DIR}/env-keys.txt" 2>/dev/null || true
fi

# Bundle.
if [[ "${1:-}" != "--no-archive" ]]; then
  local_tar="${JARVIS_ROOT}/logs/diagnostics/jarvis-diagnostics-${STAMP}.tar.gz"
  tar -czf "${local_tar}" -C "${JARVIS_ROOT}/logs/diagnostics" "${STAMP}" 2>/dev/null || true
  log_ok "Diagnostics bundle: ${local_tar}"
  echo "${local_tar}"
else
  log_ok "Diagnostics written to: ${OUT_DIR}"
  echo "${OUT_DIR}"
fi
