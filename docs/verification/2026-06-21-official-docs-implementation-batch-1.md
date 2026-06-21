# Official Docs Implementation Batch 1 — 2026-06-21

## Scope

This batch starts implementing the exhaustive official-doc action matrix from:

- `docs/verification/2026-06-21-official-docs-action-matrix.csv`
- `docs/verification/2026-06-21-tutorial-implementation-checklist.md`

The goal was to add runnable core notebooks for high-surface official additions while avoiding external API calls in default execution.

## New notebooks

| File | Official docs covered | Execution style |
|---|---|---|
| `02_langchain/14_semantic_search.ipynb` | `langchain/knowledge-base`, `langchain/retrieval`, `langchain/rag` | deterministic fake embeddings + in-memory vector store |
| `04_deepagents/12_models_and_tools.ipynb` | `deepagents/models`, `deepagents/tools`, `deepagents/permissions`, `deepagents/backends` | tool schema + agent construction, no invoke |
| `04_deepagents/13_programmatic_subagents.ipynb` | `deepagents/programmatic-subagents`, `deepagents/subagents`, `deepagents/async-subagents` | dependency gate + deterministic fan-out/fan-in fallback |
| `04_deepagents/14_event_streaming.ipynb` | `deepagents/event-streaming`, `deepagents/streaming`, `deepagents/frontend/subagent-streaming` | deterministic event projection |
| `06_langsmith/07_testing_strategy.ipynb` | `langchain/test/index`, `unit-testing`, `integration-testing`, `evals`, `langgraph/test` | fake chat model + local assertions |
| `07_examples/10_personal_assistant_subagents.ipynb` | `langchain/multi-agent/subagents-personal-assistant`, `deepagents/subagents` | deterministic routing + fan-in |
| `07_examples/11_customer_support_handoffs.ipynb` | `langchain/multi-agent/handoffs-customer-support`, `langgraph/workflows-agents` | deterministic LangGraph state machine |
| `07_examples/12_router_knowledge_base.ipynb` | `langchain/multi-agent/router-knowledge-base`, `structured-output` | deterministic source router |

## Index updates

- `README.md` notebook counts and learning paths updated.
- `06_langsmith/README.md` updated for `07_testing_strategy.ipynb`.

Tracked notebook count after this batch should become 215 once these new notebooks are added to git:

| Group | Count |
|---|---:|
| Korean core notebooks | 77 |
| English mirror notebooks | 69 |
| Integration notebooks | 69 |
| Total tracked notebooks | 215 |

## Verification evidence

### JSON, cell ID, code length audit

All 8 notebooks parsed as JSON and have sequential `cell-0`, `cell-1`, ... ids. No code cell exceeds 10 lines.

### Execution audit

Executed with `nbclient` using `kernel_name='python3'`, `timeout=120`:

- `02_langchain/14_semantic_search.ipynb` — PASS
- `04_deepagents/12_models_and_tools.ipynb` — PASS
- `04_deepagents/13_programmatic_subagents.ipynb` — PASS
- `04_deepagents/14_event_streaming.ipynb` — PASS
- `06_langsmith/07_testing_strategy.ipynb` — PASS
- `07_examples/10_personal_assistant_subagents.ipynb` — PASS
- `07_examples/11_customer_support_handoffs.ipynb` — PASS
- `07_examples/12_router_knowledge_base.ipynb` — PASS

### Static audit

- `git diff --check -- docs README.md` passed before this report.

## Remaining official-doc implementation backlog

This batch does not close the whole matrix. Remaining work is tracked in:

- `docs/verification/2026-06-21-tutorial-implementation-checklist.md`

Notable remaining core candidates include:

- `05_advanced/10_deep_agent_from_scratch.ipynb`
- `05_advanced/11_custom_workflow_agent.ipynb`
- `03_langgraph/15_backward_compatibility.ipynb`
- `03_langgraph/16_case_studies.ipynb`
- `04_deepagents/15_permissions.ipynb` or expanding `10_sandboxes_and_acp.ipynb`
- `04_deepagents/16_quality_profiles_rubric.ipynb`
- `06_langsmith/08_langgraph_testing.ipynb`
- `06_langsmith/09_runtime_rubric_evaluation.ipynb`
- `07_examples/13_skills_sql_assistant.ipynb`
- `08_integration/*` frontend/protocol/Deep Agents Code tracks
