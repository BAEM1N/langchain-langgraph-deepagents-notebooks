// Auto-generated from 12_durable_execution.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "내구성 실행")

6장에서 체크포인터 기반 장애 복구를 간략히 소개했다면, 이 장에서는 _내구성 실행(Durable Execution)_을 본격적으로 심화합니다. 실제 운영 환경에서 에이전트 워크플로는 네트워크 장애, 프로세스 재시작, 외부 API 타임아웃 등 다양한 실패 상황에 노출됩니다. 내구성 실행은 각 실행 단계를 체크포인트로 저장하여, 장애 발생 시 처음부터 재실행하지 않고 마지막 성공 지점에서 정확히 재개할 수 있게 합니다.

내구성 실행의 핵심 원리는 _결정론적 재실행(deterministic replay)_입니다. 워크플로가 재개되면 `@entrypoint` 함수는 처음부터 다시 실행되지만, 이미 완료된 `@task`는 체크포인트에서 저장된 결과를 반환합니다. 이를 통해 부수 효과(API 호출 등)의 중복 실행을 방지하면서도, 정확히 중단된 지점에서 실행을 이어갈 수 있습니다. 이 장에서는 내구성 실행의 원리와 `@entrypoint` + `@task` 기반 구현, 그리고 세 가지 내구성 모드(`exit`, `async`, `sync`)의 차이를 살펴봅니다.

#learning-header()
#learning-objectives([내구성 실행(Durable Execution)의 개념과 필요성을 이해한다], [체크포인터와 내구성 실행의 관계를 안다], [`@entrypoint` + `@task`로 내구성을 보장하는 방법을 익힌다], [내구성 모드(exit, async, sync)의 차이를 이해한다], [장애 시나리오에서의 복구 과정을 안다])

== 12.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 12.2 내구성 실행 개념

_내구성 실행(Durable Execution)_이란 프로세스나 워크플로가 핵심 지점에서 진행 상태를 저장하여, 일시 중지 후 나중에 정확히 중단된 위치에서 재개할 수 있는 기법입니다. 이 개념은 Temporal, Azure Durable Functions 등 분산 시스템에서 오래전부터 사용되어 온 검증된 패턴이며, LangGraph는 이를 AI 에이전트 워크플로에 맞게 적용합니다.

일반적인 프로그램은 프로세스가 종료되면 모든 상태를 잃습니다. 하지만 에이전트 워크플로는 수십 분에서 수 시간 동안 실행될 수 있고, 외부 API 호출이나 사람의 승인 대기 등 장시간 중단이 빈번합니다. 이런 워크플로에서 장애가 발생했을 때 처음부터 다시 실행하는 것은 시간과 비용 면에서 비효율적이며, 부수 효과의 중복 실행으로 오류를 유발할 수도 있습니다.

#align(center)[#image("../../assets/diagrams/png/durable_resume_flow.png", width: 92%, height: 82mm, fit: "contain")]

이 흐름도에서 중요한 것은 재개 지점이 _아무 줄_ 이 아니라 _체크포인트 경계_ 라는 점입니다. 따라서 부작용이 있는 작업은 `@task` 경계 바깥으로 흘러나오지 않도록 설계해야 합니다.

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
  [긴 실행 시간을 가진 워크플로의 중간 결과를 보존],
  [Human-in-the-loop],
  [사람의 승인을 기다리는 동안 상태를 유지],
)

LangGraph는 체크포인터(checkpointer)를 통해 내구성 실행을 지원합니다.

== 12.3 핵심 요구사항

내구성 실행의 개념을 이해했으니, 이제 LangGraph에서 이를 구현하기 위한 구체적인 요구사항을 살펴봅시다. 내구성 실행을 구현하려면 세 가지 요소가 반드시 갖추어져야 합니다:

+ _영속 계층 (Persistence Layer)_
체크포인터를 통해 워크플로 진행 상태를 기록합니다.
예: `InMemorySaver`(개발용), `PostgresSaver`(프로덕션용)

+ _스레드 식별자 (Thread ID)_
워크플로 인스턴스의 실행 기록을 추적하는 고유 ID입니다.
같은 `thread_id`를 사용하면 이전 실행을 이어서 재개할 수 있습니다.

+ _태스크 래핑 (Task Wrapping)_
비결정적(non-deterministic) 연산과 부수 효과(side-effect) 연산을
태스크로 감싸서 재개 시 재실행을 방지합니다.

== 12.4 내구성 모드 비교

세 가지 요구사항이 갖추어졌다면, 다음으로 결정해야 할 것은 _언제_ 체크포인트를 저장할 것인가입니다. 체크포인트를 자주 저장할수록 장애 복구 능력은 높아지지만, 그만큼 I/O 비용이 증가합니다. LangGraph는 이 트레이드오프를 조절할 수 있도록 세 가지 내구성 모드를 제공합니다:

#tip-box[내구성 모드는 `\@entrypoint(checkpointer=saver, durability_mode="sync")` 형태로 Functional API에서 설정하거나, Graph API에서는 `graph.compile(checkpointer=saver)` 시점에 지정합니다. 기본값은 `"exit"`입니다.]

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

