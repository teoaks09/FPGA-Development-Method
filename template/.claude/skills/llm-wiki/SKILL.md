---
name: llm-wiki
description: Maintain the project LLM wiki (llm/wiki) - ingest sources, update codemap cards, query, lint. Use before working on a Xilinx IP or protocol, after interface changes, and after instructive debugging.
---

Read llm/wiki/SCHEMA.md first; it defines page format and operations.
- ingest: only the requested sections of a source in llm/raw/ (large sources are ingested by a
  free model or a subagent, never in the main session).
- codemap: `make codemap`, then fill Purpose/Notes of changed cards.
- query: index.md first, then only the needed pages.
- lint: `make wiki-lint`.
Append every operation to llm/wiki/log.md.
