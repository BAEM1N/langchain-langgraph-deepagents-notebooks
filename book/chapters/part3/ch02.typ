// Auto-generated from 02_graph_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Graph API 기초", subtitle: "StateGraph로 워크플로 만들기")

`Graph API`는 `LangGraph`의 대표적인 프로그래밍 모델로, `StateGraph`에 노드와 엣지를 명시적으로 등록하여 워크플로의 흐름을 시각적으로 설계합니다. 1장에서 소개한 세 가지 기본 요소 --- State, Node, Edge --- 를 코드로 조합하는 실전 방법을 이 장에서 본격적으로 다룹니다. 상태 스키마를 `TypedDict`로 정의하고, 리듀서로 값 병합 전략을 지정하며, 조건부 엣지로 분기를 제어하는 패턴은 이후 모든 장의 기초가 됩니다. 이 장에서 `StateGraph`의 생성부터 컴파일, 실행까지의 전체 라이프사이클을 단계별로 익혀 봅니다.

#learning-header()

+ `StateGraph` 빌더의 생성-컴파일-실행 라이프사이클을 단계별로 설명할 수 있다.
+ `Annotated` 타입 힌트와 리듀서(`operator.add`, `add_messages`)로 상태 병합 전략을 지정할 수 있다.
+ 조건부 엣지(`add_conditional_edges`)와 `Command` 객체를 사용하여 동적 분기를 구현할 수 있다.
+ `MessagesState`를 활용하여 LLM 대화 기반 에이전트 상태를 정의할 수 있다.
+ 입출력 스키마를 분리하여 그래프의 공개 인터페이스를 설계할 수 있다.

== 2.1 환경 설정

이 장의 모든 예제는 OpenAI의 `gpt-5.4` 모델을 사용합니다. `load_dotenv()`는 프로젝트 루트의 `.env` 파일에서 `OPENAI_API_KEY`를 읽어 환경 변수로 등록합니다. `override=True`를 설정하면 이미 시스템에 설정된 환경 변수가 있더라도 `.env` 파일의 값이 우선 적용되므로, 프로젝트별로 다른 API 키를 사용할 때 유용합니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 2.2 StateGraph 기본 구조

환경 설정을 마쳤으니, 이제 LangGraph의 핵심 빌더 클래스인 `StateGraph`를 살펴봅시다.

`StateGraph`는 LangGraph의 그래프 빌더 클래스입니다. 상태 스키마를 인자로 받아 그래프 인스턴스를 생성하고, 여기에 노드와 엣지를 등록한 뒤 `compile()`로 실행 가능한 `CompiledGraph` 객체를 만듭니다. 이 객체는 LangChain의 Runnable 인터페이스를 구현하므로 `invoke()`, `stream()`, `ainvoke()` 등의 메서드를 모두 지원합니다. 내부적으로 LangGraph는 Google의 Pregel 모델에서 영감을 받은 메시지 패싱 방식으로 실행됩니다. 각 노드는 비활성 상태에서 시작하여 인접 엣지로부터 메시지를 받으면 활성화되고, 작업을 수행한 뒤 다시 비활성으로 전환됩니다. 이 병렬 실행의 한 라운드를 _슈퍼스텝(super-step)_이라 부릅니다.

StateGraph를 사용하는 기본 흐름은 다섯 단계로 구성됩니다:

+ `StateGraph(State)` — 상태 스키마(`TypedDict`)로 그래프 빌더를 생성합니다. 이 스키마가 그래프 전체에서 공유되는 데이터 구조를 정의합니다.
+ `add_node(name, fn)` — Python 함수를 노드로 등록합니다. 함수 이름을 생략하면 함수 객체의 `__name__`이 자동으로 사용됩니다.
+ `add_edge(src, dst)` — 두 노드 사이에 고정 연결을 추가합니다. `START`와 `END`는 각각 그래프의 진입점과 종료점을 나타내는 가상 노드입니다.
+ `compile()` — 등록된 노드와 엣지를 검증하고 실행 가능한 `CompiledGraph`를 생성합니다. 이 단계에서 체크포인터나 인터럽트 설정도 함께 지정할 수 있습니다.
+ `invoke(input)` — 초기 상태를 전달하여 그래프를 실행합니다. 모든 노드가 비활성이 되면 실행이 종료됩니다.

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

