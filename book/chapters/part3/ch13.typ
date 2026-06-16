// Auto-generated from 13_api_guide_and_pregel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "API 선택 가이드와 Pregel")

== 학습 목표
#learning-objectives([Graph API와 Functional API의 차이를 비교한다], [동일한 에이전트를 두 API로 구현한다], [Pregel 런타임의 내부 구조를 이해한다], [슈퍼스텝 실행 모델을 안다], [프로젝트에 맞는 API를 선택하는 기준을 세운다])

== 13.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 13.2 Graph API vs Functional API 개요

LangGraph는 에이전트 워크플로를 구축하기 위한 두 가지 API를 제공합니다.
두 API는 동일한 Pregel 런타임 위에서 실행되며, 하나의 애플리케이션에서 함께 사용할 수 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [추상화 방식],
  [노드와 엣지로 구성된 그래프],
  [데코레이터 기반 함수],
  [상태 관리],
  [TypedDict 스키마로 명시적 관리],
  [함수 스코프 내 로컬 변수],
  [제어 흐름],
  [조건부 엣지, 라우팅],
  [일반 Python 제어문 (if/else, for)],
  [시각화],
  [그래프 구조 자동 시각화],
  [제한적],
  [보일러플레이트],
  [상대적으로 많음],
  [최소화],
)

== 13.3 빠른 선택 가이드

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[상황],
  text(weight: "bold")[추천 API],
  text(weight: "bold")[이유],
  [복잡한 워크플로 시각화 필요],
  [Graph API],
  [노드/엣지 구조가 자동으로 다이어그램 생성],
  [병렬 실행 경로],
  [Graph API],
  [여러 노드가 자연스럽게 병렬 실행],
  [멀티 에이전트 팀],
  [Graph API],
  [에이전트 간 명확한 역할 분리],
  [기존 코드에 최소 변경],
  [Functional API],
  [데코레이터만 추가하면 됨],
  [단순 선형 워크플로],
  [Functional API],
  [보일러플레이트 없이 빠르게 구현],
  [빠른 프로토타이핑],
  [Functional API],
  [상태 스키마 정의 불필요],
)

== 13.4 Graph API 구현

에세이 작성 → 점수 매기기 워크플로를 Graph API로 구현합니다.

#code-block(`````python
from typing import TypedDict
from langgraph.constants import START
from langgraph.graph import StateGraph


class Essay(TypedDict):
    topic: str
    content: str | None
    score: float | None


def write_essay(essay: Essay):
    return {"content": f"Essay about {essay['topic']}"}


def score_essay(essay: Essay):
    return {"score": 10}


builder = StateGraph(Essay)
builder.add_node(write_essay)
builder.add_node(score_essay)
builder.add_edge(START, "write_essay")
builder.add_edge("write_essay", "score_essay")

graph_app = builder.compile()

result = graph_app.invoke({"topic": "LangGraph"})
print("Graph API 결과:", result)
`````)
#output-block(`````
Graph API 결과: {'topic': 'LangGraph', 'content': 'Essay about LangGraph', 'score': 10}
`````)

== 13.5 Functional API 구현

동일한 에세이 워크플로를 Functional API로 구현합니다.

#code-block(`````python
from typing import TypedDict
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver


class EssayResult(TypedDict):
    topic: str
    content: str | None
    score: float | None


@task
def write_essay_func(topic: str) -> str:
    return f"Essay about {topic}"


@task
def score_essay_func(content: str) -> float:
    return 10


func_saver = InMemorySaver()


@entrypoint(checkpointer=func_saver)
def essay_pipeline(topic: str) -> dict:
    content = write_essay_func(topic).result()
    score = score_essay_func(content).result()
    return {"topic": topic, "content": content, "score": score}


config = {"configurable": {"thread_id": "essay-1"}}
result = essay_pipeline.invoke("LangGraph", config)
print("Functional API 결과:", result)
`````)
#output-block(`````
Functional API 결과: {'topic': 'LangGraph', 'content': 'Essay about LangGraph', 'score': 10}
`````)

== 13.6 비교 분석

위 두 구현을 나란히 비교합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [상태 정의],
  [`TypedDict` 스키마 필수],
  [선택적 (로컬 변수 가능)],
  [노드 연결],
  [`add_edge()`, `add_conditional_edges()`],
  [일반 함수 호출],
  [체크포인터],
  [`compile(checkpointer=...)`],
  [`\@entrypoint(checkpointer=...)`],
  [코드 라인 수],
  [상대적으로 많음],
  [간결함],
  [시각화],
  [`graph.get_graph().draw_mermaid()` 지원],
  [제한적],
  [병렬 실행],
  [엣지 구조로 자연스럽게 지원],
  [`\@task` 병렬 실행으로 지원],
  [디버깅],
  [Studio에서 노드별 상태 확인],
  [함수 단위 트레이싱],
)

== 13.7 두 API 결합

하나의 애플리케이션에서 두 API를 함께 사용할 수 있습니다.
복잡한 멀티 에이전트 조정은 Graph API로, 단순한 데이터 파이프라인은 Functional API로 처리하는 패턴이 일반적입니다.

#code-block(`````python
# Graph API: 복잡한 멀티 에이전트 조정
coordinator = StateGraph(CoordinatorState)
coordinator.add_node("planner", planner_agent)
coordinator.add_node("executor", executor_agent)
coordinator.add_node("reviewer", reviewer_agent)
# ...

