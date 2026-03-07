# Agent Engineering Notebooks

LLM 기반 AI 에이전트 개발을 **초급부터 프로덕션 배포까지** 단계별로 학습하는 Jupyter Notebook 교육 자료입니다.

---

## 프로젝트 구조

```
langchain-langgraph-deepagents-notebooks/
├── .env.example                 # API 키 템플릿
├── pyproject.toml               # 의존성 관리 (uv)
├── 01_beginner/                 # 초급 과정 (8개)
├── 02_langchain/                # 중급 — LangChain v1 (13개)
├── 03_langgraph/                # 중급 — LangGraph v1 (13개)
├── 04_deepagents/               # 중급 — Deep Agents SDK (10개)
├── 05_advanced/                 # 고급 과정 (10개)
├── 06_examples/                 # 실전 응용 예제 (5개)
└── docs/                        # 참고 문서 및 가이드
```

---

## 시작하기

```bash
# 1. 저장소 클론
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks

# 2. 의존 패키지 설치 (uv 기반)
uv sync

# 3. API 키 설정
cp .env.example .env
# .env 파일을 열어 실제 키 입력

# 4. Jupyter 실행
uv run jupyter lab
```

### 환경 변수

| 변수 | 용도 | 필수 |
|------|------|------|
| `OPENAI_API_KEY` | LLM 호출 | **필수** |
| `TAVILY_API_KEY` | 웹 검색 도구 | 선택 |
| `LANGSMITH_API_KEY` | LangSmith 트레이싱 | 선택 |
| `LANGFUSE_SECRET_KEY` | Langfuse 트레이싱 | 선택 |

전체 환경 변수 목록은 [`.env.example`](.env.example)을 참고하세요.

---

## 단계별 커리큘럼

### 1. 초급 — 에이전트 입문 (`01_beginner/`, 8개)

> 대상: 프로그래밍 경험은 있지만 LLM 에이전트는 처음인 분

| # | 파일 | 주제 | 핵심 내용 |
|---|------|------|-----------|
| 00 | `00_setup.ipynb` | 환경 설정 | `.env` 파일, `ChatOpenAI`, 모델 동작 확인 |
| 01 | `01_llm_basics.ipynb` | LLM 기초 | 메시지 역할(system/human/ai), 프롬프트, 스트리밍 |
| 02 | `02_langchain_basics.ipynb` | LangChain 입문 | `@tool`, `create_agent()`, ReAct 루프 |
| 03 | `03_langchain_memory.ipynb` | LangChain 대화 | `InMemorySaver`, `thread_id`, 멀티턴 메모리 |
| 04 | `04_langgraph_basics.ipynb` | LangGraph 입문 | `StateGraph`, 노드, 엣지, `MessagesState` |
| 05 | `05_deep_agents_basics.ipynb` | Deep Agents 입문 | `create_deep_agent()`, 빌트인 도구, 커스텀 도구 |
| 06 | `06_comparison.ipynb` | 프레임워크 비교 | LangChain vs LangGraph vs Deep Agents |
| 07 | `07_mini_project.ipynb` | 미니 프로젝트 | Tavily 검색 + 요약 리서치 에이전트 |

### 2. 중급 — LangChain v1 (`02_langchain/`, 13개)

> 대상: LangChain으로 프로덕션 에이전트를 만들고 싶은 분

| # | 파일 | 주제 | 핵심 내용 |
|---|------|------|-----------|
| 01 | `01_introduction.ipynb` | LangChain 소개 | 프레임워크 개요, 아키텍처, ReAct 패턴 |
| 02 | `02_quickstart.ipynb` | 첫 번째 에이전트 | `create_agent()`, `invoke()`, `stream()` |
| 03 | `03_models_and_messages.ipynb` | 모델과 메시지 | `init_chat_model()`, 메시지 타입, 멀티모달 |
| 04 | `04_tools_and_structured_output.ipynb` | 도구와 구조화된 출력 | `@tool`, Pydantic, `with_structured_output()` |
| 05 | `05_memory_and_streaming.ipynb` | 메모리와 스트리밍 | 단기/장기 메모리, 스트리밍 모드 |
| 06 | `06_middleware.ipynb` | 미들웨어와 가드레일 | 빌트인/커스텀 미들웨어, 안전성 |
| 07 | `07_hitl_and_runtime.ipynb` | 사람 개입과 런타임 | HITL, ToolRuntime, 컨텍스트 엔지니어링, MCP |
| 08 | `08_multi_agent.ipynb` | 멀티 에이전트 패턴 | Subagents, Handoffs, Skills, Router |
| 09 | `09_custom_workflow_and_rag.ipynb` | 커스텀 워크플로와 RAG | StateGraph, 조건부 엣지, 벡터 검색 |
| 10 | `10_production.ipynb` | 프로덕션 | Studio, 테스트, UI, 배포, 관측성 |
| 11 | `11_mcp.ipynb` | MCP | Model Context Protocol, langchain-mcp-adapters, Stdio/SSE |
| 12 | `12_frontend_streaming.ipynb` | 프론트엔드 스트리밍 | useStream React 훅, StreamEvent, 커스텀 이벤트 |
| 13 | `13_guardrails.ipynb` | 가드레일 | PII 감지, HITL, 커스텀 미들웨어, 다중 가드레일 |

