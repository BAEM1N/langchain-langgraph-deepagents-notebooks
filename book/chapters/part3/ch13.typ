// Auto-generated from 13_api_guide_and_pregel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "API 선택 가이드와 Pregel")

Part 3의 마지막 장입니다. 12개 장에 걸쳐 `Graph API`와 `Functional API`를 번갈아 사용해 왔다면, 이제 두 API의 설계 철학과 내부 실행 엔진을 정리할 때입니다. 두 API는 모두 `Pregel` 런타임 위에서 슈퍼스텝 단위로 실행되며, 체크포인팅, 스트리밍, 인터럽트 등 동일한 인프라를 공유합니다. 둘 사이의 차이는 _표현 방식_에 있을 뿐, 런타임 역량에는 본질적인 차이가 없습니다. 이 장에서는 동일한 에이전트를 양쪽 API로 구현해 비교하고, `Pregel` 런타임의 내부 구조를 이해하여 프로젝트에 맞는 API 선택 기준을 세웁니다.

#learning-header()
#learning-objectives([Graph API와 Functional API의 차이를 비교한다], [동일한 에이전트를 두 API로 구현한다], [Pregel 런타임의 내부 구조를 이해한다], [슈퍼스텝 실행 모델을 안다], [프로젝트에 맞는 API를 선택하는 기준을 세운다])

== 13.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 13.2 Graph API vs Functional API 개요

LangGraph는 에이전트 워크플로를 구축하기 위한 두 가지 API를 제공합니다. _Graph API_는 노드와 엣지로 구성된 명시적 그래프를 통해 워크플로를 정의하고, _Functional API_는 `@entrypoint`와 `@task` 데코레이터를 사용하여 일반 Python 함수 형태로 워크플로를 표현합니다.

두 API는 단지 표현 방식이 다를 뿐, 내부적으로는 동일한 Pregel 런타임 위에서 실행됩니다. 따라서 체크포인팅, 스트리밍, 인터럽트, human-in-the-loop 등 모든 인프라 기능을 동일하게 사용할 수 있으며, 하나의 애플리케이션에서 두 API를 함께 사용하는 것도 가능합니다.

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

#align(center)[#image("../../assets/diagrams/png/api_selection_map.png", width: 78%, height: 112mm, fit: "contain")]

선택의 핵심은 _실행 흐름을 눈에 보이는 그래프로 관리할지_, 아니면 _Python 함수 흐름으로 간결하게 표현할지_ 입니다. 두 API 모두 Pregel 런타임 위에서 실행되므로 성능보다도 _표현 방식과 유지보수성_ 이 더 중요한 결정 기준입니다.

개요 표에서 두 API의 구조적 차이를 확인했습니다. 하지만 실무에서는 "어떤 API를 선택해야 하는가?"라는 구체적인 판단이 필요합니다. 아래 표는 일반적인 상황별로 추천하는 API와 그 이유를 정리한 것입니다.

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

이론적인 비교를 넘어, 동일한 워크플로를 두 API로 구현하여 코드 수준에서 차이를 체감해 봅시다. 간단한 "에세이 작성 -> 점수 매기기" 2단계 파이프라인을 양쪽 API로 각각 구현합니다. 먼저 Graph API부터 살펴봅시다.

Graph API에서는 (1) 상태 스키마를 `TypedDict`로 정의하고, (2) 각 단계를 노드 함수로 구현한 뒤, (3) `StateGraph`에 노드를 등록하고 엣지로 연결합니다. 코드의 구조가 곧 워크플로의 구조를 반영한다는 점이 Graph API의 특징입니다.

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

이번에는 동일한 에세이 워크플로를 Functional API로 구현합니다. Functional API에서는 상태 스키마, 엣지 연결, `StateGraph` 빌더 등의 보일러플레이트가 사라집니다. 대신 `@task`로 각 단계를 감싸고, `@entrypoint`에서 일반 Python 함수처럼 순차적으로 호출합니다.

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

