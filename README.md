# Agent Engineering Notebooks

> LangChain, LangGraph, Deep Agents, LangSmith를 **입문 → 프레임워크별 심화 → 운영/평가 → 실전 예제 → 통합 카탈로그** 순서로 학습하는 한국어 중심 Jupyter 노트북 + Typst 핸드북 저장소입니다.
>
> English: [en/README.md](en/README.md) · Korean PDF: [`book/agent-handbook.pdf`](book/agent-handbook.pdf) · English PDF: [`en/book/agent-handbook-en.pdf`](en/book/agent-handbook-en.pdf)

---

## 이 저장소로 할 수 있는 것

- **LLM 에이전트 기초**를 메시지, 프롬프트, ReAct 흐름부터 익힙니다.
- **LangChain v1**의 `create_agent`, tool, middleware, MCP, guardrails, event streaming을 실습합니다.
- **LangGraph v1**의 `StateGraph`, persistence, interrupts, subgraphs, streaming, fault tolerance를 학습합니다.
- **Deep Agents SDK**의 backend, subagent, skill, async subagent, interpreter, rubric, sandbox/ACP 개념을 다룹니다.
- **LangSmith**로 trace, dataset, evaluation, prompt hub, monitoring, Agent Evals를 연결합니다.
- **실전 예제**로 RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG, content builder agent를 만듭니다.
- **08_integration**에서 provider, vector store, retriever, sandbox, observability 등 외부 통합을 카탈로그식으로 확인합니다.

---

## 빠른 시작

```bash
git clone https://github.com/BAEM1N/langchain-langgraph-deepagents-notebooks.git
cd langchain-langgraph-deepagents-notebooks
uv sync
cp .env.example .env      # 최소 OPENAI_API_KEY 설정
uv run jupyter lab
```

필수/선택 키:

| 구분 | 환경 변수 | 용도 |
|---|---|---|
| 필수 | `OPENAI_API_KEY` | 01~07 기본 live 실행 |
| 권장 | `LANGSMITH_API_KEY`, `LANGSMITH_TRACING=true` | trace/eval 로깅 |
| 선택 | `TAVILY_API_KEY` | 일부 검색 예제 |
| 선택 | `ANTHROPIC_API_KEY`, Google/AWS 등 provider 키 | `08_integration` provider 실습 |
| 선택 | `LANGFUSE_SECRET_KEY`, `LANGFUSE_PUBLIC_KEY` | Langfuse observability |

환경 변수 예시는 [`.env.example`](.env.example)을 확인하세요.

---

## 저장소 구성

현재 tracked notebook 기준:

| 영역 | 경로 | 노트북 | 역할 |
|---|---:|---:|---|
| Korean core | `01_beginner`~`07_examples` | **69** | 기본 학습/검증 대상 |
| English mirror | `en/01_beginner`~`en/07_examples` | **69** | 영어 학습 경로. LangSmith 01~06 원본 노트북 parity 반영 완료 |
| Integrations | `08_integration` | **69** | provider/cloud/local service 통합 카탈로그. 기본 live harness에서는 제외 |
| **Total** | 전체 tracked `.ipynb` | **207** | 한국어·영어·통합 예제 전체 |

### Core curriculum — Korean source of truth

| Part | 경로 | 노트북 | 핵심 주제 |
|---:|---|---:|---|
| 01 | [`01_beginner/`](01_beginner/) | 8 | LLM 기초, 메시지, 프롬프트, ReAct, 프레임워크 비교 |
| 02 | [`02_langchain/`](02_langchain/) | 13 | LangChain v1, `create_agent`, tools, middleware, MCP, guardrails, streaming |
| 03 | [`03_langgraph/`](03_langgraph/) | 14 | Graph/Functional API, persistence, interrupts, subgraphs, local server, Pregel, fault tolerance |
| 04 | [`04_deepagents/`](04_deepagents/) | 11 | `create_deep_agent`, backend, subagent, memory/skills, interpreter, async subagents |
| 05 | [`05_advanced/`](05_advanced/) | 10 | migration, middleware, multi-agent, RAG, SQL, data analysis, voice, production |
| 06 | [`06_langsmith/`](06_langsmith/) | 6 | tracing, dataset/evaluation, prompt hub, monitoring, Agent Evals |
| 07 | [`07_examples/`](07_examples/) | 7 | RAG, SQL, data analysis, ML, deep research, multimodal PDF RAG, content builder |
| 08 | [`08_integration/`](08_integration/) | 69 | chat model, embedding, vector store, retriever, tool, sandbox, provider, observability 통합 |

---

## 추천 학습 순서

