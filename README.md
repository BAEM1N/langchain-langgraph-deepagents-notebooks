# Agent Engineering Notebooks

LLM 기반 AI 에이전트 개발을 **초급부터 프로덕션 배포까지** 단계별로 학습하는 Jupyter Notebook 교육 자료입니다.

---

## 프로젝트 구조

```
agent-engineering-notebooks/
├── .env.example                 # API 키 템플릿
├── pyproject.toml               # 의존성 관리 (uv)
├── 01_beginner/                 # 초급 과정 (8개)
├── 02_langchain/                # 중급 — LangChain v1 (10개)
├── 03_langgraph/                # 중급 — LangGraph v1 (10개)
├── 04_deepagents/               # 중급 — Deep Agents SDK (7개)
├── 05_advanced/                 # 고급 과정 (10개)
├── docs/                        # 참고 문서
│   ├── langchain/
│   ├── langgraph/
│   └── deepagents/
└── assets/                      # 이미지 등 정적 자산
```

---

## 단계별 커리큘럼

### 1. 초급 — 에이전트 입문 (`01_beginner/`, 8개)

> 대상: 프로그래밍 경험은 있지만 LLM 에이전트는 처음인 분들께 추천드립니다.

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

### 2. 중급 — LangChain v1 (`02_langchain/`, 10개)

> 대상: LangChain으로 프로덕션 에이전트를 만들고 싶은 분들께 추천드립니다.

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

### 3. 중급 — LangGraph v1 (`03_langgraph/`, 10개)

> 대상: 복잡한 워크플로와 상태 관리가 필요한 분들께 추천드립니다.

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

### 4. 중급 — Deep Agents SDK (`04_deepagents/`, 7개)

> 대상: 올인원 에이전트 시스템을 빠르게 구축하고 싶은 분들께 추천드립니다.

| # | 파일 | 주제 | 핵심 API |
|---|------|------|----------|
| 01 | `01_introduction.ipynb` | Deep Agents 소개 | 아키텍처, 핵심 개념, 설치 확인 |
| 02 | `02_quickstart.ipynb` | 첫 번째 에이전트 | `create_deep_agent()`, `invoke()`, `stream()` |
| 03 | `03_customization.ipynb` | 커스터마이징 | 모델, 시스템 프롬프트, 도구, `response_format` |
| 04 | `04_backends.ipynb` | 스토리지 백엔드 | State, Filesystem, Store, Composite |
| 05 | `05_subagents.ipynb` | 서브에이전트 | `SubAgent`, `CompiledSubAgent`, 파이프라인 |
| 06 | `06_memory_and_skills.ipynb` | 메모리 & 스킬 | `memory`, `skills`, AGENTS.md, SKILL.md |
| 07 | `07_advanced.ipynb` | 고급 기능 | Human-in-the-Loop, 스트리밍, 샌드박스, ACP, CLI |

### 5. 고급 — 프로덕션 & 멀티에이전트 (`05_advanced/`, 10개)

> 대상: 프로덕션 배포와 멀티에이전트 아키텍처를 설계하는 분들께 추천드립니다.

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

---

## 시작하기

```bash
# 1. 저장소 클론
git clone https://github.com/BAEM1N/agent-engineering-notebooks.git
cd agent-engineering-notebooks

# 2. 의존 패키지 설치 (uv 기반)
uv sync

# 3. API 키 설정
cp .env.example .env
# .env 파일을 열어 실제 키 입력

# 4. Jupyter 실행
uv run jupyter lab
```

---

## 환경 변수 설정
`.env.example`을 `.env`로 복사한 후 실제 키를 입력합니다.

### 필수

| 변수 | 용도 | 발급처 |
|------|------|--------|
| `OPENAI_API_KEY` | LLM 호출 | https://platform.openai.com/api-keys |

### 선택

| 변수 | 용도 | 발급처 |
|------|------|--------|
| `TAVILY_API_KEY` | 웹 검색 도구 (에이전트 실습) | https://tavily.com |
| `SLACK_BOT_TOKEN` | Slack 연동 (데이터 분석 에이전트) | https://api.slack.com/apps |
| `SLACK_CHANNEL_ID` | Slack 채널 ID | Slack 앱 설정 |
| `LANGSMITH_API_KEY` | LangSmith 관측성/트레이싱 | https://smith.langchain.com |
| `LANGSMITH_TRACING` | 트레이싱 활성화 (`true`/`false`) | -- |
| `LANGSMITH_PROJECT` | LangSmith 프로젝트 이름 | -- |
| `LANGFUSE_SECRET_KEY` | Langfuse 관측성/트레이싱 | https://langfuse.com |
| `LANGFUSE_PUBLIC_KEY` | Langfuse 공개 키 | https://langfuse.com |
| `LANGFUSE_HOST` | Langfuse 호스트 URL | -- |

---

## Observability (관측성)
모든 노트북은 `.env` 파일만으로 두 가지 관측성 서비스를 지원합니다.

