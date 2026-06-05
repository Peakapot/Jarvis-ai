# Security Policy

Jarvis is built **security by default**. This repository is **public** and is
engineered so that no secret material is ever committed.

## Secrets management

- **No secrets in Git.** No credentials, API keys, tokens, passwords or private
  keys belong in any tracked file. The repository ships only `.env.example`.
- **Local-only configuration.** The installer generates a git-ignored `.env`
  (with `chmod 600`) and a strong local `N8N_ENCRYPTION_KEY`. Real credentials
  are added by the operator to `.env` only.
- **Strict `.gitignore`.** `.env`, `*.key`, `*.pem`, `*credentials*.json`,
  `secrets/`, runtime `state/`, `logs/`, `backups/` and generated reports are
  excluded. Only `.env.example` is tracked.
- **Backups exclude secrets.** `backup.sh` records `.env` *key names only*
  (values redacted); credentials are re-supplied at restore time. The encrypted
  n8n credential store is included only with the explicit `--with-data` flag.
- **Diagnostics are redacted.** `diagnostics.sh` never captures secret values —
  only `.env` key names.
- **Workflows carry no credentials.** Workflows reference n8n credentials and
  environment variable *names*; `workflow-validate.sh` rejects any workflow that
  appears to contain a plaintext secret.

## Credential validation

`scripts/validate.sh` (pre-install) and `scripts/healthcheck.sh` (post-install)
verify connectivity and that required configuration is present, without printing
secret values. Missing credentials degrade to a clear `SKIP`/`WARN`, never a
silent failure (fail-safe defaults).

## Reporting a vulnerability

If you discover a security issue:

1. **Do not open a public issue** describing the vulnerability.
2. Email the maintainers privately with details and reproduction steps.
3. Allow reasonable time for a fix before any public disclosure.

We aim to acknowledge reports promptly and to ship fixes for confirmed issues as
a priority.

## Hardening recommendations

- Run on a host with full-disk encryption; keep `.env` permissions at `600`.
- Restrict the Telegram bot to known chat IDs via `TELEGRAM_ALLOWED_CHAT_IDS`.
- Put n8n behind a reverse proxy with TLS if exposed beyond localhost, and set
  `N8N_SECURE_COOKIE=true`.
- Rotate API keys periodically and after any suspected exposure.
- Keep images pinned and updated; see [`docs/upgrade.md`](docs/upgrade.md).
- Take regular backups (`./backup.sh`) and test restores (`./restore.sh`).

## Supported versions

The latest released version on the default branch receives security fixes. See
[`CHANGELOG.md`](CHANGELOG.md) for the version history.
