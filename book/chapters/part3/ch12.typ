// Auto-generated from 12_durable_execution.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "내구성 실행")

== 학습 목표
#learning-objectives([내구성 실행(Durable Execution)의 개념과 필요성을 이해한다], [체크포인터와 내구성 실행의 관계를 안다], [`@entrypoint` + `@task`로 내구성을 보장하는 방법을 익힌다], [내구성 모드(exit, async, sync)의 차이를 이해한다], [장애 시나리오에서의 복구 과정을 안다])

== 12.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 12.2 내구성 실행 개념

_내구성 실행(Durable Execution)_이란 프로세스나 워크플로가 핵심 지점에서 진행 상태를 저장하여,
일시 중지 후 나중에 정확히 중단된 위치에서 재개할 수 있는 기법입니다.

_왜 필요한가?_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[시나리오],
  text(weight: "bold")[설명],
  [장애 복구],
  [서버 장애 시 처음부터 다시 실행하지 않고 중단 지점에서 재개],
  [상태 영속],
  [긴 실행 시간의 워크플로 중간 결과를 보존],
  [Human-in-the-loop],
  [사람의 승인을 기다리는 동안 상태를 유지],
)

LangGraph는 checkpointer로 내구성 실행을 지원합니다.

== 12.3 핵심 요구사항

내구성 실행을 구현하려면 세 가지 요소가 필요합니다:

+ _영속 계층 (Persistence Layer)_
체크포인터로 워크플로 진행 상태를 기록합니다.
예: `InMemorySaver`(개발용), `PostgresSaver`(프로덕션용)

+ _스레드 식별자 (Thread ID)_
워크플로 인스턴스의 실행 기록을 추적하는 고유 ID입니다.
같은 `thread_id`를 사용하면 이전 실행을 이어서 재개할 수 있습니다.

+ _태스크 래핑 (Task Wrapping)_
비결정적(non-deterministic) 연산과 부수 효과(side-effect) 연산을
태스크로 감싸서 재개 시 재실행을 방지합니다.

== 12.4 내구성 모드 비교

LangGraph는 성능과 일관성 사이의 균형을 맞추는 세 가지 모드를 제공합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[동작],
  text(weight: "bold")[트레이드오프],
  [`"exit"`],
  [완료/에러/인터럽트 시에만 영속화],
  [최고 성능, 중간 복구 불가],
  [`"async"`],
  [다음 단계 실행 중 비동기로 영속화],
  [적절한 균형, 약간의 크래시 위험],
  [`"sync"`],
  [다음 단계 실행 전 동기로 영속화],
  [최대 내구성, 성능 비용],
)

대부분의 사용 사례에서는 기본 모드(`"exit"`)로 충분합니다.
미션 크리티컬한 워크플로에서는 `"sync"` 모드를 고려하세요.

== 12.5 문제가 있는 코드

부수 효과(API 호출 등)를 태스크로 감싸지 않으면
재개 시 동일한 API 호출이 다시 실행될 수 있습니다.

#code-block(`````python
# 문제가 있는 접근 방식: 부수 효과를 직접 호출
print("""# BAD: 부수 효과가 태스크로 감싸지지 않음
def call_api(state: State):
    # 이 API 호출은 재개 시 다시 실행됨!
    result = requests.get(state['url']).text[:100]
    return {"result": result}
""")
print("문제점:")
print("  1. 장애 후 재개 시 API가 다시 호출됨")
print("  2. 비결정적 결과가 달라질 수 있음")
print("  3. 중복 요청으로 부작용 발생 가능")
`````)
#output-block(`````
# BAD: 부수 효과가 태스크로 감싸지지 않음
def call_api(state: State):
    # 이 API 호출은 재개 시 다시 실행됨!
    result = requests.get(state['url']).text[:100]
    return {"result": result}

문제점:
  1. 장애 후 재개 시 API가 다시 호출됨
  2. 비결정적 결과가 달라질 수 있음
  3. 중복 요청으로 부작용 발생 가능
