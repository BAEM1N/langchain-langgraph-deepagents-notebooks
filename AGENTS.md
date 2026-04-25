# Agent Engineering Notebooks — AGENTS.md

이 문서는 코딩 에이전트(Claude Code, Cursor, Windsurf, Deep Agents CLI 등)가 프로젝트를 이해하고 활용할 수 있도록 작성되었다.

## 프로젝트 개요

LLM Agent 개발을 위한 **한국어 교육 자료** 프로젝트. 초급(LLM 기초)부터 고급(프로덕션 멀티에이전트)까지 단계별로 구성된 Jupyter 노트북 모음.

- **대상**: LLM Agent 개발을 배우려는 한국어 사용자
- **목표**: LangChain, LangGraph, Deep Agents SDK를 실습 중심으로 학습
- **총 노트북**: 59개 (초급 8 + 중급 36 + 고급 10 + 예제 5)

## 폴더별 컨텍스트

| 폴더 | 역할 | 난이도 | 선수 지식 | 노트북 수 |
|------|------|--------|-----------|-----------|
| `01_beginner/` | LLM·에이전트 기초, 프레임워크 비교 | 초급 | Python 기초 | 8 |
| `02_langchain/` | LangChain 에이전트, 도구, 미들웨어, RAG | 중급 | 01 완료 | 13 |
| `03_langgraph/` | LangGraph 그래프 API, 워크플로, 지속성 | 중급 | 01 완료 | 13 |
| `04_deepagents/` | Deep Agents SDK 하네스, 백엔드, 스킬 | 중급 | 01 완료 | 10 |
| `05_advanced/` | 프로덕션 패턴, 멀티에이전트, RAG, SQL | 고급 | 02-04 중 1개 이상 | 10 |
| `07_examples/` | 실전 응용 예제 (RAG, SQL, 데이터분석, ML, 딥리서치) + SKILL.md 통합 | 중급-고급 | 04 완료 | 5 |

## docs/ 구조

```
docs/
├── concepts/          # 공통 개념 (context, memory, products)
├── deepagents/        # Deep Agents SDK 문서 (19개)
│   └── examples/      # 공식 예제 5개 문서
├── langchain/         # LangChain 문서 (38개)
│   └── tutorials/     # 튜토리얼 8개
├── langgraph/         # LangGraph 문서 (23개)
│   └── tutorials/     # 튜토리얼 2개
└── skills/            # LangChain Skills 참조 (12개)
```

**활용법**: 노트북 코드와 설명은 반드시 `docs/` 내 문서를 근거로 작성한다. 임의 API 추측 금지.

## 노트북 컨벤션

### 셀 구조

1. **제목 + 학습 목표** (markdown) — `# NN. 제목 — 부제` + `## 학습 목표`
2. **환경 설정** (code) — `load_dotenv()`, `assert`
3. **Observability** (code) — LangSmith + Langfuse 설정
4. **모델 설정** (code) — `ChatOpenAI(model="gpt-4.1")`
5. **본문 섹션** (markdown + code 교대)
6. **요약 표** (markdown) — 3열 표 형식
7. **참고 문서** (markdown) — `---` + `**참고 문서:**`

### 셀 ID

`cell-0`, `cell-1`, `cell-2`, ... (0-indexed, 순차적)

### 코드 스타일

- **한국어 설명**, **영어 코드**
- 코드 셀 **10줄 이내**
- 파일명: `NN_snake_case.ipynb`

### Observability 패턴

```python
# LangSmith (선택)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_PROJECT", "agent-notebooks")

# Langfuse (선택)
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()

lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}
```

## 기술 스택

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `deepagents` | >=0.4.4 | Deep Agents SDK |
| `langchain` | >=1.2 | LangChain 프레임워크 |
| `langgraph` | >=1.0 | LangGraph 오케스트레이션 |
| `langchain-openai` | latest | OpenAI 통합 |
| `langchain-community` | latest | 커뮤니티 통합 |
| `tavily-python` | latest | 웹 검색 도구 |
| `langfuse` | >=2.0 | Observability (선택) |
| `langsmith` | >=0.3 | Observability (선택) |

**Python**: >=3.12 | **패키지 관리**: uv

## Skills 참조

`docs/skills/` 디렉토리에 LangChain Skills 문서가 저장되어 있다:

- `AGENTS.md` — 마스터 라우팅 가이드
- `framework-selection.md` — 프레임워크 선택 기준
- `langchain-*.md`, `langchain-v1-modern.md` — LangChain 스킬과 v1 작성 가드레일
- `langgraph-*.md` — LangGraph 스킬 3개
- `deep-agents-*.md` — Deep Agents 스킬 3개

코드 작성 전 관련 스킬 문서를 참조할 것.

### 07_examples 실전 스킬 (SKILL.md)

`07_examples/skills/` 디렉토리에 에이전트별 SKILL.md 파일이 있다:

| 스킬 | 경로 | 용도 |
|------|------|------|
| `rag-agent` | `skills/rag-agent/SKILL.md` | RAG 검색 패턴, 청킹 전략, 안전 규칙 |
| `sql-agent` | `skills/sql-agent/SKILL.md` | SQL 안전 규칙, query-writing 워크플로, HITL |
| `data-analysis` | `skills/data-analysis/SKILL.md` | 분석 체크리스트, 코드 실행 규칙, 멀티턴 |
| `ml-pipeline` | `skills/ml-pipeline/SKILL.md` | ML 파이프라인, 모델 비교, 보고 형식 |
| `deep-research` | `skills/deep-research/SKILL.md` | 5단계 워크플로, 서브에이전트 구성, 인용 규칙 |

에이전트 생성 시 `skills=["/skills/"]`로 전달하면 Progressive Disclosure로 필요 시에만 로드된다.

## 개발 규칙

1. **문서 기반 작성**: `docs/*.md`와 공식 문서를 근거로 코드 작성
2. **기본 모델**: `ChatOpenAI(model="gpt-4.1")`
3. **환경 변수**: `load_dotenv()` → `.env` 파일
4. **안전 모드**: `FilesystemBackend(virtual_mode=True)`, `LocalShellBackend(virtual_mode=True)`
5. **참고 문서 명시**: 노트북 마지막 셀에 참조 문서 기재
6. **테스트**: 모든 코드 셀은 실행 가능해야 함
7. **한국어 설명, 영어 코드**: 주석과 마크다운은 한국어, 변수명과 함수명은 영어
