// Auto-generated from 03_functional_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Functional API", subtitle: "@entrypoint와 @task로 워크플로 만들기")

`Graph API`가 노드-엣지 그래프를 명시적으로 구성하는 방식이라면, `Functional API`는 일반 Python 함수에 `@entrypoint`와 `@task` 데코레이터를 붙여 워크플로를 작성하는 보다 직관적인 접근입니다. 2장에서 `StateGraph`, 리듀서, 조건부 엣지를 익혔다면, 이제 동일한 기능을 더 적은 코드로 달성하는 방법을 배울 차례입니다. Functional API에서는 그래프 구조를 선언하지 않아도 체크포인팅과 내구성 실행이 자동으로 적용되며, Python의 `if`, `for`, `while` 등 일반 제어 흐름을 그대로 사용할 수 있습니다. 빠른 프로토타이핑이나 동적 분기가 많은 시나리오에 특히 유용합니다. 이 장에서는 `@task`의 `Future` 패턴과 `@entrypoint`의 단기 메모리 관리를 중심으로 `Functional API`의 핵심 사용법을 다룹니다.

#learning-header()

+ `@task` 데코레이터의 체크포인팅 동작과 `Future` 반환 패턴을 설명할 수 있다.
+ `@entrypoint`로 워크플로 진입점을 정의하고 체크포인터를 연결할 수 있다.
+ `previous` 파라미터를 활용하여 멀티턴 대화에서 이전 실행 결과를 유지할 수 있다.
+ `entrypoint.final(value, save)`로 반환값과 체크포인트 저장값을 분리할 수 있다.
+ 결정론성 요구사항을 이해하고, 비결정적 작업을 올바르게 `@task`로 감쌀 수 있다.

== 3.1 환경 설정

2장과 동일하게 환경 변수를 로드하고 LLM 모델을 초기화합니다. Functional API의 데코레이터는 `langgraph.func` 모듈에서 임포트합니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 3.2 \@task --- 체크포인팅 가능한 작업 단위

환경 설정을 마쳤으니, 이제 Functional API의 첫 번째 핵심 데코레이터인 `@task`를 살펴봅시다.

`@task` 데코레이터는 Functional API의 핵심 구성 요소입니다. 함수를 `@task`로 감싸면 두 가지 중요한 효과가 발생합니다. 첫째, 해당 함수의 실행 결과가 체크포인트에 저장되어 _내구성 실행(durable execution)_이 보장됩니다. 장애가 발생하여 워크플로가 재개될 때, 이미 완료된 태스크는 체크포인트에서 결과를 복원하므로 다시 실행되지 않습니다. 둘째, 호출 시 즉시 `Future`와 유사한 객체를 반환하여 병렬 실행의 가능성을 열어둡니다. 실제 결과가 필요한 시점에 `.result()`를 호출하면 됩니다.

- `@task` 데코레이터로 감싸면 실행 결과가 체크포인트에 자동 저장됩니다
- 호출 시 즉시 `Future` 객체를 반환하며, `.result()`로 동기 대기할 수 있습니다
- `@task`로 감싸지 않은 비결정적 연산(API 호출, 난수 생성 등)은 재개 시 _다시 실행_됩니다
- Graph API의 노드(node)에 대응하는 개념으로, 체크포인팅의 최소 단위입니다

아래 코드에서 `call_llm` 함수는 `@task`로 감싸져 있으므로, LLM 호출 결과가 체크포인트에 저장됩니다. `.result()`가 호출되기 전까지는 실제 실행이 시작되지 않을 수 있다는 점에 주목하세요.

#code-block(`````python
from langgraph.func import entrypoint, task

@task
def call_llm(messages):
    return model.invoke(messages)

# 호출 시 Future 반환
future = call_llm(messages)