`````)

== 12.6 \@task로 개선

`@task` 데코레이터로 부수 효과를 감싸면
재개 시 이전 결과를 체크포인트에서 복원하여 재실행을 방지합니다.

#code-block(`````python
# 개선된 접근 방식: @task로 부수 효과 래핑
print("""# GOOD: @task로 부수 효과를 감쌈
from langgraph.func import task

@task
def _make_request(url: str):
    return requests.get(url).text[:100]

def call_api(state: State):
    # 각 요청이 개별 태스크로 실행됨
    requests = [_make_request(url) for url in state['urls']]
    results = [req.result() for req in requests]
    return {"results": results}
""")
print("개선 효과:")
print("  1. 재개 시 체크포인트에서 결과 복원")
print("  2. API 중복 호출 방지")
print("  3. 각 태스크가 독립적으로 추적됨")
`````)
#output-block(`````
# GOOD: @task로 부수 효과를 감쌈
from langgraph.func import task

@task
def _make_request(url: str):
    return requests.get(url).text[:100]

def call_api(state: State):
    # 각 요청이 개별 태스크로 실행됨
    requests = [_make_request(url) for url in state['urls']]
    results = [req.result() for req in requests]
    return {"results": results}

개선 효과:
  1. 재개 시 체크포인트에서 결과 복원
  2. API 중복 호출 방지
  3. 각 태스크가 독립적으로 추적됨
`````)

== 12.7 Graph API에서의 내구성

StateGraph에 체크포인터를 연결하면 각 노드 실행 후 상태가 자동 저장됩니다.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver


class DocState(TypedDict):
    topic: str
    draft: str
    final: str


def write_draft(state: DocState) -> dict:
    return {"draft": f"Draft about {state['topic']}"}


def finalize(state: DocState) -> dict:
    return {"final": f"Final: {state['draft']}"}


checkpointer = InMemorySaver()

builder = StateGraph(DocState)
builder.add_node("write_draft", write_draft)
builder.add_node("finalize", finalize)
builder.add_edge(START, "write_draft")
builder.add_edge("write_draft", "finalize")
builder.add_edge("finalize", END)

graph = builder.compile(checkpointer=checkpointer)

# 실행 (thread_id로 실행 추적)
config = {"configurable": {"thread_id": "doc-1"}}
result = graph.invoke({"topic": "LangGraph"}, config)
print("결과:", result)
`````)
#output-block(`````
결과: {'topic': 'LangGraph', 'draft': 'Draft about LangGraph', 'final': 'Final: Draft about LangGraph'}
`````)

== 12.8 Functional API에서의 내구성

`@entrypoint`와 `@task`를 조합하면 Functional API에서도 내구성을 보장할 수 있습니다.

#code-block(`````python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver


@task
def generate_draft(topic: str) -> str:
    return f"Draft about {topic}"


@task
def review_draft(draft: str) -> str:
    return f"Reviewed: {draft}"


func_checkpointer = InMemorySaver()


@entrypoint(checkpointer=func_checkpointer)
def write_document(topic: str) -> str:
    draft = generate_draft(topic).result()
    reviewed = review_draft(draft).result()
    return reviewed


config = {"configurable": {"thread_id": "func-1"}}
result = write_document.invoke("Durable Execution", config)
print("결과:", result)
`````)
#output-block(`````
결과: Reviewed: Draft about Durable Execution
`````)

== 12.9 장애 복구 시나리오

같은 `thread_id`로 재실행하면 체크포인트에서 이전 상태를 복원하여 이어서 실행합니다.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver


class PipelineState(TypedDict):
    data: str
    step: int
    result: str


call_count = 0


def step_one(state: PipelineState) -> dict:
    global call_count
    call_count += 1
    print(f"  step_one 실행 (호출 횟수: {call_count})")
    return {"data": state["data"].upper(), "step": 1}


def step_two(state: PipelineState) -> dict:
    print(f"  step_two 실행")
    return {"result": f"Processed: {state['data']}", "step": 2}


recovery_saver = InMemorySaver()

builder = StateGraph(PipelineState)
builder.add_node("step_one", step_one)
builder.add_node("step_two", step_two)
builder.add_edge(START, "step_one")
builder.add_edge("step_one", "step_two")
builder.add_edge("step_two", END)

pipeline = builder.compile(checkpointer=recovery_saver)

# 첫 번째 실행
config = {"configurable": {"thread_id": "recovery-1"}}
print("=== 첫 번째 실행 ===")
result = pipeline.invoke(
    {"data": "hello", "step": 0, "result": ""},
    config
)
print(f"결과: {result}")

# 체크포인트 확인
print("\n=== 체크포인트에서 상태 복원 ===")
saved = pipeline.get_state(config)
print(f"저장된 상태: {saved.values}")
print(f"step_one 총 호출 횟수: {call_count}")
`````)
#output-block(`````
=== 첫 번째 실행 ===
  step_one 실행 (호출 횟수: 1)
  step_two 실행
