Mandatory reading: llm/wiki/SCHEMA.md, llm/wiki/index.md.
- ingest: read only the requested sections of a source in llm/raw/; write short pages with
  citations (document no + version + section); new facts are `status: unverified`.
- codemap: `make codemap`, then fill only Purpose and Notes of changed cards.
- lint: `make wiki-lint`; fix mechanical findings, report contradictions.
Append every operation to llm/wiki/log.md. Never edit llm/raw/.
