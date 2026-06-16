// Auto-generated from 02_graph_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Graph API 기초", subtitle: "StateGraph로 워크플로 만들기")

== 학습 목표
StateGraph, 노드, 엣지, 조건부 분기, 상태 리듀서를 이해합니다.

== 2.1 환경 설정

LLM 모델과 필요한 모듈을 불러옵니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 2.2 StateGraph 기본 구조

StateGraph를 사용하는 기본 흐름입니다:

+ `StateGraph(State)` — 상태 스키마로 그래프 빌더 생성
+ `add_node()` — 노드(함수) 등록
+ `add_edge()` — 노드 간 연결
+ `compile()` — 실행 가능한 그래프 생성
+ `invoke()` — 그래프 실행

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

== 2.3 상태 리듀서

`Annotated`로 상태 업데이트 방식을 지정합니다.

=== 리듀서란?

- 리듀서는 상태 필드가 _어떻게 업데이트되는지_ 결정합니다
- 리듀서 없음: 단순 덮어쓰기 (override)
- `operator.add`: 리스트 항목을 누적 (append)
- 커스텀 함수로 리듀서 정의도 가능

== 2.4 조건부 엣지

상태에 따라 다른 노드로 분기합니다.

- `add_conditional_edges(source, routing_function)` — 라우팅 함수의 반환값이 다음 노드 이름
- 라우팅 함수는 `Literal` 타입 힌트를 사용하면 시각화에 도움

#code-block(`````python
START → classify → [route] → weather → END
                           → math    → END
                           → general → END
`````)

== 2.5 메시지 기반 상태

LLM 에이전트에 적합한 `MessagesState`를 사용합니다.

- `MessagesState`는 `messages: Annotated[list[AnyMessage], add_messages]`를 포함하는 사전 정의된 상태
- `add_messages` 리듀서가 메시지 리스트를 자동으로 누적
- LLM 응답을 메시지 히스토리에 자연스럽게 추가

== 2.6 입출력 스키마

그래프의 입출력을 내부 상태와 분리합니다.

- `StateGraph(InternalState, input_schema=InputSchema, output_schema=OutputSchema)`
- 입력 스키마: 외부에서 받는 데이터만 포함
- 출력 스키마: 외부로 내보내는 데이터만 포함
- 내부 상태: 중간 처리용 필드 포함 (외부에 노출되지 않음)

== 2.7 런타임 컨텍스트 — `context_schema` + `Runtime[ContextSchema]`

State에 넣지 않을 의존성(LLM provider, DB connection, user id 등)을 _호출 시점_에 주입합니다.

- 그래프 컴파일 시 `context_schema=ContextSchema` 지정
- 노드 시그니처에 `runtime: Runtime[ContextSchema]` 추가
- `graph.invoke({...}, context={...})` 으로 전달
- `runtime.execution_info` — thread/run/checkpoint/attempt
- `runtime.server_info` — LangGraph Server의 assistant/graph/user 정보
- `runtime.drain_requested` — graceful shutdown 신호

== 2.8 `add_node()` 고급 옵션 — retry / timeout / cache / error_handler / defer

`add_node()` 는 일반 함수 외에 신뢰성·성능 제어 파라미터를 받습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[타입],
  text(weight: "bold")[용도],
  [`retry_policy`],
  [`RetryPolicy(max_attempts=..., retry_on=...)`],
  [일시 장애 자동 재시도. 기본은 대부분의 예외, 단 `ValueError`/`TypeError` 등은 제외],
  [`timeout`],
  [`TimeoutPolicy(run_timeout=..., idle_timeout=...)`],
  [초과 시 `NodeTimeoutError`. async 노드 전용, attempt별 독립 적용],
  [`cache_policy`],
  [`CachePolicy(ttl=..., key_func=...)`],
  [입력 해시 기반 결과 캐싱. 컴파일 시 `cache=InMemoryCache()` 필요],
  [`error_handler`],
  [`Callable[[NodeError], Command]`],
  [retry 소진 후 복구용 `Command` 반환],
  [`defer`],
  [`bool`],
  [다른 분기가 끝날 때까지 노드 실행 지연 (fan-out/fan-in)],
)

== 2.9 `Send` + `Command` — 동적 fan-out 과 부모 그래프 라우팅

- `Send("worker", {...})` — 조건부 엣지에서 동적으로 워커 인스턴스를 생성, 각자 다른 state를 받음 (map-reduce)
- `Command(update=..., goto=...)` — 노드 반환값에서 state 갱신 + 라우팅을 동시에 표현
- `Command(graph=Command.PARENT, ...)` — 서브그래프 노드에서 부모 그래프로 점프

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [_StateGraph_],
  [상태 스키마 기반 그래프 빌더],
  [_Node_],
  [Python 함수로 정의된 처리 단위],
  [_Edge_],
  [노드 간 고정 연결 (`add_edge`)],
  [_Conditional Edge_],
  [상태 기반 동적 분기 (`add_conditional_edges`)],
  [_Reducer_],
  [`Annotated` + `operator.add`로 상태 누적 방식 정의],
  [_MessagesState_],
  [LLM 대화용 사전 정의된 상태],
  [_Input/Output Schema_],
  [내부 상태와 외부 입출력 분리],
  [_`context_schema` + `Runtime`_],
  [State에 넣지 않는 호출 시점 의존성 주입],
  [_`add_node()` 옵션_],
  [`retry_policy` / `timeout` / `cache_policy` / `error_handler` / `defer`],
  [_`Send` + `Command`_],
  [동적 fan-out (map-reduce), state 갱신 + 라우팅 동시 처리, `Command.PARENT` 로 부모 그래프 점프],
)
