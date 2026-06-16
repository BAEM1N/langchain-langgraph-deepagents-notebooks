// Auto-generated from 09_subgraphs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "서브그래프", subtitle: "그래프 안의 그래프")

== 학습 목표
서브그래프로 복잡한 워크플로를 모듈화합니다.

== 9.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
# docs/langgraph 패치 기준 canonical 모델 ID
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 9.2 서브그래프 개념

- _서브그래프_: 다른 그래프의 노드로 사용되는 독립적인 그래프
- _장점_: 모듈화, 재사용, 팀별 독립 개발
- 각 서브그래프는 자체 상태(State)를 가짐
- 부모 \<-\> 서브그래프 간 상태는 _공유 키_로 매핑

== 9.3 서브그래프 만들기

== 9.4 부모 그래프에 서브그래프 추가

== 9.4.1 패턴 1: 래퍼 노드를 통한 서브그래프 호출 (상태 스키마가 다른 경우)

위 예시(9.4)에서는 부모 그래프와 서브그래프가 _동일한 키_(`text`, `word_count`, `char_count`)를 공유했기 때문에, 컴파일된 서브그래프를 `add_node()`에 직접 전달할 수 있었습니다.

실무에서는 부모 그래프와 서브그래프의 _상태 스키마가 완전히 다른_ 경우가 많습니다. 이때는 _래퍼 함수(wrapper function)_를 사용하여:

+ 부모 상태에서 필요한 필드를 _추출_하여 서브그래프 입력으로 변환
+ 서브그래프를 _실행_
+ 서브그래프 출력을 부모 상태 형식으로 _매핑_

합니다. 공식 문서에서 _Pattern 1: Call Subgraph Inside a Node_라고 부르는 방식입니다.

== 9.5 LLM 기반 서브그래프

전문 에이전트를 서브그래프로 구성합니다.

== 9.6 서브그래프 스트리밍

`subgraphs=True`를 주면 서브그래프 내부 단계도 스트리밍됩니다.

=== v1 (기본) — `(namespace, data)` 튜플
#code-block(`````python
for chunk in graph.stream(inputs, stream_mode="updates", subgraphs=True):
    ns, data = chunk  # tuple unpack
    ...
`````)

=== v2 — `chunk["type"]` / `chunk["ns"]` / `chunk["data"]` (권장)
#code-block(`````python
for chunk in graph.stream(inputs, stream_mode="updates", subgraphs=True, version="v2"):
    chunk["type"]  # "updates"
    chunk["ns"]    # () for root, ("node_2:<id>",) for subgraph
    chunk["data"]  # {"node_name": {"key": "value"}}
`````)

v2는 모든 청크가 `StreamPart` dict로 통일되므로 tuple vs dict 판별이 필요 없습니다.

== 9.7 서브그래프 Checkpointer 3가지 모드

서브그래프 `compile(checkpointer=...)` 인자에 따라 동작이 달라집니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[`checkpointer=`],
  text(weight: "bold")[동작],
  [_Per-Invocation_ (기본)],
  [`None` (또는 미지정)],
  [매 호출마다 fresh 상태로 시작. 부모의 checkpointer를 상속해 _interrupt와 durable execution은 단일 호출 내에서 동작_],
  [_Per-Thread_ (stateful)],
  [`True`],
  [동일 thread에서 호출이 누적되어 _대화 이력 유지_],
  [_Stateless_],
  [`False`],
  [checkpoint 자체를 만들지 않음. 일반 함수 호출처럼 동작 — _interrupt 불가_, 프로세스 crash 시 복구 불가],
)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[Stateless],
  text(weight: "bold")[Per-Invocation],
  text(weight: "bold")[Per-Thread],
  [`checkpointer=`],
  [`False`],
  [`None`],
  [`True`],
  [Interrupt (HITL)],
  [불가],
  [가능],
  [가능],
  [멀티턴 메모리],
  [없음],
  [없음],
  [있음],
  [상태 조회],
  [불가],
  [현재 호출만],
  [가능],
  [동일 subgraph 병렬 호출],
  [가능],
  [가능],
  [_불가_ (namespace 충돌)],
)

=== Per-Thread 주의점 — 병렬 tool 호출 금지

per-thread 서브그래프를 tool로 노출하면, LLM이 이 tool을 동시에 여러 번 호출할 수 있습니다. 두 호출이 같은 namespace에 동시에 쓰려 하면 checkpoint conflict가 발생합니다. `ToolCallLimitMiddleware`로 동시 호출을 막아야 합니다.

#code-block(`````python
# 3가지 checkpointer 모드 — API 레퍼런스 (create_agent를 subagent로 쓰는 예)
from langchain.agents import create_agent
from langchain.tools import tool
from langgraph.checkpoint.memory import MemorySaver

