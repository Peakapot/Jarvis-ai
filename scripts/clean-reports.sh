#!/usr/bin/env bash
# =============================================================================
# clean-reports.sh — Remove all generated content so you can start fresh
# -----------------------------------------------------------------------------
# Deletes every generated asset under reports/ — awareness toolkit output,
# intelligence briefs, Learning Hub publications (incl. publications.json) and
# the archive — while PRESERVING the directory scaffold, the tracked `.gitkeep`
# markers and any `portal.json` branding override (Fail-safe defaults).
#
# After cleaning it re-creates the standard report directories and makes them
# writable by the n8n container, so the next workflow run can write immediately.
#
# Safe to run repeatedly (Idempotent). Asks for confirmation unless --yes (or
# JARVIS_ASSUME_YES=1) is given; --dry-run previews without deleting.
#
# Usage:
#   scripts/clean-reports.sh [--dry-run] [--yes|-y] [--keep-archive]
#
# Options:
#   --dry-run        Show what would be removed; delete nothing.
#   --yes, -y        Do not prompt for confirmation (also: JARVIS_ASSUME_YES=1).
#   --keep-archive   Leave reports/archive/** untouched.
#   -h, --help       Show this help.
#
# Note on permissions: report files are written by the n8n container (often a
# different uid than your host user). If deletion is blocked, re-run with sudo,
# or from inside the container, e.g.:
#   docker compose run --rm -u root --no-deps --entrypoint sh n8n \
#     -c 'rm -rf /reports/* && echo done'   (the gitkeeps will be restored on next install)
# =============================================================================
set -o errexit -o nounset -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
log_init "clean-reports"

REPORTS_DIR="${JARVIS_ROOT}/reports"

DRY_RUN=0
KEEP_ARCHIVE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=1 ;;
    -y|--yes)       export JARVIS_ASSUME_YES=1 ;;
    --keep-archive) KEEP_ARCHIVE=1 ;;
    -h|--help)      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)              log_error "Unknown option: $1"; exit 2 ;;
  esac
  shift
done

# Standard report scaffold (mirrors install.sh) — re-created after cleaning.
SCAFFOLD_DIRS=(
  "learning-hub" "archive/learning-hub"
  "awareness" "awareness/posters" "awareness/quiz" "awareness/tabletop"
  "awareness/tips" "awareness/teachable" "awareness/kpi" "awareness/calendar"
  "awareness/video" "awareness/signage" "awareness/elearning"
  "awareness/certificates" "awareness/comics"
)

if [[ ! -d "${REPORTS_DIR}" ]]; then
  log_warn "No reports directory at ${REPORTS_DIR} — nothing to clean."
  exit 0
fi

# Build the delete list: every regular file/symlink under reports/, EXCEPT the
# tracked .gitkeep markers and any portal.json branding override. Optionally skip
# the archive tree. NUL-delimited to survive spaces/newlines in names.
declare -a PRUNE=()
[[ "${KEEP_ARCHIVE}" == 1 ]] && PRUNE+=(-path "${REPORTS_DIR}/archive" -prune -o)

mapfile -d '' -t TARGETS < <(
  find "${REPORTS_DIR}" "${PRUNE[@]}" \
    \( -type f -o -type l \) \
    ! -name '.gitkeep' ! -name 'portal.json' \
    -print0
)

COUNT="${#TARGETS[@]}"

if (( COUNT == 0 )); then
  log_ok "reports/ is already clean (no generated content found)."
  exit 0
fi

# Human-readable size of what we're about to remove (best-effort).
SIZE="$(printf '%s\0' "${TARGETS[@]}" | du -ch --files0-from=- 2>/dev/null | tail -n1 | cut -f1 || true)"
SIZE="${SIZE:-?}"

log_section "Clean generated reports"
printf '  Target : %s\n' "${REPORTS_DIR}" >&2
printf '  Files  : %s (%s)%s\n' "${COUNT}" "${SIZE}" \
  "$([[ "${KEEP_ARCHIVE}" == 1 ]] && echo '  [keeping archive/]' || echo '')" >&2

if [[ "${DRY_RUN}" == 1 ]]; then
  log_warn "Dry run — the following would be removed:"
  printf '    %s\n' "${TARGETS[@]#${REPORTS_DIR}/}" >&2
  log_ok "Dry run complete. Re-run without --dry-run to delete."
  exit 0
fi

if ! confirm "Permanently delete ${COUNT} generated file(s) under reports/?"; then
  log_warn "Aborted — nothing was deleted."
  exit 0
fi

# Delete, tolerating per-file permission errors (container-owned files) so we can
# report a clear remediation instead of aborting half-way.
FAILED=0
for f in "${TARGETS[@]}"; do
  rm -f -- "${f}" 2>/dev/null || { FAILED=$((FAILED+1)); }
done

# Prune directories that are now empty and not part of the tracked scaffold
# (e.g. one-off subfolders), leaving .gitkeep-backed dirs in place.
find "${REPORTS_DIR}" -mindepth 1 -type d -empty -delete 2>/dev/null || true

# Re-create the standard scaffold and make it writable by the n8n container.
for d in "${SCAFFOLD_DIRS[@]}"; do
  mkdir -p "${REPORTS_DIR}/${d}" 2>/dev/null || true
done
chmod -R a+rwX "${REPORTS_DIR}" 2>/dev/null || true

if (( FAILED > 0 )); then
  log_error "${FAILED} file(s) could not be deleted (likely owned by the n8n container)."
  log_warn  "Re-run with sudo, or remove them from inside the container, e.g.:"
  printf '    docker compose run --rm -u root --no-deps --entrypoint sh n8n -c '\''rm -rf /reports/*'\''\n' >&2
  printf '    (then re-run %s to restore the scaffold)\n' "scripts/clean-reports.sh" >&2
  exit 1
fi

REMOVED=$((COUNT - FAILED))
log_ok "Removed ${REMOVED} generated file(s); report scaffold restored and writable."
log_info "Start fresh: run a workflow, then open the Awareness Portal at http://localhost:${DASHBOARD_PORT:-8088}"
