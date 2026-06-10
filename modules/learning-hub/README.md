# Learning Hub — Magazine, E-learning & Dashboard

A self-contained Jarvis module that turns **one run** into a complete
**read → learn → certify** loop:

1. **Magazine** — a monthly **staff security-awareness magazine** to consulting-
   publication spec (RSS digest → AI editor → full-bleed cover pass + body pass
   with running header and page-number footers → merged Gotenberg PDF): "At a
   glance" stat band, numbered sections with hairline rules, Exhibit-captioned
   gpt-image-2 cover/feature/threat art, serif pull quote, "The bottom line"
   takeaways.
2. **E-learning** — a **gamified** interactive course **derived strictly from that
   edition** (the magazine content grounds the AI): XP, levels and achievement
   badges; a playable **three.js mini-game** ("Firewall: Threat Storm" — allow or
   block AI-written threat/safe scenarios flying at your firewall, with combos,
   integrity and per-decision educational feedback; auto-falls back to a 2D version
   without WebGL); section images, narration, a scored knowledge check, a
   "questions you missed" review, confetti, and a bedded completion certificate.
   Shipped **both** as self-contained HTML (for the portal) and as a **SCORM 1.2
   package** (`imsmanifest.xml`, mastery score) for any corporate LMS. The vendored
   `config/vendor/three.min.js` (MIT) is inlined so packages work offline in
   locked-down LMS networks.
3. **Publication record** — both artifacts are registered in
   `reports/learning-hub/publications.json` with the **release date** and a
   **30-day completion window**.
4. **Awareness Portal** — a local, branded web app (served by an nginx container)
   where a learner reads the magazine anytime, completes the course, sees
   **Complete**, and keeps a personal **certificate library**. Its **Library** view
   also **auto-discovers every asset** any workflow writes to `reports/` (via nginx
   JSON autoindex), and its **Create** view is a **self-service launcher** — one
   place to kick off any workflow: each awareness tool opens its n8n request form,
   and the Learning Hub / intelligence briefs show their schedule + Telegram command.
   Branding and the n8n location are set in [`dashboard/portal.json`](dashboard/portal.json)
   (`{ "brand", "tagline", "accent", "logo", "n8nBaseUrl" }`); `n8nBaseUrl` defaults
   to `http://<portal-host>:5678`. Drop a `reports/portal.json` to override without
   rebuilding.

This module does **not** modify or depend on any other module. It reuses only the
shared provider abstractions (`AI_PROVIDER`, `IMAGE_PROVIDER`) and Gotenberg.

## Workflows

| Workflow | What it does |
|----------|--------------|
| `workflows/learning-hub.json` | Publication generator + orchestrator: builds the magazine, derives the course (calls the course workflow), registers the publication. Triggers: monthly schedule, **Run Now** (manual), or **On Command**. |
| `workflows/learning-hub-elearning.json` | Magazine-grounded course generator. Called by the publication workflow (or run manually for a topic). Writes the lesson HTML to `reports/learning-hub/`. |

## Run it

```bash
# 1. Import workflows (auto-discovered via module.json autoImport)
scripts/workflows/workflow-import.sh

# 2. Start the dashboard (nginx static service)
docker compose up -d dashboard

# 3. Generate the first edition: open the
#    "Jarvis · Learning Hub — Publication + Course" workflow in n8n and Execute
#    (or wait for the monthly schedule).

# 4. Open the dashboard
open http://localhost:8088   # or your DASHBOARD_PORT
```

The dashboard reads `reports/learning-hub/publications.json` and tracks completion
and certificates in the browser (localStorage) — a single-user demo. The course,
when launched from the dashboard, reports completion back via `postMessage`.

## Configuration

See [`config/config.example.env`](config/config.example.env). Key variables:
`LEARNING_HUB_ENABLED`, `LEARNING_HUB_SCHEDULE_CRON`, `LEARNING_HUB_PASS_MARK`,
`LEARNING_HUB_SOURCES_FILE`, `DASHBOARD_PORT`. Branding follows `CLIENT_NAME`.

## Outputs

```
reports/learning-hub/
├── learning-hub-<date>.pdf        # magazine (PDF)
├── learning-hub-<date>.html       # magazine (HTML)
├── <course>-<date>.html           # gamified e-learning course (self-contained)
├── <course>-<date>-scorm.zip      # SCORM 1.2 package for any corporate LMS
└── publications.json              # dashboard registry (magazine + course + deadline)
reports/archive/learning-hub/      # dated magazine PDF + JSON archive
```

## Health

```bash
modules/learning-hub/healthcheck.sh
```

See [`docs/overview.md`](docs/overview.md) for architecture details.