아래 코드는 이 다섯 단계를 실제로 구현한 가장 단순한 예제입니다. `topic` 필드를 받아 에세이를 생성하는 단일 노드 그래프입니다. 실행 결과에서 `content` 필드에 LLM이 생성한 값이 들어 있는지 확인해 보세요.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END

class MyState(TypedDict):
    topic: str
    content: str | None

def write(state: MyState):
    return {"content": f"Essay about {state['topic']}"}

builder = StateGraph(MyState)
builder.add_node("write", write)
builder.add_edge(START, "write")
builder.add_edge("write", END)

graph = builder.compile()
result = graph.invoke({"topic": "AI"})
print(result)
`````)

#tip-box[`compile()` 이후에는 노드나 엣지를 추가할 수 없습니다. 그래프 구조를 변경하려면 빌더(`StateGraph`)부터 다시 시작해야 합니다. 이는 실행 시점의 그래프가 불변(immutable)임을 보장하기 위한 설계입니다.]

== 2.3 상태 리듀서

그래프의 기본 골격을 세웠으니, 이제 상태가 _어떻게 업데이트되는지_ 제어하는 리듀서를 살펴봅시다. 여러 노드가 같은 상태 필드에 값을 쓸 때, 기본 동작은 단순 덮어쓰기(override)입니다. 그러나 메시지 히스토리처럼 값을 _누적_해야 하는 경우가 많으므로, `Annotated` 타입 힌트로 각 필드의 업데이트 전략을 명시합니다. 리듀서는 LangGraph 상태 관리의 핵심 메커니즘이며, 이를 올바르게 이해하지 못하면 병렬 노드 실행 시 데이터가 유실되는 문제가 발생할 수 있습니다.

=== 리듀서란?

리듀서(reducer)는 함수형 프로그래밍의 `reduce` 개념에서 가져온 것으로, 기존 상태값과 새로운 업데이트를 인자로 받아 최종 상태값을 반환하는 함수입니다. `TypedDict`의 각 필드에 `Annotated` 타입 힌트를 사용하여 리듀서를 지정하면, 해당 필드에 값이 기록될 때마다 지정된 리듀서 함수가 호출됩니다. 리듀서가 지정되지 않은 필드는 가장 마지막에 기록된 값이 그대로 유지됩니다(last-write-wins).

- 리듀서 없음: 단순 덮어쓰기(override) --- 마지막으로 쓴 노드의 값이 유지됩니다
- `operator.add`: 리스트끼리 연결(concatenate)하거나 숫자를 합산합니다
- `add_messages`: 메시지 리스트 전용 리듀서 --- 동일 ID의 메시지는 덮어쓰고(upsert), 새 메시지는 추가합니다. 딕셔너리나 튜플 형태의 메시지를 자동으로 LangChain `Message` 객체로 역직렬화하는 기능도 포함되어 있습니다.
- 커스텀 함수: `def my_reducer(current, update): ...` 형태로 직접 정의할 수 있습니다

아래 코드에서 `messages` 필드에는 `operator.add` 리듀서가 적용되어 있어, 각 노드가 반환하는 메시지가 기존 리스트에 누적됩니다. 반면 `count` 필드에는 리듀서가 없으므로 마지막으로 기록한 값이 유지됩니다. 두 필드의 동작 차이를 주의 깊게 관찰해 보세요.

#code-block(`````python
from typing import TypedDict, Annotated
import operator

class MyState(TypedDict):
    messages: Annotated[list, operator.add]  # 리듀서: 누적
    count: int                                # 리듀서 없음: 덮어쓰기
