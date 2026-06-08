# Awareness Toolkit

On-demand security-awareness **asset generators** for a client's awareness team.
Each is a self-contained n8n workflow that reuses the platform engine (AI provider
switch → image/Gotenberg → `fs`) and writes files to `/reports/awareness/<tool>/`.

Trigger two ways:
- **Telegram command** (e.g. `/poster phishing`, `/explainer mfa`) — the file is
  saved and returned in chat. Dispatched from the Telegram assistant via an
  Execute-Workflow node.
- **Manual** — open the workflow in n8n and Execute (defaults to topic "phishing").

Branding is generic for the MVP; set `CLIENT_NAME` in `.env` to white-label.
Steer topics with `config/awareness/topics.txt`.

## Tools
| Workflow | Command | Output (in `/reports/awareness/`) |
|---|---|---|
| poster-explainer.json | `/poster` `/explainer` | `posters/poster-<topic>-<date>.pdf` (poster + one-page explainer) |
| _quiz-pack.json_ (Phase 2) | `/quiz` | quiz participant + facilitator pack |
| _teachable-moment.json_ (Phase 1) | `/teachable` | news-triggered internal-comms one-pager |
| _micro-tips.json_ (Phase 2) | `/tips` | printable tips + lock-screen cards |
| _tabletop-pack.json_ (Phase 2) | `/tabletop` | scenario + injects + facilitator PDF |
| _kpi-report.json_ (Phase 3) | `/kpi` | client KPI report from config/awareness/kpi-input.json |

## Import
`./workflows` is mounted at `/workflows`, so:
```
docker compose exec n8n n8n import:workflow --input=/workflows/awareness/poster-explainer.json
```
Then re-import `telegram-assistant.json` for the dispatch commands.