# Functional API: 단순 데이터 처리
@entrypoint(checkpointer=saver)
def preprocess(data: str) -> str:
    cleaned = clean_data(data).result()
    validated = validate_data(cleaned).result()
    return validated
`````)

복잡도가 높아지면 Functional에서 Graph로, 과도하게 설계된 경우 Graph에서 Functional로 마이그레이션할 수 있습니다.

== 13.8 Pregel 런타임 개요

_Pregel_은 LangGraph의 내부 실행 엔진입니다.
`StateGraph`를 컴파일하거나 `@entrypoint`를 사용하면 내부적으로 Pregel 인스턴스가 생성됩니다.

이름은 Google의 Pregel 알고리즘에서 따왔으며, 대규모 병렬 그래프 연산을 효율적으로 처리합니다.

_핵심 구성 요소:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구성 요소],
  text(weight: "bold")[역할],
  [_액터(Actor)_],
  [채널에서 데이터를 읽고 처리 결과를 채널에 씀],
  [_채널(Channel)_],
  [액터 간 데이터 통신을 담당],
)

_실행 3단계 (매 스텝마다):_

+ _Plan_ — 이번 스텝에서 실행할 액터를 결정
+ _Execute_ — 선택된 액터를 병렬로 실행 (완료, 실패, 또는 타임아웃까지)
+ _Update_ — 새로운 값으로 채널을 갱신

실행할 액터가 없거나 최대 스텝에 도달하면 종료됩니다.

== 13.9 Pregel 직접 사용

일반적으로 Pregel을 직접 사용할 필요는 없지만,
내부 동작 원리를 이해하기 위해 간단한 예제를 살펴봅니다.

#code-block(`````python
from langgraph.channels import EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder

# 단일 노드: 입력을 두 번 반복
node1 = (
    NodeBuilder()
    .subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b")
)

app = Pregel(
    nodes={"node1": node1},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
    },
    input_channels=["a"],
    output_channels=["b"],
)

result = app.invoke({"a": "foo"})
print("Pregel 결과:", result)
# 'foo' + 'foo' = 'foofoo'
`````)
#output-block(`````
Pregel 결과: {'b': 'foofoo'}
`````)

== 13.10 채널 타입

Pregel은 5가지 채널 타입을 제공합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Purpose],
  [_`LastValue`_],
  [가장 최근 값을 저장. 입력/출력에 적합한 기본 채널],
  [_`EphemeralValue`_],
  [실행 step 내부에서만 유효한 임시 값],
  [_`Topic`_],
  [설정 가능한 PubSub. 다중 값 + optional 중복 제거 / 누적],
  [_`BinaryOperatorAggregate`_],
  [현재 값과 업데이트에 binary operator 적용(러닝 토탈 등)],
  [_`DeltaChannel`_ (beta, `langgraph\>=1.2`)],
  [step별 incremental delta만 저장. 자주 쓰이고 빠르게 자라는 채널(메시지 리스트 등)에 적합],
)

#code-block(`````python
from langgraph.channels import (
    EphemeralValue,
    LastValue,
    Topic,
    BinaryOperatorAggregate,
)
from langgraph.pregel import Pregel, NodeBuilder

# --- 1. LastValue: 최신 값만 유지 ---
node_lv = (
    NodeBuilder()
    .subscribe_only("input")
    .do(lambda x: x.upper())
    .write_to("output")
)

app_lv = Pregel(
    nodes={"node": node_lv},
    channels={
        "input": EphemeralValue(str),
        "output": LastValue(str),
    },
    input_channels=["input"],
    output_channels=["output"],
)
print("LastValue:", app_lv.invoke({"input": "hello"}))

# --- 2. Topic: 여러 값을 누적 ---
node_t1 = (
    NodeBuilder()
    .subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b", "c")
)

node_t2 = (
    NodeBuilder()
    .subscribe_to("b")
    .do(lambda x: x["b"] + x["b"])
    .write_to("c")
)

app_topic = Pregel(
    nodes={"node1": node_t1, "node2": node_t2},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
        "c": Topic(str, accumulate=True),
    },
    input_channels=["a"],
    output_channels=["c"],
)
print("Topic:", app_topic.invoke({"a": "foo"}))

# --- 3. BinaryOperatorAggregate: 리듀서 적용 ---
def reducer(current, update):
    if current:
        return current + " | " + update
    return update

node_b1 = (
    NodeBuilder()
    .subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b", "c")
)