| 목표 | 추천 경로 |
|---|---|
| 처음 시작 | `01_beginner` → `02_langchain/01~05` |
| LangChain 앱 개발 | `02_langchain` → `05_advanced/01_middleware.ipynb` → `07_examples` |
| 상태 기반 워크플로 | `03_langgraph` → `03_langgraph/14_fault_tolerance.ipynb` → `05_advanced/02~03` |
| Deep Agents 중심 개발 | `04_deepagents` → `04_deepagents/11_async_subagents.ipynb` → `07_examples/07_content_builder_agent.ipynb` |
| 운영/평가 | `06_langsmith` → `05_advanced/09_production.ipynb` |
| provider/DB/검색 통합 | 필요한 카테고리의 `08_integration/NN_*` 폴더 |

`08_integration/`은 provider 키, 로컬 서비스, 유료 sandbox가 섞여 있으므로 기본 smoke 실행에서는 제외합니다.

---

## Agent Handbook

Typst로 조판한 PDF 핸드북도 함께 관리합니다.

| 언어 | PDF | Typst entry | Chapters |
|---|---|---|---:|
| Korean | [`book/agent-handbook.pdf`](book/agent-handbook.pdf) | [`book/main.typ`](book/main.typ) | 81 |
| English | [`en/book/agent-handbook-en.pdf`](en/book/agent-handbook-en.pdf) | [`en/book/main.typ`](en/book/main.typ) | 81 |

빌드:

```bash
python book/scripts/build.py      # Korean PDF
python en/book/scripts/build.py   # English PDF
```

구성:

| Part | 주제 | Chapters |
|---:|---|---:|
| I | Agent foundations | 8 |
| II | LangChain v1 | 13 |
| III | LangGraph v1 | 14 |
| IV | Deep Agents | 15 |
| V | Advanced patterns | 10 |
| VI | LangSmith | 6 |
| VII | Applied examples | 7 |
| VIII | Integrations | 8 |

주의: Part IV ch11~ch15와 Part VI는 수동 관리 Typst가 포함되어 있습니다. `book/scripts/config.yaml`에 무리하게 추가해 덮어쓰지 마세요.

---

## 실행 검증 정책

기본 검증은 `01`~`07` core notebooks만 대상으로 합니다. `08_integration/`은 의도적으로 제외됩니다.

```bash
# 변경된 01~07 노트북만 gpt-4.1 live smoke
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300

# LangSmith dataset/prompt/evaluate write까지 허용할 때
UV_NO_SYNC=1 uv run python local/notebook_execution_01_07_gpt41/run_notebooks.py \
  --changed-only --force --timeout 300 --allow-langsmith-mutations
```

로컬 실행 harness는 다음을 보장합니다.

- `08_integration/` 제외
- notebook source는 수정하지 않고 `local/notebook_execution_01_07_gpt41/` 아래 복사본 실행
- source 모델 문자열은 실행 복사본에서 `gpt-4.1`로 치환
- LangSmith project는 `langchain-langgraph-deepagents-notebooks`
- LangSmith mutation 리소스는 `local-exec-*` prefix로 namespace 처리

최근 검증 evidence는 [`docs/verification/2026-06-17-tutorial-gap-analysis.md`](docs/verification/2026-06-17-tutorial-gap-analysis.md)에 기록되어 있습니다.

---

## 기술 스택

| 패키지 | 기준 | 용도 |
|---|---|---|
| `python` | `>=3.12` | 노트북 실행 환경 |
| `uv` | lockfile 기반 | 패키지 관리 |
| `langchain` | `>=1.3.9` | agents, tools, middleware, streaming |
| `langchain-core` | `>=1.4.7` | message/tool/model core abstractions |
| `langgraph` | `>=1.2.5` | state graph, persistence, fault tolerance |
| `deepagents` | `>=0.6.10` | Deep Agents SDK, backend, subagents, skills |
| `agentevals` | `>=0.0.9` | trajectory match, LLM-as-judge evals |
| `langsmith` | lockfile | tracing, datasets, experiments, prompt hub |
| `langchain-openai` | `>=1.3.2` | OpenAI model integration |
| `pymupdf4llm` | `>=1.27.2.3` | multimodal PDF RAG preprocessing |

전체 의존성은 [`pyproject.toml`](pyproject.toml)과 `uv.lock`을 기준으로 관리합니다.

---

## 참고 문서

- [`AGENTS.md`](AGENTS.md) — 코딩 에이전트용 프로젝트 컨텍스트와 규칙
- [`docs/skills/`](docs/skills/) — LangChain/LangGraph/Deep Agents 작성 가드레일
- [`docs/OBSERVABILITY.md`](docs/OBSERVABILITY.md) — LangSmith/Langfuse 관측 설정
- [`docs/MODEL_PROVIDERS.md`](docs/MODEL_PROVIDERS.md) — provider 선택과 로컬 모델 옵션
- [`docs/translation/KO_EN_TRANSLATION_GUIDE.md`](docs/translation/KO_EN_TRANSLATION_GUIDE.md) — 한영 번역 가이드
- [`07_examples/skills/`](07_examples/skills/) — 실전 예제용 SKILL.md 모음

---

## 라이선스

MIT