`````)

#tip-box[`Annotated[list[AnyMessage], add_messages]`는 LangGraph에서 가장 자주 사용되는 리듀서 패턴입니다. `add_messages`는 단순 append가 아니라 메시지 ID를 기준으로 _upsert_ 동작을 수행하므로, 메시지 수정이나 삭제(`RemoveMessage`)도 자연스럽게 처리됩니다. `RemoveMessage(id=msg.id)` 형태로 메시지를 삭제하거나, `RemoveMessage(id=REMOVE_ALL_MESSAGES)`로 전체 히스토리를 초기화할 수도 있습니다.]

#warning-box[병렬로 실행되는 두 노드가 리듀서 없이 같은 필드에 값을 쓰면, 어떤 노드의 값이 최종적으로 남을지 예측할 수 없습니다. 병렬 실행이 가능한 필드에는 반드시 리듀서를 지정하세요.]

== 2.4 조건부 엣지

리듀서로 상태 업데이트 전략을 정의했다면, 이제 _실행 흐름을 동적으로 제어_하는 방법을 알아봅시다. 고정 엣지(`add_edge`)만으로는 항상 같은 경로를 따르지만, 실제 에이전트는 LLM의 판단이나 상태 값에 따라 다른 노드로 분기해야 하는 경우가 대부분입니다. 조건부 엣지는 이러한 동적 분기를 가능하게 하는 메커니즘입니다.

=== add_conditional_edges

`add_conditional_edges(source, routing_function)` 메서드는 `source` 노드 실행 후 `routing_function`을 호출하여 다음 노드를 결정합니다. 라우팅 함수는 현재 상태(`State`)를 인자로 받고, 다음에 실행할 노드의 이름을 문자열로 반환합니다. 반환값이 `END`이면 그래프 실행이 종료됩니다.

- `add_conditional_edges(source, routing_function)` --- 라우팅 함수의 반환값이 다음 노드 이름
- 라우팅 함수에 `Literal["node_a", "node_b"]` 반환 타입 힌트를 추가하면, 그래프 시각화(`draw_mermaid_png()`) 시 가능한 분기 경로가 자동으로 표시됩니다
- 선택적으로 `mapping` 딕셔너리를 세 번째 인자로 전달하여, 라우팅 함수의 반환값을 실제 노드 이름에 매핑할 수 있습니다

다음 예제는 라우팅 함수를 사용한 조건부 분기의 전형적인 패턴입니다. `classify` 노드가 질문을 분류한 뒤, `route` 함수가 분류 결과에 따라 적절한 처리 노드로 분기합니다.

#code-block(`````python
from typing import Literal

def route(state) -> Literal["weather", "math", "general"]:
    return state["classification"]

builder.add_conditional_edges("classify", route)
`````)

=== Command --- 상태 업데이트 + 라우팅 통합

LangGraph 0.2.x부터는 `Command` 객체를 사용하여 상태 업데이트와 라우팅을 하나의 반환값으로 통합할 수 있습니다. `Command(update={"field": value}, goto="next_node")`와 같이 작성하면 노드 함수 안에서 다음 노드를 직접 지정할 수 있어, 별도의 라우팅 함수 없이도 분기가 가능합니다. `Command`는 `update`로 상태를 수정하면서 동시에 `goto`로 다음 노드를 지정하므로, 분기 로직과 상태 업데이트가 하나의 반환문에 응집됩니다.

#code-block(`````python
from langgraph.types import Command

def classify_node(state):
    result = classify(state["messages"][-1].content)
    return Command(
        update={"classification": result},
        goto="handle_urgent" if result == "urgent" else "handle_normal",
    )