#note-box[`"async"` 모드에서는 다음 태스크 실행과 체크포인트 저장이 동시에 진행됩니다. 만약 체크포인트 저장이 완료되기 전에 프로세스가 크래시되면, 해당 태스크의 결과가 유실될 수 있습니다. 이 위험이 허용되지 않는 금융 거래 등의 시나리오에서는 `"sync"` 모드를 사용하세요.]

== 12.5 문제가 있는 코드

내구성 모드를 이해했으니, 이제 _올바른 코드와 잘못된 코드의 차이_를 구체적으로 살펴봅시다. 내구성 실행의 핵심 원리인 _결정론적 재실행(deterministic replay)_을 제대로 활용하려면, 어떤 코드를 `@task`로 감싸야 하는지 정확히 이해해야 합니다. 부수 효과(API 호출 등)를 태스크로 감싸지 않으면, 재개 시 동일한 API 호출이 다시 실행되어 심각한 문제를 일으킬 수 있습니다.

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

위 문제를 해결하는 방법은 간단합니다. 부수 효과를 `@task` 데코레이터로 감싸면 됩니다. `@task`로 감싼 함수의 결과는 체크포인트에 저장되므로, 워크플로가 재개될 때 실제 함수를 다시 호출하지 않고 저장된 결과를 즉시 반환합니다. 이것이 결정론적 재실행의 핵심 메커니즘입니다.

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

`@task` 패턴을 이해했으니, 이제 두 가지 API에서 내구성이 어떻게 동작하는지 비교해 봅시다. Graph API에서는 내구성 구현이 더 단순합니다. `StateGraph`에 체크포인터를 연결하기만 하면, 각 노드 실행이 완료될 때마다 전체 상태가 자동으로 저장됩니다. 노드 자체가 내구성의 기본 단위가 되므로, 별도의 `@task` 래핑이 필요하지 않습니다.

#note-box[Graph API에서는 각 노드가 하나의 체크포인트 단위입니다. 노드 A가 성공하고 노드 B에서 장애가 발생하면, 재개 시 노드 B부터 다시 실행됩니다. 따라서 하나의 노드 안에 여러 개의 독립적인 부수 효과가 있다면, 이를 별도의 노드로 분리하는 것이 내구성 측면에서 유리합니다.]

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

Functional API에서의 내구성은 Graph API와 근본적으로 다른 방식으로 동작합니다. `@entrypoint`와 `@task`를 조합하면 내구성을 보장할 수 있지만, 재개 시의 동작이 다릅니다. `@entrypoint` 함수는 _항상_ 처음부터 다시 실행되며, 이미 완료된 `@task`는 실제로 실행되지 않고 체크포인트에서 저장된 결과를 반환합니다. 따라서 `@entrypoint` 내부의 모든 비결정적 코드는 반드시 `@task`로 감싸야 합니다.

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

이론적인 설명만으로는 내구성 실행의 가치를 체감하기 어렵습니다. 이제 구체적인 장애 복구 시나리오를 통해 체크포인터가 실제로 어떻게 동작하는지 확인해 봅시다. 핵심 원리는 간단합니다: 같은 `thread_id`로 재실행하면 체크포인트에서 이전 상태를 복원하여 이어서 실행합니다.

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

#note-box[장애가 발생했을 때 “어디서 다시 시작되는가?”를 항상 확인하세요. LangGraph는 마지막으로 _성공적으로 체크포인트된 작업 이후_ 부터 다시 시작합니다. 그래서 외부 API 호출, 파일 쓰기, 결제 같은 부작용은 _재실행되어도 안전한 단위_ 로 감싸야 합니다.]

== 12.10 재개 시작점

내구성 실행에서 가장 중요한 차이 중 하나는 _재개 시작점_입니다. Graph API와 Functional API는 동일한 체크포인터를 사용하지만, 재개 동작이 근본적으로 다릅니다:

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

#warning-box[Functional API에서 재개 시 `\@entrypoint` 함수가 처음부터 다시 실행되므로, `\@task` 밖에 있는 코드(변수 초기화, 조건문 등)는 _결정론적_이어야 합니다. 비결정적 코드가 `\@task` 밖에 있으면 재실행 시 다른 분기를 탈 수 있어 예측할 수 없는 동작이 발생합니다.]

== 12.11 프로덕션 내구성 패턴

재개 시작점의 차이를 이해했다면, 이제 프로덕션 환경에서 내구성을 효과적으로 활용하기 위한 모범 사례를 정리합니다. 아래 패턴들은 장애 복구뿐 아니라, 코드의 유지보수성과 테스트 용이성까지 향상시킵니다.

#warning-box[프로덕션 환경에서 `InMemorySaver`를 사용하면 프로세스 재시작 시 모든 체크포인트가 유실됩니다. 반드시 `PostgresSaver` 등 영속 저장소 기반 체크포인터를 사용하세요. LangGraph Platform을 사용하면 체크포인터가 자동으로 관리되므로 별도 설정이 필요 없습니다.]

+ _멱등성(Idempotent) 연산 구현_
같은 요청을 여러 번 실행해도 결과가 동일하도록 설계합니다.
멱등성 키(idempotency key)를 활용하여 중복 처리를 방지합니다.

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
]
#chapter-end()
