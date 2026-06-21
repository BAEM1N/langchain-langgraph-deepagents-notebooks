# Official LangChain Docs Coverage Assessment — 2026-06-19

## Scope

User request: fetch the actual upstream originals for the current LangChain Learn surface and the three product overviews, then estimate what is worth adding to this course repository.

Official entry points checked:

- https://docs.langchain.com/oss/python/learn
- https://docs.langchain.com/oss/python/langchain/overview
- https://docs.langchain.com/oss/python/langgraph/overview
- https://docs.langchain.com/oss/python/deepagents/overview

The fetch was expanded through the official `llms-full.txt` source index for the relevant OSS Python sections, because the four entry points are navigation hubs rather than the full source set.

## Upstream snapshot captured

Raw upstream originals were saved under the ignored local workspace:

- Snapshot directory: `local/official_langchain_docs_2026-06-19/`
- Full upstream source bundle: `local/official_langchain_docs_2026-06-19/llms-full.txt`
- Individual Markdown pages: `local/official_langchain_docs_2026-06-19/pages/*.md`
- Inventory: `local/official_langchain_docs_2026-06-19/inventory.csv`
- JSON inventory: `local/official_langchain_docs_2026-06-19/inventory.json`

Fetched page count: **148** official pages.

| Section | Pages fetched |
|---|---:|
| Learn | 1 |
| Concepts | 4 |
| LangChain | 66 |
| LangGraph | 36 |
| Deep Agents | 41 |

Fetch status:

- Direct `.md` fetch succeeded: 144 pages
- Extracted from `llms-full.txt` fallback: 4 pages

## Local material inventory

Generated inventory:

- `local/repo_material_inventory_2026-06-19.csv`

Current local material count from the repo scan:

| Area | Items |
|---|---:|
| `docs/**/*.md` | 118 |
| Korean notebooks `01`-`08` | 138 |
| English notebooks | 69 |
| Total scanned docs/notebooks | 325 |

Important note: the project is much larger than the older top-level description that says “60 notebooks.” The current tree includes `06_langsmith`, `08_integration`, and English mirrors.

## Current coverage summary

### Strongly covered already

These official surfaces are already represented well by local docs and/or runnable notebooks:

| Official surface | Local coverage |
|---|---|
| LangChain core agent harness (`create_agent`) | `docs/langchain/01-03*`, `02_langchain/01-04`, `05_advanced/01` |
| Models, messages, tools, structured output | `docs/langchain/04-09*`, `02_langchain/03-04` |
| Middleware, guardrails, runtime, HITL | `docs/langchain/10-17*`, `02_langchain/06-07`, `05_advanced/01` |
| RAG, SQL, voice tutorials | `docs/langchain/tutorials/*`, `07_examples/01-02`, `05_advanced/05-06`, `05_advanced/08` |
| Multi-agent: subagents, handoffs, router, skills | `docs/langchain/18-23*`, `docs/langchain/tutorials/*`, `05_advanced/02-03`, `07_examples/07` |
| LangGraph Graph API / Functional API | `docs/langgraph/18-22*`, `03_langgraph/02-03` |
| LangGraph persistence, memory, interrupts, time travel, subgraphs | `docs/langgraph/05`, `08-11`, `25-26`, `03_langgraph/06`, `08-09` |
| LangGraph fault tolerance | `docs/langgraph` plus `03_langgraph/14_fault_tolerance.ipynb` |
| Deep Agents quickstart, customization, backends, subagents, HITL, memory, skills, sandboxes, ACP | `docs/deepagents/01-16*`, `04_deepagents/01-11` |
| Deep Agents tutorials: data analysis, deep research, content builder | `docs/deepagents/tutorials/*`, `docs/deepagents/examples/*`, `07_examples/03`, `05`, `07` |
| LangSmith / Agent Evals | `06_langsmith/`, `en/06_langsmith/`, `06_langsmith/06_agent_evals.ipynb` |

### Covered as docs, but not yet ideal as lessons

| Official surface | Current local state | Add? |
|---|---|---|
| LangChain semantic search (`knowledge-base`) | Local tutorial Markdown exists; RAG notebooks include adjacent material | Optional short beginner/example notebook if we want a gentler RAG prerequisite |
| LangChain unit/integration testing | Official pages fetched; local has broad test/eval docs and Agent Evals notebook | Yes, add one compact testing strategy lesson if expanding evaluation track |
| Event streaming across LangChain/LangGraph/Deep Agents | Existing streaming notebooks and docs; official split is now more protocol-oriented | Refresh references; maybe add source notes rather than new core notebooks |
| Deep Agents programmatic subagents | Mentioned/gated in advanced material; dependency gate remains (`langchain_quickjs` not installed in prior audit) | Defer full live notebook until dependency policy is accepted |
| Deep Agents Code / `dcode` | Some conceptual notes; official has a full `code/*` section | Good `08_integration` candidate, not core 01-07 |
| Frontend surfaces | `02_langchain/12_frontend_streaming.ipynb`, `docs/langchain/28-ui.md`, `docs/langgraph/15-ui.md`; official has many detailed React/UI pages | Add only in `08_integration` or appendix |

## Recommended additions

