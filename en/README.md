# Agent Engineering Notebooks

Jupyter Notebook learning materials for studying **LLM-based AI agent development step by step, from beginner concepts to production deployment**.

> Korean version: [../README.md](../README.md)

---

## Project Structure

```text
langchain-langgraph-deepagents-notebooks/
├── .env.example                 # API key template
├── pyproject.toml               # Dependency management (uv)
├── 01_beginner/                 # Korean beginner track (8 notebooks)
├── 02_langchain/                # Korean intermediate — LangChain v1 (13 notebooks)
├── 03_langgraph/                # Korean intermediate — LangGraph v1 (13 notebooks)
├── 04_deepagents/               # Korean intermediate — Deep Agents SDK (10 notebooks)
├── 05_advanced/                 # Korean advanced track (10 notebooks)
├── 06_examples/                 # Korean applied examples (5 notebooks)
├── en/                          # English notebook tree + English handbook assets
└── docs/                        # Reference documents and guides
```

---

## Getting Started

```bash
# 1. Clone the repository
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks

# 2. Install dependencies (uv)
uv sync --python 3.12 --extra observability

# 3. Configure API keys
cp .env.example .env
# Open .env and enter your real keys

# 4. Launch Jupyter
uv run --python 3.12 jupyter lab
```

### Environment Variables

| Variable | Purpose | Required |
|------|------|------|
| `OPENAI_API_KEY` | LLM calls | **Required** |
| `TAVILY_API_KEY` | Web search tool | Optional |
| `LANGSMITH_API_KEY` | LangSmith tracing | Optional |
| `LANGFUSE_SECRET_KEY` | Langfuse tracing | Optional |

For the full list, see [`.env.example`](../.env.example).

---

## Step-by-Step Curriculum

### 1. Beginner — Agent Foundations (`01_beginner/`, 8 notebooks)

> Recommended for developers with basic programming experience who are new to LLM agents.

| # | File | Topic | Core Content |
|---|------|------|-----------|
| 00 | `00_setup.ipynb` | Environment Setup | `.env`, `ChatOpenAI`, first model check |
| 01 | `01_llm_basics.ipynb` | LLM Basics | message roles (`system`/`human`/`ai`), prompts, streaming |
| 02 | `02_langchain_basics.ipynb` | LangChain Basics | `@tool`, `create_agent()`, ReAct loop |
| 03 | `03_langchain_memory.ipynb` | LangChain Memory | `InMemorySaver`, `thread_id`, multi-turn memory |
| 04 | `04_langgraph_basics.ipynb` | LangGraph Basics | `StateGraph`, nodes, edges, `MessagesState` |
| 05 | `05_deep_agents_basics.ipynb` | Deep Agents Basics | `create_deep_agent()`, built-in tools, custom tools |
| 06 | `06_comparison.ipynb` | Framework Comparison | LangChain vs LangGraph vs Deep Agents |
| 07 | `07_mini_project.ipynb` | Mini Project | Tavily search + summarization research agent |

### 2. Intermediate — LangChain v1 (`02_langchain/`, 13 notebooks)

> Recommended for learners who want to build production-oriented agents with LangChain.

| # | File | Topic | Core Content |
|---|------|------|-----------|
| 01 | `01_introduction.ipynb` | Introduction to LangChain | framework overview, architecture, ReAct pattern |
| 02 | `02_quickstart.ipynb` | First Agent | `create_agent()`, `invoke()`, `stream()` |
| 03 | `03_models_and_messages.ipynb` | Models and Messages | `init_chat_model()`, message types, multimodal input |
| 04 | `04_tools_and_structured_output.ipynb` | Tools and Structured Output | `@tool`, Pydantic, `with_structured_output()` |
| 05 | `05_memory_and_streaming.ipynb` | Memory and Streaming | short/long-term memory, streaming modes |
| 06 | `06_middleware.ipynb` | Middleware | built-in/custom middleware, safety |
| 07 | `07_hitl_and_runtime.ipynb` | HITL and Runtime | human-in-the-loop, ToolRuntime, context engineering, MCP |
| 08 | `08_multi_agent.ipynb` | Multi-Agent | subagents, handoffs, skills, routing |
| 09 | `09_custom_workflow_and_rag.ipynb` | Custom Workflow and RAG | StateGraph, conditional edges, retrieval |
| 10 | `10_production.ipynb` | Production | Studio, testing, UI, deployment, observability |
| 11 | `11_mcp.ipynb` | MCP | Model Context Protocol, adapters, stdio/SSE |
| 12 | `12_frontend_streaming.ipynb` | Frontend Streaming | `useStream`, `StreamEvent`, custom events |
| 13 | `13_guardrails.ipynb` | Guardrails | PII detection, HITL, custom middleware, multi-guardrail setups |

