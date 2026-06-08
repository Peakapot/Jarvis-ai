# Awareness Toolkit

On-demand security-awareness **asset generators** for supporting a client's
awareness team. Each is a self-contained n8n workflow that reuses the platform
engine (AI provider switch → image/Gotenberg → `fs`) and writes files to
`/reports/awareness/<tool>/`.

Trigger two ways:
- **Telegram command** (e.g. `/poster phishing`, `/tabletop ransomware`) — the
  file is saved and returned in chat. Dispatched from the Telegram assistant via
  `Prep Toolkit Cmd → Toolkit Router → Run <tool> (Execute Workflow) → Send
  Toolkit Document`.
- **Manual** — open the workflow in n8n and Execute (defaults to topic "phishing").

Branding is generic for the MVP; set `CLIENT_NAME` in `.env` to white-label.
Steer topics with `config/awareness/topics.txt`. Provider follows `AI_PROVIDER`.

## Tools
| Workflow | Command(s) | Output (in `/reports/awareness/`) |
|---|---|---|
| `poster-explainer.json` | `/poster` `/explainer` | `posters/` — A4 poster (AI image) + one-page explainer PDF |
| `quiz-pack.json` | `/quiz` | `quiz/` — participant quiz + facilitator answer-key (incl. Spot-the-Phish) |
| `tabletop-pack.json` | `/tabletop` | `tabletop/` — scenario, roles, timed injects, debrief, facilitator notes |
| `micro-tips.json` | `/tips` (+ weekly) | `tips/` — printable tips one-pager + lock-screen cards |
| `teachable-moment.json` | `/teachable` (+ weekly) | `teachable/` — news-triggered "what happened / why / what to do" note |
| `kpi-report.json` | `/kpi` | `kpi/` — client KPI report from `config/awareness/kpi-input.json` |

## Choosing the topic & options
- **Telegram:** pass the topic in the command, e.g. `/poster mfa`,
  `/tabletop ransomware`, `/quiz social engineering`.
- **Manual run in n8n:** click **Execute** — an **Open Form** trigger shows a form
  to choose a **Topic** (curated dropdown, or type a **Custom topic**) plus
  optional **Audience** and **Tone**, and per-tool extras (quiz: questions &
  difficulty; tabletop: duration & seniority; tips: number of tips). Submit and
  the asset is generated. The form also has a **shareable web-form URL** the team
  can use without Telegram.
- **Default:** with nothing supplied, tools use `DEFAULT_AWARENESS_TOPIC` from
  `.env` (falls back to `phishing`).
- *teachable-moment* takes an optional **Focus** (else it auto-picks the week's
  top breach); *kpi-report* reads `config/awareness/kpi-input.json` with optional
  Period/Client overrides on the form.

## Inputs
- `config/awareness/topics.txt` — suggested topics/themes (mirrored in the form dropdowns).
- `config/awareness/kpi-input.json` — copy from `kpi-input.example.json` and fill
  with the client's real phishing-sim / training metrics.

## Import
`./workflows` is mounted at `/workflows`, so each is importable directly:
```
for w in poster-explainer quiz-pack tabletop-pack micro-tips teachable-moment kpi-report; do
  docker compose exec n8n n8n import:workflow --input=/workflows/awareness/$w.json
done
docker compose exec n8n n8n import:workflow --input=/workflows/core/telegram-assistant.json
docker compose restart n8n
```
Then **Publish** each workflow. If an Execute-Workflow node in the Telegram
assistant shows its target unset (n8n 2.0), pick the matching "Awareness — …"
workflow from its dropdown once.
