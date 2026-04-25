# Agent Engineering Notebooks

> LLM 에이전트를 **초급부터 프로덕션**까지 단계별로 배우는 Jupyter 실습 + Typst 핸드북.
> English: [en/README.md](en/README.md) · Handbook PDF: [`book/agent-handbook.pdf`](book/agent-handbook.pdf) · Release: [`v1.0.0`](https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks/releases/tag/v1.0.0)

---

## 시작하기

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync
cp .env.example .env      # OPENAI_API_KEY 최소 1개
uv run jupyter lab
```

필수: `OPENAI_API_KEY`. 선택: `TAVILY_API_KEY` · `ANTHROPIC_API_KEY` · `LANGSMITH_API_KEY` · `LANGFUSE_SECRET_KEY`. 자세한 내용은 [`.env.example`](.env.example).

---

## 커리큘럼 — 8 Parts · 94 노트북

| # | 트랙 | 대상 | 주요 기술 |
|---|------|------|----------|
| **01** [`01_beginner/`](01_beginner/) | 에이전트 입문 (8) | LLM 처음 | 메시지·프롬프트·ReAct·비교 |
| **02** [`02_langchain/`](02_langchain/) | LangChain v1 (13) | 프로덕션 에이전트 | `create_agent` · 미들웨어 · MCP · HITL |
| **03** [`03_langgraph/`](03_langgraph/) | LangGraph v1 (13) | 복잡한 워크플로 | `StateGraph` · 체크포인터 · subgraph · Pregel |
| **04** [`04_deepagents/`](04_deepagents/) | Deep Agents SDK (10) | 올인원 시스템 | `create_deep_agent` · backend · subagent · skill |
| **05** [`05_advanced/`](05_advanced/) | 고급 패턴 (10) | 멀티에이전트 · 배포 | 미들웨어 심화 · RAG · SQL · 보이스 · 프로덕션 |
| **06** [`06_examples/`](06_examples/) | 실전 예제 (5) | 실무 응용 | RAG · SQL · 데이터분석 · ML · 딥 리서치 |
| **07** [`07_integration/`](07_integration/) | 생태계 통합 (13 카테고리, **69 노트북**) | 외부 도구 · 공급자 | ✅ **전 카테고리 완료** (executed 42 / key·service-gated 27) |
| **08** [`08_langsmith/`](08_langsmith/) | LangSmith (5) | 관측·평가·프롬프트 | Trace · dataset · evaluator · prompt hub · monitoring |

노트북별 상세 토픽 → 각 폴더 `README.md` 참조.

---

## `07_integration/` · 13 카테고리

LangChain 공식 integrations 섹션 11개 + LangGraph Store + Observability.

| # | 카테고리 | 상태 |
|---|----------|------|
| 01 [chat_models](07_integration/01_chat_models/) | OpenAI · Anthropic · Google · Ollama · Bedrock · Groq · Mistral · Cohere · 라우터 | ✅ 9/9 |
| 02 [embeddings](07_integration/02_embeddings/) | OpenAI · Google · Cohere · Voyage · Ollama · HuggingFace | ✅ 6/6 |
| 03 [vectorstores](07_integration/03_vectorstores/) | InMemory/FAISS · Chroma · PGVector · Pinecone · Qdrant · Weaviate · Milvus · ES | ✅ 8/8 |
| 04 [document_loaders](07_integration/04_document_loaders/) | PDF · Web · Cloud Storage · Productivity · Structured | ✅ 5/5 |
| 05 [retrievers](07_integration/05_retrievers/) | BM25+Ensemble · MultiVector · SelfQuery · Web · Vendor | ✅ 5/5 |
| 06 [text_splitters](07_integration/06_text_splitters/) | Character/Recursive · Markdown/HTML/Code · Semantic | ✅ 3/3 |
| 07 [tools](07_integration/07_tools/) | Search · Code exec · SQL · Playwright · Productivity · Knowledge | ✅ 6/6 |
| 08 [checkpointers](07_integration/08_checkpointers/) | InMemory · SQLite · Postgres · CosmosDB | ✅ 4/4 |
| 09 [stores](07_integration/09_stores/) | InMemoryStore · PostgresStore | ✅ 2/2 |
| 10 [sandboxes](07_integration/10_sandboxes/) | Modal · Daytona · Runloop | ✅ 3/3 |
| 11 [provider_middleware](07_integration/11_provider_middleware/) | Anthropic 5 · Bedrock · OpenAI Moderation | ✅ 7/7 |
| 12 [observability](07_integration/12_observability/) | Langfuse · OpenTelemetry | ✅ 2/2 |
| 13 [providers](07_integration/13_providers/) | Anthropic · OpenAI · Google · AWS · Microsoft · Groq · HF · NVIDIA · Ollama | ✅ 9/9 |

---

## 📖 Agent Handbook (PDF)

Typst 로 조판한 **8 Parts · 82 chapters** 책.

- `book/agent-handbook.pdf` — 한국어 (18 MB)
- `en/book/agent-handbook-en.pdf` — English (12 MB)

로컬 빌드:
```bash
typst compile --root . book/main.typ    book/out/main.pdf      # ko
typst compile --root . en/book/main.typ en/book/out/main.pdf   # en
```

### Part 구성

| Part | 주제 | 챕터 수 |
|------|------|--------|
| I | 에이전트 입문 | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 13 |
| IV | Deep Agents (0.5 async subagents · production · context engineering · streaming · permissions) | 15 |
| V | 고급 패턴 | 10 |
| VI | 실전 응용 | 5 |
| **VII** | **LangSmith** (v1 신규) | 5 |
| **VIII** | **Integrations** (v1 신규 — provider middleware 7종 포함) | 9 |

---

## 기술 스택

| 패키지 | 최소 버전 | 용도 |
|--------|----------|------|
| `langchain` | 1.2 | 에이전트 · 도구 · 미들웨어 |
| `langgraph` | 1.1 | 상태 그래프 워크플로 |
| `deepagents` | 0.5 | 올인원 에이전트 SDK |
| `langsmith` | 0.7 | 관측 · 평가 · 프롬프트 허브 |
| `langchain-openai` / `langchain-anthropic` / `langchain-aws` | — | 공급자 통합 |

전체 의존성: [`pyproject.toml`](pyproject.toml)

---

## 더 보기

- [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) — LangSmith · Langfuse 가이드
- [`docs/MODEL_PROVIDERS.md`](docs/MODEL_PROVIDERS.md) — OpenRouter · Ollama · vLLM · LM Studio
- [`docs/SKILLS.md`](docs/SKILLS.md) — LangChain Skills 사용법
- [`docs/skills/langchain-v1-modern.md`](docs/skills/langchain-v1-modern.md) — v1 작성 가드레일
- [`AGENTS.md`](AGENTS.md) — 코딩 에이전트용 프로젝트 컨텍스트

---

## 라이선스

MIT