`````)

#warning-box[`Command` 객체를 사용하면 `add_conditional_edges()` 없이도 분기를 구현할 수 있지만, 시각화 다이어그램에 분기 경로가 자동으로 표시되지 않을 수 있습니다. 복잡한 워크플로에서는 가독성을 위해 명시적 조건부 엣지를 선호하는 경우가 많습니다. `Command`는 서브그래프에서 부모 그래프로 라우팅하거나(`graph=Command.PARENT`), 인터럽트 후 재개(`resume=`)할 때도 활용됩니다.]

전체 라우팅 흐름을 도식으로 나타내면 다음과 같습니다:

#code-block(`````python
START → classify → [route] → weather → END
                           → math    → END
                           → general → END
`````)

== 2.5 메시지 기반 상태

조건부 엣지까지 익혔으니, 이제 LLM 에이전트에서 가장 자주 사용되는 상태 패턴인 `MessagesState`를 살펴봅시다. 채팅 기반 에이전트는 대화 히스토리를 핵심 상태로 사용하기 때문에, LangGraph는 이를 위한 편의 클래스를 제공합니다. 매번 `messages: Annotated[list[AnyMessage], add_messages]`를 직접 선언하는 대신, `MessagesState`를 상속하면 이 보일러플레이트를 생략할 수 있습니다.

- `MessagesState`는 `messages: Annotated[list[AnyMessage], add_messages]`를 포함하는 사전 정의된 상태 클래스입니다
- `add_messages` 리듀서가 메시지 리스트를 자동으로 누적하며, 동일 ID 메시지는 교체(upsert)됩니다
- LLM 응답(`AIMessage`)을 반환하면 메시지 히스토리에 자연스럽게 추가됩니다
- 추가 필드가 필요하면 `MessagesState`를 상속하여 확장할 수 있습니다

아래 코드는 `MessagesState`를 상속하여 커스텀 필드 `language`를 추가한 예제입니다. `messages` 필드는 이미 `add_messages` 리듀서가 적용되어 있으므로 별도로 선언할 필요가 없습니다.

#code-block(`````python
from langgraph.graph import MessagesState

class AgentState(MessagesState):
    language: str  # 추가 필드
`````)

#tip-box[`MessagesState`를 사용할 때 노드 함수에서 `{"messages": [ai_response]}`를 반환하면, `add_messages` 리듀서가 자동으로 기존 메시지 리스트에 새 메시지를 추가합니다. 리스트 전체를 교체하는 것이 아니라 _병합_하는 것이므로, 이전 대화 내역이 유지됩니다.]

== 2.6 입출력 스키마

`MessagesState`로 대화 기반 상태를 정의하는 법을 배웠으니, 마지막으로 그래프의 _외부 인터페이스_를 설계하는 방법을 살펴봅시다.

실제 프로덕션 에이전트에서는 내부에서만 사용하는 중간 데이터(예: 분류 결과, 중간 점수, 디버그 정보)를 외부에 노출하지 않아야 합니다. 입출력 스키마를 분리하면 그래프의 공개 인터페이스를 깔끔하게 유지할 수 있고, API 사용자는 필요한 데이터만 주고받게 됩니다. 이는 소프트웨어 설계에서 _캡슐화(encapsulation)_ 원칙에 해당합니다.

- `StateGraph(InternalState, input=InputSchema, output=OutputSchema)` --- 세 가지 스키마를 한 번에 지정합니다
- 입력 스키마: 외부에서 받는 데이터만 포함합니다. `invoke()` 호출 시 이 스키마에 맞는 데이터만 전달할 수 있습니다.
- 출력 스키마: 외부로 내보내는 데이터만 포함합니다. `invoke()`의 반환값이 이 스키마로 필터링됩니다.
- 내부 상태: 중간 처리용 필드를 포함하며, 외부에는 노출되지 않습니다

아래 코드는 입출력 스키마 분리의 전형적인 패턴입니다. `intermediate` 필드는 내부 처리에만 사용되며, 호출자는 `question`만 전달하고 `answer`만 받습니다.

#code-block(`````python
class InputSchema(TypedDict):
    question: str

class OutputSchema(TypedDict):
    answer: str

class FullState(TypedDict):
    question: str
    answer: str
    intermediate: str  # 내부 전용

