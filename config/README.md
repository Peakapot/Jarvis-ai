# Configuration

All runtime behaviour is driven by configuration, not hard-coded values
(Configuration over hard coding). Secrets never live here — only in the
git-ignored `.env` at the repository root.

## Contents

```
config/
├── providers/            # provider abstraction descriptors (no secrets)
│   ├── provider.schema.json   # JSON Schema all descriptors conform to
│   ├── ai/                    # ollama (default), claude, openai
│   ├── email/                 # smtp (default), gmail, microsoft365
│   └── image/                 # openai
├── rss-feeds.txt         # Cyber Brief intelligence sources (one URL per line)
└── templates/            # configuration templates (non-secret)
```

## Provider abstraction

Switching a provider is a **configuration change, not a code change**:

1. Set the relevant variable in `.env`:
   - AI: `AI_PROVIDER=ollama|claude|openai` (Ollama is the default)
   - Email: `EMAIL_PROVIDER=smtp|gmail|microsoft365`
   - Image: `IMAGE_PROVIDER=openai`
2. Provide that provider's credentials in `.env` (and/or n8n credentials for
   OAuth providers).
3. Workflows resolve the active provider at runtime via
   `scripts/providers/resolve-provider.sh <ai|email|image>`.

Each descriptor references secret **env var names only** (e.g.
`"valueEnv": "OPENAI_API_KEY"`) so this directory is safe in a public repo.

## Adding a provider

Create `config/providers/<kind>/<id>.json` conforming to
[`providers/provider.schema.json`](providers/provider.schema.json), then select
it via the corresponding `*_PROVIDER` variable. No workflow redesign required.
