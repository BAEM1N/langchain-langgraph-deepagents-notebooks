// Source: 08_integration/README.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "통합 카테고리 개요", subtitle: "LangChain 생태계 지도")

LangChain·LangGraph·Deep Agents는 공통 에이전트 인터페이스 아래 _프로바이더별 구현_을 플러그인 형태로 연결합니다. Part II~Part IV가 "에이전트를 어떻게 쓰는가"를 다뤘다면, 이 Part는 "에이전트를 _무엇과_ 연결하는가"를 살핍니다. 13개 카테고리의 통합 표면을 한눈에 파악하고, 각 카테고리의 대표 패키지와 선택 기준을 정리합니다.

#learning-header()
#learning-objectives(
  [LangChain 생태계의 13개 통합 카테고리를 조감한다],
  [Provider Middleware가 왜 별도 카테고리로 분리되는지 이해한다],
  [벤더 선택이 필요한 영역(Chat Models, Vector Stores)과 표준화된 영역(Middleware, Checkpointers)을 구분한다],
  [이 Part에서 다루는 7개 Provider Middleware 장의 맵을 그린다],
)

== 1.1 기준 버전 스냅샷

이 Part의 코드는 다음 버전을 전제로 합니다. 최신 릴리스는 `docs/skills/langchain-dependencies.md`로 확인하세요.

- `langchain` 1.3+ (event streaming v3)
- `langgraph` 1.2+ (per-node timeout · `DeltaChannel` · graceful shutdown)
- `deepagents` 0.6.1+ (`CodeInterpreterMiddleware`, async subagents, interpreter snapshots)

#warning-box[LangChain 1.2 `create_agent`는 같은 미들웨어 클래스의 _중복 인스턴스_를 거부합니다. `AssertionError: Please remove duplicate middleware instances.`가 발생하면 서브클래싱으로 두 인스턴스를 서로 다른 타입으로 분리하세요.]

== 1.2 13개 통합 카테고리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[카테고리],
  text(weight: "bold")[대표 패키지],
  text(weight: "bold")[선택 기준],
  [Chat Models],
  [`langchain-openai`, `langchain-anthropic`, `langchain-google-genai`, `langchain-aws`],
  [모델 성능·비용·리전 요건],
  [Embeddings],
  [`langchain-openai`, `langchain-cohere`, `langchain-voyageai`],
  [도메인 벤치마크·라이선스·다국어 지원],
  [Vector Stores],
  [`langchain-chroma`, `langchain-pinecone`, `langchain-pgvector`],
  [운영 규모·메타데이터 필터링·관리형 여부],
  [Document Loaders],
  [`langchain-community.document_loaders`],
  [소스 포맷(PDF, Notion, Slack 등)],
  [Retrievers],
  [`langchain.retrievers`, 벤더 특화 리트리버],
  [하이브리드 검색·MMR·재랭커 통합],
  [Text Splitters],
  [`langchain-text-splitters`],
  [언어·구조(코드 vs 프로즈)·오버랩 전략],
  [Tools],
  [`langchain-community.tools`, MCP 도구],
  [외부 API 연동·인증 방식·호출 제약],
  [Checkpointers],
  [`langgraph-checkpoint-postgres`, `-sqlite`],
  [내구성 요구·멀티 테넌트·백업 전략],
  [Stores],
  [`langgraph-store-postgres`, 벤더 관리형],
  [영속 메모리 규모·검색 방식(키/벡터)],
  [Sandboxes],
  [`langchain-daytona`, `langchain-modal`, `langchain-runloop`],
  [격리 수준·콜드 스타트·비용],
  [Provider Middleware],
  [`langchain-anthropic`, `langchain-aws`, `langchain-openai`],
  [프로바이더 고유 기능(캐시·네이티브 도구·정책)],
  [Observability],
  [`langsmith`, `langfuse`, OpenTelemetry],
  [SaaS vs 자체 호스팅·PII 정책],
  [Providers (Hosted Runtime)],
  [LangGraph Platform, Anthropic Skills, OpenAI Agents],
  [관리형 런타임 vs 자체 호스팅·SDK 호환성],
)

