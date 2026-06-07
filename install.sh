#!/usr/bin/env bash
# =============================================================================
# install.sh — Jarvis bootstrap installer (idempotent, re-runnable)
# -----------------------------------------------------------------------------
# Single entry point to stand up the entire Jarvis stack with minimal host
# modification (Docker First). Implements the project's Bootstrap Philosophy:
# detect existing state, skip completed tasks, repair broken tasks and continue
# safely. Running it again after a failure resumes where it left off — no manual
# cleanup required.
#
# Stages (each tracked as an idempotent task):
#   1. Pre-flight environment validation        (scripts/validate.sh)
#   2. Configuration bootstrap                   (.env from .env.example)
#   3. Directory & permission scaffolding
#   4. Docker network & volume provisioning
#   5. Stack start                               (docker compose up -d)
#   6. Ollama model pull                         (default provider)
#   7. Workflow import                           (workflows as source code)
#   8. Intelligence product registration         (registry-driven, idempotent)
#   9. Post-install health check                 (scripts/healthcheck.sh)
#  10. Readiness report
#
# Usage:
#   ./install.sh [--reset] [--skip-validate] [--yes] [--no-pull]
#     --reset          clear all task state and start fresh (does NOT delete data)
#     --skip-validate  skip pre-flight validation (not recommended)
#     --yes            non-interactive; accept defaults (CI-friendly)
#     --no-pull        do not pull Ollama models (offline installs)
# =============================================================================
set -o errexit -o nounset -o pipefail

JARVIS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export JARVIS_ROOT
# shellcheck source=scripts/lib/common.sh
source "${JARVIS_ROOT}/scripts/lib/common.sh"
# shellcheck source=scripts/lib/intelligence.sh
source "${JARVIS_ROOT}/scripts/lib/intelligence.sh"
log_init "installer"

SKIP_VALIDATE=0
NO_PULL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset) state_reset_all; log_ok "Task state reset" ;;
    --skip-validate) SKIP_VALIDATE=1 ;;
    --yes) export JARVIS_ASSUME_YES=1 ;;
    --no-pull) NO_PULL=1 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_fatal "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

state_init

banner() {
  cat >&2 <<'EOF'
   _   _   _   _   _
  | | | |_| |_| | | |   JARVIS — Personal AI Assistant Platform
  |_| |_| |_| |_| |_|   Docker-first · Modular · Recoverable
EOF
}

# ---------------------------------------------------------------------------
# Stage 1 — Validation.
# ---------------------------------------------------------------------------
stage_validate() {
  if (( SKIP_VALIDATE == 1 )); then
    log_warn "Skipping pre-flight validation (--skip-validate)"
    return 0
  fi
  "${JARVIS_ROOT}/scripts/validate.sh" || log_fatal "Pre-flight validation failed. Resolve the issues above and re-run ./install.sh"
}

# ---------------------------------------------------------------------------
# Stage 2 — Configuration bootstrap. Generates a local-only .env from the
# tracked .env.example, generating secrets where appropriate. Never overwrites
# an existing .env (Idempotent + Security by default).
# ---------------------------------------------------------------------------
stage_config() {
  local example="${JARVIS_ROOT}/.env.example"
  [[ -f "${example}" ]] || log_fatal "Missing .env.example (corrupt checkout?)"
  if [[ -f "${JARVIS_ENV_FILE}" ]]; then
    log_ok "Configuration already exists at .env (leaving untouched)"
  else
    cp "${example}" "${JARVIS_ENV_FILE}"
    chmod 600 "${JARVIS_ENV_FILE}"
    # Generate a strong n8n encryption key locally if the placeholder is present.
    if grep -q '^N8N_ENCRYPTION_KEY=$' "${JARVIS_ENV_FILE}" 2>/dev/null \
       || grep -q '^N8N_ENCRYPTION_KEY=changeme' "${JARVIS_ENV_FILE}" 2>/dev/null; then
      local key
      key="$(head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 40)"
      sed -i "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${key}|" "${JARVIS_ENV_FILE}"
      log_ok "Generated local n8n encryption key"
    fi
    log_ok "Created .env from .env.example (chmod 600)"
    log_warn "Edit .env to add credentials (Telegram/Email/etc.) then re-run if needed"
  fi
  load_env
}