# 결과가 필요할 때 .result()로 대기
response = future.result()
`````)

#tip-box[`\@task`는 Graph API의 `add_node()`와 동일한 역할을 합니다. Graph API에서는 노드 경계에서 자동으로 체크포인팅이 이루어지지만, Functional API에서는 `\@task`로 명시적으로 체크포인팅 경계를 지정해야 합니다. `\@task` 바깥에서 수행된 작업은 체크포인트에 저장되지 않습니다.]

== 3.3 병렬 태스크 실행

`@task` 하나를 사용하는 법을 배웠으니, 이제 여러 태스크를 _동시에_ 실행하는 패턴을 살펴봅시다.

`@task`의 `Future` 패턴은 병렬 실행을 자연스럽게 가능하게 합니다. 핵심 원리는 간단합니다: 여러 태스크를 먼저 호출하여 `Future` 객체를 모두 받아둔 뒤, `.result()`를 나중에 일괄 호출하면 태스크들이 동시에 실행됩니다. Graph API에서 하나의 노드에서 여러 노드로 엣지를 연결하는 팬아웃(fan-out) 구조와 동일한 효과를 Python 코드만으로 달성할 수 있습니다. 명시적인 `asyncio`나 스레딩 코드 없이도 병렬 실행이 이루어진다는 점이 큰 장점입니다.

아래 코드에서 `futures` 리스트를 먼저 구성하고, 이후 리스트 컴프리헨션에서 `.result()`를 일괄 호출합니다. 만약 `.result()`를 즉시 호출하면 태스크가 순차적으로 실행되므로, 병렬 실행을 원한다면 반드시 호출과 대기를 분리해야 합니다.

#code-block(`````python
@task
def add_one(n: int) -> int:
    return n + 1

@entrypoint(checkpointer=checkpointer)
def parallel(numbers: list[int]) -> list[int]:
    futures = [add_one(n) for n in numbers]  # 먼저 모두 호출
    return [f.result() for f in futures]     # 나중에 일괄 대기
`````)

#warning-box[병렬 실행의 이점을 얻으려면 태스크 호출(Future 생성)과 결과 대기(`.result()`)를 반드시 분리하세요. `add_one(n).result()`처럼 즉시 대기하면 순차 실행과 동일합니다.]

== 3.4 previous --- 단기 메모리 (이전 실행 결과 접근)

병렬 실행을 익혔으니, 이제 Functional API에서 _멀티턴 대화_를 구현하는 방법을 알아봅시다.

Graph API에서 체크포인터를 사용하면 `MessagesState`의 `add_messages` 리듀서가 이전 대화 상태를 자동으로 누적합니다. 그러나 Functional API에서는 `TypedDict` 상태와 리듀서를 사용하지 않으므로, 이전 실행 결과에 접근하는 별도의 메커니즘이 필요합니다. `@entrypoint`의 `previous` 파라미터가 바로 이 역할을 담당합니다. 같은 `thread_id`로 워크플로를 재호출하면, 직전 실행에서 저장한 값이 `previous` 키워드 인자로 전달됩니다. 최초 호출 시에는 `previous`가 `None`이므로, 기본값 처리를 반드시 해야 합니다.

`previous`는 `thread_id` 기반 단기 메모리입니다. 서로 다른 `thread_id`는 독립적인 메모리 공간을 가지므로, 사용자별 대화 세션을 자연스럽게 분리할 수 있습니다.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()

@entrypoint(checkpointer=checkpointer)
def chat(message: str, *, previous=None) -> str:
    messages = previous or []
    messages.append({"role": "user", "content": message})
    response = call_llm(messages).result()
    messages.append(response)
    return entrypoint.final(
        value=response.content,  # 호출자에게 반환
        save=messages,           # 다음 호출의 previous로 전달
    )

# 같은 thread_id로 호출하면 이전 대화가 유지됨
config = {"configurable": {"thread_id": "user-1"}}
chat.invoke("안녕하세요", config=config)
chat.invoke("제 이름이 뭐였죠?", config=config)
`````)

#tip-box[`previous` 파라미터 외에도 `\@entrypoint`는 `store`(장기 메모리), `writer`(커스텀 스트리밍), `config`(런타임 설정)를 키워드 인자로 주입받을 수 있습니다. 이들은 모두 자동으로 감지되므로, 함수 시그니처에 해당 이름의 파라미터를 추가하기만 하면 됩니다.]

== 3.5 entrypoint.final --- 반환값과 체크포인트 저장값 분리

