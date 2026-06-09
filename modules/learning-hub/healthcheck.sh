#!/usr/bin/env bash
# learning-hub — module health check. Verifies the module's assets are present and
# well-formed. Exit 0 = healthy, 1 = problem. Safe to run repeatedly.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
fail=0
ok()   { printf '  OK   %s\n' "$1"; }
bad()  { printf '  FAIL %s\n' "$1"; fail=1; }

jsoncheck() { if command -v jq >/dev/null 2>&1; then jq -e . "$1" >/dev/null 2>&1; else python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$1" >/dev/null 2>&1; fi; }

echo "learning-hub health:"
for f in module.json workflows/learning-hub.json workflows/learning-hub-elearning.json; do
  if [[ -f "${HERE}/${f}" ]] && jsoncheck "${HERE}/${f}"; then ok "${f}"; else bad "${f} (missing or invalid JSON)"; fi
done
for f in dashboard/index.html dashboard/app.js dashboard/styles.css prompts/analyst.md prompts/course.md; do
  if [[ -f "${HERE}/${f}" ]]; then ok "${f}"; else bad "${f} (missing)"; fi
done
if [[ -f "${ROOT}/config/learning-hub-sources.txt" ]]; then ok "config/learning-hub-sources.txt"; else bad "config/learning-hub-sources.txt (missing)"; fi
if [[ -f "${ROOT}/templates/report/learning-hub.html.tpl" ]]; then ok "templates/report/learning-hub.html.tpl"; else bad "templates/report/learning-hub.html.tpl (missing)"; fi

if [[ "${fail}" -eq 0 ]]; then echo "learning-hub: healthy"; else echo "learning-hub: unhealthy"; fi
exit "${fail}"