Provider Middleware는 _프로바이더 서버 측_에서 활성화되는 기능(프롬프트 캐시, 네이티브 도구, 컨텐츠 정책)을 LangChain 미들웨어 포맷으로 감싼 것입니다. 공식 문서에는 한 줄 정도만 언급되는 경우가 많아 실행 가능한 코드로 정리해 두는 편이 실용적입니다. 이 Part의 ch2~ch8에서 7개 미들웨어를 각각 1장씩 다룹니다.

== 1.3 Provider Middleware 로드맵

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[장],
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[효과],
  [2],
  [`AnthropicPromptCachingMiddleware`],
  [긴 시스템 프롬프트/도구 정의 서버 측 캐시 (5m/1h)],
  [3],
  [`ClaudeBashToolMiddleware`],
  [Claude 네이티브 bash 도구 + 실행 정책 3종],
  [4],
  [`StateClaudeTextEditorMiddleware` / `FilesystemClaudeTextEditorMiddleware`],
  [네이티브 text editor 6개 오퍼레이션],
  [5],
  [`StateClaudeMemoryMiddleware` / `FilesystemClaudeMemoryMiddleware`],
  [`/memories/*` 경로 계약으로 모델 자기 메모],
  [6],
  [`StateFileSearchMiddleware`],
  [상태 안 가상 파일의 glob/grep 검색],
  [7],
  [`BedrockPromptCachingMiddleware`],
  [AWS Bedrock 경유 Claude/Nova 캐시],
  [8],
  [`OpenAIModerationMiddleware`],
  [OpenAI Moderation API로 사전/사후 검사],
)


== 1.4 새 통합 표면: UI · Code · 견고성

2026년 기준 통합 범위는 provider middleware만으로 끝나지 않습니다. 새 표면은 이 Part의 13개 카테고리 수를 바꾸지 않고, 기존 카테고리 위에 얹히는 _연결 방식_으로 읽는 것이 안전합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[표면],
  text(weight: "bold")[핵심],
  text(weight: "bold")[이 책에서 이어지는 위치],
  [Generative UI / AG-UI],
  [controlled · declarative · open-ended UI 생성 패턴과 frontend/server 이벤트 경계],
  [Part 2/3의 agent state · streaming, Part 8의 provider/runtime 통합],
  [Deep Agents Code],
  [`/oss/deepagents/code`의 configuration · approval · extensions · plugins · MCP tools],
  [Part 4의 permissions/skills/subagents/backend와 같은 개념을 코딩 에이전트 런타임으로 확장],
  [RAG · fault tolerance · multimodal],
  [retrieval, checkpointer/retry/resume, multimodal `read_file`이 Deep Agents 파일시스템과 결합],
  [Part 4/5/7의 core agent · advanced patterns · examples와 연결],
)

Generative UI는 LLM이 UI를 _어느 정도까지_ 결정하느냐에 따라 controlled, declarative, open-ended로 나뉩니다. AG-UI는 이 흐름을 frontend와 agent server 사이의 이벤트 프로토콜로 연결하는 별도 트랙입니다. 따라서 이 장에서는 새 노트북을 만들지 않고, state/streaming/hosted runtime을 배운 뒤 frontend 통합 후보로 표시합니다.

Deep Agents Code 문서는 `configuration`, `approval`, `extensions`, `plugins`, `MCP tools`처럼 코딩 에이전트 제품화 표면을 다룹니다. 여기서의 승인·확장·플러그인은 Part 4의 permissions, skills, subagents, backend와 같은 개념을 더 좁은 코딩 에이전트 실행 환경에 맞춘 것입니다. 별도 자격 증명이나 환경 변수를 추가로 전제하지 않습니다.