### 3. 중급 — LangGraph v1 (`03_langgraph/`, 13개)

> 대상: 복잡한 워크플로와 상태 관리가 필요한 분

| # | 파일 | 주제 | 핵심 내용 |
|---|------|------|-----------|
| 01 | `01_introduction.ipynb` | LangGraph 소개 | 아키텍처, Graph vs Functional API, 핵심 개념 |
| 02 | `02_graph_api.ipynb` | Graph API 기초 | StateGraph, 노드, 엣지, 리듀서, 조건부 분기 |
| 03 | `03_functional_api.ipynb` | Functional API 기초 | `@entrypoint`, `@task`, `previous`, `entrypoint.final` |
| 04 | `04_workflows.ipynb` | 워크플로 패턴 | Chaining, Parallelization, Routing, Orchestrator |
| 05 | `05_agents.ipynb` | 에이전트 구축 | ReAct 에이전트 (Graph/Functional), `bind_tools()` |
| 06 | `06_persistence_and_memory.ipynb` | 지속성과 메모리 | 체크포인터, InMemoryStore, Durable Execution |
| 07 | `07_streaming.ipynb` | 스트리밍 | values, updates, messages, custom 모드 |
| 08 | `08_interrupts_and_time_travel.ipynb` | 인터럽트와 타임 트래블 | `interrupt()`, `Command(resume=)`, 체크포인트 리플레이 |
| 09 | `09_subgraphs.ipynb` | 서브그래프 | 그래프 모듈화, 상태 매핑, 서브그래프 스트리밍 |
| 10 | `10_production.ipynb` | 프로덕션 | Studio, 테스트, 배포, 관측성, Pregel |
| 11 | `11_local_server.ipynb` | 로컬 서버 | langgraph dev, Studio, Python SDK, REST API |
| 12 | `12_durable_execution.ipynb` | 내구성 실행 | 체크포인터, @task, 장애 복구, 내구성 모드 |
| 13 | `13_api_guide_and_pregel.ipynb` | API 가이드와 Pregel | Graph vs Functional, Pregel 런타임, 슈퍼스텝 |

### 4. 중급 — Deep Agents SDK (`04_deepagents/`, 10개)

> 대상: 올인원 에이전트 시스템을 빠르게 구축하고 싶은 분

| # | 파일 | 주제 | 핵심 API |
|---|------|------|----------|
| 01 | `01_introduction.ipynb` | Deep Agents 소개 | 아키텍처, 핵심 개념, 설치 확인 |
| 02 | `02_quickstart.ipynb` | 첫 번째 에이전트 | `create_deep_agent()`, `invoke()`, `stream()` |
| 03 | `03_customization.ipynb` | 커스터마이징 | 모델, 시스템 프롬프트, 도구, `response_format` |
| 04 | `04_backends.ipynb` | 스토리지 백엔드 | State, Filesystem, Store, Composite |
| 05 | `05_subagents.ipynb` | 서브에이전트 | `SubAgent`, `CompiledSubAgent`, 파이프라인 |
| 06 | `06_memory_and_skills.ipynb` | 메모리 & 스킬 | `memory`, `skills`, AGENTS.md, SKILL.md |
| 07 | `07_advanced.ipynb` | 고급 기능 | Human-in-the-Loop, 스트리밍, 샌드박스, ACP, CLI |
| 08 | `08_harness.ipynb` | 에이전트 하네스 | AgentHarness, 파일시스템, 컨텍스트 관리, 서브에이전트 |
| 09 | `09_comparison.ipynb` | 외부 프레임워크 비교 | Deep Agents vs OpenCode vs Claude Agent SDK |
| 10 | `10_sandboxes_and_acp.ipynb` | 샌드박스와 ACP | Modal/Daytona/Runloop, Agent Client Protocol |

