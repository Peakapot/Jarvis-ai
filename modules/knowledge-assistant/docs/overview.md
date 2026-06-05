# knowledge-assistant — Architecture & Notes

RAG over a personal knowledge base. Long-term memory and research archives are
stored in the future Qdrant vector DB.

## Where this module fits

```
Telegram / Webhook (query)                 Ingest source (file / URL / note)
        |                                            |
   rag-query.json                               ingest.json
        |                                            |
  embed query  --\                          chunk + summarise (ingest-summarize)
        |         \                                  |
  Qdrant search    AI Provider Abstraction     embed chunks
        |         /  (embeddings + chat)             |
  retrieved chunks                            Qdrant upsert (KNOWLEDGE_COLLECTION)
        |
  RAG answer (knowledge.rag-qa, cited)
```

## Design principles followed
- **Separation of concerns** — config, prompts, workflows, docs, health checks isolated here.
- **Provider abstraction** — embeddings and generation route through the core AI abstraction.
- **Configuration over hard coding** — Qdrant endpoint, collection and top-k are env-driven.
- **Fail-safe defaults** — disabled/unconfigured → SKIP, not FAIL.
- **Security by default** — `QDRANT_API_KEY` is referenced by name only; never committed.

## Open questions for implementation
- Chunking strategy (size/overlap) and embedding model selection.
- Hybrid (keyword + vector) search vs. pure vector.
- Collection lifecycle: per-source namespaces vs. a single collection with metadata filters.
