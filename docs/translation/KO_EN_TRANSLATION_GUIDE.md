# KO ↔ EN Translation Guide
This document is the **source of truth for terminology alignment** before translating the Korean notebooks and Typst handbook into English.
Primary source references used to normalize these terms: `book/chapters/appendix_glossary.typ`, `docs/2026-03-11_glossary_prep.md`, `README.md`, `README.en.md`, and the framework reference docs under `docs/langchain/`, `docs/langgraph/`, and `docs/deepagents/`.
## How to use this guide
- Check this guide **before** translating notebook headings, glossary entries, chapter titles, or repeated framework terminology.
- If a Korean source term appears here, use the preferred English form exactly.
- If a future translation needs a new recurring term, add it here first so notebooks and Typst chapters stay aligned.

## Translation rules
1. **API / code identifiers** — Do not translate code identifiers such as `create_agent()`, `StateGraph`, `ToolRuntime`, `@entrypoint`, and environment variable names. Keep the original spelling exactly.
2. **Framework / product names** — Do not translate product names: LangChain, LangGraph, Deep Agents, LangSmith, Langfuse, MCP, ACP.
3. **First mention policy** — On first mention in a chapter or notebook, expand abbreviations in English when helpful: “retrieval-augmented generation (RAG)”, “human-in-the-loop (HITL)”, “personally identifiable information (PII)”.
4. **Heading style** — Use Title Case for notebook/book major headings (e.g. “Learning Objectives”, “Getting Started”), and sentence case for normal prose.
5. **Hyphenation** — Use the preferred forms consistently: “human-in-the-loop”, “multi-agent”, “real-time”, “open-source”, “thread ID”, “vector store”.
6. **Observability vocabulary** — Translate “관측성/관측 가능성” as “observability”, not “visibility” or “traceability”. Use “tracing” for “트레이싱/추적”.
7. **Educational tone** — Prefer clear instructional English over literal translation. Translate explanations naturally, but keep technical meaning and examples intact.
8. **Code cell prompts and output** — Keep executable code in English. User-facing prompt strings and printed messages may be translated to English if doing so does not change the learning intent.
9. **Typst/book consistency** — Use the same English labels in notebooks and the Typst handbook so headings, summaries, callout boxes, and appendix labels match.
10. **Fallback rule** — If a new term is not in this guide, prefer the official framework/provider wording from the repo’s `docs/` sources, then add the chosen term here before large-scale translation.

## Repository / curriculum labels
| Korean | Preferred English | Notes |
|---|---|---|
| 프로젝트 구조 | Repository Layout | Use for top-level README section headers. |
| 시작하기 | Getting Started | Preferred onboarding heading. |
| 환경 변수 | Environment Variables | Use in README and setup chapters. |
| 단계별 커리큘럼 | Curriculum at a Glance | Preferred README section title; use “curriculum” in running text. |
| 추가 문서 | Additional Documents | Preferred README/supporting docs heading. |
| 대상 독자 | Target Audience | Use in handbook frontmatter or course intros. |
| 이 책의 특징 | What This Book Offers | Preferred handbook frontmatter heading; avoid overly literal “Features of This Book”. |
| 이 책의 구성 | How This Book Is Organized | Preferred handbook/frontmatter heading. |
| 이 책의 사용법 | How to Use This Book | Matches common handbook style. |
| 실습 중심 | hands-on | Use adjectivally: “a hands-on guide”, “hands-on examples”. |
| 실전 응용 | applied | Use for course/example descriptions: “applied examples”, “applied patterns”. |
| 초급 | Beginner | Track/difficulty label. |
| 중급 | Intermediate | Track/difficulty label. |
| 고급 | Advanced | Track/difficulty label. |
| 에이전트 입문 | Agent Foundations | Preferred track title; broader and more natural than “Agent Introduction”. |
| 실전 응용 예제 | Applied Examples | Preferred folder/section title for `07_examples`. |