결과: {'data': 'HELLO', 'step': 2, 'result': 'Processed: HELLO'}

=== 체크포인트에서 상태 복원 ===
저장된 상태: {'data': 'HELLO', 'step': 2, 'result': 'Processed: HELLO'}
step_one 총 호출 횟수: 1
`````)

== 12.10 재개 시작점

워크플로가 재개될 때 API에 따라 시작점이 다릅니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[API],
  text(weight: "bold")[재개 시작점],
  text(weight: "bold")[설명],
  [StateGraph],
  [중단된 노드의 시작],
  [해당 노드를 처음부터 다시 실행],
  [서브그래프],
  [부모 노드 → 서브그래프 내 중단 노드],
  [부모 노드에서 시작 후 서브그래프 내 해당 노드로 이동],
  [Functional API],
  [`\@entrypoint` 시작],
  [엔트리포인트에서 시작, `\@task` 결과는 캐시에서 복원],
)

_핵심 차이:_
- StateGraph: 노드 단위 재개 (중단된 노드만 재실행)
- Functional API: 엔트리포인트부터 재실행하되, 완료된 `@task`는 캐시 결과 사용

== 12.11 프로덕션 내구성 패턴

프로덕션 환경에서 내구성을 보장하기 위한 모범 사례:

+ _멱등성(Idempotent) 연산 구현_
같은 요청을 여러 번 실행해도 결과가 같도록 설계합니다.
멱등성 키(idempotency key)로 중복 처리를 방지합니다.

+ _부수 효과 분리_
API 호출, 파일 쓰기 등의 부수 효과를 개별 `@task`로 분리합니다.
순수 로직과 부수 효과를 명확히 구분합니다.

+ _비결정적 코드 래핑_
난수 생성, 타임스탬프 등 비결정적 연산도 `@task`로 감쌉니다.

+ _영속 저장소 사용_
개발: `InMemorySaver`
프로덕션: `PostgresSaver` 또는 외부 데이터베이스

+ _스레드 ID 관리_
각 워크플로 인스턴스에 고유한 `thread_id`를 부여합니다.
장애 복구 시 동일한 `thread_id`로 재개합니다.

== 12.12 LangGraph 1.2 Fault Tolerance

내구성 실행은 checkpoint를 통해 재개 지점을 보존합니다. LangGraph 1.2의 fault tolerance는 여기에 _노드 시도 단위 제어_를 추가합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[언제 쓰나],
  [노드 timeout],
  [`TimeoutPolicy`, `NodeTimeoutError`],
  [외부 API가 오래 멈추는 경우],
  [재시도],
  [`RetryPolicy`],
  [일시적 네트워크/5xx 실패],
  [보정 handler],
  [`error_handler=...`, `NodeError`, `Command`],
  [Saga/보상 트랜잭션],
  [Graceful shutdown],
  [`RunControl.request_drain()`, `GraphDrained`],
  [배포·점검 전 안전 중단],
)

#code-block(`````python
# LangGraph 1.2 fault tolerance 패턴
from importlib.metadata import version

print("설치된 langgraph:", version("langgraph"))
print("필요 버전: langgraph>=1.2.0")

