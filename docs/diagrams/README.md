# Diagrams

All architecture diagrams in this documentation set are written as
[Mermaid](https://mermaid.js.org/) code blocks **inside the Markdown that
references them** — most notably in [../architecture.md](../architecture.md).

## Why diagrams-as-code

We treat diagrams the same way we treat the rest of the system
(*Documentation as code*):

- **Versioned and reviewable.** A diagram change shows up as a readable text
  diff in a pull request, just like a code change. No opaque binary assets.
- **No external tooling required.** GitHub renders Mermaid natively in
  Markdown, so the diagrams display in the repository without any build step,
  image export, or proprietary editor.
- **Always in sync.** Because the diagram source sits next to the prose and the
  code it describes, it is updated in the same change that updates behaviour.
  Stale, out-of-date PNGs are designed out.
- **Accessible.** The source is plain text — greppable, diff-able and editable
  by anyone with a text editor.

## Conventions

- Keep each diagram in the document whose subject it illustrates, immediately
  after the section that introduces it.
- Prefer `flowchart`/`graph` for topology and `sequenceDiagram` for request
  flows.
- Name nodes after the real services, scripts or files they represent (e.g.
  `n8n`, `ollama`, `resolve-provider.sh`) so the diagram maps 1:1 onto the code.

## Diagram inventory

| Diagram | Location | Type |
| --- | --- | --- |
| Container / component topology | [../architecture.md](../architecture.md#component-and-container-topology) | `flowchart` |
| Telegram message round-trip | [../architecture.md](../architecture.md#request-flow-a-telegram-message-round-trip) | `sequenceDiagram` |

If you add a new diagram, add a row here so the inventory stays complete.
