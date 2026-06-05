#!/usr/bin/env bash
# =============================================================================
# resolve-provider.sh — Provider abstraction resolver
# -----------------------------------------------------------------------------
# Single source of truth for "which provider is active and how do I reach it"
# (AI / Image / Email Provider Abstraction). Reads the relevant *_PROVIDER
# variable from .env, loads the matching descriptor from config/providers/<kind>/
# and prints the resolved, env-substituted connection facts as JSON.
#
# This keeps provider selection a *configuration* concern: workflows and scripts
# call this resolver instead of hard-coding any provider's endpoints or auth.
#
# Usage:
#   scripts/providers/resolve-provider.sh ai      # uses AI_PROVIDER
#   scripts/providers/resolve-provider.sh image   # uses IMAGE_PROVIDER
#   scripts/providers/resolve-provider.sh email   # uses EMAIL_PROVIDER
#   scripts/providers/resolve-provider.sh ai --id claude   # force a specific id
#
# Output: a JSON object on stdout describing the active provider (no secret
# VALUES, only resolved non-secret facts + the env var NAMES that hold secrets).
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"
log_init "providers"
load_env

kind="${1:-}"
[[ -z "${kind}" ]] && log_fatal "Usage: resolve-provider.sh <ai|image|email> [--id ID]"
shift || true

forced_id=""
[[ "${1:-}" == "--id" ]] && { forced_id="$2"; shift 2; }

# Determine the active provider id from the appropriate env var.
case "${kind}" in
  ai)    active="${forced_id:-${AI_PROVIDER:-ollama}}" ;;
  image) active="${forced_id:-${IMAGE_PROVIDER:-openai}}" ;;
  email) active="${forced_id:-${EMAIL_PROVIDER:-smtp}}" ;;
  *) log_fatal "Unknown provider kind: ${kind}" ;;
esac

descriptor="${JARVIS_ROOT}/config/providers/${kind}/${active}.json"
[[ -f "${descriptor}" ]] || log_fatal "No descriptor for ${kind} provider '${active}' (${descriptor})"

# Emit a compact resolved view. jq preferred; degrade gracefully without it.
if have_cmd jq; then
  jq -c --arg kind "${kind}" --arg active "${active}" \
     '{kind:$kind, active:$active, displayName:.displayName, capabilities:.capabilities,
       endpoint:.endpoint, auth:.auth, model:.model, n8nCredentialType:.n8nCredentialType}' \
     "${descriptor}"
else
  log_warn "jq not installed; emitting raw descriptor"
  cat "${descriptor}"
fi