example = r'''
from langgraph.errors import NodeError
from langgraph.types import Command, RetryPolicy, TimeoutPolicy
from langgraph.runtime import Runtime  # heartbeat 사용 시

def payment_error_handler(state: State, error: NodeError) -> Command:
    # retry 모두 소진 후 실행되는 보정 함수
    return Command(
        update={"status": f"compensated: {error.error}"},
        goto="finalize",
    )

builder.add_node(
    "charge_payment",
    charge_payment,
    timeout=TimeoutPolicy(idle_timeout=30),                     # NodeTimeoutError
    retry_policy=RetryPolicy(max_attempts=3, retry_on=ConnectionError),
    error_handler=payment_error_handler,                        # 보정 트랜잭션
)

# 장기 작업 노드: heartbeat로 idle timeout 갱신
async def long_running_node(state: State, runtime: Runtime) -> dict:
    for batch in fetch_batches():
        process(batch)
        runtime.heartbeat()
    return {"result": "done"}

builder.add_node(
    "long_running_node",
    long_running_node,
    timeout=TimeoutPolicy(idle_timeout=30, refresh_on="heartbeat"),
)
'''
print(example)
`````)

=== Graceful shutdown — `RunControl` / `GraphDrained` / `Runtime.drain_requested`

장기 실행 그래프를 즉시 강제 종료하지 않고 현재 superstep을 끝낸 뒤 checkpoint를 남기려면 `RunControl.request_drain()`을 사용합니다. drain이 요청되면 런은 `GraphDrained`로 멈추고 같은 config로 나중에 재개할 수 있습니다.

노드 내부에서는 `Runtime.drain_requested`로 drain 신호를 직접 확인할 수 있습니다.

#code-block(`````python
# Graceful shutdown 패턴 — langgraph>=1.2
example = r'''
from langgraph.runtime import RunControl, Runtime
from langgraph.errors import GraphDrained

# 1) 호출 측: 외부 시그널(SIGTERM 등)에 drain 요청
control = RunControl()
control.request_drain("sigterm")

try:
    result = graph.invoke(inputs, config, control=control)
except GraphDrained as e:
    print(f"Drained: {e.reason}")
    # checkpoint는 이미 저장됨 — 같은 config로 재개 가능

# 같은 config로 재개
graph.invoke(None, config)

# 2) 노드 내부: drain 신호를 직접 감지
async def my_node(state: State, runtime: Runtime) -> dict:
    if runtime.drain_requested:
        return {"status": "skipped"}
    # ... 일반 처리
    return {"status": "done"}
'''
print(example)
`````)

== 12.13 DeltaChannel — checkpoint 저장량 최적화

기본 checkpoint는 superstep마다 채널 값을 전체 저장합니다. 메시지 목록처럼 계속 커지는 append-heavy 채널은 장기 thread에서 저장량이 크게 늘어납니다. LangGraph 1.2의 `DeltaChannel`은 누적 전체값 대신 delta를 저장해 checkpoint 비용을 낮춥니다.

- `snapshot_frequency=K`로 K step마다 전체 snapshot을 남겨 읽기 지연을 제한합니다.
- beta 기능이므로 프로덕션 적용 전 저장량, 읽기 지연, 마이그레이션 비용을 측정합니다.
- 내구성 실행 설계에서는 `DeltaChannel`을 _저장 최적화_, `TimeoutPolicy`/`error_handler`를 _실패 복구 제어_로 분리해 이해합니다.

#code-block(`````python
# DeltaChannel 개념 예시 — 실제 실행은 langgraph>=1.2에서 확인하세요.
example = r'''
from typing_extensions import Annotated, TypedDict
from langgraph.channels.delta import DeltaChannel

def append(state: list[str], writes: list[list[str]]) -> list[str]:
    return state + [item for batch in writes for item in batch]

class State(TypedDict):
    # append-heavy 메시지/로그 채널에서 checkpoint delta 저장을 고려
    items: Annotated[list[str], DeltaChannel(reducer=append, snapshot_frequency=50)]
'''
print(example)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [내구성 개념],
  [중단 지점에서 재개할 수 있는 실행 기법],
  [핵심 요구사항],
  [영속 계층 + 스레드 ID + 태스크 래핑],
  [내구성 모드],
  [exit(기본), async(균형), sync(최대 내구성)],
  [\@task],
  [부수 효과를 감싸서 재실행 방지],
  [Graph API],
  [`checkpointer` 연결로 노드별 자동 저장],
  [Functional API],
  [`\@entrypoint` + `\@task`로 내구성 보장],
  [장애 복구],
  [같은 `thread_id`로 체크포인트에서 재개],
)


#references-box[
- #link("../docs/langgraph/06-durable-execution.md")[Durable Execution]
- #link("../docs/langgraph/06-durable-execution.md")[Fault Tolerance]
]
#chapter-end()