node_b2 = (
    NodeBuilder()
    .subscribe_only("b")
    .do(lambda x: x + x)
    .write_to("c")
)

app_agg = Pregel(
    nodes={"node1": node_b1, "node2": node_b2},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
        "c": BinaryOperatorAggregate(str, operator=reducer),
    },
    input_channels=["a"],
    output_channels=["c"],
)
print("BinaryOperatorAggregate:", app_agg.invoke({"a": "foo"}))
`````)
#output-block(`````
LastValue: {'output': 'HELLO'}
Topic: {'c': ['foofoo', 'foofoofoofoo']}
BinaryOperatorAggregate: {'c': 'foofoo | foofoofoofoo'}
`````)

=== DeltaChannel (beta, `langgraph\>=1.2`)

`DeltaChannel`은 매 step의 full 누적값이 아니라 _incremental delta만 저장_합니다. 메시지 리스트처럼 자주 쓰이고 무한히 자라는 채널의 checkpoint 비용을 줄이는 데 사용합니다.

- Reducer는 associative해야 하며 _write 시점이 아니라 reconstruction 시점_에 실행됩니다.
- `snapshot_frequency=K`로 K step마다 full snapshot을 한 번 기록해 reconstruction 비용을 제한합니다.
- Bulk reducer 시그니처는 `(current_state, sequence_of_writes) -> new_state` 입니다.

#code-block(`````python
# DeltaChannel 개념 예시 — 실제 실행은 langgraph>=1.2에서 확인하세요.
example = r'''
from typing import Annotated, Sequence
from typing_extensions import TypedDict
from langgraph.channels import DeltaChannel

def list_reducer(state: list, writes: Sequence[list]) -> list:
    # (current_state, sequence_of_writes) -> new_state
    result = list(state)
    for write in writes:
        result.extend(write)
    return result

class State(TypedDict):
    messages: Annotated[
        list[str],
        DeltaChannel(list_reducer, snapshot_frequency=5),
    ]
'''
print(example)
`````)

== 13.11 슈퍼스텝 실행 모델

Pregel은 _슈퍼스텝(Super-step)_ 단위로 실행됩니다.
각 슈퍼스텝에서 동일 레벨의 노드(액터)가 병렬로 실행되고,
모든 노드가 완료되면 채널이 업데이트된 후 다음 슈퍼스텝으로 넘어갑니다.

#code-block(`````python
[슈퍼스텝 1] Node A, Node B  (병렬 실행)
     ↓ 채널 업데이트
[슈퍼스텝 2] Node C  (A, B 결과 기반)
     ↓ 채널 업데이트
[슈퍼스텝 3] Node D
     ↓
END
`````)

_슈퍼스텝의 특징:_
- 같은 슈퍼스텝 내 노드는 서로의 출력을 볼 수 없음 (이전 스텝의 채널 값만 참조)
- 모든 노드가 완료되어야 다음 스텝 진행
- 체크포인터가 설정된 경우, 각 슈퍼스텝 후 상태 저장
- 실행할 노드가 없으면 자동 종료

== 13.12 API 선택 기준 가이드

최종 선택을 위한 의사결정 프레임워크입니다:

_1단계: 복잡도 평가_
- 노드가 3개 이하이고 선형 흐름 → _Functional API_
- 조건 분기, 병렬 경로, 순환 구조 → _Graph API_

_2단계: 팀 협업_
- 혼자 또는 소규모 팀 → 어느 쪽이든 가능
- 여러 팀원이 각 노드를 담당 → _Graph API_ (시각화와 역할 분리)

_3단계: 기존 코드 활용_
- 기존 절차적 코드에 LangGraph 기능 추가 → _Functional API_
- 새로운 워크플로를 처음부터 설계 → _Graph API_

_4단계: 발전 가능성_
- 프로토타입에서 시작 → _Functional API_ → 복잡해지면 Graph API로 마이그레이션
- 처음부터 확장성 고려 → _Graph API_

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [Graph API],
  [노드/엣지 기반, 시각화 강점, 복잡한 워크플로에 적합],
  [Functional API],
  [데코레이터 기반, 최소 보일러플레이트, 선형 워크플로에 적합],
  [비교],
  [동일 런타임, 함께 사용 가능, 복잡도에 따라 선택],
  [Pregel],
  [LangGraph의 내부 실행 엔진, 액터-채널 모델],
  [채널],
  [LastValue, EphemeralValue, Topic, BinaryOperatorAggregate, DeltaChannel(beta)],
  [슈퍼스텝],
  [동일 레벨 노드 병렬 실행 → 채널 업데이트 → 다음 스텝],
  [선택 기준],
  [복잡도, 팀 협업, 기존 코드, 발전 가능성으로 판단],
)


#references-box[
- #link("../docs/langgraph/18-choosing-apis.md")[Choosing between Graph and Functional APIs]
- #link("../docs/langgraph/23-pregel.md")[LangGraph Runtime (Pregel)]
]
#chapter-end()
