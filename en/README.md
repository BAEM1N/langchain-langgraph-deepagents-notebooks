# Agent Engineering Notebooks

> Korean-first Jupyter notebooks and Typst handbooks for learning LangChain, LangGraph, Deep Agents, and LangSmith from **agent foundations to production-grade evaluation and integrations**.
>
> Korean: [../README.md](../README.md) · Korean PDF: [`../book/agent-handbook.pdf`](../book/agent-handbook.pdf) · English PDF: [`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf)

---

## What this repository covers

- **LLM agent foundations**: messages, prompts, ReAct-style loops, and framework selection.
- **LangChain v1**: `create_agent`, tools, middleware, MCP, guardrails, and event streaming.
- **LangGraph v1**: `StateGraph`, persistence, interrupts, subgraphs, streaming, and fault tolerance.
- **Deep Agents SDK**: backends, subagents, skills, async subagents, interpreters, rubrics, sandboxes, and ACP.
- **LangSmith**: traces, datasets, evaluations, prompt hub, monitoring, and Agent Evals.
- **Applied examples**: RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG, and a content builder agent.
- **Integration catalog**: providers, vector stores, retrievers, sandboxes, observability, and local/cloud runtime integrations.

---

## Quick start

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync
cp .env.example .env      # set at least OPENAI_API_KEY
uv run jupyter lab
```

Keys:

| Type | Environment variable | Purpose |
|---|---|---|
| Required | `OPENAI_API_KEY` | Default 01~07 live execution |
| Recommended | `LANGSMITH_API_KEY`, `LANGSMITH_TRACING=true` | Trace/eval logging |
| Optional | `TAVILY_API_KEY` | Search examples |
| Optional | `ANTHROPIC_API_KEY`, Google/AWS provider keys | `08_integration` provider notebooks |
| Optional | `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY` | Langfuse observability |

See [`.env.example`](../.env.example) for the full template.

---

## Repository map

Tracked notebook count:

| Area | Path | Notebooks | Role |
|---|---:|---:|---|
| Korean core | `01_beginner`~`07_examples` | **69** | Primary source of truth and default validation scope |
| English mirror | `en/01_beginner`~`en/07_examples` | **64** | English learner path; `en/06_langsmith` currently starts with Agent Evals |
| Integrations | `08_integration` | **69** | Provider/cloud/local-service integration catalog; excluded from default live harness |
| **Total** | all tracked `.ipynb` files | **202** | Korean, English, and integration notebooks |

### Core curriculum

| Part | Path | Notebooks | Core topics |
|---:|---|---:|---|
| 01 | [`01_beginner/`](../01_beginner/) | 8 | LLM basics, messages, prompts, ReAct, framework comparison |
| 02 | [`02_langchain/`](../02_langchain/) | 13 | LangChain v1, `create_agent`, tools, middleware, MCP, guardrails, streaming |
| 03 | [`03_langgraph/`](../03_langgraph/) | 14 | Graph/Functional API, persistence, interrupts, subgraphs, local server, Pregel, fault tolerance |
| 04 | [`04_deepagents/`](../04_deepagents/) | 11 | `create_deep_agent`, backends, subagents, memory/skills, interpreters, async subagents |
| 05 | [`05_advanced/`](../05_advanced/) | 10 | migration, middleware, multi-agent, RAG, SQL, data analysis, voice, production |
| 06 | [`06_langsmith/`](../06_langsmith/) | 6 | tracing, datasets/evaluation, prompt hub, monitoring, Agent Evals |
| 07 | [`07_examples/`](../07_examples/) | 7 | RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG, content builder |
| 08 | [`08_integration/`](../08_integration/) | 69 | chat models, embeddings, vector stores, retrievers, tools, sandboxes, providers, observability |

---

## Recommended learning paths

| Goal | Suggested path |
|---|---|
| Start from scratch | `01_beginner` → `02_langchain/01~05` |
| Build LangChain apps | `02_langchain` → `05_advanced/01_middleware.ipynb` → `07_examples` |
| Learn stateful workflows | `03_langgraph` → `03_langgraph/14_fault_tolerance.ipynb` → `05_advanced/02~03` |
| Build with Deep Agents | `04_deepagents` → `04_deepagents/11_async_subagents.ipynb` → `07_examples/07_content_builder_agent.ipynb` |
| Operate and evaluate agents | `06_langsmith` → `05_advanced/09_production.ipynb` |
| Integrate providers and services | The relevant `08_integration/NN_*` category |

`08_integration/` mixes provider keys, local services, and paid sandboxes, so it is intentionally excluded from the default smoke harness.

---

## Agent Handbook

The repository also maintains Typst-generated PDF handbooks.

| Language | PDF | Typst entry | Chapters |
|---|---|---|---:|
| Korean | [`../book/agent-handbook.pdf`](../book/agent-handbook.pdf) | [`../book/main.typ`](../book/main.typ) | 81 |
| English | [`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf) | [`book/main.typ`](book/main.typ) | 81 |

Build:

```bash
python book/scripts/build.py      # Korean PDF, from repo root
python en/book/scripts/build.py   # English PDF, from repo root
```

Part layout:

| Part | Topic | Chapters |
|---:|---|---:|
| I | Agent foundations | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 14 |
| IV | Deep Agents | 15 |
| V | Advanced patterns | 10 |
| VI | LangSmith | 6 |
| VII | Applied examples | 7 |
| VIII | Integrations | 8 |

Note: Part IV late chapters and Part VI include manually maintained Typst. Do not add those chapters to notebook YAML generation unless you intentionally migrate the manual chapters.

---

## Validation policy

Default validation targets only 01~07 notebooks. `08_integration/` is excluded.

```bash
# Run changed 01~07 notebooks with gpt-4.1 on transformed local copies
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300

# Allow real LangSmith dataset/prompt/evaluate writes with a local-exec prefix
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300 --allow-langsmith-mutations
```

The harness:

- excludes `08_integration/`,
- executes copied notebooks under `local/notebook_execution_01_07_gpt41/`,
- rewrites source model strings to `gpt-4.1` in the local copies,
- logs to the LangSmith project `langchain-langgraph-deepagents-notebooks`, and
- namespaces LangSmith mutations with `local-exec-*` prefixes.

Recent verification evidence is in [`../docs/verification/2026-06-17-tutorial-gap-analysis.md`](../docs/verification/2026-06-17-tutorial-gap-analysis.md).

---

## Tech stack

| Package | Baseline | Purpose |
|---|---|---|
| `python` | `>=3.12` | Notebook runtime |
| `uv` | lockfile-based | Dependency management |
| `langchain` | `>=1.3.9` | agents, tools, middleware, streaming |
| `langchain-core` | `>=1.4.7` | message/tool/model core abstractions |
| `langgraph` | `>=1.2.5` | state graphs, persistence, fault tolerance |
| `deepagents` | `>=0.6.10` | Deep Agents SDK, backends, subagents, skills |
| `agentevals` | `>=0.0.9` | trajectory matching and LLM-as-judge evals |
| `langsmith` | lockfile | tracing, datasets, experiments, prompt hub |
| `langchain-openai` | `>=1.3.2` | OpenAI model integration |
| `pymupdf4llm` | `>=1.27.2.3` | multimodal PDF RAG preprocessing |

Dependencies are managed through [`../pyproject.toml`](../pyproject.toml) and `uv.lock`.

---

## See also

- [`../AGENTS.md`](../AGENTS.md) — project context and rules for coding agents
- [`../docs/skills/`](../docs/skills/) — LangChain/LangGraph/Deep Agents authoring guardrails
- [`../docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md) — LangSmith/Langfuse setup
- [`../docs/MODEL_PROVIDERS.md`](../docs/MODEL_PROVIDERS.md) — provider selection and local model options
- [`../docs/translation/KO_EN_TRANSLATION_GUIDE.md`](../docs/translation/KO_EN_TRANSLATION_GUIDE.md) — KO ↔ EN translation guide
- [`../07_examples/skills/`](../07_examples/skills/) — SKILL.md files for applied examples

---

## License

MIT
