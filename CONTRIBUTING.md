# Contributing to Jarvis

Thank you for helping build Jarvis. This project is engineered as a long-term
product, so contributions are held to a standard that protects maintainability,
reliability, recoverability, observability and security. Please read this guide
before opening a pull request.

## Architectural principles (non-negotiable)

Every change must respect these principles:

- **Infrastructure as Code** — anything you add should be reproducible from the
  repository, not from manual host steps.
- **Configuration over hard coding** — expose tunables via `.env` /
  descriptors, never literals in code.
- **Modular architecture & separation of concerns** — prefer adding a *module*
  over modifying the core. Every component must be replaceable.
- **Idempotent operations** — scripts must be safe to run repeatedly.
- **Fail-safe defaults & graceful failure** — handle the unhappy path; degrade,
  don't crash.
- **Security by default** — never commit secrets; reference env var *names*.
- **Observability by default** — use the structured logging library.
- **Documentation as code** — update the relevant `docs/` files in the same PR.

## Repository conventions

### Shell scripts

- Start with `#!/usr/bin/env bash` and strict mode (handled by sourcing
  `scripts/lib/common.sh`).
- Source the shared library; use `log_info`/`log_ok`/`log_warn`/`log_error`
  instead of raw `echo` for status output.
- Make installer-style steps idempotent with `ensure_task` / the state helpers.
- Keep scripts `shellcheck`-clean. Run:

  ```bash
  shellcheck scripts/*.sh scripts/**/*.sh *.sh
  ```

### Workflows (workflows as source code)

- No workflow may exist only inside the n8n UI. Export and commit changes:

  ```bash
  scripts/workflows/workflow-export.sh   # pull live changes into workflows/
  scripts/workflows/workflow-validate.sh # must pass before commit
  ```

- Every workflow must define an `errorWorkflow` and give external calls a
  failure path. Never embed credentials — reference n8n credentials / env names.

### Prompts (first-class assets)

- Store prompts under `prompts/` (or a module's `prompts/`), never inline in a
  workflow. Add an entry to `prompts/registry.json`.
- Use YAML frontmatter (`id`, `version`, `purpose`, `owner`, `variables`) and
  bump the semver `version` plus the in-file Changelog on every change.

### Providers

- Add a new provider as a JSON descriptor under `config/providers/<kind>/` that
  conforms to `config/providers/provider.schema.json`. Reference secret env var
  *names* only. Switching providers must remain a configuration change.

### Modules (plugins)

- Copy `modules/_template/` to `modules/<your-module>/` and fill in
  `module.json`, `config/`, `prompts/`, `workflows/`, `docs/` and
  `healthcheck.sh`. See [`modules/README.md`](modules/README.md).

## Commit & PR process

- Use **logical commits** with **meaningful messages** (imperative mood, e.g.
  "Add calendar-assistant module scaffold"). Reference issues where relevant.
- Keep PRs focused. Include: what changed, why, and how you tested it.
- Update `CHANGELOG.md` under `[Unreleased]`.
- Ensure CI passes (workflow validation + shellcheck).
- Do not commit `.env`, secrets, logs, backups or generated reports.

## Testing your change

```bash
scripts/validate.sh            # host prerequisites
shellcheck $(git ls-files '*.sh')
scripts/workflows/workflow-validate.sh
./install.sh --yes             # idempotent; safe to re-run
scripts/healthcheck.sh
```

## Code of conduct

Be respectful and constructive. Assume good intent. Security issues should be
reported privately — see [`SECURITY.md`](SECURITY.md).