`previous`로 이전 실행 결과에 접근하는 법을 배웠는데, 여기서 한 가지 의문이 생깁니다: 호출자에게 반환하는 값과 체크포인트에 저장하는 값이 _항상 같아야_ 할까요? 대부분의 경우 그렇지 않습니다.

예를 들어, 사용자에게는 최종 답변 문자열만 반환하되, 체크포인트에는 전체 메시지 히스토리를 저장하고 싶을 수 있습니다. `entrypoint.final(value, save)` 형태로 반환하면 이 두 가지를 명확하게 분리할 수 있습니다. `value`는 `invoke()`의 반환값이 되고, `save`는 다음 호출 시 `previous` 파라미터로 전달됩니다. `entrypoint.final`을 사용하지 않고 단순히 값을 반환하면, 반환값이 곧 저장값이 됩니다.

#code-block(`````python
@entrypoint(checkpointer=checkpointer)
def my_workflow(inputs, *, previous=None):
    summary = summarize(inputs).result()
    full_state = {"summary": summary, "raw": inputs}
    # value: 호출자에게 반환 / save: previous로 저장
    return entrypoint.final(value=summary, save=full_state)
`````)

이 패턴은 특히 API 응답은 가볍게 유지하면서 내부적으로는 풍부한 상태를 보존해야 하는 경우에 유용합니다. 예를 들어 사용자에게는 요약 텍스트만 반환하되, 체크포인트에는 원본 데이터, 중간 분석 결과, 메시지 히스토리 등을 모두 저장할 수 있습니다.

== 3.6 결정론성 요구사항

반환값과 저장값을 분리하는 방법까지 배웠으니, Functional API를 안전하게 사용하기 위한 _가장 중요한 규칙_을 짚고 넘어갑시다.

Functional API에서 가장 주의해야 할 점은 _결정론성(determinism)_ 요구사항입니다. 내구성 실행의 핵심 메커니즘은 다음과 같습니다: 장애가 발생하면 `@entrypoint` 함수가 처음부터 다시 실행되지만, 이미 완료된 `@task`는 체크포인트에서 결과를 복원하여 재실행하지 않습니다. 이 메커니즘이 올바르게 작동하려면, `@entrypoint` 내부의 `@task` 바깥 코드가 _항상 같은 결과를 생성_해야 합니다. 만약 `@task` 바깥에 비결정적 코드가 있으면, 재개 시 다른 값이 생성되어 이전 실행과 다른 분기를 탈 수 있습니다.

_반드시 `@task`로 감싸야 하는 작업:_

- LLM 호출 (`model.invoke()`, `model.ainvoke()`)
- 외부 API 요청 (`requests.get()`, `httpx.get()`)
- 난수 생성 (`random.random()`, `uuid.uuid4()`)
- 현재 시각 참조 (`datetime.now()`, `time.time()`)
- 파일 I/O 및 데이터베이스 쿼리

_`@task` 바깥에 둘 수 있는 작업:_

- 순수 함수 연산 (문자열 조작, 리스트 변환 등)
- 조건 분기 (`if/else`)
- 반복문 (`for`, `while`)

#warning-box[`\@entrypoint` 내부에서 `\@task` 바깥에 `random.random()`이나 `datetime.now()` 같은 비결정적 코드를 작성하면, 재개 시 이전과 다른 값이 사용되어 워크플로가 일관되지 않게 동작할 수 있습니다. 이런 연산도 반드시 `\@task`로 감싸세요. 이는 Functional API의 가장 흔한 실수이므로 특히 주의가 필요합니다.]

== 3.7 LLM 에이전트 (Functional API)

결정론성 요구사항까지 이해했으니, 이제 지금까지 배운 모든 것을 결합하여 _완전한 ReAct 에이전트_를 구현해 봅시다.

지금까지 배운 `@task`와 `@entrypoint`를 결합하면, Graph API 없이도 완전한 ReAct 에이전트를 구현할 수 있습니다. 핵심 아이디어는 간단합니다: `while` 루프 안에서 LLM을 호출하고, `tool_calls`가 있으면 도구를 실행한 뒤 다시 LLM을 호출하는 과정을 반복합니다. `tool_calls`가 없으면 루프를 종료합니다. 이 패턴은 Graph API에서 `add_conditional_edges`로 구현하는 ReAct 루프와 동일하지만, Python의 `while` 문으로 더 직관적으로 표현됩니다.

아래 코드에서 두 가지 핵심 포인트를 관찰하세요. 첫째, LLM 호출과 도구 실행이 모두 `@task`로 감싸져 있어 체크포인팅이 보장됩니다. 둘째, `while llm_result.tool_calls` 조건으로 도구 호출 여부에 따른 분기가 자연스럽게 이루어집니다.

#code-block(`````python
@task
def call_llm(messages):
    return model.invoke(messages)

