# Agent Engineering Notebooks

> **LangChain · LangGraph · Deep Agents · LangSmith를 한국어로 끝까지 실습하는 LLM Agent 교육 저장소**
>
> 입문 개념부터 프레임워크별 심화, 운영·평가, 실전 에이전트 예제, provider 통합 카탈로그까지 Jupyter Notebook, Typst 핸드북, 강의 Deck 산출물로 함께 제공합니다.

[![Python](https://img.shields.io/badge/Python-3.12%2B-3776AB?logo=python&logoColor=white)](pyproject.toml)
[![Package Manager](https://img.shields.io/badge/package-uv-6E56CF)](uv.lock)
[![LangChain](https://img.shields.io/badge/LangChain-v1-1C3C3C)](docs/langchain/01-overview.md)
[![LangGraph](https://img.shields.io/badge/LangGraph-v1-1C3C3C)](docs/langgraph/01-quickstart.md)
[![Deep Agents](https://img.shields.io/badge/Deep%20Agents-SDK-111827)](docs/deepagents/01-overview.md)

- **English README:** [`en/README.md`](en/README.md)
- **Korean Handbook:** [`book/agent-handbook.pdf`](book/agent-handbook.pdf)
- **English Handbook:** [`en/book/agent-handbook-en.pdf`](en/book/agent-handbook-en.pdf)
- **Latest release note:** [`docs/releases/v1.2.0.md`](docs/releases/v1.2.0.md)
- **Lecture decks:** [`decks/`](decks/) — 강의용 HTML/PDF/PPTX/대본 산출물 보관 위치

---

## 이 저장소는 무엇인가요?

이 저장소는 “LLM Agent를 실제로 만들고 운영하는 방법”을 단계적으로 배우기 위한 **교육용 노트북 커리큘럼**입니다. 단순 API 호출 예제를 모아둔 곳이 아니라, 다음 흐름을 하나의 학습 경로로 묶습니다.

1. **LLM·Agent 기초** — 메시지, 프롬프트, tool calling, ReAct, memory
2. **LangChain v1** — `create_agent`, tools, middleware, MCP, guardrails, streaming
3. **LangGraph v1** — `StateGraph`, persistence, interrupt, subgraph, durable execution
4. **Deep Agents SDK** — backend, subagent, skill, memory, sandbox, async subagent
5. **LangSmith 운영** — tracing, dataset, evaluation, prompt hub, monitoring, Agent Evals
6. **실전 예제** — RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG
7. **통합 카탈로그** — provider, vector store, retriever, sandbox, observability 연결 예제

핵심 목표는 “문서를 읽었다”가 아니라 **실행 가능한 노트북을 따라가며 에이전트 앱의 구조, 제어, 검증, 운영을 이해하는 것**입니다.

---

## 한눈에 보는 구성

| 구분 | 수량 | 설명 |
|---|---:|---|
| Korean core notebooks | 86 | `01_beginner`~`07_examples` 한국어 원본 학습 경로 |
| English mirror notebooks | 86 | `en/01_beginner`~`en/07_examples` 영어 학습 경로 |
| Integration notebooks | 69 | `08_integration` provider·DB·sandbox·observability 통합 카탈로그 |
| Total notebooks | 241 | tracked `.ipynb` 기준 전체 노트북 |
| Handbook PDFs | 2 | 한국어/영어 Typst 기반 PDF 핸드북 |
| Lecture decks | `decks/` | 커밋 가능한 강의용 HTML/PDF/PPTX/대본 산출물 보관 위치 |
| Local docs | 100+ | LangChain, LangGraph, Deep Agents, Skills, observability 참고 문서 |

---

## 누구에게 적합한가요?

- Python 기초를 알고 있고 LLM Agent 개발을 체계적으로 배우고 싶은 사람
- LangChain v1, LangGraph v1, Deep Agents SDK의 역할 차이를 알고 싶은 사람
- RAG, SQL Agent, Deep Research Agent, Data Analysis Agent를 직접 만들어보고 싶은 사람
- LangSmith 기반 tracing/evaluation/monitoring까지 포함한 운영 흐름을 배우고 싶은 사람
- 한국어 강의, 워크숍, 사내 교육 자료를 만들기 위한 실습 원본이 필요한 사람

---

## 빠른 시작

### 1. 저장소 받기

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
```

### 2. 환경 설치

```bash
uv sync
cp .env.example .env
```

기본 개발 런타임은 `.python-version`의 Python 3.14입니다. 프로젝트 자체는 Python 3.12 이상을 지원하며, Python 3.14에서는 `pydantic>=2.13.4`를 사용해 `pydantic.v1` 호환 경고를 방지합니다.

`.env`에 최소한 다음 값을 설정합니다.

```dotenv
OPENAI_API_KEY=sk-...
```

### 3. Jupyter 실행

```bash
uv run jupyter lab
```

처음이라면 [`01_beginner/00_setup.ipynb`](01_beginner/00_setup.ipynb)부터 시작하세요.

---

## 환경 변수

| 필요도 | 환경 변수 | 사용처 |
|---|---|---|
| 필수 | `OPENAI_API_KEY` | 기본 노트북 live 실행 |
| 권장 | `LANGSMITH_API_KEY` | LangSmith tracing/evaluation |
| 권장 | `LANGSMITH_TRACING=true` | LangChain/LangGraph 실행 trace 기록 |
| 선택 | `TAVILY_API_KEY` | 웹 검색 기반 agent/RAG 예제 |
| 선택 | `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY` | Langfuse observability 예제 |
| 선택 | Anthropic, Google, AWS, Groq 등 provider key | `08_integration` provider 실습 |

전체 예시는 [`.env.example`](.env.example)을 확인하세요.

---

## 커리큘럼 지도

| Part | 경로 | 노트북 | 역할 | 주요 주제 |
|---:|---|---:|---|---|
| 01 | [`01_beginner/`](01_beginner/) | 8 | 입문 | LLM 기본기, LangChain/LangGraph/Deep Agents 첫 실습, 미니 프로젝트 |
| 02 | [`02_langchain/`](02_langchain/) | 14 | LangChain 심화 | agents, tools, structured output, memory, middleware, HITL, MCP, guardrails, semantic search |
| 03 | [`03_langgraph/`](03_langgraph/) | 16 | LangGraph 심화 | Graph API, Functional API, persistence, streaming, interrupts, subgraphs, fault tolerance, compatibility, case studies |
| 04 | [`04_deepagents/`](04_deepagents/) | 16 | Deep Agents 심화 | `create_deep_agent`, backend, subagent, memory, skills, sandbox, ACP, async/programmatic subagents, event streaming, permissions, rubric |
| 05 | [`05_advanced/`](05_advanced/) | 12 | 고급 패턴 | migration, middleware, multi-agent, context/memory, agentic RAG, SQL, voice, production, custom workflow |
| 06 | [`06_langsmith/`](06_langsmith/) | 9 | 운영·평가 | tracing, datasets, evaluation, prompt hub, production monitoring, Agent Evals, testing strategy, graph testing, runtime rubric |
| 07 | [`07_examples/`](07_examples/) | 11 | 실전 예제 | RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG, content builder, subagents, handoffs, router, skills |
| 08 | [`08_integration/`](08_integration/) | 69 | 통합 카탈로그 | providers, embeddings, vector stores, retrievers, tools, sandboxes, observability |

---

## 추천 학습 경로

| 목표 | 추천 순서 |
|---|---|
| LLM Agent를 처음 배우기 | `01_beginner` → `02_langchain/01~05` → `07_examples/01_rag_agent.ipynb` |
| LangChain v1 앱 개발 | `02_langchain` → `02_langchain/14_semantic_search.ipynb` → `05_advanced/01_middleware.ipynb` → `07_examples` |
| LangGraph로 상태 기반 워크플로 만들기 | `03_langgraph` → `03_langgraph/14_fault_tolerance.ipynb` → `03_langgraph/15_backward_compatibility.ipynb` → `05_advanced/02~03` |
| Deep Agents 중심으로 빠르게 만들기 | `04_deepagents` → `04_deepagents/12_models_and_tools.ipynb` → `04_deepagents/14_event_streaming.ipynb` → `07_examples/07_content_builder_agent.ipynb` |
| 운영·평가 체계 붙이기 | `06_langsmith` → `06_langsmith/07_testing_strategy.ipynb` → `06_langsmith/08_langgraph_testing.ipynb` → `05_advanced/09_production.ipynb` |
| provider나 DB 통합 찾아보기 | 필요한 항목만 [`08_integration/`](08_integration/)에서 선택 |

> `08_integration/`은 API key, 로컬 서비스, cloud sandbox, 과금 가능 리소스가 섞여 있으므로 기본 smoke test 대상에서 제외됩니다.

---

## 주요 폴더 설명

```text
.
├── 01_beginner/          # LLM·Agent 입문 노트북
├── 02_langchain/         # LangChain v1 중심 노트북
├── 03_langgraph/         # LangGraph v1 중심 노트북
├── 04_deepagents/        # Deep Agents SDK 중심 노트북
├── 05_advanced/          # 프로덕션·멀티에이전트·RAG·SQL 고급 패턴
├── 06_langsmith/         # tracing/evaluation/monitoring 운영 트랙
├── 07_examples/          # 실제 에이전트 앱 예제와 SKILL.md
├── 08_integration/       # provider/vector DB/tool/sandbox 통합 카탈로그
├── docs/                 # 프레임워크별 로컬 참고 문서와 작성 가드레일
├── book/                 # 한국어 Typst 핸드북 소스와 PDF
├── decks/                # 강의용 deck 산출물(HTML/PDF/PPTX/대본)
├── en/                   # 영어 mirror 노트북과 영어 핸드북
├── assets/               # 노트북/문서용 이미지 자산
├── local/                # 로컬 검증 harness와 실행 리포트
├── pyproject.toml        # Python 의존성 정의
└── uv.lock               # 재현 가능한 uv lockfile
```

---

## 실전 예제와 Skills

[`07_examples/`](07_examples/)는 단일 예제가 아니라 “작동 가능한 agent product 패턴”을 모아둔 영역입니다.

| 예제 | 노트북 | Skill |
|---|---|---|
| RAG Agent | [`07_examples/01_rag_agent.ipynb`](07_examples/01_rag_agent.ipynb) | [`rag-agent`](07_examples/skills/rag-agent/SKILL.md) |
| SQL Agent | [`07_examples/02_sql_agent.ipynb`](07_examples/02_sql_agent.ipynb) | [`sql-agent`](07_examples/skills/sql-agent/SKILL.md) |
| Data Analysis Agent | [`07_examples/03_data_analysis_agent.ipynb`](07_examples/03_data_analysis_agent.ipynb) | [`data-analysis`](07_examples/skills/data-analysis/SKILL.md) |
| ML Agent | [`07_examples/04_ml_agent.ipynb`](07_examples/04_ml_agent.ipynb) | [`ml-pipeline`](07_examples/skills/ml-pipeline/SKILL.md) |
| Deep Research Agent | [`07_examples/05_deep_research_agent.ipynb`](07_examples/05_deep_research_agent.ipynb) | [`deep-research`](07_examples/skills/deep-research/SKILL.md) |
| Multimodal PDF RAG | [`07_examples/06_multimodal_pdf_rag.ipynb`](07_examples/06_multimodal_pdf_rag.ipynb) | [`multimodal-rag`](07_examples/skills/multimodal-rag/SKILL.md) |
| Content Builder Agent | [`07_examples/07_content_builder_agent.ipynb`](07_examples/07_content_builder_agent.ipynb) | [`content-builder`](07_examples/skills/content-builder/SKILL.md) |
| Personal Assistant Subagents | [`07_examples/10_personal_assistant_subagents.ipynb`](07_examples/10_personal_assistant_subagents.ipynb) | 공식 subagents 패턴 |
| Customer Support Handoffs | [`07_examples/11_customer_support_handoffs.ipynb`](07_examples/11_customer_support_handoffs.ipynb) | 공식 handoffs 패턴 |
| Router Knowledge Base | [`07_examples/12_router_knowledge_base.ipynb`](07_examples/12_router_knowledge_base.ipynb) | 공식 router 패턴 |
| Skills SQL Assistant | [`07_examples/13_skills_sql_assistant.ipynb`](07_examples/13_skills_sql_assistant.ipynb) | 공식 skills + SQL safety 패턴 |

Deep Agents에서 skills 디렉토리를 연결하면 예제별 `SKILL.md`를 progressive disclosure 방식으로 사용할 수 있습니다.

---

## 참고 문서

노트북 코드는 가능한 한 repo-local 문서와 공식 패턴을 근거로 작성되어 있습니다.

| 문서 | 설명 |
|---|---|
| [`docs/README.md`](docs/README.md) | 공개 문서 지도와 유지보수 기준 |
| [`docs/langchain/`](docs/langchain/) | LangChain v1 핵심 개념과 튜토리얼 정리 |
| [`docs/langgraph/`](docs/langgraph/) | LangGraph v1 API, persistence, deploy, observability 정리 |
| [`docs/deepagents/`](docs/deepagents/) | Deep Agents SDK, backend, subagent, skills, sandbox 정리 |
| [`docs/skills/`](docs/skills/) | LangChain/LangGraph/Deep Agents 작성 가드레일 |
| [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) | LangSmith/Langfuse 관측 설정 |
| [`docs/MODEL_PROVIDERS.md`](docs/MODEL_PROVIDERS.md) | provider 선택과 로컬 모델 옵션 |
| [`docs/SKILLS.md`](docs/SKILLS.md) | Skills 개념과 저장소 내 활용 방식 |
| [`docs/translation/KO_EN_TRANSLATION_GUIDE.md`](docs/translation/KO_EN_TRANSLATION_GUIDE.md) | 한국어↔영어 mirror 번역 가이드 |

---

## 핸드북 빌드

노트북 커리큘럼과 함께 Typst 기반 PDF 핸드북을 관리합니다.

| 언어 | PDF | Typst entry |
|---|---|---|
| 한국어 | [`book/agent-handbook.pdf`](book/agent-handbook.pdf) | [`book/main.typ`](book/main.typ) |
| 영어 | [`en/book/agent-handbook-en.pdf`](en/book/agent-handbook-en.pdf) | [`en/book/main.typ`](en/book/main.typ) |

빌드 명령:

```bash
python book/scripts/build.py
python en/book/scripts/build.py
```

---

## 검증 정책

기본 live smoke는 `01_beginner`~`07_examples` core notebooks를 대상으로 합니다. `08_integration/`은 외부 provider, DB, cloud sandbox, 로컬 서비스 의존성이 있어 별도 검증합니다.

```bash
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300
```

LangSmith dataset/prompt/evaluate 쓰기까지 허용할 때:

```bash
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300 --allow-langsmith-mutations
```

최근 검증 기록은 [`docs/verification/2026-06-21-tutorial-update-and-addition-backlog.md`](docs/verification/2026-06-21-tutorial-update-and-addition-backlog.md)를 참고하세요.

---

## 작성·기여 원칙

이 저장소의 노트북과 문서는 교육 자료로 사용되므로 다음 원칙을 지향합니다.

- 설명은 한국어, 코드는 영어 식별자를 사용합니다.
- 노트북은 `cell-0`, `cell-1`, ... 순서의 안정적인 cell id를 유지합니다.
- 코드 셀은 교육용으로 짧게 유지하고, 단계별 실행 흐름을 깨지 않습니다.
- 새 API 사용은 `docs/`의 로컬 문서 또는 공식 문서에 근거해 작성합니다.
- 기본 모델은 교육 소스 기준 `ChatOpenAI(model="gpt-5.4")`를 사용합니다.
- 외부 쓰기, 과금, provider별 secret이 필요한 예제는 명확히 표시합니다.

에이전트가 이 repo를 수정할 때의 상세 규칙은 [`AGENTS.md`](AGENTS.md)를 참고하세요.

---

## 기술 스택

| 항목 | 기준 |
|---|---|
| Python | `>=3.12` (기본 개발 환경 `3.14`) |
| Package manager | `uv` |
| Core frameworks | LangChain v1, LangGraph v1, Deep Agents SDK |
| Model integration | `langchain-openai` 중심, `08_integration`에서 provider 확장 |
| Observability | LangSmith, Langfuse, OpenTelemetry 예제 |
| Data/RAG | FAISS, vector stores, retrievers, document loaders, text splitters |
| Evaluation | LangSmith evaluation, `agentevals`, notebook smoke harness |

정확한 버전은 [`pyproject.toml`](pyproject.toml)과 [`uv.lock`](uv.lock)을 기준으로 합니다.

---

## 라이선스

현재 저장소 루트에 별도 `LICENSE` 파일은 포함되어 있지 않습니다. 공개 배포나 재사용 조건이 필요하다면 라이선스를 먼저 확정해 주세요.
