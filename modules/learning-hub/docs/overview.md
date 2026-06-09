# Learning Hub — architecture & operations

## Goal
A demoable **read → learn → certify** loop on top of the existing Jarvis stack,
shipped as one self-contained module without touching any other module.

## Pipeline (Workflow A — Publication + Course)
```
Schedule / Run Now / On Command
  → Enabled? (schedule only)
  → Load Sources (config/learning-hub-sources.txt)
  → Fetch Sources (RSS, graceful)
  → Aggregate Sources (news digest, reduced-coverage fallback)
  → Use Claude? → AI Analyst (Claude|Ollama)   [prompt: learning-hub.analyst]
  → Prep Magazine (parse JSON + cover prompt)
  → Generate Cover (image provider, graceful)
  → Render Magazine (premium A4 HTML, inline CSS)
  → PDF Input → Gotenberg PDF
  → Write Magazine (PDF + HTML + JSON archive -> reports/learning-hub)
  → Build Course Source (grounding text + ids + 30-day window)
  → Run E-learning (Execute Workflow -> Workflow B)
  → Register Publication (upsert reports/learning-hub/publications.json)
```

## Pipeline (Workflow B — Course from magazine)
A copy of the awareness e-learning pipeline (so the existing module is untouched):
`On Command / Run Manually → Resolve Input → Use Claude? → AI → Prep Content →
Generate Section Images → Render HTML → Package & Write`. Differences: it accepts a
magazine `source` grounding + a `title`/`publicationId`/`courseId`; the AI is told
to base the course strictly on the supplied edition; the rendered lesson embeds the
ids, posts a `jarvis:complete` message to the dashboard when finished, and supports a
`#cert?name=` deep link to open straight to the certificate.

## Dashboard
Static SPA (`dashboard/`) served by an nginx container that also mounts `reports/`
read-only at the same origin, so the magazine PDF, the course HTML and the dashboard
share one origin (iframe + `postMessage` + `localStorage` all work). It reads
`reports/learning-hub/publications.json`, renders a card per edition (read magazine /
start course / status / deadline countdown → "Overdue" after 30 days, non-blocking),
and keeps progress + a certificate library in `localStorage` (single-user demo).

## Data contracts
- **publications.json**: `{ updated, publications: [ { id, title, releaseDate,
  deadlineDays, magazine:{pdf,html}, course:{id,html,title,passMark} } ] }`.
- **completion message** (course → dashboard): `{ type:'jarvis:complete',
  publicationId, courseId, learner, score, passed, date, title }`.

## Build
The render/code-node logic is authored as fragments and assembled into the two
workflow JSONs by a dev-time build script (kept outside the repo). The committed
source of truth is the workflow JSON under `workflows/`.

## Upgrade paths
- Persist progress server-side via a small webhook → `reports/learning-hub/progress.json`
  (multi-device) instead of localStorage.
- Hard-lock the course after the 30-day deadline (currently warn-only).
- Add a Telegram command (registry-driven) without editing the core assistant.