### LangSmith

환경 변수만 설정하면 **코드 수정 없이** 자동 트레이싱이 활성화됩니다.

```bash
# .env
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=agent-engineering-notebooks
```

LangChain/LangGraph의 모든 `invoke()`, `stream()` 호출이 자동으로 LangSmith에 기록됩니다.

### Langfuse

Langfuse는 `CallbackHandler`를 생성하여 `config`로 전달하는 방식입니다.

```python
from langfuse.langchain import CallbackHandler

langfuse_handler = CallbackHandler()

# invoke/stream 호출 시 config에 콜백 전달
result = agent.invoke(
    {"messages": [...]},
    config={"callbacks": [langfuse_handler]},
)
```

```bash
# .env
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_HOST=https://cloud.langfuse.com
```

각 노트북 상단의 Observability 셀에서 두 서비스 모두 자동으로 초기화됩니다.

---

## 다른 모델 프로바이더 사용하기

이 교육 자료는 기본적으로 `ChatOpenAI(model="gpt-4.1")`을 사용합니다.
아래 코드로 교체하면 노트북 내 어디서든 다른 프로바이더를 사용할 수 있습니다.

### OpenRouter

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"],
    model="anthropic/claude-sonnet-4",
)
```

### Ollama (로컬)

```bash
pip install langchain-ollama
```

```python
from langchain_ollama import ChatOllama

model = ChatOllama(model="llama3.1")
```

### vLLM (셀프호스트)

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="http://localhost:8000/v1",
    api_key="dummy",
    model="meta-llama/Llama-3.1-8B-Instruct",
)
```

### LM Studio (로컬)

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    base_url="http://localhost:1234/v1",
    api_key="lm-studio",
    model="local-model",
)
```

> 위 모델 객체는 노트북에서 `ChatOpenAI(model="gpt-4.1")`이 사용되는 모든 곳에 그대로 대입할 수 있습니다.

---

## 기술 스택

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `langchain` | >= 1.2 | 에이전트 생성, 도구, 미들웨어 |
| `langchain-openai` | >= 1.1.10 | OpenAI 모델 연동 |
| `langchain-community` | >= 0.4 | 커뮤니티 통합 (SQL 등) |
| `langchain-text-splitters` | >= 1.1 | 문서 청킹 |
| `langgraph` | >= 1.0 | 상태 그래프 워크플로, 오케스트레이션 |
| `deepagents` | >= 0.4.4 | 올인원 에이전트 SDK |
| `faiss-cpu` | >= 1.13 | 벡터 유사도 검색 |
| `tavily-python` | >= 0.7.22 | 웹 검색 API |
| `python-dotenv` | >= 1.2.2 | 환경 변수 관리 |
| `langfuse` | >= 2.0 (선택) | 관측성/트레이싱 |
| `langsmith` | >= 0.3 (선택) | 관측성/평가/배포 |

---

## LangChain Skills와 함께 사용하기

[LangChain Skills](https://github.com/langchain-ai/langchain-skills)는 LangChain, LangGraph, Deep Agents 프레임워크용 **에이전트 스킬 모음**입니다. Claude Code나 Deep Agents CLI와 함께 사용하면 코딩 에이전트가 프레임워크 문서를 참조하여 더 정확한 코드를 작성할 수 있습니다.

### 설치

```bash
# 모든 스킬 한번에 설치 (권장)
npx skills add langchain-ai/langchain-skills --skill '*' --yes

# 글로벌 설치 (모든 프로젝트에서 사용)
npx skills add langchain-ai/langchain-skills --skill '*' --yes --global
```

### 포함된 스킬 (11개)

| 카테고리 | 스킬 | 설명 |
|----------|------|------|
| **시작하기** | Framework Comparison | LangChain vs LangGraph vs Deep Agents 비교 |
| | Dependency Management | Python/TypeScript 의존성 관리 참조 |
| **Deep Agents** | Core Architecture | 아키텍처 및 harness 설정 가이드 |
| | Memory & Persistence | 메모리 및 지속성 패턴 |
| | Subagent Orchestration | 서브에이전트 오케스트레이션 및 작업 계획 |
| **LangChain** | Agent & Tools | 에이전트 생성 및 도구 통합 |
| | Human-in-the-Loop | 사람 승인 워크플로 |
| | RAG Pipeline | 문서 로더, 임베딩, 벡터 스토어 |
| **LangGraph** | StateGraph | 노드, 엣지, 그래프 구성 |
| | Persistence & Memory | 체크포인트 지속성, 크로스 스레드 메모리 |
| | Interrupt & Review | 인터럽트 기반 사람 리뷰 시스템 |

> 이 교육 자료로 학습한 후 LangChain Skills를 설치하면, AI 코딩 에이전트가 프레임워크 API를 정확히 사용하도록 도와줍니다.

---

## 라이선스

MIT
