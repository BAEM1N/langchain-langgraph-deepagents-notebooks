# Agent Engineering Notebooks

> LLM 에이전트를 **기초부터 프로덕션 운영**까지 단계별로 익히는 한국어 Jupyter 실습 자료와 Typst 핸드북입니다.  
> English: [en/README.md](en/README.md) · Handbook PDF: [`book/agent-handbook.pdf`](book/agent-handbook.pdf) · Release: [`v1.0.0`](https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks/releases/tag/v1.0.0)

---

## 빠른 시작

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync
cp .env.example .env      # 최소 OPENAI_API_KEY 설정
uv run jupyter lab
```

- **필수 키**: `OPENAI_API_KEY`
- **선택 키**: `TAVILY_API_KEY`, `ANTHROPIC_API_KEY`, `LANGSMITH_API_KEY`, `LANGFUSE_SECRET_KEY`
- 환경 변수 예시는 [`.env.example`](.env.example)을 확인하세요.

---

## 커리큘럼 한눈에 보기 — 8 Parts · 134 노트북

| # | 트랙 | 대상 | 노트북 | 핵심 주제 |
|---|------|------|--------|----------|
| **01** | [`01_beginner/`](01_beginner/) | LLM 에이전트 입문자 | 8 | 메시지 · 프롬프트 · ReAct · 프레임워크 비교 |
| **02** | [`02_langchain/`](02_langchain/) | LangChain v1 기반 에이전트 개발자 | 13 | `create_agent` · 도구 · 미들웨어 · MCP · HITL |
| **03** | [`03_langgraph/`](03_langgraph/) | 상태 그래프와 복잡한 워크플로 학습자 | 13 | `StateGraph` · 체크포인터 · subgraph · Pregel |
| **04** | [`04_deepagents/`](04_deepagents/) | 올인원 에이전트 시스템 구축자 | 11 | `create_deep_agent` · backend · subagent · skill · async subagents |
| **05** | [`05_advanced/`](05_advanced/) | 고급 패턴과 운영 설계 학습자 | 10 | 멀티에이전트 · RAG · SQL · 보이스 · 프로덕션 |
| **06** | [`07_examples/`](07_examples/) | 실전 응용 프로젝트 학습자 | 5 | RAG · SQL · 데이터 분석 · ML · 딥 리서치 |
| **07** | [`08_integration/`](08_integration/) | 외부 도구·공급자 통합 개발자 | 69 | LangChain/LangGraph 생태계 통합 13개 카테고리 |
| **08** | [`06_langsmith/`](06_langsmith/) | 관측·평가·프롬프트 운영 학습자 | 5 | Trace · dataset · evaluator · prompt hub · monitoring |

노트북별 세부 토픽은 각 폴더의 `README.md`에서 확인할 수 있습니다.

---

## `08_integration/` — 13개 통합 카테고리

LangChain 공식 integrations 섹션 11개에 LangGraph Store와 Observability를 더해 구성했습니다.

| # | 카테고리 | 내용 | 상태 |
|---|----------|------|------|
| 01 | [chat_models](08_integration/01_chat_models/) | OpenAI · Anthropic · Google · Ollama · Bedrock · Groq · Mistral · Cohere · 라우터 | ✅ 9/9 |
| 02 | [embeddings](08_integration/02_embeddings/) | OpenAI · Google · Cohere · Voyage · Ollama · HuggingFace | ✅ 6/6 |
| 03 | [vectorstores](08_integration/03_vectorstores/) | InMemory/FAISS · Chroma · PGVector · Pinecone · Qdrant · Weaviate · Milvus · Elasticsearch | ✅ 8/8 |
| 04 | [document_loaders](08_integration/04_document_loaders/) | PDF · Web · Cloud Storage · Productivity · Structured/Code | ✅ 5/5 |
| 05 | [retrievers](08_integration/05_retrievers/) | BM25+Ensemble · MultiVector · SelfQuery · Web · Vendor-managed | ✅ 5/5 |
| 06 | [text_splitters](08_integration/06_text_splitters/) | Character/Recursive · Markdown/HTML/Code · Semantic | ✅ 3/3 |
| 07 | [tools](08_integration/07_tools/) | Search · Code execution · SQL · Playwright · Productivity · Knowledge | ✅ 6/6 |
| 08 | [checkpointers](08_integration/08_checkpointers/) | InMemory · SQLite · Postgres · CosmosDB | ✅ 4/4 |
| 09 | [stores](08_integration/09_stores/) | InMemoryStore · PostgresStore | ✅ 2/2 |
| 10 | [sandboxes](08_integration/10_sandboxes/) | Modal · Daytona · Runloop | ✅ 3/3 |
| 11 | [provider_middleware](08_integration/11_provider_middleware/) | Anthropic 5종 · Bedrock · OpenAI Moderation | ✅ 7/7 |
| 12 | [observability](08_integration/12_observability/) | Langfuse · OpenTelemetry | ✅ 2/2 |
| 13 | [providers](08_integration/13_providers/) | Anthropic · OpenAI · Google · AWS · Microsoft · Groq · HuggingFace · NVIDIA · Ollama | ✅ 9/9 |

---

## 📖 Agent Handbook

Typst로 조판한 **8 Parts · 82 chapters** 핸드북입니다.

- 한국어 PDF: [`book/agent-handbook.pdf`](book/agent-handbook.pdf) (18 MB)
- English PDF: [`en/book/agent-handbook-en.pdf`](en/book/agent-handbook-en.pdf) (12 MB)

로컬 빌드:

```bash
typst compile --root . book/main.typ    book/out/main.pdf      # ko
typst compile --root . en/book/main.typ en/book/out/main.pdf   # en
```

### 핸드북 Part 구성

| Part | 주제 | 챕터 수 |
|------|------|--------|
| I | 에이전트 입문 | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 13 |
| IV | Deep Agents: async subagents · production · context engineering · streaming · permissions | 15 |
| V | 고급 패턴 | 10 |
| **VI** | **LangSmith** | 5 |
| VII | 실전 응용 예제 | 5 |
| VIII | Integrations: provider middleware 7종 포함 | 9 |

---

## 기술 스택

| 패키지 | 최소 버전 | 용도 |
|--------|----------|------|
| `langchain` | 1.2 | 에이전트 · 도구 · 미들웨어 |
| `langgraph` | 1.0 | 상태 그래프 워크플로 |
| `deepagents` | 0.4.4 | 올인원 에이전트 SDK |
| `langsmith` | 0.3 | 관측 · 평가 · 프롬프트 허브 |
| `langchain-openai` | 1.1.10 | OpenAI 모델 통합 |
| `langchain-community` | 0.4 | 커뮤니티 통합 |

전체 의존성은 [`pyproject.toml`](pyproject.toml)을 기준으로 관리합니다.

---

## 학습 순서 추천

1. `01_beginner/`에서 LLM 메시지, 프롬프트, 간단한 에이전트 흐름을 익힙니다.
2. 목적에 맞게 `02_langchain/`, `03_langgraph/`, `04_deepagents/` 중 하나를 깊게 학습합니다.
3. 운영·확장 패턴은 `05_advanced/`와 `06_langsmith/`에서 확인합니다.
4. 실제 프로젝트 감각은 `07_examples/`와 `08_integration/` 실습으로 보강합니다.

---

## 더 보기

- [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) — LangSmith · Langfuse 가이드
- [`docs/MODEL_PROVIDERS.md`](docs/MODEL_PROVIDERS.md) — OpenRouter · Ollama · vLLM · LM Studio
- [`docs/SKILLS.md`](docs/SKILLS.md) — LangChain Skills 사용법
- [`docs/skills/langchain-v1-modern.md`](docs/skills/langchain-v1-modern.md) — LangChain v1 작성 가드레일
- [`AGENTS.md`](AGENTS.md) — 코딩 에이전트용 프로젝트 컨텍스트

---

## 라이선스

MIT
