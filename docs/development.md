# Development

Contributor guide for **Jarvis**: repository layout, conventions, and how to add
workflows, prompts, providers and modules.

> See also: [architecture.md](architecture.md) ·
> [operations.md](operations.md) · [upgrade.md](upgrade.md)

## Table of contents

- [Repository layout](#repository-layout)
- [Shell conventions](#shell-conventions)
- [Adding a workflow](#adding-a-workflow)
- [Adding a prompt](#adding-a-prompt)
- [Adding a provider](#adding-a-provider)
- [Adding a module](#adding-a-module)
- [ShellCheck](#shellcheck)
- [CI pipeline](#ci-pipeline)
- [Testing](#testing)

## Repository layout

```text
Jarvis-ai/
├── install.sh                 # idempotent bootstrap (9 stages)
├── backup.sh / restore.sh     # full-system backup & recovery
├── docker-compose.yml         # service topology (profiles for future services)
├── .env.example               # configuration template (copied to .env)
├── scripts/
│   ├── validate.sh            # pre-flight host validation
│   ├── healthcheck.sh         # runtime health (PASS/WARN/FAIL/SKIP, --json)
│   ├── status.sh              # operational dashboard
│   ├── diagnostics.sh         # redacted support bundle
│   ├── lib/                   # shared library: common, logging, state, colors
│   ├── providers/             # resolve-provider.sh (provider abstraction)
│   └── workflows/             # import/export/validate/migrate/backup/restore
├── workflows/                 # workflows as source code (core/ modules/ exported/)
├── prompts/                   # versioned prompts + registry.json
├── config/
│   ├── providers/             # AI/email/image descriptors + schema
│   └── rss-feeds.txt          # cyber-brief sources
├── modules/_template/         # copy-me plugin module scaffold
├── templates/                 # email/report templates
├── docs/                      # this documentation set (+ diagrams/, runbooks/)
├── reports/ backups/ logs/ state/   # generated runtime dirs (git-ignored content)
└── tests/                     # test harness location
```

## Shell conventions

All scripts share one set of conventions, centralised in
[`scripts/lib/`](../scripts/lib):

- **Strict bash mode.** `set -o errexit -o nounset -o pipefail`. Sourcing
  `common.sh` applies it automatically (opt out only via `JARVIS_NO_STRICT=1`).
- **One-line boilerplate.** Source the library and init logging:
  ```bash
  #!/usr/bin/env bash
  set -o errexit -o nounset -o pipefail
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/lib/common.sh"   # also pulls in logging.sh, state.sh, colors.sh
  log_init "mycomponent"                 # -> logs/mycomponent.log
  load_env                               # load .env if present
  ```
- **Structured logging.** Use `log_info` / `log_ok` / `log_warn` / `log_error` /
  `log_fatal` / `log_section`. Every call writes a human line to stderr and a
  JSON line to `logs/<component>.log`
  ([operations.md](operations.md#the-structured-json-log-format)). Keep **stdout
  for data** so scripts compose in pipelines.
- **Idempotent steps.** Use `ensure_task <id> "Description" <command>` for any
  step that should run once and be skippable on re-run (backed by
  [`state.sh`](../scripts/lib/state.sh)). This is the pattern that makes
  `install.sh` re-runnable.
- **Helpers.** `require_cmd` / `have_cmd` (dependencies), `semver_ge` (version
  comparison), `confirm` / `prompt_default` (honour `JARVIS_ASSUME_YES` and
  non-TTY), `retry`, `run_step`, and `compose` (resolves `docker compose` v2 or
  legacy `docker-compose`).
- **Config over hard coding.** Read tunables from `.env` with sane defaults
  (`${VAR:-default}`); never bake host-specific values into code.
- **Fail-safe + secure.** Validate before mutating; never print secrets; degrade
  to WARN/SKIP rather than crashing when a feature is simply unconfigured.
- **Self-documenting `--help`.** Each script's header comment is its help text
  (printed by `-h|--help`).

## Adding a workflow

Workflows are source code; none may live only in the n8n UI
([architecture.md](architecture.md#workflows-as-source-code)).

1. Author or edit the workflow in n8n, then **export** it to disk:
   ```bash
   scripts/workflows/workflow-export.sh
   ```
   Move the exported JSON into `workflows/core/` (or `workflows/modules/` for a
   module) and give it a stable file name.
2. **Validate** before committing:
   ```bash
   scripts/workflows/workflow-validate.sh
   ```
   It checks valid JSON, the n8n shape (`nodes` array + `connections` object),
   and the absence of plaintext secrets.
3. **Import** to confirm it loads:
   ```bash
   scripts/workflows/workflow-import.sh
   ```
4. Reference any prompts by **id** (not inline text), set
   `settings.errorWorkflow` to `Jarvis · Error Handler`, and give external calls
   a failure path. Add new Telegram commands by extending the Command Router
   switch in [`telegram-assistant.json`](../workflows/core/telegram-assistant.json).
5. **Schema changes** go through a migration: add
   `scripts/workflows/migrations/NNNN-description.sh` (idempotent, takes a
   workflow path as `$1`). See [upgrade.md](upgrade.md#workflow-migrations).
6. Commit the JSON. Review it as a diff.

## Adding a prompt

Prompts are first-class, versioned, and stored **outside** workflows
([architecture.md](architecture.md#prompt-management)).

1. Create `prompts/<owner>/<name>.md` with YAML frontmatter and a changelog:
   ```markdown
   ---
   id: telegram.example
   version: 1.0.0
   purpose: One-line description.
   owner: telegram-assistant
   provider_agnostic: true
   variables:
     - name: INPUT
       description: What this variable carries.
   ---

   # Title

   ... prompt body, interpolating {{INPUT}} ...

   ---
   ## Changelog
   - 1.0.0 — Initial version.
   ```
2. Register it in [`prompts/registry.json`](../prompts/registry.json) with
   `id`, `file`, `version`, `purpose`, `owner`.
3. Reference the prompt by `id` from the workflow.
4. **Bump `version` (semver) on every meaningful change** and note it in the
   prompt's changelog and the registry.

## Adding a provider

Provider selection is configuration, not code
([architecture.md](architecture.md#provider-abstraction-layer)).

1. Create a descriptor `config/providers/<kind>/<id>.json` (`kind` is `ai`,
   `image` or `email`) conforming to
   [`provider.schema.json`](../config/providers/provider.schema.json). Required:
   `id`, `kind`, `displayName`, `capabilities`. Reference secrets by **env var
   name only** (e.g. `"baseUrlEnv": "OLLAMA_BASE_URL"`), never values.
2. Add any new env vars to `.env.example` (no secrets) and document them.
3. Select it via the relevant `*_PROVIDER` variable in `.env`.
4. Confirm resolution:
   ```bash
   scripts/providers/resolve-provider.sh <kind> --id <id>
   ```

No workflow changes are required — workflows resolve providers at runtime.

## Adding a module

Capabilities can ship as self-contained plugin modules
([architecture.md](architecture.md#plugin--module-architecture)). Start from the
scaffold:

1. Copy the template:
   ```bash
   cp -r modules/_template modules/<your-module>
   ```
2. Edit `module.json` (the contract): `id`, `name`, `version`, `status`,
   `provides`, `dependsOn`, `prompts`, `workflows`, `envVars`, `healthcheck`.
3. Add the module's prompts (`prompts/*.md`, register shared ones in the root
   `prompts/registry.json`), workflows (`workflows/*.json`), config
   (`config/config.example.env`, env-var names only), and `healthcheck.sh`
   (PASS/WARN/FAIL/SKIP, `--json`; SKIP when not enabled).
4. Import the workflow(s) and set the module's env vars in `.env`.
5. Run the module health check:
   ```bash
   modules/<your-module>/healthcheck.sh --json
   ```

See [`modules/_template/README.md`](../modules/_template/README.md) for the full
contract table.

## ShellCheck

All shell is written to pass [ShellCheck](https://www.shellcheck.net/). Scripts
carry `# shellcheck source=...` directives so the linter can follow sourced
libraries. Run it before committing:

```bash
shellcheck install.sh backup.sh restore.sh scripts/**/*.sh
```

(`.gitignore` excludes `.shellcheck-cache/`.)

## CI pipeline

Continuous integration runs from [`.github/workflows/`](../.github/workflows).
The intended pipeline mirrors the local checks, so a PR is green only if it would
install cleanly:

1. **Lint** — ShellCheck across all scripts.
2. **Workflow integrity** — `scripts/workflows/workflow-validate.sh` (valid JSON,
   n8n shape, no plaintext secrets).
3. **Config validation** — provider descriptors against
   `provider.schema.json`; prompt registry consistency.
4. **Smoke** — `scripts/validate.sh --json` on the runner.

Keep CI in lockstep with the scripts: if you add a check locally, add it to CI
(*Documentation as code* applies to the pipeline too).

## Testing

The [`tests/`](../tests) directory is the home for the test harness. Favour:

- **Unit-style** tests of library functions (`semver_ge`, state markers,
  JSON-escaping in logging) using a bash test runner such as
  [bats](https://github.com/bats-core/bats-core).
- **Integration** checks that exercise the idempotent paths: run `install.sh`
  twice and assert the second run skips completed stages; run
  `workflow-import.sh` twice and assert no duplication.
- **Fixture** validation: keep sample workflows that must pass/fail
  `workflow-validate.sh`.

Run health and validation locally as part of any change:

```bash
scripts/validate.sh
scripts/workflows/workflow-validate.sh
scripts/healthcheck.sh
```