### 3. Intermediate — LangGraph v1 (`03_langgraph/`, 13 notebooks)

> Recommended for learners who need complex workflows and stateful orchestration.

| # | File | Topic | Core Content |
|---|------|------|-----------|
| 01 | `01_introduction.ipynb` | Introduction to LangGraph | architecture, Graph API vs Functional API, core concepts |
| 02 | `02_graph_api.ipynb` | Graph API Basics | StateGraph, nodes, edges, reducers, conditional branching |
| 03 | `03_functional_api.ipynb` | Functional API Basics | `@entrypoint`, `@task`, `previous`, `entrypoint.final` |
| 04 | `04_workflows.ipynb` | Workflow Patterns | chaining, parallelization, routing, orchestrator patterns |
| 05 | `05_agents.ipynb` | Building Agents | ReAct agents (Graph/Functional), `bind_tools()` |
| 06 | `06_persistence_and_memory.ipynb` | Persistence and Memory | checkpointers, InMemoryStore, durable execution |
| 07 | `07_streaming.ipynb` | Streaming | values, updates, messages, custom modes |
| 08 | `08_interrupts_and_time_travel.ipynb` | Interrupts and Time Travel | `interrupt()`, `Command(resume=)`, checkpoint replay |
| 09 | `09_subgraphs.ipynb` | Subgraphs | modular graphs, state mapping, subgraph streaming |
| 10 | `10_production.ipynb` | Production | Studio, testing, deployment, observability, Pregel |
| 11 | `11_local_server.ipynb` | Local Server | `langgraph dev`, Studio, Python SDK, REST API |
| 12 | `12_durable_execution.ipynb` | Durable Execution | checkpointers, `@task`, recovery, durability modes |
| 13 | `13_api_guide_and_pregel.ipynb` | API Guide and Pregel | Graph vs Functional API, Pregel runtime, supersteps |

### 4. Intermediate — Deep Agents SDK (`04_deepagents/`, 10 notebooks)

> Recommended for learners who want to build all-in-one agent systems quickly.

| # | File | Topic | Core APIs |
|---|------|------|----------|
| 01 | `01_introduction.ipynb` | Introduction to Deep Agents | architecture, key concepts, installation check |
| 02 | `02_quickstart.ipynb` | First Agent | `create_deep_agent()`, `invoke()`, `stream()` |
| 03 | `03_customization.ipynb` | Customization | model selection, system prompts, tools, `response_format` |
| 04 | `04_backends.ipynb` | Backends | State, Filesystem, Store, Composite |
| 05 | `05_subagents.ipynb` | Subagents | `SubAgent`, `CompiledSubAgent`, pipelines |
| 06 | `06_memory_and_skills.ipynb` | Memory and Skills | `memory`, `skills`, AGENTS.md, SKILL.md |
| 07 | `07_advanced.ipynb` | Advanced Features | HITL, streaming, sandboxes, ACP, CLI |
| 08 | `08_harness.ipynb` | Agent Harness | AgentHarness, filesystem, context management, subagents |
| 09 | `09_comparison.ipynb` | Framework Comparison | Deep Agents vs OpenCode vs Claude Agent SDK |
| 10 | `10_sandboxes_and_acp.ipynb` | Sandboxes and ACP | Modal/Daytona/Runloop, Agent Client Protocol |

