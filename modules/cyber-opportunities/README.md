# Cyber Opportunities — Intelligence Module

**Daily Cyber Opportunities Intelligence Brief** — identifies commercial
opportunities relevant to cybersecurity consulting and managed services, with a
GCC-first regional focus.

> Intelligence product `cyber-opportunities`, registered in
> [`config/intelligence/products.json`](../../config/intelligence/products.json).
> Built entirely on the established workflow, prompt, configuration, branding,
> backup and documentation frameworks — it is a model for future intelligence
> products.

## What it does

Each day at **06:15** (configurable) the workflow:

1. Loads opportunity sources from
   [`config/cyber-opportunities-sources.txt`](../../config/cyber-opportunities-sources.txt).
2. Analyses them with the **provider-abstracted AI** (Ollama by default) using
   [`prompts/analyst.md`](prompts/analyst.md).
3. Auto-generates a **premium cover image** from the top opportunities via the
   **Image Provider Abstraction**.
4. Renders **HTML / PDF / email / archive** using the shared branded base
   template and stores every output (Opportunity Archive).
5. Emails the brief via the **Email Provider Abstraction**.

Every step has a **failure path**: a bad source, an unavailable AI/image/email
provider, or a disabled flag degrades gracefully rather than breaking the brief.

## Report sections

Executive Summary · Top Opportunities · Regional Breakdown · High Priority
Opportunities · Strategic Relevance · Recommended Actions · Win Probability
Assessment · Opportunity Archive · Historical Trends.

## Opportunity coverage

RFPs · RFIs · government tenders · managed security · security-awareness
programmes · GRC · SOC · vulnerability management · OT security · critical
infrastructure security · AI security · cloud security.

**Primary regions:** UAE, Saudi Arabia, Qatar, Oman, Bahrain, Kuwait
**Secondary:** United Kingdom, Europe, Global strategic.

## Configuration

See [`config/config.example.env`](config/config.example.env). Key variables
(in the root `.env`): `CYBER_OPPS_ENABLED`, `CYBER_OPPS_SCHEDULE_CRON`,
`CYBER_OPPS_PRIMARY_REGIONS`, `CYBER_OPPS_SECONDARY_REGIONS`,
`CYBER_OPPS_OUTPUT_FORMATS`.

## Telegram

`/opportunities` — request the latest brief, historical editions, or search by
organisation. Routed by the Telegram assistant workflow.

## Health

```bash
modules/cyber-opportunities/healthcheck.sh        # human report
modules/cyber-opportunities/healthcheck.sh --json # machine readable
```

The top-level `scripts/healthcheck.sh` also reports this product via the shared
intelligence library.

## Files

| Path | Purpose |
|------|---------|
| `module.json` | Module + intelligence manifest |
| `prompts/analyst.md` | Versioned analyst prompt |
| `workflows/cyber-opportunities.json` | n8n workflow (auto-imported) |
| `healthcheck.sh` | Module health check |
| `config/config.example.env` | Configuration reference |
| `docs/overview.md` | Architecture & operations notes |