@tool
def fruit_info(fruit_name: str) -> str:
    """Look up fruit info."""
    return f"Info about {fruit_name}"

# === 1) Per-Invocation (기본) ===
# subagent에 checkpointer 미지정 → 부모로부터 상속, 호출마다 fresh
fruit_subagent_per_invocation = create_agent(
    model="gpt-5.4-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
)

# === 2) Per-Thread (stateful) ===
fruit_subagent_per_thread = create_agent(
    model="gpt-5.4-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=True,  # ← 핵심
)

# === 3) Stateless ===
fruit_subagent_stateless = create_agent(
    model="gpt-5.4-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=False,  # ← interrupt 불가
)

# === Per-Thread를 tool로 노출할 때 — 병렬 호출 차단 ===
reference_code = r'''
from langchain.agents.middleware import ToolCallLimitMiddleware

@tool
def ask_fruit_expert(question: str) -> str:
    """Ask the fruit expert."""
    response = fruit_subagent_per_thread.invoke(
        {"messages": [{"role": "user", "content": question}]},
    )
    return response["messages"][-1].content

agent = create_agent(
    model="gpt-5.4-mini",
    tools=[ask_fruit_expert],
    middleware=[
        ToolCallLimitMiddleware(tool_name="ask_fruit_expert", run_limit=1),
    ],
    checkpointer=MemorySaver(),
)
'''
print(reference_code)
print("3가지 모드 객체 생성 완료:",
      type(fruit_subagent_per_invocation).__name__,
      type(fruit_subagent_per_thread).__name__,
      type(fruit_subagent_stateless).__name__)
`````)

== 9.8 Namespace Isolation — 여러 Per-Thread 서브그래프 격리

서로 _다른_ per-thread 서브그래프 여러 개를 같이 쓰면 namespace가 겹쳐 state 충돌이 생길 수 있습니다. 각 서브그래프를 _고유 노드 이름_을 가진 별도 `StateGraph`로 감싸 안정적인 namespace를 부여합니다.

핵심 패턴:
- `agent = create_agent(model=..., name=name, ...)` — agent에 이름 부여
- `StateGraph(MessagesState).add_node(name, agent)` — _같은 이름_으로 그래프 노드 등록
- 이 노드 이름이 LangGraph 내부에서 checkpoint namespace 접두사가 됨

#code-block(`````python
from langgraph.graph import MessagesState, StateGraph
from langchain.agents import create_agent
from langchain.tools import tool


@tool
def veggie_info(veggie_name: str) -> str:
    """Look up veggie info."""
    return f"Info about {veggie_name}"


def create_sub_agent(model: str, *, name: str, **kwargs):
    """고유 노드 이름으로 agent를 감싸 namespace를 격리합니다."""
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)        # 고유 이름 → 안정적 namespace
        .add_edge("__start__", name)
        .compile()
    )


# 서로 다른 두 per-thread subagent — namespace가 격리됨
fruit_agent_isolated = create_sub_agent(
    "gpt-5.4-mini",
    name="fruit_agent",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=True,
)

veggie_agent_isolated = create_sub_agent(
    "gpt-5.4-mini",
    name="veggie_agent",
    tools=[veggie_info],
    prompt="You are a veggie expert.",
    checkpointer=True,
)

print("두 per-thread subagent가 서로 다른 namespace로 격리되었습니다.")
print("  - fruit_agent: namespace prefix = ('fruit_agent:<uuid>',)")
print("  - veggie_agent: namespace prefix = ('veggie_agent:<uuid>',)")
print("→ 두 agent의 checkpoint state가 충돌하지 않습니다.")
`````)

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
  [_Pattern 1_ (Call inside node)],
  [상태 스키마가 다를 때 — 래퍼 함수로 변환],
  [_Pattern 2_ (Add as node)],
  [공유 키가 있을 때 — `add_node(name, subgraph)` 직접],
  [스트리밍 v1],
  [`subgraphs=True` → `(namespace, data)` 튜플],
  [_스트리밍 v2_],
  [`subgraphs=True, version="v2"` → `chunk["type"]` / `chunk["ns"]` / `chunk["data"]`],
  [_Per-Invocation_ (`checkpointer=None`)],
  [매 호출 fresh, 부모 checkpointer 상속],
  [_Per-Thread_ (`checkpointer=True`)],
  [thread별 누적 메모리, 병렬 호출 금지],
  [_Stateless_ (`checkpointer=False`)],
  [checkpoint 없음, interrupt 불가],
  [_Namespace Isolation_],
  [여러 per-thread subagent는 `StateGraph().add_node(name, agent)`로 감싸 격리],
  [`get_state(config, subgraphs=True)`],
  [서브그래프 내부 상태 검사 (parent에 checkpointer 필요)],
)