# ---------------------------------------------------------------------------
# Stage 3 — Scaffolding. Ensure runtime directories exist with safe perms.
# ---------------------------------------------------------------------------
stage_scaffold() {
  local d
  for d in logs backups reports state reports/cyber-brief reports/archive \
           logs/diagnostics data; do
    mkdir -p "${JARVIS_ROOT}/${d}"
  done
  chmod 700 "${JARVIS_ROOT}/state" 2>/dev/null || true
  # The n8n container writes reports/logs as its own uid (node=1000), which may
  # differ from the host user's uid. Make these bind-mounted trees writable by
  # any uid so workflow file-writes succeed (host files stay readable).
  chmod -R a+rwX "${JARVIS_ROOT}/reports" "${JARVIS_ROOT}/logs" 2>/dev/null || true
  log_ok "Runtime directories ready"
}

# ---------------------------------------------------------------------------
# Stage 4 — Docker network/volumes. Compose manages these, but we create the
# external network up-front so multiple modules can share it (Modular).
# ---------------------------------------------------------------------------
stage_docker_network() {
  require_cmd docker
  local net="${JARVIS_DOCKER_NETWORK:-jarvis-net}"
  if docker network inspect "${net}" >/dev/null 2>&1; then
    log_ok "Docker network '${net}' already exists"
  else
    docker network create "${net}" >/dev/null && log_ok "Created docker network '${net}'"
  fi
}

# ---------------------------------------------------------------------------
# Stage 5 — Start the stack.
# ---------------------------------------------------------------------------
stage_stack_up() {
  ( cd "${JARVIS_ROOT}" && compose up -d ) || log_fatal "docker compose up failed (see logs)"
  log_ok "Stack started"
  # Wait for n8n to become healthy (bounded).
  local url="${N8N_BASE_URL:-http://localhost:5678}"
  for _ in $(seq 1 30); do
    if curl -fsS --max-time 4 -o /dev/null "${url}/healthz" 2>/dev/null \
       || curl -fsS --max-time 4 -o /dev/null "${url}" 2>/dev/null; then
      log_ok "n8n is up at ${url}"
      return 0
    fi
    sleep 3
  done
  log_warn "n8n did not report healthy within timeout; continuing (check logs)"
}

