# LangChain Dependencies

패키지 버전 및 의존성 관리 가이드.

## 요구사항

- 이 저장소는 Python 3.12+
- Node.js 20+ (TypeScript 사용 시)

## 핵심 패키지

| 패키지 | 용도 | 최소 버전 | 비고 |
|--------|------|-----------|------|
| `langchain` | 코어 프레임워크 | 1.4.4+ | `langchain.mcp` beta, event streaming v3 |
| `langchain-core` | 기본 추상화 | 1.6.9+ | 직접 명시 권장 |
| `langgraph` | 워크플로/에이전트 런타임 | 1.2.14+ | `interrupt(response_schema=...)`, `trace_policy`, fault tolerance |
| `deepagents` | 고수준 에이전트 하네스 | 0.7.23+ | opt-in todo, backend 인스턴스 계약, fork subagents, skill tool disclosure |
| `langsmith` | 관측성 | 0.14.7+ | tracing/eval, SmithDB-backed run queries |
| `langchain-openai` | OpenAI 통합 | 1.7.0+ | 전용 패키지 권장 |
| `langchain-anthropic` | Anthropic 통합 | 최신 | 전용 패키지 권장 |
| `langchain-google-genai` | Google 통합 | 4.4.1+ | Gemini + Vertex AI 단일 SDK, thinking 설정 |
| `langchain-community` | 커뮤니티 통합 | 0.4.2,<0.5 | 보수적 minor 고정 |
| `mcp` | MCP v2 프로토콜 | 2.3.0,<3 | FastMCP 4 기반 계약 |
| `fastmcp` | MCP client/server | 4.1.0,<5 | 도구는 문맥 종료 후 재연결 가능 |
| `langfuse` | 선택적 관측성 | 4.17.0,<5 | LangChain callback 통합 |
| `assemblyai` | 음성 스트리밍 | 1.6.1,<2 | versioned RealTimeTranscriber |
| `cartesia` | 음성 합성 | 4.2.0,<5 | websocket_connect/context 흐름 |
| `pymupdf4llm` | PDF Markdown 추출 | 1.28.2+ | 슬라이드/논문 PDF 이미지·표 추출 |

### 선택적 샌드박스 (deepagents 0.4+)

| 패키지 | 용도 |
|--------|------|
| `langchain-modal` | Modal 기반 코드 실행 |
| `langchain-daytona` | Daytona 샌드박스 |
| `langchain-runloop` | Runloop 샌드박스 |

### 선택적 Deep Agents 확장

| 패키지 / extra | 용도 |
|----------------|------|
| `deepagents[quickjs]` / `langchain-quickjs>=0.3.8` | `CodeInterpreterMiddleware`, PTC, dynamic subagents |
| `deepagents-code` | `dcode` 터미널 코딩 에이전트 |
| `langchain[mcp]` | `MCPAdapter` beta와 FastMCP 기반 MCP 통합 |

## 설치

```bash
# uv (권장)
uv add langchain langgraph langchain-openai

# deepagents까지
uv add langchain-core langchain langgraph deepagents langchain-openai langchain-anthropic "langchain[mcp]"

# PDF/슬라이드 멀티모달 RAG
uv add pymupdf4llm

# pip
pip install "langchain-core>=1.6.9" "langchain[mcp]>=1.4.4" "langgraph>=1.2.14" "deepagents>=0.7.23" "langsmith>=0.14.7" "pymupdf4llm>=1.28.2" "mcp>=2.3.0,<3" "fastmcp>=4.1.0,<5"
```

## 버전 관리 원칙

전체 설치는 `uv sync --all-extras`와 저장소 `uv.lock`을 기준으로 재현한다. `websockets>=15.0.1,<16`은 OpenAI realtime / Cartesia websocket extras의 실제 호환 제약이다. 최신 전체 버전과 호환 가능한 버전을 구분한다.

1. **LangChain 1.4.4+ / LangGraph 1.2.14+ / DeepAgents 0.7.23+ 사용** — MCPAdapter, response schema, backend 0.7 계약, skill tool disclosure 예제 기준
2. **전용 통합 패키지 우선** — `langchain-openai` > `langchain-community`의 OpenAI
3. **langchain-community는 보수적 고정** — 빈번한 변경 가능성
4. **langchain-core 직접 명시 권장** — monorepo/교육 환경에서 버전 경계를 명확히 함
5. **샌드박스 패키지는 필요할 때만** — 기본 실행에는 불필요

## 주요 버전별 변경 요약

- **langchain 1.1**: `.profile`, `SystemMessage` system_prompt, `ModelRetryMiddleware`, OpenAI content moderation, summarization dynamic trigger
- **langchain 1.2**: 도구 `extras` 속성 (Anthropic programmatic tool calling, fine-grained streaming), `response_format` strict
- **langchain 1.3**: `stream_events()` / `astream_events()` `version="v3"` — typed projection 기반 agent event streaming
- **langgraph 1.1**: `version="v2"` 스트리밍/인보크, `GraphOutput`, Pydantic/dataclass 자동 강제
- **langgraph 1.2**: `DeltaChannel`, per-node timeout, node-level `error_handler`, graceful shutdown, event streaming v3
- **deepagents 0.4**: 샌드박스 패키지 3종, OpenAI Responses API 기본, `ContextOverflowError` 자동 요약
- **deepagents 0.5**: async subagents, 멀티모달 `read_file`, `StateBackend()` / `StoreBackend()` 직접 인스턴스화
- **deepagents 0.6**: `CodeInterpreterMiddleware`(QuickJS), interpreter snapshots, programmatic subagents, `RubricMiddleware`, Deep Agents Code(`dcode`), Deep Agents event streaming v3
- **deepagents 0.7**: 계획 도구 opt-in, backend factory 제거, `StoreBackend(namespace=...)` 필수, subagent `mode="fork"`, skill `metadata.include_tools`, state 입력의 `pinned_skills`
- **langchain 1.4**: `langchain.mcp.MCPAdapter` beta 도입. 기존 `langchain-mcp-adapters`는 migration 비교용으로만 사용
- **langsmith 0.14**: run 조회는 SmithDB `client.runs.query()` 중심. async, project UUID, 시간 범위, pagination, `selects=[...]` projection을 함께 처리. `selects` 기본값은 `ID`뿐이므로 `NAME`, `INPUTS`, `OUTPUTS`, `START_TIME`, `END_TIME`, `TRACE_ID`, `METADATA`, `FEEDBACK_STATS`, `LS_USER_ID`처럼 실제로 읽는 필드를 명시한다.

각 버전 세부 내용은 docs.langchain.com/oss/python/releases/changelog 참조.
