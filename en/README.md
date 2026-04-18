# Agent Engineering Notebooks

> Jupyter notebooks + Typst handbook covering **LLM agents from beginner to production**.
> 한국어: [../README.md](../README.md) · Handbook PDF: [`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf) · Release: [`v1.0.0`](https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks/releases/tag/v1.0.0)

---

## Getting Started

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync --python 3.12 --extra observability
cp .env.example .env      # at minimum, set OPENAI_API_KEY
uv run --python 3.12 jupyter lab
```

Required: `OPENAI_API_KEY`. Optional: `TAVILY_API_KEY` · `ANTHROPIC_API_KEY` · `LANGSMITH_API_KEY` · `LANGFUSE_SECRET_KEY`. See [`.env.example`](../.env.example).

---

## Curriculum — 8 Parts · 94 notebooks

| # | Track | Audience | Core topics |
|---|-------|----------|------------|
| **01** [`01_beginner/`](../01_beginner/) | Agent foundations (8) | First LLM agent | messages · prompts · ReAct · framework compare |
| **02** [`02_langchain/`](../02_langchain/) | LangChain v1 (13) | Production agents | `create_agent` · middleware · MCP · HITL |
| **03** [`03_langgraph/`](../03_langgraph/) | LangGraph v1 (13) | Complex workflows | `StateGraph` · checkpointers · subgraphs · Pregel |
| **04** [`04_deepagents/`](../04_deepagents/) | Deep Agents SDK (10) | All-in-one systems | `create_deep_agent` · backends · subagents · skills |
| **05** [`05_advanced/`](../05_advanced/) | Advanced patterns (10) | Multi-agent · deploy | middleware deep-dive · RAG · SQL · voice · prod |
| **06** [`06_examples/`](../06_examples/) | Applied examples (5) | Real projects | RAG · SQL · data analysis · ML · deep research |
| **07** [`07_integration/`](../07_integration/) | Ecosystem integrations (13) | External tools · providers | **Provider middleware 7 complete** / rest roadmapped |
| **08** [`08_langsmith/`](../08_langsmith/) | LangSmith (5) | Observability · eval | trace · dataset · evaluator · prompt hub · monitoring |

Per-notebook topics: see each folder's `README.md`.

---

## `07_integration/` · 13 categories

LangChain's 11 official integration categories + LangGraph Store + Observability.

| # | Category | Status |
|---|----------|--------|
| 01 [chat_models](../07_integration/01_chat_models/) | OpenAI · Anthropic · Google · Ollama · Bedrock · Groq · Mistral · Cohere · … | ⬜ |
| 02 [embeddings](../07_integration/02_embeddings/) | OpenAI · Cohere · Voyage · Ollama · HuggingFace | ⬜ |
| 03 [vectorstores](../07_integration/03_vectorstores/) | Chroma · PGVector · Pinecone · Qdrant · Weaviate · Milvus · ES | ⬜ |
| 04 [document_loaders](../07_integration/04_document_loaders/) | PDF · web · S3/GCS · Notion · Slack · GitHub | ⬜ |
| 05 [retrievers](../07_integration/05_retrievers/) | BM25 · MultiVector · Parent · SelfQuery · Tavily · Kendra | ⬜ |
| 06 [text_splitters](../07_integration/06_text_splitters/) | Recursive · Markdown · language-aware · Semantic | ⬜ |
| 07 [tools](../07_integration/07_tools/) | Search · code exec · SQL · Playwright · Gmail · GitHub | ⬜ |
| 08 [checkpointers](../07_integration/08_checkpointers/) | InMemory · SQLite · Postgres · CosmosDB | ⬜ |
| 09 [stores](../07_integration/09_stores/) | InMemoryStore · PostgresStore | ⬜ |
| 10 [sandboxes](../07_integration/10_sandboxes/) | Modal · Daytona · Runloop | ⬜ |
| **11** [**provider_middleware**](../07_integration/11_provider_middleware/) | **Anthropic 5 · Bedrock · OpenAI Moderation** | **✅ 7/7** |
| 12 [observability](../07_integration/12_observability/) | LangSmith · Langfuse · OTel | ⬜ |
| 13 [providers](../07_integration/13_providers/) | Anthropic · OpenAI · Google · AWS · … per-vendor catalog | ⬜ |

---

## 📖 Agent Handbook (PDF)

Typesetted in Typst — **8 Parts · 82 chapters**.

- `en/book/agent-handbook-en.pdf` — English (12 MB)
- `book/agent-handbook.pdf` — Korean (18 MB)

Local build:
```bash
typst compile --root . en/book/main.typ en/book/out/main.pdf  # en
typst compile --root . book/main.typ    book/out/main.pdf     # ko
```

### Part layout

| Part | Topic | Chapters |
|------|-------|---------|
| I | Agent foundations | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 13 |
| IV | Deep Agents (0.5 async subagents · production · context engineering · streaming · permissions) | 15 |
| V | Advanced patterns | 10 |
| VI | Applied examples | 5 |
| **VII** | **LangSmith** (new in v1) | 5 |
| **VIII** | **Integrations** (new in v1 — 7 provider-middleware chapters) | 9 |

---

## Tech stack

| Package | Min version | Use |
|---------|-------------|-----|
| `langchain` | 1.2 | Agents · tools · middleware |
| `langgraph` | 1.1 | State graph workflows |
| `deepagents` | 0.5 | All-in-one agent SDK |
| `langsmith` | 0.7 | Observability · evaluation · prompt hub |
| `langchain-openai` / `langchain-anthropic` / `langchain-aws` | — | Provider integrations |

Full dependency tree: [`../pyproject.toml`](../pyproject.toml)

---

## See also

- [`book/README.md`](book/README.md) — English handbook worktree & Typst build notes
- [`../docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md) — LangSmith · Langfuse setup
- [`../docs/MODEL_PROVIDERS.md`](../docs/MODEL_PROVIDERS.md) — OpenRouter · Ollama · vLLM · LM Studio
- [`../docs/SKILLS.md`](../docs/SKILLS.md) — LangChain Skills installation & usage
- [`../docs/skills/langchain-v1-modern.md`](../docs/skills/langchain-v1-modern.md) — v1 authoring guardrail
- [`../docs/translation/KO_EN_TRANSLATION_GUIDE.md`](../docs/translation/KO_EN_TRANSLATION_GUIDE.md) — KO ↔ EN translation guide
- [`../AGENTS.md`](../AGENTS.md) — Coding-agent project context

---

## License

MIT
