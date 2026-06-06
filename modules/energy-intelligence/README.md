# Energy Intelligence — Intelligence Module

**Daily Energy Intelligence Brief** — tracks strategic developments in the energy
sector with a heavy focus on the **UAE and the ADNOC ecosystem**, then regional
and global oil & gas.

> Intelligence product `energy-intelligence`, registered in
> [`config/intelligence/products.json`](../../config/intelligence/products.json).
> Built on the same workflow, prompt, configuration, branding, backup and
> documentation frameworks as every other intelligence product.

## What it does

Each day at **06:30** (configurable) the workflow:

1. Loads energy sources from
   [`config/energy-sources.txt`](../../config/energy-sources.txt).
2. Analyses them with the **provider-abstracted AI** (Ollama by default) using
   [`prompts/analyst.md`](prompts/analyst.md).
3. Auto-generates a **premium cover image** from the top stories via the
   **Image Provider Abstraction**.
4. Renders **HTML / PDF / email / archive** using the shared branded base
   template and stores every output.
5. Emails the brief via the **Email Provider Abstraction**.

Every step has a **failure path** (bad source, unavailable provider, disabled
flag) so the brief degrades gracefully rather than breaking.

## Report sections

Executive Summary · Top Stories · ADNOC Focus · UAE Focus · Regional Focus ·
Global Focus · Strategic Implications · Investment Activity · Digital
Transformation Activity · Cybersecurity Activity · Emerging Trends.

## Focus

**Primary:** ADNOC, ADNOC Gas, ADNOC Drilling, TAQA, Masdar, Borouge, TA'ZIZ,
Mubadala Energy, UAE energy sector.
**Secondary:** Saudi Aramco, Shell, BP, Chevron, ExxonMobil, TotalEnergies,
QatarEnergy, plus energy security, technology, AI, cybersecurity and digital
transformation.

## Configuration

See [`config/config.example.env`](config/config.example.env). Key variables (in
the root `.env`): `ENERGY_BRIEF_ENABLED`, `ENERGY_BRIEF_SCHEDULE_CRON`,
`ENERGY_BRIEF_PRIMARY_FOCUS`, `ENERGY_BRIEF_SECONDARY_FOCUS`,
`ENERGY_BRIEF_OUTPUT_FORMATS`.

## Telegram

`/energy` — request the latest briefing, historical editions, or search by
organisation (e.g. ADNOC, TAQA, Masdar).

## Health

```bash
modules/energy-intelligence/healthcheck.sh        # human report
modules/energy-intelligence/healthcheck.sh --json # machine readable
```

## Files

| Path | Purpose |
|------|---------|
| `module.json` | Module + intelligence manifest |
| `prompts/analyst.md` | Versioned analyst prompt |
| `workflows/energy-intelligence.json` | n8n workflow (auto-imported) |
| `healthcheck.sh` | Module health check |
| `config/config.example.env` | Configuration reference |
| `docs/overview.md` | Architecture & operations notes |