builder = StateGraph(
    FullState,
    input=InputSchema,
    output=OutputSchema,
)
`````)

#tip-box[입출력 스키마를 분리하면 API 문서 자동 생성, 타입 검증, 그리고 LangGraph Platform 배포 시 Swagger 문서 생성이 훨씬 깔끔해집니다. 또한 그래프를 서브그래프로 재사용할 때 인터페이스 계약이 명확해지므로, 팀 간 협업에서도 큰 도움이 됩니다.]

== 2.7 add_node() 고급 옵션

기본 골격을 익혔으니, 프로덕션 환경에서 자주 쓰이는 `add_node()`의 고급 파라미터들을 살펴봅시다. 단순히 함수만 등록하는 것을 넘어, 재시도, 타임아웃, 캐싱, 에러 복구, 실행 지연까지 노드 단위로 세밀하게 제어할 수 있습니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  [`retry_policy`],
  [`RetryPolicy(max_attempts=..., retry_on=...)` — 실패 시 자동 재시도. 기본 정책은 일반 네트워크 에러 위주이며, `ValueError`/`TypeError`/`RuntimeError`는 제외],
  [`timeout`],
  [`TimeoutPolicy(run_timeout=..., idle_timeout=...)` — 초과 시 `NodeTimeoutError` 발생. async 노드 전용, attempt별 독립 적용],
  [`cache_policy`],
  [`CachePolicy(ttl=..., key_func=...)` — 입력 해시 기반 결과 캐싱. 컴파일 시 `InMemoryCache` 또는 `SqliteCache` 필요],
  [`error_handler`],
  [`NodeError`를 인자로 받아 복구용 `Command`를 반환하는 콜백 — 폴백 노드로 우회하거나 상태에 에러 정보를 기록],
  [`defer`],
  [`True`로 지정하면 다른 분기의 pending 태스크가 모두 완료된 뒤에 실행 — 분기 길이가 다른 fan-out/fan-in에 유용],
)

#code-block(`````python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import RetryPolicy, CachePolicy

builder.add_node(
    "expensive_node",
    expensive_node,
    retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError),
    cache_policy=CachePolicy(ttl=3),
)
graph = builder.compile(cache=InMemoryCache())
`````)

#tip-box[`cache_policy`는 `@task`의 `cache_policy`와 동일한 객체이며, Graph API에서도 같은 방식으로 컴파일 시 `cache=`를 지정해야 동작합니다. `retry_policy`의 `retry_on`을 좁히지 않으면 `ValueError`처럼 코드 버그성 예외도 그대로 재시도되어 비용이 발생할 수 있으므로, 대상 예외를 명시하는 편이 안전합니다.]

== 2.8 Runtime 컨텍스트와 context_schema

상태(`State`)에는 노드 간에 흐르는 데이터를 담지만, LLM 프로바이더나 사용자 ID처럼 호출 시점에 주입하되 상태를 오염시키지 않는 _런타임 의존성_이 필요한 경우가 많습니다. LangGraph는 `context_schema` + `Runtime[ContextSchema]` 패턴으로 이를 노출합니다. 상태와 런타임 컨텍스트가 분리되므로 체크포인트에 불필요한 자격 증명이나 핸들이 함께 저장되지 않습니다.

- `StateGraph(State, context_schema=ContextSchema)` — 컨텍스트 스키마를 그래프에 선언합니다
- 노드 시그니처에 `runtime: Runtime[ContextSchema]`를 추가하면 `runtime.context`로 호출 시 전달된 값에 접근합니다
- `graph.invoke(inputs, context={...})` — `context` 키워드 인자로 컨텍스트를 주입합니다
- `runtime.execution_info`로 `attempt`, `thread_id`, `run_id`, 체크포인트 정보에 접근할 수 있어 재시도 횟수에 따라 동작을 분기할 수 있습니다
- `runtime.server_info`는 LangGraph Server에서 assistant ID, graph ID, 인증된 사용자 정보를 제공합니다
- `runtime.drain_requested`는 graceful shutdown 신호를 노드에 전달합니다

#code-block(`````python
from dataclasses import dataclass
from langgraph.runtime import Runtime

