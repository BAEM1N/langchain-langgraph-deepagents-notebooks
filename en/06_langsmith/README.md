# 06. LangSmith — Tracing · Evaluation · Prompt Ops

This folder is the English source-notebook mirror for the LangSmith track. It covers the operational loop around LangChain, LangGraph, and Deep Agents applications: trace inspection, datasets, evaluation, prompt versioning, production monitoring, and Agent Evals.

---

## Curriculum

| # | File | Topic | Runtime behavior |
|---|---|---|---|
| 01 | [`01_quickstart.ipynb`](01_quickstart.ipynb) | API keys, first trace, UI tour | trace read/write |
| 02 | [`02_tracing_agents.ipynb`](02_tracing_agents.ipynb) | LangGraph subgraph traces, Deep Agents subagent traces, feedback, filters | some feedback writes |
| 03 | [`03_datasets_and_evaluation.ipynb`](03_datasets_and_evaluation.ipynb) | datasets, code evaluators, LLM-as-judge, pairwise/summary evaluators | dataset/evaluate writes |
| 04 | [`04_prompt_hub.ipynb`](04_prompt_hub.ipynb) | `push_prompt`/`pull_prompt`, commit SHA pinning, tags | prompt writes |
| 05 | [`05_production_monitoring.ipynb`](05_production_monitoring.ipynb) | dashboards, online autoeval, feedback API, sampling, PII hygiene | monitoring/read examples |
| 06 | [`06_agent_evals.ipynb`](06_agent_evals.ipynb) | AgentEvals trajectory match, LLM-as-judge, LangSmith experiment | dataset/evaluate writes |

---

## Setup

```bash
uv sync
cp .env.example .env
```

Minimum `.env`:

```dotenv
OPENAI_API_KEY=sk-...
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langchain-langgraph-deepagents-notebooks
```

---

## Validation

Default smoke runs skip or guard remote mutation cells. To validate real LangSmith resource writes, run with the explicit mutation flag:

```bash
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --only en/06_langsmith \
  --force --timeout 300 --allow-langsmith-mutations
```

The local harness namespaces created LangSmith resources with a `local-exec-*` prefix.

---

## Related

- [`../../06_langsmith/README.md`](../../06_langsmith/README.md) — Korean LangSmith track
- [`../../docs/OBSERVABILITY.md`](../../docs/OBSERVABILITY.md)
- [`../../docs/verification/2026-06-17-tutorial-gap-analysis.md`](../../docs/verification/2026-06-17-tutorial-gap-analysis.md)