## Notebook / handbook structural labels
| Korean | Preferred English | Notes |
|---|---|---|
| 학습 목표 | Learning Objectives | Canonical notebook/chapter label. |
| 환경 설정 | Environment Setup | Use for setup chapters/notebooks. |
| 시작하기 전에 | Before You Start | Subtitle for setup/introduction material. |
| 동작 확인 | Smoke Test | Preferred concise label for first-run validation steps. |
| 요약 | Summary | Canonical closing section label. |
| 참고 문서 | References | Preferred final citation section label. |
| 다음 단계 | Next Steps | Canonical transition label. |
| 핵심 내용 | Key Concepts | Preferred section label in educational material. |
| 실습 환경 | Practice Environment | Use in handbook/frontmatter sections about runtime setup. |
| 코드 블록 읽기 | Reading Code Blocks | Handbook instructional label. |
| 박스 유형 | Callout Types | Preferred label for note/tip/warning box explanations. |
| 주의 | Caution | Use for warning-style callout titles. |
| 팁 | Tip | Use for tip-style callout titles. |
| 노트 | Note | Use for note-style callout titles. |

## Frameworks / protocols / products
| Korean | Preferred English | Notes |
|---|---|---|
| LangChain | LangChain | Keep unchanged. |
| LangGraph | LangGraph | Keep unchanged. |
| Deep Agents | Deep Agents | Keep unchanged. |
| LangSmith | LangSmith | Keep unchanged. |
| Langfuse | Langfuse | Keep unchanged. |
| 모델 컨텍스트 프로토콜 | Model Context Protocol (MCP) | Prefer full expansion on first mention, then MCP. |
| 에이전트 클라이언트 프로토콜 | Agent Client Protocol (ACP) | Prefer full expansion on first mention, then ACP. |
| 관측성 | observability | Preferred term in prose. |
| 관측 가능성 | observability | Treat as same term as 관측성. |

## Agent patterns / execution model
| Korean | Preferred English | Notes |
|---|---|---|
| 에이전트 | agent | Lowercase in running text unless starting a sentence or heading. |
| 워크플로 | workflow | Preferred generic term. |
| 오케스트레이터 | orchestrator | Preferred role/system term. |
| 워커 | worker | Preferred role term. |
| 서브에이전트 | subagent | Use closed form “subagent” for consistency. |
| 핸드오프 | handoff | Preferred routing/control transfer term. |
| 라우터 | router | Preferred routing component term. |
| 리액트 | ReAct | Keep the established pattern name exactly. |
| 휴먼 인 더 루프 | human-in-the-loop (HITL) | Use full phrase on first mention, HITL afterward if helpful. |
| 중단 | interrupt | Use as noun or verb depending on sentence. |
| 재개 | resume | Use as noun/verb depending on sentence. |
| 내구성 실행 | durable execution | Preferred LangGraph/agent runtime term. |
| 슈퍼스텝 | superstep | Pregel execution term. |
| 프리젤 | Pregel | Keep framework model name unchanged. |
| 멀티 에이전트 | multi-agent | Always hyphenate when used adjectivally. |

## State / memory / runtime
| Korean | Preferred English | Notes |
|---|---|---|
| 상태 | state | Preferred core runtime term. |
| 체크포인터 | checkpointer | Use “checkpoint” only for the saved artifact, “checkpointer” for the component. |
| 스레드 ID | thread ID | Use this exact capitalization. |
| 런타임 컨텍스트 | runtime context | Preferred phrase for execution-time context. |
| 단기 메모리 | short-term memory | Preferred memory category term. |
| 장기 메모리 | long-term memory | Preferred memory category term. |
| 의미 기억 | semantic memory | Memory taxonomy term. |
| 일화 기억 | episodic memory | Memory taxonomy term. |
| 절차 기억 | procedural memory | Memory taxonomy term. |
| 스토어 | store | Lowercase in prose when generic; preserve class names separately. |
| 인메모리 스토어 | InMemoryStore | Preserve official class name exactly. |
| 에이전트 상태 | AgentState | Preserve official schema/class name exactly. |
| 메시지 상태 | MessagesState | Preserve official schema/class name exactly. |
| 컨텍스트 스키마 | `context_schema` | Keep identifier form in technical explanations. |
| 상태 스키마 | `state_schema` | Keep identifier form in technical explanations. |

