Mandatory reading: llm/wiki/SCHEMA.md, llm/wiki/index.md.

Operations (see SCHEMA.md):
- ingest: read a source from llm/raw/ (only the sections asked), write/update atomic pages with
  citations (document no + version + section), mark new facts status: unverified.
- codemap: run `make codemap`, then fill only the Purpose and Notes sections of changed cards.
- lint: run `make wiki-lint`, fix mechanical findings, report content contradictions.
Append every operation to llm/wiki/log.md. Never edit llm/raw/.