### 5. 고급 — 프로덕션 & 멀티에이전트 (`05_advanced/`, 10개)

> 대상: 프로덕션 배포와 멀티에이전트 아키텍처를 설계하는 분

| # | 파일 | 주제 | 핵심 내용 |
|---|------|------|-----------|
| 00 | `00_migration.ipynb` | v0 -> v1 마이그레이션 | 브레이킹 체인지, import 경로, `create_agent` |
| 01 | `01_middleware.ipynb` | 미들웨어 심화 | 7종 빌트인, 커스텀 작성, 실행 순서 |
| 02 | `02_multi_agent_subagents.ipynb` | 멀티에이전트: Subagents | 감독자-서브에이전트 3계층, HITL, ToolRuntime |
| 03 | `03_multi_agent_handoffs_router.ipynb` | 멀티에이전트: Handoffs & Router | 상태 머신, Command 전이, Send API 병렬 라우팅 |
| 04 | `04_context_memory.ipynb` | 컨텍스트 & 메모리 | `context_schema`, InMemoryStore, Skills 패턴 |
| 05 | `05_agentic_rag.ipynb` | Agentic RAG | 벡터 검색, 문서 관련성 평가, 쿼리 리라이트 |
| 06 | `06_sql_agent.ipynb` | SQL 에이전트 | SQLDatabaseToolkit, `interrupt()`, `Command(resume=)` |
| 07 | `07_data_analysis.ipynb` | 데이터 분석 에이전트 | Deep Agents + 샌드박스, Slack 연동, 스트리밍 |
| 08 | `08_voice_agent.ipynb` | 보이스 에이전트 | STT/Agent/TTS Sandwich 패턴, Sub-700ms |
| 09 | `09_production.ipynb` | 프로덕션 배포 | 테스트, LangSmith 평가, 트레이싱, LangGraph Platform |

### 6. 실전 응용 예제 (`06_examples/`, 5개)

> 대상: Deep Agents SDK의 실전 응용 패턴을 따라하며 응용력을 키우고 싶은 분

| # | 파일 | 주제 | 핵심 내용 |
|---|------|------|-----------|
| 01 | `01_rag_agent.ipynb` | RAG 에이전트 | InMemoryVectorStore, `content_and_artifact`, create_deep_agent |
| 02 | `02_sql_agent.ipynb` | SQL 에이전트 | SQLDatabaseToolkit, AGENTS.md 안전규칙, HITL interrupt |
| 03 | `03_data_analysis_agent.ipynb` | 데이터 분석 에이전트 | LocalShellBackend, run_pandas, 스트리밍, 멀티턴 |
| 04 | `04_ml_agent.ipynb` | 머신러닝 에이전트 | run_ml_code, 자유 EDA→전처리→모델비교, 멀티턴 |
| 05 | `05_deep_research_agent.ipynb` | 딥 리서치 에이전트 | 병렬 서브에이전트 3개, think_tool, 5단계 워크플로 |

---

## 기술 스택

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `langchain` | >= 1.2 | 에이전트 생성, 도구, 미들웨어 |
| `langchain-openai` | >= 1.1.10 | OpenAI 모델 연동 |
| `langgraph` | >= 1.0 | 상태 그래프 워크플로, 오케스트레이션 |
| `deepagents` | >= 0.4.4 | 올인원 에이전트 SDK |
| `python-dotenv` | >= 1.2.2 | 환경 변수 관리 |

전체 의존성은 [`pyproject.toml`](pyproject.toml)을 참고하세요.

---

## 추가 문서

| 문서 | 내용 |
|------|------|
| [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) | LangSmith / Langfuse 관측성 설정 |
| [`docs/MODEL_PROVIDERS.md`](docs/MODEL_PROVIDERS.md) | OpenRouter, Ollama, vLLM, LM Studio 등 다른 모델 사용법 |
| [`docs/SKILLS.md`](docs/SKILLS.md) | LangChain Skills / langchain-ecosystem-skills 설치 및 사용법 |
| [`AGENTS.md`](AGENTS.md) | 코딩 에이전트용 프로젝트 컨텍스트 |

---

## 라이선스

MIT
