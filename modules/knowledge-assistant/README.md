# Knowledge Assistant (`knowledge-assistant`)

> Retrieval-augmented Q&A and document ingestion over a personal knowledge base.
> Long-term memory and research archives are stored in the future **Qdrant**
> vector DB. Self-contained module (Plugin Architecture / Separation of concerns).

**Status: planned (scaffold).** Structurally valid placeholder; not yet wired
into the live stack.

## Purpose

Turn a growing pile of notes, documents and research into something you can
*ask*. Documents are chunked, embedded and stored in a vector collection;
questions are answered with retrieval-augmented generation (RAG) so answers cite
the source material instead of relying on the model's memory.

## Capabilities

- `knowledge.ingest` — chunk, embed and store documents in the vector DB.
- `knowledge.search` — semantic search over stored chunks.
- `knowledge.qa` — answer a question using retrieved context (RAG), citing sources.

## Configuration

See [`config/config.example.env`](./config/config.example.env). Copy the
relevant lines into the repository root `.env`. Secret **values** never live in
the repo — only env var **names** are referenced.

| Env var | Default | Secret | Purpose |
|---------|---------|--------|---------|
| `KNOWLEDGE_ASSISTANT_ENABLED` | `false` | no | Enable the module's workflows. |
| `QDRANT_URL` | `http://jarvis-qdrant:6333` | no | Vector DB endpoint (future core service). |
| `QDRANT_API_KEY` | _(empty)_ | yes | Vector DB API key, if required. |
| `KNOWLEDGE_COLLECTION` | `jarvis_knowledge` | no | Collection name. |
| `KNOWLEDGE_TOP_K` | `5` | no | Chunks retrieved per query. |

Embeddings are produced through the core **AI Provider Abstraction** (Ollama
supports embeddings by default) — the module does not hardcode a provider.

## How to enable

1. Provision the Qdrant core service (planned) and confirm `QDRANT_URL` is reachable.
2. Set `KNOWLEDGE_ASSISTANT_ENABLED=true` and the `QDRANT_*` / `KNOWLEDGE_*` vars in `.env`.
3. Register the prompts in `prompts/registry.json` (root) if shared.
4. Import the workflows: `scripts/workflows/workflow-import.sh modules/knowledge-assistant/workflows`.
5. Run the health check (below).

## Health checks

```bash
modules/knowledge-assistant/healthcheck.sh          # human-readable
modules/knowledge-assistant/healthcheck.sh --json   # machine-readable
```

When the module is disabled it reports `SKIP`, never `FAIL` (Fail-safe defaults).