위 두 구현의 실행 결과는 동일합니다. 하지만 코드의 구조와 표현력에서 의미 있는 차이가 있습니다. 아래 표에서 항목별로 나란히 비교합니다:

#note-box[Functional API가 항상 "더 좋다"는 의미가 아닙니다. 간단한 선형 워크플로에서는 Functional API가 간결하지만, 조건 분기가 많거나 병렬 실행 경로가 복잡한 경우에는 Graph API의 명시적 구조가 가독성과 유지보수 면에서 유리합니다.]

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

실전에서는 "Graph API _또는_ Functional API"가 아니라 "Graph API _그리고_ Functional API"인 경우가 많습니다. 하나의 애플리케이션에서 두 API를 함께 사용할 수 있습니다. 복잡한 멀티 에이전트 조정은 Graph API로, 단순한 데이터 파이프라인은 Functional API로 처리하는 패턴이 일반적입니다.

#tip-box[Functional API로 작성한 `\@entrypoint` 함수는 Graph API의 노드로 사용할 수 있습니다. 반대로, Graph API로 컴파일된 그래프를 Functional API의 `\@entrypoint` 내부에서 `invoke()`로 호출할 수도 있습니다. 두 API는 완전히 호환됩니다.]

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

복잡도가 증가하면 Functional에서 Graph로, 과도하게 설계된 경우 Graph에서 Functional로 마이그레이션할 수 있습니다.

== 13.8 Pregel 런타임 개요

API 선택 가이드를 살펴보았으니, 이제 두 API가 공유하는 _내부 실행 엔진_을 자세히 들여다봅시다. 왜 내부 구조를 알아야 할까요? Graph API와 Functional API의 동작 방식, 성능 특성, 디버깅 전략을 깊이 이해하려면 그 아래에서 동작하는 런타임의 원리를 파악해야 합니다.

_Pregel_은 LangGraph의 내부 실행 엔진입니다. `StateGraph`를 컴파일하거나 `@entrypoint`를 사용하면 내부적으로 Pregel 인스턴스가 생성됩니다. 이름은 Google의 Pregel 논문(2010, "Pregel: A System for Large-Scale Graph Processing")에서 따왔으며, 대규모 병렬 그래프 연산의 핵심 아이디어를 LLM 에이전트 실행에 맞게 적용한 것입니다.

LangGraph에서 Pregel은 _액터(actor)_와 _채널(channel)_이라는 두 가지 핵심 개념으로 구성됩니다. 각 노드는 채널에서 데이터를 읽고 처리 결과를 채널에 쓰는 액터이며, 채널은 액터 간 데이터 통신을 담당합니다. Graph API에서 `TypedDict`의 각 필드는 채널에 대응되고, 리듀서(`Annotated[list, operator.add]`)는 채널의 업데이트 정책에 대응됩니다.

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

일반적으로 Pregel을 직접 사용할 필요는 없습니다. Graph API와 Functional API가 Pregel의 복잡성을 깔끔하게 추상화하기 때문입니다. 그러나 내부 동작 원리를 이해하면 디버깅과 성능 최적화에 도움이 되므로, 간단한 예제를 살펴봅니다. 아래 코드에서 `NodeBuilder`로 액터를 정의하고, 채널을 통해 데이터를 연결하는 Pregel의 저수준 API를 직접 사용합니다.

#warning-box[아래의 Pregel 직접 사용 코드는 _학습 목적_입니다. 프로덕션 코드에서는 Graph API 또는 Functional API를 사용하세요. Pregel의 내부 API는 LangGraph 버전에 따라 변경될 수 있습니다.]

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

Pregel의 가장 핵심적인 추상화는 채널입니다. 채널은 Graph API의 상태 필드와 리듀서에 정확히 대응됩니다. Pregel은 세 가지 채널 타입을 제공하며, 각각 Graph API에서 익숙한 패턴과 1:1로 매핑됩니다.