## Tools / APIs / interfaces
| Korean | Preferred English | Notes |
|---|---|---|
| 도구 | tool | Preferred generic tool term. |
| 도구 호출 | tool calling | Preferred structured-output / agent term. |
| 구조화된 출력 | structured output | Preferred output-format term. |
| 미들웨어 | middleware | Preferred runtime policy/interceptor term. |
| 가드레일 | guardrail | Preferred safety/control term. |
| 개인 식별 정보 | personally identifiable information (PII) | Expand on first mention if needed. |
| 툴 런타임 | `ToolRuntime` | Preserve official runtime type exactly. |
| 그래프 API | Graph API | Capitalize as named API surface. |
| 함수형 API | Functional API | Capitalize as named API surface. |
| 엔트리포인트 | `@entrypoint` | Preserve decorator exactly. |
| 태스크 | `@task` | Preserve decorator exactly. |
| 상태 그래프 | `StateGraph` | Preserve class name exactly. |
| 센드 | `Send` | Preserve API type exactly. |
| 커맨드 | `Command` | Preserve API type exactly. |
| create_agent | `create_agent()` | Preserve function name exactly. |
| create_deep_agent | `create_deep_agent()` | Preserve function name exactly. |

## Backends / execution environments
| Korean | Preferred English | Notes |
|---|---|---|
| 백엔드 | backend | Preferred generic term. |
| 상태 백엔드 | `StateBackend` | Preserve class/type name exactly. |
| 파일시스템 백엔드 | `FilesystemBackend` | Preserve class/type name exactly. |
| 스토어 백엔드 | `StoreBackend` | Preserve class/type name exactly. |
| 복합 백엔드 | `CompositeBackend` | Preserve class/type name exactly. |
| 로컬 셸 백엔드 | `LocalShellBackend` | Preserve class/type name exactly. |
| 가상 모드 | `virtual_mode=True` / virtual mode | Keep code literal in examples; use “virtual mode” in prose. |
| 샌드박스 | sandbox | Preferred isolated runtime term. |
| Modal | Modal | Keep provider name unchanged. |
| Daytona | Daytona | Keep provider name unchanged. |
| Runloop | Runloop | Keep provider name unchanged. |

## Retrieval / data / search
| Korean | Preferred English | Notes |
|---|---|---|
| 검색 증강 생성 | retrieval-augmented generation (RAG) | Use full expansion on first mention if helpful. |
| 리트리버 | retriever | Preferred retrieval component term. |
| 임베딩 | embedding | Preferred representation term. |
| 벡터 스토어 | vector store | Use this exact spacing. |
| 청킹 | chunking | Preferred document-splitting term. |
| 리랭킹 | reranking | Use closed form noun. |
| SQL 에이전트 | SQL agent | Preferred phrase for NL-to-SQL agents. |
| SQLDatabaseToolkit | `SQLDatabaseToolkit` | Preserve class name exactly. |

## Streaming / frontend / quality
| Korean | Preferred English | Notes |
|---|---|---|
| 스트리밍 | streaming | Preferred incremental-delivery term. |
| 스트림 이벤트 | `StreamEvent` | Preserve official event type when referring to the API. |
| 토큰 스트리밍 | token streaming | Preferred phrase. |
| 첫 토큰까지 걸리는 시간 | time to first token (TTFT) | Expand on first mention if useful. |
| 첫 오디오까지 걸리는 시간 | time to first audio (TTFA) | Expand on first mention if useful. |
| 평가 | evaluation | Preferred quality measurement term. |
| 실행 궤적 | trajectory | Preferred execution-path term. |
| LLM 판정자 | LLM-as-Judge | Use repo’s established term casing. |
| 사용자 정의 이벤트 | custom event | Preferred streaming/frontend phrase. |
| 프론트엔드 스트리밍 | frontend streaming | Preferred section/chapter phrase. |

## Quick decisions for upcoming translation work
- Translate prose into natural instructional English; do **not** mirror Korean sentence structure mechanically.
- Keep API names, decorators, class names, environment variables, and package names unchanged.
- Use the same English chapter/notebook labels everywhere: **Learning Objectives**, **Summary**, **References**, **Next Steps**, **Getting Started**, **Repository Layout**.
- In the handbook frontmatter, prefer **What This Book Offers**, **Target Audience**, **How This Book Is Organized**, and **How to Use This Book**.
- For Deep Agents / LangGraph runtime concepts, distinguish **checkpointer** (component) from **checkpoint** (saved state), and **thread ID** from generic “session”.
- For RAG material, prefer **retrieval-augmented generation (RAG)**, **retriever**, **embedding**, **vector store**, **chunking**, and **reranking**.
- For observability material, use **observability**, **tracing**, **evaluation**, **trajectory**, and **LLM-as-Judge** consistently.