@task
def call_tool(tool_call):
    return tool.invoke(tool_call)

@entrypoint(checkpointer=checkpointer)
def agent(inputs: dict) -> list:
    messages = inputs["messages"]
    llm_result = call_llm(messages).result()
    while llm_result.tool_calls:
        tool_results = [
            call_tool(tc).result()
            for tc in llm_result.tool_calls
        ]
        messages = messages + [llm_result] + tool_results
        llm_result = call_llm(messages).result()
    return messages + [llm_result]
`````)

=== Graph API vs. Functional API --- 언제 무엇을 선택할까?

두 API는 상호 배타적이지 않으며, 같은 프로젝트 안에서 혼용할 수 있습니다. 컴파일된 그래프를 `@entrypoint` 안에서 `.invoke()`할 수도 있고, `@entrypoint` 함수를 `StateGraph`의 노드로 등록할 수도 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기준],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [워크플로 구조],
  [노드-엣지 그래프 명시],
  [일반 Python 코드],
  [시각화],
  [자동 다이어그램 생성],
  [코드 리딩으로 이해],
  [상태 관리],
  [TypedDict + 리듀서],
  [함수 스코프 변수],
  [적합한 경우],
  [복잡한 분기, 팀 협업],
  [빠른 프로토타이핑, 동적 로직],
)

== 3.8 \@task 재시도와 캐싱

ReAct 루프까지 구현했다면, 이제 프로덕션 환경에서 신뢰성을 끌어올리는 두 가지 옵션을 살펴봅시다. `@task`는 Graph API의 `add_node()`와 동일한 정책 객체를 받아 _재시도_와 _캐싱_을 데코레이터 한 줄로 지정할 수 있습니다.

`RetryPolicy`는 실패 시 자동 재시도 정책입니다. 기본 정책은 일반적인 네트워크 에러를 대상으로 하며, `retry_on`으로 특정 예외만 좁힐 수 있습니다. `max_attempts`는 최대 시도 횟수입니다.

#code-block(`````python
from langgraph.types import RetryPolicy

@task(retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError))
def fetch_data(url: str) -> dict:
    response = httpx.get(url)
    response.raise_for_status()
    return response.json()
`````)

`CachePolicy`는 태스크 입력 해시를 기반으로 결과를 캐싱합니다. `ttl`은 캐시 유효 시간(초)입니다. 캐싱을 활성화하려면 `@entrypoint(cache=InMemoryCache())`로 엔트리포인트에 캐시 백엔드를 연결하고, 캐시하려는 각 `@task`에 `cache_policy`를 지정합니다 --- 두 곳에 _분리_해서 지정하는 패턴이 핵심입니다.

#code-block(`````python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import CachePolicy

@task(cache_policy=CachePolicy(ttl=120))
def slow_compute(x: int) -> int:
    time.sleep(1)
    return x * 2

@entrypoint(cache=InMemoryCache())
def main(inputs: dict) -> dict[str, int]:
    a = slow_compute(inputs["a"]).result()
    b = slow_compute(inputs["b"]).result()
    return {"a": a, "b": b}
`````)

#tip-box[`@task(timeout=1.0, retry_policy=RetryPolicy(retry_on=NodeTimeoutError))` 패턴으로 타임아웃과 재시도를 결합할 수도 있습니다. 같은 `thread_id`로 입력에 `None`을 전달하면 직전 실패 지점부터 재시도되며, 이미 성공한 태스크의 결과는 체크포인트에서 재사용됩니다.]

== 3.9 구조화된 interrupt와 Command(resume=)

장애 복구뿐 아니라 _사람의 검토_가 필요한 경우에도 Functional API는 자연스러운 인터페이스를 제공합니다. `interrupt()` 함수는 워크플로 실행을 일시 중단하고 사람의 입력을 기다립니다. 단순 문자열뿐 아니라 딕셔너리 형태의 _구조화된 페이로드_를 전달할 수 있어, 호출자에게 검토에 필요한 컨텍스트를 풍부하게 제공할 수 있습니다.

#code-block(`````python
from langgraph.types import Command, interrupt

