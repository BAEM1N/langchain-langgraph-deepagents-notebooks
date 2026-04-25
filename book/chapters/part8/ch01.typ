// Source: 08_integration/README.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "통합 카테고리 개요", subtitle: "LangChain 생태계 지도")

LangChain·LangGraph·Deep Agents는 공통 에이전트 인터페이스 아래 _프로바이더별 구현_을 플러그인 형태로 연결하는 구조를 취합니다. Part II~Part IV에서 "에이전트를 어떻게 쓰는가"에 집중했다면, 이 Part는 "에이전트를 _무엇과_ 연결하는가"에 초점을 맞춥니다. 12개 카테고리에 걸친 통합 표면을 한눈에 파악하고, 각 카테고리의 대표 패키지와 선택 기준을 정리합니다.

#learning-header()
#learning-objectives(
  [LangChain 생태계의 12개 통합 카테고리를 조감한다],
  [Provider Middleware가 왜 별도 카테고리로 분리되는지 이해한다],
  [벤더 선택이 필요한 영역(Chat Models, Vector Stores)과 표준화된 영역(Middleware, Checkpointers)을 구분한다],
  [이 Part에서 다루는 7개 Provider Middleware 장의 맵을 그린다],
)

== 1.1 기준 버전 스냅샷

이 Part의 코드는 다음 버전을 전제로 합니다. 최신 릴리스는 `docs/skills/langchain-dependencies.md`로 확인하세요.

- `langchain` 1.2
- `langgraph` 1.1
- `deepagents` 0.5.0

#warning-box[LangChain 1.2 `create_agent`는 같은 미들웨어 클래스의 _중복 인스턴스_를 거부합니다. `AssertionError: Please remove duplicate middleware instances.`가 발생하면 서브클래싱으로 두 인스턴스를 서로 다른 타입으로 분리하세요.]

== 1.2 12개 통합 카테고리

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
)

Provider Middleware는 _프로바이더 서버 측_에서 활성화되는 기능(프롬프트 캐시, 네이티브 도구, 컨텐츠 정책)을 LangChain 미들웨어 포맷으로 감싼 것입니다. 공식 문서에 한 줄로만 언급되는 경우가 많아 실행 가능한 코드로 한 번 정리해 두는 가치가 큽니다. 이 Part의 ch2~ch8에서 7개 미들웨어를 각각 1장씩 다룹니다.

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

== 1.4 공통 패턴

이 Part의 모든 장은 세 단계 루프를 공유합니다.

+ *환경 설정* — `.env`에 해당 프로바이더 키를 넣고 패키지를 설치합니다.
+ *기본 사용* — `create_agent(..., middleware=[Middleware()])` 한 줄로 기능을 켭니다.
+ *검증* — `usage_metadata`, `tool_calls`, 또는 Moderation 응답을 읽어 기능이 실제로 동작했는지 확인합니다.

#tip-box[프로바이더 특화 미들웨어는 _모델을 같이 정해야_ 합니다. Anthropic 미들웨어를 OpenAI 모델에 붙이면 `unsupported_model_behavior` 설정에 따라 경고만 나오거나 예외가 발생합니다. 멀티 프로바이더 파이프라인에서는 `ModelFallbackMiddleware`와 조합할 때 순서에 주의하세요.]

== 핵심 정리

- 통합은 12개 카테고리로 정리되며, 각 카테고리는 "프로바이더 플러그인 + 공통 인터페이스" 구조를 공유한다
- Provider Middleware는 프로바이더 _서버 측_ 고유 기능을 LangChain 미들웨어로 감싼 영역
- 이 Part의 2~8장이 7개 Provider Middleware를 1장씩 실행 가능한 코드로 다룬다
- 중복 인스턴스 제약, 모델 매칭, 멀티 프로바이더 폴백은 Provider Middleware 공통 주의점