RAG, fault tolerance, multimodal은 새 카테고리가 아니라 기존 축의 결합입니다. RAG는 Retriever/Vector Store와 Deep Agents 파일 컨텍스트의 결합이고, fault tolerance는 LangGraph checkpointer · retry · resume과 운영 장의 연결이며, multimodal은 `read_file`이 이미지/PDF/오디오/비디오 입력을 모델별 제한 안에서 전달하는 문제입니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[공식 참조],
  text(weight: "bold")[확인할 내용],
  [#link("https://docs.langchain.com/oss/python/langchain/frontend/generative-ui")[LangChain Generative UI]],
  [controlled/declarative/open-ended UI 패턴],
  [#link("https://docs.langchain.com/oss/python/deepagents/ag-ui")[Deep Agents AG-UI]],
  [frontend/server 통합 이벤트 경계],
  [#link("https://docs.langchain.com/oss/deepagents/code/configuration")[Deep Agents Code configuration]],
  [코딩 에이전트 런타임 설정],
  [#link("https://docs.langchain.com/oss/deepagents/code/approval-modes")[Code approval modes]],
  [실행 전 승인 정책과 권한 경계],
  [#link("https://docs.langchain.com/oss/deepagents/code/extensions")[Code extensions]],
  [런타임 기능 확장과 스킬/메모리 연결],
  [#link("https://docs.langchain.com/oss/deepagents/code/plugins")[Code plugins]],
  [외부 도구 묶음과 배포 단위],
  [#link("https://docs.langchain.com/oss/python/deepagents/fault-tolerance")[Deep Agents fault tolerance]],
  [재시도·재개·체크포인터와 운영 안정성],
  [#link("https://docs.langchain.com/oss/python/deepagents/multimodal")[Deep Agents multimodal]],
  [파일 백엔드와 멀티모달 입력 처리],
  [#link("https://docs.langchain.com/oss/python/deepagents/rag")[Deep Agents RAG]],
  [검색·파일 컨텍스트·서브에이전트 결합],
)

== 1.5 공통 패턴

이 Part의 모든 장은 세 단계 루프를 공유합니다.

+ *환경 설정* — `.env`에 해당 프로바이더 키를 넣고 패키지를 설치합니다.
+ *기본 사용* — `create_agent(..., middleware=[Middleware()])` 한 줄로 기능을 켭니다.
+ *검증* — `usage_metadata`, `tool_calls`, 또는 Moderation 응답을 읽어 기능이 실제로 동작하는지 확인합니다.

#tip-box[프로바이더 특화 미들웨어는 _모델을 같이 정해야_ 합니다. Anthropic 미들웨어를 OpenAI 모델에 붙이면 `unsupported_model_behavior` 설정에 따라 경고만 나오거나 예외가 발생합니다. 멀티 프로바이더 파이프라인에서는 `ModelFallbackMiddleware`와 조합할 때 순서에 주의하세요.]

== 1.6 Observability 환경변수 표준화

LangChain 1.1부터 트레이싱 관련 환경변수는 `LANGCHAIN_*` → `LANGSMITH_*`로 표준화되었습니다. 옛 변수도 호환을 위해 일정 기간 동작하지만, _신규 코드는 새 이름만 씁니다_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[변수],
  text(weight: "bold")[역할],
  text(weight: "bold")[비고],
  [`LANGSMITH_TRACING`],
  [트레이스 활성화 (`true` / `false`)],
  [모든 `create_agent` 실행 자동 계측],
  [`LANGSMITH_API_KEY`],
  [LangSmith 계정 키],
  [`ls__` 접두사],
  [`LANGSMITH_PROJECT`],
  [트레이스 분류 프로젝트 이름],
  [`tracing_context`로 호출 구간별 override 가능],
  [`LANGSMITH_ENDPOINT`],
  [self-host LangSmith용 엔드포인트],
  [선택 — SaaS 사용 시 불필요],
)

== 핵심 정리

- 통합은 13개 카테고리로 정리되며, 각 카테고리는 "프로바이더 플러그인 + 공통 인터페이스" 구조를 공유한다
- Provider Middleware는 프로바이더 _서버 측_ 고유 기능을 LangChain 미들웨어로 감싼 영역
- 이 Part의 2~8장이 7개 Provider Middleware를 1장씩 실행 가능한 코드로 다룬다
- Generative UI/AG-UI, Deep Agents Code, RAG/fault tolerance/multimodal은 새 노트북 목록이 아니라 기존 state·streaming·backend·retrieval·operations 축과 연결해 읽는다
- 중복 인스턴스 제약, 모델 매칭, 멀티 프로바이더 폴백은 Provider Middleware 공통 주의점