- `LastValue`: 리듀서 없는 필드에 대응합니다. 새 값이 들어오면 이전 값을 단순히 덮어씁니다.
- `Topic`: `operator.add` 리듀서에 대응합니다. 새 값이 들어올 때마다 리스트에 누적됩니다.
- `BinaryOperatorAggregate`: 커스텀 리듀서에 대응합니다. 두 값을 결합하는 함수를 직접 지정합니다.

#tip-box[Graph API에서 `Annotated[list, operator.add]` 타입 힌트를 사용하면, 내부적으로 Pregel의 `BinaryOperatorAggregate` 채널이 생성됩니다. Graph API의 "리듀서"라는 개념이 Pregel 레벨에서는 "채널 타입"으로 표현되는 것입니다. 이 대응 관계를 이해하면 Graph API의 상태 관리 동작을 더 정확히 예측할 수 있습니다.]

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

== 13.11 슈퍼스텝 실행 모델

채널 타입을 이해했다면, 이제 Pregel이 이 채널들을 어떻게 조율하여 그래프를 실행하는지 살펴봅시다. Pregel은 _슈퍼스텝(Super-step)_ 단위로 실행됩니다. 슈퍼스텝은 Pregel 실행의 기본 시간 단위로, 각 슈퍼스텝에서 실행 준비가 된 모든 노드(액터)가 _병렬로_ 실행됩니다. 모든 노드의 실행이 완료되면 채널이 업데이트되고, 그 후에야 다음 슈퍼스텝이 시작됩니다.

이 모델의 핵심 특성은 _동기적 병렬성_입니다. 같은 슈퍼스텝 내의 노드들은 서로의 출력을 볼 수 없고, 오직 이전 슈퍼스텝에서 채널에 기록된 값만 참조할 수 있습니다. 이 제약 덕분에 Pregel은 노드 간 경쟁 조건(race condition) 없이 안전하게 병렬 실행을 수행할 수 있습니다.

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

#note-box[_5문장 요약_
1. Graph API는 노드와 엣지를 명시적으로 설계해야 할 때 가장 강합니다.
2. Functional API는 `@task` 중심으로 빠르게 작성하고 싶을 때 더 자연스럽습니다.
3. 복잡한 분기와 시각적 디버깅이 중요하면 Graph API가 유리합니다.
4. 직선형 워크플로와 내구성 태스크 조합은 Functional API가 간결합니다.
5. 두 방식은 경쟁 관계가 아니라 같은 런타임을 공유하는 표현 계층입니다.]

== 13.12 API 선택 기준 가이드

Pregel 런타임의 내부 구조까지 이해했으므로, 이제 이 모든 지식을 종합하여 실용적인 API 선택 기준을 정리합시다. 아래는 프로젝트 초기에 API를 결정할 때 사용할 수 있는 4단계 의사결정 프레임워크입니다. 각 단계에서 자신의 프로젝트 상황에 맞는 조건을 확인하세요.

#warning-box[API 선택은 되돌릴 수 없는 결정이 아닙니다. Functional API로 시작한 프로젝트가 복잡해지면 Graph API로 마이그레이션할 수 있고, 그 반대도 가능합니다. 두 API가 동일한 Pregel 런타임을 공유하므로, 점진적 전환이 가능합니다. "완벽한 선택"보다 "빠르게 시작"하는 것이 더 중요합니다.]

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

Part 3 전체를 통해 LangGraph의 모든 핵심 개념을 다루었습니다. 상태 그래프(ch01-02), Functional API(ch03), 워크플로 패턴(ch04), 에이전트 구축(ch05), 지속성(ch06), 스트리밍(ch07), 인터럽트(ch08), 서브그래프(ch09), 프로덕션(ch10-11), 내구성 실행(ch12), 그리고 이 장에서의 API 선택 가이드와 Pregel 런타임까지 --- 이제 LangGraph로 프로덕션 수준의 에이전트를 설계하고 구축할 준비가 완료되었습니다.

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
  [LastValue, Topic, BinaryOperatorAggregate 3종류],
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
