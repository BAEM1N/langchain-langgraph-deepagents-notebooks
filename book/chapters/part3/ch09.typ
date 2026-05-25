// Auto-generated from 09_subgraphs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "서브그래프", subtitle: "그래프 안의 그래프")

8장까지 단일 그래프 내에서의 실행 제어를 다루었다면, 이 장에서는 _그래프를 구성 단위로 분리_하는 서브그래프를 다룹니다. 에이전트 시스템이 복잡해지면 하나의 거대한 그래프로 모든 로직을 관리하기 어려워집니다.

`LangGraph`의 서브그래프는 독립적으로 컴파일된 그래프를 부모 그래프의 노드로 삽입하여, 관심사 분리와 재사용성을 확보하는 모듈화 전략입니다. 각 서브그래프는 _자체 상태 스키마_를 가지며, 부모 그래프와는 _공유 키_를 통해 데이터를 주고받습니다. 서브그래프 내부에서 발생한 인터럽트는 부모 그래프 계층 구조를 따라 전파되므로, Human-in-the-loop 패턴도 서브그래프 경계를 넘어 자연스럽게 작동합니다. 이 장에서는 서브그래프의 설계, 상태 매핑, 그리고 서브그래프 내부의 인터럽트 처리까지 실습합니다.

#learning-header()
서브그래프로 복잡한 워크플로를 모듈화합니다.

- 독립적으로 컴파일된 그래프를 부모 그래프의 노드로 삽입할 수 있습니다
- 공유 키(shared key)를 통해 부모-서브그래프 간 데이터를 전달할 수 있습니다
- 래퍼 함수를 사용하여 서로 다른 상태 스키마를 매핑할 수 있습니다
- 서브그래프 내부의 인터럽트 전파 메커니즘을 이해합니다
- `subgraphs=True` 옵션으로 서브그래프 내부를 스트리밍할 수 있습니다

== 9.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 9.2 서브그래프 개념

에이전트 시스템의 규모가 커지면, 하나의 그래프에 모든 노드와 엣지를 담는 것은 유지보수와 테스트 측면에서 비효율적입니다. 서브그래프는 이 문제를 해결하는 LangGraph의 핵심 모듈화 전략입니다.

서브그래프는 _독립적으로 컴파일되고 테스트 가능한_ 그래프를 부모 그래프의 노드로 사용하는 패턴입니다. 소프트웨어 공학의 관점에서 함수 추출(extract function)에 비유할 수 있습니다. 하나의 거대한 함수를 여러 작은 함수로 나누듯, 거대한 그래프를 여러 서브그래프로 분리합니다.

- _서브그래프_: 다른 그래프의 노드로 사용되는 독립적인 그래프
- _장점_: 모듈화, 재사용, 팀별 독립 개발, 독립 테스트 가능
- 각 서브그래프는 자체 상태(State)를 가짐
- 부모 \<-\> 서브그래프 간 상태는 _공유 키_로 매핑

서브그래프를 부모 그래프에 추가하는 방법은 두 가지입니다. 부모와 서브그래프의 상태 스키마에 공유 키가 있으면 컴파일된 서브그래프를 `add_node()`에 직접 전달할 수 있습니다. 상태 스키마가 완전히 다르면 래퍼 함수를 사용하여 상태를 변환해야 합니다.

#tip-box[서브그래프는 독립적으로 `compile()`하여 단독 실행 및 테스트가 가능합니다. 개발 단계에서 서브그래프를 먼저 완성하고 테스트한 뒤, 부모 그래프에 통합하는 _보텀업(bottom-up) 개발 방식_이 권장됩니다.]

== 9.3 서브그래프 만들기

서브그래프를 만드는 것은 일반 그래프를 만드는 것과 동일합니다. `StateGraph`로 빌더를 생성하고, 노드와 엣지를 추가한 뒤 `compile()`로 컴파일합니다. 핵심은 서브그래프가 _자체적인 상태 스키마_를 가진다는 점입니다. 부모 그래프의 상태와는 독립적으로 설계할 수 있으며, 필요한 데이터만 공유 키를 통해 주고받습니다.

== 9.4 부모 그래프에 서브그래프 추가

서브그래프를 만들었다면, 이제 부모 그래프에 노드로 추가할 차례입니다. 가장 간단한 방법은 부모와 서브그래프의 상태 스키마가 공유 키를 가지는 경우입니다. 이때는 컴파일된 서브그래프 객체를 `add_node()`에 직접 전달하면 됩니다. LangGraph가 자동으로 공유 키를 통해 데이터를 매핑합니다.

== 9.4.1 패턴 1: 래퍼 노드를 통한 서브그래프 호출 (상태 스키마가 다른 경우)