### P0 — Source/reference sync, low risk

These are documentation sync tasks, not new learner chapters. They would make the repo’s `docs/` tree align more closely with official navigation.

1. **Create `docs/concepts/` and add the four official concept pages**
   - `products` / frameworks-runtimes-harnesses
   - `providers-and-models`
   - `memory`
   - `context`

   Why: AGENTS already describes `docs/concepts/`, but the current scan found no `docs/concepts` directory. These pages are useful as cross-framework orientation.

2. **Add explicit event-streaming source notes**
   - `docs/langchain/event-streaming.md` or update `docs/langchain/08-streaming.md`
   - `docs/langgraph/event-streaming.md` or update `docs/langgraph/07-streaming.md`
   - `docs/deepagents/event-streaming.md` or update `docs/deepagents/15-streaming.md`

   Why: official docs now distinguish normal streaming from typed event-streaming surfaces. Existing lessons can stay, but references should be protocol-current.

3. **Add missing Deep Agents reference stubs for current official nav**
   - `a2a`
   - `mcp`
   - `models`
   - `tools`
   - `programmatic-subagents`
   - `event-streaming`
   - `frontend/*` summary index
   - `code/*` summary index

   Why: Deep Agents official surface has expanded faster than the core course. Adding reference summaries avoids immediate notebook churn while preserving awareness.

### P1 — Best next course additions

1. **Testing strategy chapter**
   - Candidate path: `06_langsmith/07_testing_strategy.ipynb` and `en/06_langsmith/07_testing_strategy.ipynb`, or `05_advanced/10_testing_and_replay.ipynb`.
   - Source pages: official LangChain `test/unit-testing`, `test/integration-testing`, `test/evals`, plus local Agent Evals chapter.
   - Content: mock models, in-memory checkpointers/stores, structural assertions, trajectory evals, record/replay guidance, key/cost gates.

   Why: Agent Evals now exists locally, but unit/integration testing discipline is still scattered.

2. **Minimal semantic search pre-RAG notebook**
   - Candidate path: `02_langchain/14_semantic_search.ipynb` or `07_examples/08_semantic_search_minimal.ipynb`.
   - Keep it short: documents → splitter → embeddings → vector store → retriever.

   Why: official Learn separates Semantic Search before RAG. Our RAG examples are strong, but beginners would benefit from a standalone retrieval-only lesson.

3. **Deep Agents event streaming mini-lesson**
   - Candidate path: refresh `04_deepagents/07_advanced.ipynb` or add `04_deepagents/12_streaming_events.ipynb` only if we accept a new chapter.
   - Focus: task/subagent/todo/filesystem events and how frontend consumers differ from notebook consumers.

   Why: official Deep Agents now has richer streaming/frontend event docs. This is valuable for production debugging.

### P2 — Integration / appendix candidates

1. **Deep Agents Code (`dcode`) appendix**
   - Candidate path: `08_integration/14_deepagents_code/`.
   - Mark as CLI/integration-only; exclude from default notebook smoke.

2. **Frontend Agent UI track**
   - Candidate path: `08_integration/15_agent_frontend/`.
   - Cover `useStream`, branching chat, join/rejoin, message queues, reasoning tokens, tool calling, generative UI.

3. **Deep Agents A2A / Agent Server / ACP integration**
   - Candidate path: `08_integration/16_agent_protocols/`.
   - Requires server runtime and external protocol assumptions; should not enter core 01-07 notebooks.

### P3 — Defer unless scope changes

| Candidate | Reason to defer |
|---|---|
| Full Deep Agents programmatic subagents live notebook | Needs explicit dependency/runtime policy, likely QuickJS-related gate |
| Cloud deployment/provider tutorials | Keys, cost, and external-service fragility |
| Full React frontend examples in main track | Not a notebook-native learner path |
| Changelog mirroring | Useful for maintenance, not course content |
| Case studies / get-help / academy pages | Navigation/support resources, not worth course chapters |

## Concrete next execution order

1. Add `docs/concepts/` source summaries.
2. Add/update event-streaming reference notes across LangChain, LangGraph, Deep Agents.
3. Add Deep Agents missing-reference index notes (`a2a`, `mcp`, `models`, `tools`, `code`, `frontend`, `programmatic-subagents`).
4. Decide whether the next runnable lesson is:
   - testing strategy, if the goal is production readiness; or
   - semantic search, if the goal is beginner path smoothness.
5. Keep `08_integration` as the landing zone for frontend, CLI, server, protocol, and cloud/provider examples.

## Verification evidence

Commands run for this assessment:

```bash
python /tmp/fetch_langchain_docs.py
python /tmp/local_inventory.py
```

Results:

- Official pages fetched: 148
- Official inventory saved: `local/official_langchain_docs_2026-06-19/inventory.csv`
- Local docs/notebooks inventoried: 325
- Local inventory saved: `local/repo_material_inventory_2026-06-19.csv`

## Decision

Do not add every official page as a notebook. The repo already covers the high-value official tutorial surfaces well. The best next work is:

1. close reference gaps caused by official navigation expansion;
2. add one testing strategy lesson for production quality; and
3. optionally add a short semantic-search prerequisite lesson for beginner continuity.