### 5. Advanced — Production & Multi-Agent Patterns (`05_advanced/`, 10 notebooks)

> Recommended for learners designing production deployments and multi-agent architectures.

| # | File | Topic | Core Content |
|---|------|------|-----------|
| 00 | `00_migration.ipynb` | Migration | breaking changes, import paths, `create_agent` |
| 01 | `01_middleware.ipynb` | Advanced Middleware | built-in middleware types, custom design, execution order |
| 02 | `02_multi_agent_subagents.ipynb` | Multi-Agent: Subagents | supervisor–subagent hierarchy, HITL, ToolRuntime |
| 03 | `03_multi_agent_handoffs_router.ipynb` | Multi-Agent: Handoffs and Router | state transitions, `Command`, Send API routing |
| 04 | `04_context_memory.ipynb` | Context and Memory | `context_schema`, InMemoryStore, skills patterns |
| 05 | `05_agentic_rag.ipynb` | Agentic RAG | retrieval, relevance grading, query rewriting |
| 06 | `06_sql_agent.ipynb` | SQL Agent | SQLDatabaseToolkit, `interrupt()`, `Command(resume=)` |
| 07 | `07_data_analysis.ipynb` | Data Analysis | Deep Agents + sandbox, Slack integration, streaming |
| 08 | `08_voice_agent.ipynb` | Voice Agent | STT/Agent/TTS sandwich pattern, sub-700ms design |
| 09 | `09_production.ipynb` | Production Deployment | testing, LangSmith evaluation, tracing, LangGraph Platform |

### 6. Applied Examples (`06_examples/`, 5 notebooks)

> Recommended for learners who want to follow end-to-end practical agent patterns with Deep Agents.

| # | File | Topic | Core Content |
|---|------|------|-----------|
| 01 | `01_rag_agent.ipynb` | RAG Agent | InMemoryVectorStore, `content_and_artifact`, `create_deep_agent()` |
| 02 | `02_sql_agent.ipynb` | SQL Agent | SQLDatabaseToolkit, AGENTS.md safety rules, HITL interrupt |
| 03 | `03_data_analysis_agent.ipynb` | Data Analysis Agent | LocalShellBackend, `run_pandas`, streaming, multi-turn analysis |
| 04 | `04_ml_agent.ipynb` | ML Agent | FilesystemBackend, `run_ml_code`, EDA → model comparison |
| 05 | `05_deep_research_agent.ipynb` | Deep Research Agent | parallel subagents, `think_tool`, five-step workflow |

---

## Execution Status

| Item | Status |
|------|--------|
| English notebooks | **59 / 59 executed successfully** |
| Execution summary | [EXECUTION_STATUS.md](EXECUTION_STATUS.md) |
| Raw results | [execution_results.tsv](execution_results.tsv) |

---

## 📖 English Agent Handbook

The English handbook assets and Typst sources are organized under [`book/`](book/).

> **[`book/agent-handbook-en.pdf`](book/agent-handbook-en.pdf)**

The full-compile artifact is also available:

> **[`book/agent-handbook-en-full.pdf`](book/agent-handbook-en-full.pdf)**

---

## Additional Documents

| Document | Description |
|------|------|
| [`book/README.md`](book/README.md) | English handbook worktree and Typst build notes |
| [`book/main.typ`](book/main.typ) | English handbook Typst entry point |
| [`../docs/translation/KO_EN_TRANSLATION_GUIDE.md`](../docs/translation/KO_EN_TRANSLATION_GUIDE.md) | KO ↔ EN translation guide |
| [`../docs/translation/ko_en_term_map.csv`](../docs/translation/ko_en_term_map.csv) | Translation term map CSV |
| [`../book/agent-handbook.pdf`](../book/agent-handbook.pdf) | Korean handbook PDF |
| [`../AGENTS.md`](../AGENTS.md) | Project context for coding agents |

---

## License

MIT