@task
def review(input_query: str):
    # 구조화된 인터럽트 — 호출자가 풍부한 컨텍스트로 검토
    human_review = interrupt({
        "question": "이 결과를 승인하시겠습니까?",
        "tool_call": {"name": "send_email", "args": {...}},
    })
    return human_review

@entrypoint(checkpointer=checkpointer)
def workflow(input_query: str):
    return review(input_query).result()
`````)

재개할 때는 `Command(resume=...)`로 사람의 응답을 전달합니다. `interrupt()` 호출이 마치 _정상적으로 그 값을 반환한 것처럼_ 워크플로가 재개되므로, 호출 측 코드 흐름은 변하지 않습니다.

#code-block(`````python
config = {"configurable": {"thread_id": "review-1"}}
workflow.invoke("초안 검토 요청", config=config)
# 사람이 검토 후 재개
workflow.invoke(Command(resume={"approved": True, "comment": "OK"}), config=config)
`````)

== 3.10 \@entrypoint 주입 파라미터

`previous` 외에도 `@entrypoint`는 함수 시그니처의 키워드 인자 이름으로 _런타임 의존성을 자동 주입_합니다. 함수 시그니처에 해당 이름의 파라미터를 추가하기만 하면 LangGraph가 자동으로 감지합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[역할],
  [`previous`],
  [직전 체크포인트의 저장값 (단기 메모리)],
  [`store`],
  [`BaseStore` 인스턴스로 장기 메모리 접근],
  [`writer`],
  [`StreamWriter` 객체로 커스텀 스트리밍 emit (async + Python < 3.11 호환용)],
  [`config`],
  [`RunnableConfig` — `thread_id`, metadata, configurable 값 접근],
)

#code-block(`````python
from langgraph.types import StreamWriter

@entrypoint(checkpointer=checkpointer, store=store)
def workflow(
    inputs: dict,
    *,
    previous=None,
    store=None,
    writer: StreamWriter = None,
    config=None,
):
    writer({"phase": "start"})
    user_id = config["configurable"]["user_id"]
    memory = store.get(("users", user_id), "profile")
    ...
`````)

#tip-box[Python 3.11 이상에서는 `langgraph.config.get_stream_writer()`를 사용해 함수 내 어디서든 stream writer를 가져올 수도 있어, 파라미터 주입 대신 더 간결한 호출이 가능합니다.]

이 장에서 Functional API의 핵심 구성 요소를 모두 다루었습니다. `@task`로 체크포인팅 단위를 정의하고, `@entrypoint`로 워크플로의 진입점을 만들며, `previous`와 `entrypoint.final`로 메모리를 관리하고, `retry_policy`/`cache_policy`로 신뢰성을 강화하며, 구조화된 `interrupt()`로 HITL을 구성하는 패턴이 Functional API의 전체 도구 상자입니다. 무엇보다 중요한 것은 결정론성 요구사항으로, 비결정적 작업을 `@task`로 감싸는 규칙을 항상 준수해야 합니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[설명],
  [`\@task`],
  [비동기 작업, 체크포인팅, 병렬 실행],
  [`\@entrypoint`],
  [워크플로 진입점, 실행 관리],
  [`.result()`],
  [Future 결과 동기 대기],
  [`previous`],
  [이전 실행 결과 접근 (단기 메모리)],
  [`entrypoint.final`],
  [반환값 ≠ 저장값 분리],
)

#next-step-box[다음 장에서는 Graph API와 Functional API 모두를 활용하여 다섯 가지 핵심 워크플로 패턴 --- Prompt Chaining, Parallelization, Routing, Orchestrator-Worker, Evaluator-Optimizer --- 을 구현합니다. 두 API의 차이를 실전 패턴으로 체감하게 됩니다.]

#chapter-end()