@dataclass
class ContextSchema:
    llm_provider: str = "openai"
    user_id: str | None = None

def node(state: State, runtime: Runtime[ContextSchema]):
    if runtime.execution_info.attempt > 1:
        # 첫 시도가 실패한 경우 폴백 로직
        ...
    print("thread:", runtime.execution_info.thread_id)
    print("run:", runtime.execution_info.run_id)
    return {"results": "processed"}

graph = StateGraph(State, context_schema=ContextSchema).compile()
graph.invoke({...}, context={"llm_provider": "anthropic", "user_id": "u-1"})
`````)

== 2.9 Send와 Command.PARENT — 동적 팬아웃과 서브그래프 라우팅

`Command` 객체를 한 번 더 확장해 봅시다. 라우팅과 상태 업데이트의 조합 외에도, 두 가지 고급 사용처가 있습니다.

`Send("worker", {...})`는 라우팅 함수가 _하나의 노드 이름_ 대신 _Send 객체 리스트_를 반환하도록 하여, 컴파일 시점이 아닌 _실행 시점_에 워커 인스턴스를 동적으로 생성합니다. 각 `Send`는 워커 노드에 _독립적인 상태_를 주입하므로, 동일한 노드 함수가 서로 다른 데이터를 동시에 처리할 수 있습니다. 이것이 Map-Reduce 패턴의 Map 단계이며, 4장에서 자세히 다룹니다.

#code-block(`````python
from langgraph.types import Send

def fan_out(state):
    # 런타임에 항목 수만큼 워커 생성
    return [Send("worker", {"task": t}) for t in state["tasks"]]

builder.add_conditional_edges("planner", fan_out)
`````)

서브그래프 안의 노드에서 `Command(graph=Command.PARENT, goto="next", update={...})`를 반환하면 _부모 그래프_의 노드로 라우팅됩니다. 서브그래프가 자신의 종료 조건을 판단하고 부모 워크플로의 다음 단계를 직접 지정하는 패턴에 유용합니다.

#code-block(`````python
from langgraph.types import Command

def sub_node(state):
    return Command(
        graph=Command.PARENT,
        goto="parent_aggregator",
        update={"sub_result": state["value"]},
    )
`````)

#tip-box[`Command.PARENT`는 9장의 서브그래프와 결합할 때 본격적으로 활용됩니다. 여기서는 "서브그래프에서 부모로 직접 라우팅이 가능하다"는 사실만 기억해 두면 됩니다.]

이 장에서 Graph API의 핵심 구성 요소를 모두 다루었습니다. `StateGraph` 빌더의 생성-컴파일-실행 라이프사이클, `Annotated` 타입 힌트를 활용한 리듀서 기반 상태 병합, `add_conditional_edges`와 `Command`를 통한 동적 분기, `MessagesState`를 활용한 LLM 대화 패턴, 입출력 스키마를 통한 인터페이스 분리, `add_node()`의 고급 옵션, `Runtime` 컨텍스트 주입, 그리고 `Send`/`Command.PARENT`까지 --- 이 모든 것이 이후 장에서 반복적으로 사용되는 기초 패턴입니다. 특히 리듀서와 조건부 엣지는 에이전트의 상태 관리와 의사결정 로직의 근간이므로, 다음 장으로 넘어가기 전에 충분히 익혀 두시기 바랍니다.

#chapter-summary-header()

이번 장에서 배운 내용을 정리합니다.

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
)

#next-step-box[다음 장에서는 동일한 워크플로를 `\@entrypoint`와 `\@task` 데코레이터로 작성하는 Functional API를 다룹니다. Graph API와의 차이를 직접 비교하며, 각 API가 적합한 상황을 감각적으로 이해하게 됩니다.]

#chapter-end()
