# Dış inceleme prompt'u

Aşağıdaki metni diğer modellere (ChatGPT, Gemini, Grok, DeepSeek, ...) ver; yanına
`METHODOLOGY.md`'yi (gerekirse `SETUP.md`, `manifest.toml`, `agents/roles.toml`) ekle.

---

You are reviewing a methodology kit for developing AMD/Xilinx FPGA designs with LLM agents.
Context: one experienced FPGA engineer (unit lead), Ubuntu workstation, Vivado, Claude Code (Pro
subscription, usage limits run out quickly), opencode with free models (Qwen3.8 Flash Next: reliable
logic, weak FPGA hygiene; DeepSeek Flash v4.1: good hygiene and documentation, frequent logic errors),
AMD Ross (Vivado MCP server + agent skills). Some projects move to an internal network with free
models and Vivado but no Claude and no internet. Testbenches are SystemVerilog, never cocotb.
The user wants light documentation and principle-level rules (rigid rules age quickly as AI improves),
but a standard folder structure and generated agents/skills/AGENTS.md.

Please answer briefly and concretely:
1. What is wrong, risky or missing? Rank the top 5 by impact.
2. Which parts are over-engineered for one engineer and could be removed?
3. Is the team-level split (L1–L4) and the role → model table sensible? What would you change?
4. Is the handoff between Claude Code and opencode (task/result cards in the repo, `opencode run`)
   robust? What fails first in practice?
5. Verification: is "the testbench is written from the spec by a different model, and only script
   results count" enough? What would you add without making it heavy?
6. Is anything inconsistent with current industry practice (agentic coding, spec-driven development,
   FPGA verification)? Cite sources if you can.
7. One thing you would do differently from scratch.

Do not rewrite the document. Give a list of findings with a one-line suggested change each.