공유 키를 통한 직접 추가는 편리하지만, 실무에서는 부모 그래프와 서브그래프의 상태 스키마가 완전히 다른 경우가 훨씬 많습니다. 이때는 래퍼 함수가 필요합니다.

위 예시(9.4)에서는 부모 그래프와 서브그래프가 _동일한 키_(`text`, `word_count`, `char_count`)를 공유했기 때문에, 컴파일된 서브그래프를 `add_node()`에 직접 전달할 수 있었습니다.

하지만 실무에서는 부모 그래프와 서브그래프의 _상태 스키마가 완전히 다른_ 경우가 많습니다. 이때는 _래퍼 함수(wrapper function)_를 사용하여:

+ 부모 상태에서 필요한 필드를 _추출_하여 서브그래프 입력으로 변환
+ 서브그래프를 _실행_
+ 서브그래프 출력을 부모 상태 형식으로 _매핑_

하는 패턴을 사용합니다. 이것이 공식 문서에서 _Pattern 1: Call Subgraph Inside a Node_라고 부르는 방식입니다.

#warning-box[래퍼 함수에서 서브그래프를 호출할 때는 `subgraph.invoke()`를 사용합니다. 이때 서브그래프의 체크포인터는 부모 그래프의 체크포인터와 별도로 동작합니다. 서브그래프 내부의 중간 상태는 부모 그래프의 체크포인트에 포함되지 않으므로, 서브그래프 내부 디버깅이 필요하다면 `subgraphs=True` 스트리밍을 활용하세요.]

== 9.5 LLM 기반 서브그래프

지금까지 단순한 데이터 처리 서브그래프를 살펴보았습니다. 이제 실전에서 가장 많이 사용되는 패턴인 LLM 기반 서브그래프를 다뤄봅시다.

서브그래프의 진정한 위력은 _전문 에이전트_를 모듈로 분리할 때 드러납니다. 예를 들어, 검색 에이전트, 코드 작성 에이전트, 데이터 분석 에이전트를 각각 독립적인 서브그래프로 만들고, 오케스트레이터 그래프가 이들을 조율하는 멀티 에이전트 시스템을 구축할 수 있습니다. 각 서브그래프는 자체 시스템 프롬프트, 도구 세트, 상태 스키마를 가지므로 전문 분야에 특화된 동작을 수행합니다.

#tip-box[멀티 에이전트 시스템에서 서브그래프 간 통신은 부모 그래프의 상태를 통해 이루어집니다. 서브그래프끼리 직접 통신하는 것이 아니라, 부모 그래프가 _오케스트레이터_ 역할을 하여 어떤 서브그래프를 언제 호출할지 결정합니다. 이 패턴은 Part 4에서 멀티 에이전트 아키텍처로 본격적으로 다룹니다.]

== 9.6 서브그래프 스트리밍

서브그래프를 사용할 때 디버깅과 모니터링을 위해 내부 실행 과정을 관찰해야 하는 경우가 있습니다. `stream()` 또는 `astream()`에 `subgraphs=True` 옵션을 전달하면 서브그래프 내부의 각 노드 실행도 스트리밍으로 받을 수 있습니다.

기본적으로 서브그래프 내부의 실행은 부모 그래프에게 "블랙박스"처럼 보입니다. 부모 그래프는 서브그래프가 반환한 최종 결과만 볼 수 있습니다. `subgraphs=True`를 설정하면 이 블랙박스를 열어 내부의 각 단계를 실시간으로 관찰할 수 있습니다.

v2 스트리밍(`version="v2"`)에서 서브그래프 청크는 통일된 `StreamPart` dict로 반환됩니다. 청크의 세 필드만 기억하면 됩니다.

#code-block(`````python
for chunk in graph.stream(
    {"foo": "foo"},
    subgraphs=True,
    stream_mode="updates",
    version="v2",
):
    print(chunk["type"])  # "updates"
    print(chunk["ns"])    # () = root, ("node_2:<id>",) = subgraph
    print(chunk["data"])  # {"node_name": {"key": "value"}}
