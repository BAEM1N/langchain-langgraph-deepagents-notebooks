# Agent Engineering Notebooks

> Korean-first Jupyter labs and a Typst handbook for learning **LLM agents from fundamentals to production operations**.  
> 한국어: [../README.md](../README.md) · Handbook PDF: [`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf) · Release: [`v1.0.0`](https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks/releases/tag/v1.0.0)

---

## Quick start

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync
cp .env.example .env      # set at least OPENAI_API_KEY
uv run jupyter lab
```

- **Required key**: `OPENAI_API_KEY`
- **Optional keys**: `TAVILY_API_KEY`, `ANTHROPIC_API_KEY`, `LANGSMITH_API_KEY`, `LANGFUSE_SECRET_KEY`
- See [`.env.example`](../.env.example) for the environment template.

---

## Curriculum at a glance — 8 Parts · 134 notebooks

| # | Track | Audience | Notebooks | Core topics |
|---|-------|----------|-----------|-------------|
| **01** | [`01_beginner/`](../01_beginner/) | New LLM agent learners | 8 | messages · prompts · ReAct · framework comparison |
| **02** | [`02_langchain/`](../02_langchain/) | LangChain v1 agent builders | 13 | `create_agent` · tools · middleware · MCP · HITL |
| **03** | [`03_langgraph/`](../03_langgraph/) | State graph and workflow learners | 13 | `StateGraph` · checkpointers · subgraphs · Pregel |
| **04** | [`04_deepagents/`](../04_deepagents/) | All-in-one agent system builders | 11 | `create_deep_agent` · backends · subagents · skills · async subagents |
| **05** | [`05_advanced/`](../05_advanced/) | Advanced pattern and operations learners | 10 | multi-agent · RAG · SQL · voice · production |
| **06** | [`07_examples/`](../07_examples/) | Applied project learners | 5 | RAG · SQL · data analysis · ML · deep research |
| **07** | [`08_integration/`](../08_integration/) | External tool and provider integrators | 69 | 13 LangChain/LangGraph ecosystem integration categories |
| **08** | [`06_langsmith/`](../06_langsmith/) | Observability, evaluation, and prompt-ops learners | 5 | trace · dataset · evaluator · prompt hub · monitoring |

For per-notebook details, open the `README.md` inside each folder.

---

## `08_integration/` — 13 integration categories

This section combines LangChain's 11 official integration categories with LangGraph Store and Observability.

| # | Category | Coverage | Status |
|---|----------|----------|--------|
| 01 | [chat_models](../08_integration/01_chat_models/) | OpenAI · Anthropic · Google · Ollama · Bedrock · Groq · Mistral · Cohere · routers | ✅ 9/9 |
| 02 | [embeddings](../08_integration/02_embeddings/) | OpenAI · Google · Cohere · Voyage · Ollama · HuggingFace | ✅ 6/6 |
| 03 | [vectorstores](../08_integration/03_vectorstores/) | InMemory/FAISS · Chroma · PGVector · Pinecone · Qdrant · Weaviate · Milvus · Elasticsearch | ✅ 8/8 |
| 04 | [document_loaders](../08_integration/04_document_loaders/) | PDF · Web · Cloud Storage · Productivity · Structured/Code | ✅ 5/5 |
| 05 | [retrievers](../08_integration/05_retrievers/) | BM25+Ensemble · MultiVector · SelfQuery · Web · vendor-managed | ✅ 5/5 |
| 06 | [text_splitters](../08_integration/06_text_splitters/) | Character/Recursive · Markdown/HTML/Code · Semantic | ✅ 3/3 |
| 07 | [tools](../08_integration/07_tools/) | Search · code execution · SQL · Playwright · productivity · knowledge | ✅ 6/6 |
| 08 | [checkpointers](../08_integration/08_checkpointers/) | InMemory · SQLite · Postgres · CosmosDB | ✅ 4/4 |
| 09 | [stores](../08_integration/09_stores/) | InMemoryStore · PostgresStore | ✅ 2/2 |
| 10 | [sandboxes](../08_integration/10_sandboxes/) | Modal · Daytona · Runloop | ✅ 3/3 |
| 11 | [provider_middleware](../08_integration/11_provider_middleware/) | Five Anthropic patterns · Bedrock · OpenAI Moderation | ✅ 7/7 |
| 12 | [observability](../08_integration/12_observability/) | Langfuse · OpenTelemetry | ✅ 2/2 |
| 13 | [providers](../08_integration/13_providers/) | Anthropic · OpenAI · Google · AWS · Microsoft · Groq · HuggingFace · NVIDIA · Ollama | ✅ 9/9 |

---

## 📖 Agent Handbook

A Typst-typeset handbook with **8 Parts · 82 chapters**.

- English PDF: [`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf) (12 MB)
- Korean PDF: [`../book/agent-handbook.pdf`](../book/agent-handbook.pdf) (18 MB)

Local build:

```bash
typst compile --root . en/book/main.typ en/book/out/main.pdf   # en
typst compile --root . book/main.typ    book/out/main.pdf      # ko
```

### Handbook part layout

| Part | Topic | Chapters |
|------|-------|----------|
| I | Agent foundations | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 13 |
| IV | Deep Agents: async subagents · production · context engineering · streaming · permissions | 15 |
| V | Advanced patterns | 10 |
| **VI** | **LangSmith** | 5 |
| VII | Applied examples | 5 |
| VIII | Integrations: including 7 provider-middleware chapters | 9 |

---

## Tech stack

| Package | Minimum version | Use |
|---------|-----------------|-----|
| `langchain` | 1.2 | agents · tools · middleware |
| `langgraph` | 1.0 | state graph workflows |
| `deepagents` | 0.4.4 | all-in-one agent SDK |
| `langsmith` | 0.3 | observability · evaluation · prompt hub |
| `langchain-openai` | 1.1.10 | OpenAI model integration |
| `langchain-community` | 0.4 | community integrations |

The full dependency set is managed in [`../pyproject.toml`](../pyproject.toml).

---

## Recommended learning path

1. Start with `01_beginner/` to learn LLM messages, prompts, and basic agent flows.
2. Go deep into one core layer: `02_langchain/`, `03_langgraph/`, or `04_deepagents/`.
3. Use `05_advanced/` and `06_langsmith/` for operations, scaling, and evaluation patterns.
4. Build practical confidence with `07_examples/` and the integration labs in `08_integration/`.

---

## See also

- [`book/README.md`](book/README.md) — English handbook worktree and Typst build notes
- [`../docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md) — LangSmith · Langfuse setup
- [`../docs/MODEL_PROVIDERS.md`](../docs/MODEL_PROVIDERS.md) — OpenRouter · Ollama · vLLM · LM Studio
- [`../docs/SKILLS.md`](../docs/SKILLS.md) — LangChain Skills installation and usage
- [`../docs/skills/langchain-v1-modern.md`](../docs/skills/langchain-v1-modern.md) — LangChain v1 authoring guardrails
- [`../docs/translation/KO_EN_TRANSLATION_GUIDE.md`](../docs/translation/KO_EN_TRANSLATION_GUIDE.md) — KO ↔ EN translation guide
- [`../AGENTS.md`](../AGENTS.md) — Coding-agent project context

---

## License

MIT
