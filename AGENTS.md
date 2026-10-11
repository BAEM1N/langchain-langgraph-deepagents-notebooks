# Agent Engineering Notebooks — AGENTS.md

이 문서는 코딩 에이전트(Claude Code, Cursor, Windsurf, Deep Agents CLI 등)가 프로젝트를 이해하고 활용할 수 있도록 작성되었다.

## 프로젝트 개요

LLM Agent 개발을 위한 **한국어 교육 자료** 프로젝트. 초급(LLM 기초)부터 고급(프로덕션 멀티에이전트)까지 단계별로 구성된 Jupyter 노트북 모음.

- **대상**: LLM Agent 개발을 배우려는 한국어 사용자
- **목표**: LangChain, LangGraph, Deep Agents SDK를 실습 중심으로 학습
- **총 노트북**: 241개 tracked `.ipynb` (한국어 core 86 + 영어 mirror 86 + integration 69)

## 폴더별 컨텍스트

| 폴더 | 역할 | 난이도 | 선수 지식 | 노트북 수 |
|------|------|--------|-----------|-----------|
| `01_beginner/` | LLM·에이전트 기초, 프레임워크 비교 | 초급 | Python 기초 | 8 |
| `02_langchain/` | LangChain 에이전트, 도구, 미들웨어, RAG | 중급 | 01 완료 | 14 |
| `03_langgraph/` | LangGraph 그래프 API, 워크플로, 지속성 | 중급 | 01 완료 | 16 |
| `04_deepagents/` | Deep Agents SDK 하네스, 백엔드, 스킬 | 중급 | 01 완료 | 16 |
| `05_advanced/` | 프로덕션 패턴, 멀티에이전트, RAG, SQL | 고급 | 02-04 중 1개 이상 | 12 |
| `06_langsmith/` | LangSmith tracing, evaluation, monitoring | 중급-고급 | 02-04 중 1개 이상 | 9 |
| `07_examples/` | 실전 응용 예제와 SKILL.md 통합 | 중급-고급 | 04 완료 | 11 |
| `08_integration/` | provider, vector DB, retriever, sandbox, observability 통합 카탈로그 | 고급 | 주제별 선택 | 69 |
| `en/` | 01~07 영어 mirror | 중급-고급 | 한국어 core 대응 | 86 |

## docs/ 구조

```
docs/
├── concepts/          # 공통 개념 (context, memory, products)
├── deepagents/        # Deep Agents SDK 문서와 공식 경로 매핑 (55개)
│   └── examples/      # 공식 예제 5개 문서
├── langchain/         # LangChain 문서와 공식 경로 매핑 (63개)
│   └── tutorials/     # 튜토리얼 8개
├── langgraph/         # LangGraph 문서와 공식 경로 매핑 (60개)
│   └── tutorials/     # 튜토리얼 2개
└── skills/            # LangChain Skills 참조와 작성 가드레일 (13개)
```

**활용법**: 노트북 코드와 설명은 반드시 `docs/` 내 문서를 근거로 작성한다. 임의 API 추측 금지.

## 노트북 컨벤션

### 셀 구조

1. **제목 + 학습 목표** (markdown) — `# NN. 제목 — 부제` + `## 학습 목표`
2. **환경 설정** (code) — `load_dotenv()`, `assert`
3. **Observability** (code) — LangSmith + Langfuse 설정
4. **모델 설정** (code) — `ChatOpenAI(model="gpt-5.4")`
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
# LangSmith (선택) — LANGSMITH_TRACING=true 면 자동 트레이싱
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGSMITH_PROJECT", "agent-notebooks")

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
| `deepagents` | 0.7.23 조사 기준 | Deep Agents SDK |
| `langchain` | 1.4.4 조사 기준 | LangChain 프레임워크 |
| `langgraph` | 1.2.14 조사 기준 | LangGraph 오케스트레이션 |
| `langchain-openai` | 1.7.0 조사 기준 | OpenAI 통합 |
| `langchain-community` | latest | 커뮤니티 통합 |
| `tavily-python` | latest | 웹 검색 도구 |
| `langfuse` | >=2.0 | Observability (선택) |
| `langsmith` | 0.14.7 조사 기준 | Observability (선택) |

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
| `multimodal-rag` | `skills/multimodal-rag/SKILL.md` | PDF/PPTX-export 슬라이드 기반 이미지·표 포함 RAG |

에이전트 생성 시 `skills=["/skills/"]`로 전달하면 Progressive Disclosure로 필요 시에만 로드된다.

## 개발 규칙

1. **문서 기반 작성**: `docs/*.md`와 공식 문서를 근거로 코드 작성
2. **기본 모델**: `ChatOpenAI(model="gpt-5.4")`
3. **환경 변수**: `load_dotenv()` → `.env` 파일
4. **안전 모드**: `FilesystemBackend(virtual_mode=True)`, `LocalShellBackend(virtual_mode=True)`
5. **참고 문서 명시**: 노트북 마지막 셀에 참조 문서 기재
6. **테스트**: 모든 코드 셀은 실행 가능해야 함
7. **한국어 설명, 영어 코드**: 주석과 마크다운은 한국어, 변수명과 함수명은 영어

### 최신성 주의

- Deep Agents 0.7 기준 계획 도구는 기본 내장이 아니라 `TodoListMiddleware`를 명시해 구성한다.
- Deep Agents backend는 `BackendProtocol` 인스턴스를 전달한다. `StoreBackend`는 keyword-only `namespace=`가 필요하며, `namespace=lambda rt: ...` factory는 여전히 유효하다.
- `FilesystemBackend`/`LocalShellBackend`의 `virtual_mode=True`는 경로 정규화 보조 장치일 뿐 셸 격리가 아니다. 운영 실행은 sandbox backend와 권한 규칙을 별도로 설계한다.
- LangChain MCP는 `langchain.mcp.MCPAdapter` beta API를 기준으로 설명한다. 기존 `langchain_mcp_adapters.MultiServerMCPClient`는 역사적 migration 문맥으로만 둔다.
- LangSmith run 조회는 `client.list_runs` 단순 치환이 아니다. SmithDB `client.runs.query()`는 async, project UUID, 시간 범위, 페이지 처리, `selects=[...]` 필드 projection을 함께 다룬다. `runs.query()`에서 `selects`를 생략하면 `ID`만 채워지므로 `NAME`, `INPUTS`, `OUTPUTS`, `START_TIME`, `END_TIME`, `TRACE_ID`, `METADATA`, `FEEDBACK_STATS`, `LS_USER_ID`처럼 읽는 필드를 SCREAMING_SNAKE_CASE로 명시한다.