# ---------------------------------------------------------------------------
# Stage 6 — Pull the default Ollama model (Ollama is the default provider).
# ---------------------------------------------------------------------------
stage_ollama_pull() {
  if (( NO_PULL == 1 )); then
    log_warn "Skipping Ollama model pull (--no-pull)"
    return 0
  fi
  local model="${OLLAMA_DEFAULT_MODEL:-llama3.1:8b}"
  local svc="${OLLAMA_SERVICE_NAME:-ollama}"
  log_info "Pulling Ollama model '${model}' (first run can take a while)"
  if ( cd "${JARVIS_ROOT}" && compose exec -T "${svc}" ollama pull "${model}" ); then
    log_ok "Ollama model '${model}' ready"
  else
    log_warn "Could not pull '${model}' (offline?). You can run later: compose exec ${svc} ollama pull ${model}"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Stage 7 — Import workflows.
# ---------------------------------------------------------------------------
stage_workflows() {
  "${JARVIS_ROOT}/scripts/workflows/workflow-import.sh" \
    || log_warn "Some workflows failed to import (re-run after fixing; install continues)"
}

# ---------------------------------------------------------------------------
# Stage 8 — Register intelligence products. Registry-driven (no hardcoded list):
# ensures each product's report/archive directories exist and reports its
# schedule. Future products appear here automatically once added to
# config/intelligence/products.json (Future expansion).
# ---------------------------------------------------------------------------
stage_intelligence() {
  local ids id name reportdir archivedir sched_var sched_def count=0
  ids="$(intel_ids)"
  if [[ -z "${ids}" ]]; then
    log_warn "No intelligence products registered (jq missing or empty registry)"
    return 0
  fi
  while IFS= read -r id; do
    [[ -z "${id}" ]] && continue
    count=$((count+1))
    name="$(intel_field "${id}" name)"
    reportdir="$(intel_field "${id}" reportDir)"
    archivedir="$(intel_field "${id}" archiveDir)"
    sched_var="$(intel_field "${id}" scheduleEnv)"
    sched_def="$(intel_field "${id}" scheduleDefault)"
    [[ -n "${reportdir}" ]] && { mkdir -p "${JARVIS_ROOT}/${reportdir}"; chmod -R a+rwX "${JARVIS_ROOT}/${reportdir}" 2>/dev/null || true; }
    [[ -n "${archivedir}" ]] && { mkdir -p "${JARVIS_ROOT}/${archivedir}"; chmod -R a+rwX "${JARVIS_ROOT}/${archivedir}" 2>/dev/null || true; }
    if intel_enabled "${id}"; then
      log_ok "Intelligence product '${name}' enabled — schedule ${!sched_var:-${sched_def}}"
    else
      log_info "Intelligence product '${name}' present but disabled ($(intel_field "${id}" enabledEnv)=false)"
    fi
  done <<<"${ids}"
  log_ok "Registered ${count} intelligence product(s)"
}

# ---------------------------------------------------------------------------
# Stage 8/9 — Health + readiness report.
# ---------------------------------------------------------------------------
stage_health() {
  "${JARVIS_ROOT}/scripts/healthcheck.sh" || log_warn "Health check reported issues (see report above)"
}

readiness_report() {
  local report
  report="${JARVIS_ROOT}/reports/readiness-$(date -u +%Y%m%dT%H%M%SZ).txt"
  {
    echo "Jarvis Readiness Report"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "======================================="
    echo
    echo "## Task state"
    state_status
    echo
    echo "## Health check"
    "${JARVIS_ROOT}/scripts/healthcheck.sh" --json 2>/dev/null || true
    echo
    echo "## Next steps"
    echo " - Open n8n at ${N8N_BASE_URL:-http://localhost:5678}"
    echo " - Send your Telegram bot a /help message"
    echo " - Review docs/operations.md for daily operations"
  } >"${report}"
  log_ok "Readiness report written: ${report}"
  cat "${report}" >&2 || true
}

main() {
  banner
  log_section "Jarvis installation starting"
  ensure_task "01-validate"        "Stage 1/10 · Validate environment"   stage_validate
  ensure_task "02-config"          "Stage 2/10 · Bootstrap configuration" stage_config
  # config must be loaded for later stages even if already done.
  load_env
  ensure_task "03-scaffold"        "Stage 3/10 · Create directories"     stage_scaffold
  ensure_task "04-docker-network"  "Stage 4/10 · Provision docker network" stage_docker_network
  ensure_task "05-stack-up"        "Stage 5/10 · Start stack"            stage_stack_up
  # Model pull and workflow import are allowed to fail without blocking re-runs.
  ensure_task "06-ollama-pull"     "Stage 6/10 · Pull default model"     stage_ollama_pull || true
  ensure_task "07-workflows"       "Stage 7/10 · Import workflows"       stage_workflows || true
  # Intelligence registration is idempotent; always reconcile (not state-gated)
  # so newly-added products are picked up on re-runs.
  run_step "Stage 8/10 · Register intelligence products" stage_intelligence || true
  stage_health
  readiness_report
  log_ok "Installation complete. Re-run ./install.sh any time; completed steps are skipped."
}

main "$@"