`````)

- `chunk["type"]` --- 모드 식별자 (`"updates"`, `"values"`, `"messages"`, ...)
- `chunk["ns"]` --- 네임스페이스 튜플. root는 `()`, 서브그래프는 `("node_2:<uuid>",)`
- `chunk["data"]` --- 모드별 payload

#tip-box[v1 API에서는 `subgraphs=True` 옵션에 따라 반환 형태(`tuple` vs `dict`)가 달라져 분기 처리가 번거로웠습니다. v2는 항상 같은 dict 형태이므로 root/서브그래프 코드를 통일할 수 있습니다.]

=== 서브그래프 Checkpointer 3모드

서브그래프 컴파일 시 `checkpointer=` 인자에 따라 메모리/인터럽트 동작이 달라집니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[`checkpointer=`],
  text(weight: "bold")[동작],
  text(weight: "bold")[적합 시나리오],
  [Per-invocation (기본)],
  [`None`],
  [매 호출마다 fresh. 단일 invoke 안에서는 부모 체크포인터 상속(인터럽트 지원)],
  [툴로 감싼 subagent, 멀티 에이전트 라우팅],
  [Per-thread (stateful)],
  [`True`],
  [동일 thread에서 호출 간 state 누적. 대화 이력 유지],
  [장기 대화를 가진 전문 subagent],
  [Stateless],
  [`False`],
  [체크포인트 없음 --- 일반 함수 호출. 인터럽트 미지원],
  [부수효과 없는 순수 변환],
)

#warning-box[Per-thread 서브그래프는 _병렬 tool 호출_에 취약합니다. LLM이 동일 subagent를 동시에 여러 번 호출하면 같은 namespace에 동시에 쓰기가 발생해 충돌이 납니다. `ToolCallLimitMiddleware(tool_name="...", run_limit=1)`로 동시 호출을 제한하세요.]

=== Namespace Isolation --- 여러 per-thread 서브그래프 분리

서로 다른 per-thread 서브그래프를 같은 부모 그래프에서 사용하려면, 각각을 _고유한 노드 이름_으로 감싸 namespace를 분리해야 합니다. `StateGraph(MessagesState).add_node(name, agent)` 패턴이 표준입니다.

#code-block(`````python
from langgraph.graph import MessagesState, StateGraph
from langchain.agents import create_agent

def create_sub_agent(model, *, name, **kwargs):
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)          # 고유 name → 안정적 namespace
        .add_edge("__start__", name)
        .compile()
    )

fruit_agent = create_sub_agent(
    "gpt-5.4-mini", name="fruit_agent",
    tools=[fruit_info], prompt="You are a fruit expert.",
    checkpointer=True,
)
veggie_agent = create_sub_agent(
    "gpt-5.4-mini", name="veggie_agent",
    tools=[veggie_info], prompt="You are a veggie expert.",
    checkpointer=True,
)
`````)

각 subagent는 자기 이름과 동일한 namespace에서만 체크포인트를 쓰므로, 서로의 state를 침범하지 않습니다.

#tip-box[서브그래프 스트리밍 시 각 이벤트에는 서브그래프의 _네임스페이스 경로_가 포함됩니다. 예를 들어 `("parent:sub_agent",)`처럼 계층 구조가 표시되어, 어느 레벨의 어느 서브그래프에서 발생한 이벤트인지 정확히 구분할 수 있습니다.]

== 9.7 서브그래프 내부의 인터럽트 전파

서브그래프의 강력한 특성 중 하나는 _인터럽트 전파_입니다. 서브그래프 내부의 노드에서 `interrupt()`가 호출되면, 이 인터럽트는 부모 그래프 계층 구조를 따라 위로 전파됩니다. 부모 그래프에서 `Command(resume=...)`로 재개하면, 서브그래프 내부의 정확한 중단 지점에서 실행이 재개됩니다.

이 메커니즘 덕분에 8장에서 배운 Human-in-the-loop 패턴이 서브그래프 경계를 넘어 자연스럽게 작동합니다. 서브그래프를 설계할 때 인터럽트를 포함해도, 부모 그래프 쪽에서 별도의 처리 코드를 작성할 필요가 없습니다.

#warning-box[서브그래프 내부에서 인터럽트가 발생하면, 부모 그래프의 해당 슈퍼스텝 전체가 중단됩니다. 같은 슈퍼스텝에서 병렬 실행 중인 다른 서브그래프가 있다면, 해당 서브그래프의 실행도 함께 중단되므로 주의가 필요합니다.]

이 장에서 서브그래프를 통한 워크플로 모듈화를 다루었습니다. 독립적인 상태 스키마, 공유 키를 통한 데이터 매핑, 래퍼 함수를 통한 상태 변환, 그리고 서브그래프 내부의 스트리밍과 인터럽트 전파까지 --- 대규모 에이전트 시스템을 구축하는 데 필요한 모듈화 전략을 갖추었습니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [서브그래프],
  [독립적으로 컴파일된 그래프를 노드로 사용],
  [공유 키],
  [부모-서브그래프 간 상태 매핑],
  [모듈화],
  [복잡한 워크플로를 작은 단위로 분리],
  [스트리밍],
  [`subgraphs=True`로 내부 단계 추적],
)

#next-step-box[다음 장에서는 개발 환경에서 검증된 에이전트를 _프로덕션으로 전환_하는 과정을 다룹니다. `langgraph.json` 설정, 테스트 전략, 배포 옵션, 그리고 LangSmith 기반 관측성까지 살펴봅니다.]

#chapter-end()
