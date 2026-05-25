# LangChain Dependencies

패키지 버전 및 의존성 관리 가이드.

## 요구사항

- Python 3.10+
- Node.js 20+ (TypeScript 사용 시)

## 핵심 패키지

| 패키지 | 용도 | 최소 버전 | 비고 |
|--------|------|-----------|------|
| `langchain` | 코어 프레임워크 | 1.3.0+ | event streaming v3, ~~0.3 레거시~~ |
| `langchain-core` | 기본 추상화 | — | langchain에 포함 |
| `langgraph` | 워크플로/에이전트 런타임 | 1.2.0+ | fault tolerance, `stream_events(..., version="v3")` |
| `deepagents` | 고수준 에이전트 하네스 | 0.6.1+ | async subagents, interpreters, event streaming v3 |
| `langsmith` | 관측성 | 선택 | tracing/eval |
| `langchain-openai` | OpenAI 통합 | 최신 | 전용 패키지 권장 |
| `langchain-anthropic` | Anthropic 통합 | 최신 | 전용 패키지 권장 |
| `langchain-google-genai` | Google 통합 | 4.0.0+ | Gemini + Vertex AI 단일 SDK |
| `langchain-community` | 커뮤니티 통합 | — | 보수적 버전 고정 |
| `pymupdf4llm` | PDF Markdown 추출 | 1.27.2.3+ | 슬라이드/논문 PDF 이미지·표 추출 |

### 선택적 샌드박스 (deepagents 0.4+)

| 패키지 | 용도 |
|--------|------|
| `langchain-modal` | Modal 기반 코드 실행 |
| `langchain-daytona` | Daytona 샌드박스 |
| `langchain-runloop` | Runloop 샌드박스 |

## 설치

```bash
# uv (권장)
uv add langchain langgraph langchain-openai

# deepagents까지
uv add langchain langgraph deepagents langchain-openai langchain-anthropic

# PDF/슬라이드 멀티모달 RAG
uv add pymupdf4llm

# pip
pip install "langchain>=1.3" "langgraph>=1.2" "deepagents>=0.6.1" "pymupdf4llm>=1.27.2.3"
```

## 버전 관리 원칙

1. **LangChain 1.3+ / LangGraph 1.2+ / DeepAgents 0.6.1+ 사용** — 최신 스트리밍·fault tolerance·interpreter 예제 기준
2. **전용 통합 패키지 우선** — `langchain-openai` > `langchain-community`의 OpenAI
3. **langchain-community는 보수적 고정** — 빈번한 변경 가능성
4. **langchain-core 직접 설치 불필요** — `langchain`에 포함
5. **샌드박스 패키지는 필요할 때만** — 기본 실행에는 불필요

## 주요 버전별 변경 요약

- **langchain 1.1**: `.profile`, `SystemMessage` system_prompt, `ModelRetryMiddleware`, OpenAI content moderation, summarization dynamic trigger
- **langchain 1.2**: 도구 `extras` 속성 (Anthropic programmatic tool calling, fine-grained streaming), `response_format` strict
- **langchain 1.3**: `stream_events()` / `astream_events()` `version="v3"` — typed projection 기반 agent event streaming
- **langgraph 1.1**: `version="v2"` 스트리밍/인보크, `GraphOutput`, Pydantic/dataclass 자동 강제
- **langgraph 1.2**: `DeltaChannel`, per-node timeout, node-level `error_handler`, graceful shutdown, event streaming v3
- **deepagents 0.4**: 샌드박스 패키지 3종, OpenAI Responses API 기본, `ContextOverflowError` 자동 요약
- **deepagents 0.5**: async subagents, 멀티모달 `read_file`, `StateBackend()` / `StoreBackend()` 직접 인스턴스화
- **deepagents 0.6**: `CodeInterpreterMiddleware`(QuickJS), interpreter snapshots, Deep Agents event streaming v3

각 버전 세부 내용은 docs.langchain.com/oss/python/releases/changelog 참조.
