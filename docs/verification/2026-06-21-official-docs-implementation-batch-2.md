# Official Docs Implementation Batch 2 — 2026-06-21

## Scope

This batch continues implementing the official-doc tutorial backlog after Batch 1.

## New notebooks

| File | Official docs covered | Execution style |
|---|---|---|
| `03_langgraph/15_backward_compatibility.ipynb` | `langgraph/backward-compatibility`, `langgraph/changelog-py` | feature detection + migration checklist |
| `03_langgraph/16_case_studies.ipynb` | `langgraph/case-studies`, `thinking-in-langgraph`, `workflows-agents` | architecture review template |
| `04_deepagents/15_permissions.ipynb` | `deepagents/permissions`, `human-in-the-loop`, `sandboxes` | deterministic permission policy evaluator |
| `04_deepagents/16_quality_profiles_rubric.ipynb` | `deepagents/profiles`, `rubric`, `langchain/test/evals` | profile registration + deterministic rubric evaluator |
| `05_advanced/10_deep_agent_from_scratch.ipynb` | `langchain/deep-agent-from-scratch`, `deepagents/overview` | harness skeleton without external calls |
| `05_advanced/11_custom_workflow_agent.ipynb` | `langchain/multi-agent/custom-workflow`, `langgraph/workflows-agents` | deterministic StateGraph workflow agent |
| `06_langsmith/08_langgraph_testing.ipynb` | `langgraph/test`, `checkpointers`, `langchain/test/unit-testing` | node/graph/checkpointer assertions |
| `06_langsmith/09_runtime_rubric_evaluation.ipynb` | `deepagents/rubric`, `langchain/test/evals` | deterministic runtime rubric grader |
| `07_examples/13_skills_sql_assistant.ipynb` | `langchain/multi-agent/skills-sql-assistant`, `langchain/sql-agent` | in-memory SQLite + read-only safety policy |

## Index updates

- `README.md` notebook counts and track descriptions updated during Batch 2; the later English mirror/Typst pass brings the current tracked curriculum total to 241 notebooks.
- `06_langsmith/README.md` updated for chapters 08 and 09.

## Verification evidence

### JSON, cell ID, code length audit

All 9 notebooks parsed as JSON, have sequential `cell-0`, `cell-1`, ... ids, and have no code cell over 10 lines.

### Execution audit

Executed with `nbclient`, `kernel_name='python3'`, `timeout=120`:

- `03_langgraph/15_backward_compatibility.ipynb` — PASS
- `03_langgraph/16_case_studies.ipynb` — PASS
- `04_deepagents/15_permissions.ipynb` — PASS
- `04_deepagents/16_quality_profiles_rubric.ipynb` — PASS
- `05_advanced/10_deep_agent_from_scratch.ipynb` — PASS
- `05_advanced/11_custom_workflow_agent.ipynb` — PASS
- `06_langsmith/08_langgraph_testing.ipynb` — PASS
- `06_langsmith/09_runtime_rubric_evaluation.ipynb` — PASS
- `07_examples/13_skills_sql_assistant.ipynb` — PASS

## Remaining official-doc implementation backlog

The main remaining body is now integration-heavy:

- `08_integration/14_langchain_frontend_foundations/`
- `08_integration/15_branching_time_travel_chat/`
- `08_integration/16_frontend_hitl/`
- `08_integration/17_frontend_integrations/`
- `08_integration/18_langgraph_frontend_graph_execution/`
- `08_integration/19_langgraph_custom_stream_channels/`
- `08_integration/20_langgraph_local_server_ui/`
- `08_integration/21_deepagents_code_cli/`
- `08_integration/22_deepagents_code_mcp_tools/`
- `08_integration/23_deepagents_code_memory_skills/`
- `08_integration/24_deepagents_code_remote_sandboxes/`
- `08_integration/25_deepagents_code_subagents/`
- `08_integration/26_deepagents_frontend/`
- `08_integration/27_agent_protocols/`

English mirrors and book/Typst chapter wiring were completed in `2026-06-21-typst-english-mirror-verification.md`.
