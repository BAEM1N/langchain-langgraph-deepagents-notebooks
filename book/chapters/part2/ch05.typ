// Auto-generated from 05_memory_and_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "메모리와 스트리밍")

실용적인 에이전트라면 대화를 기억하고, 장기적인 사용자 선호도를 학습하며, 응답을 실시간으로 전달할 수 있어야 합니다. Part I에서 `InMemorySaver`의 기본 사용법을 다뤘다면, 이 장에서는 단기/장기 메모리의 차이, 메시지 트리밍 전략, 그리고 5가지 스트리밍 모드의 실전 활용법을 깊이 있게 학습합니다.

#learning-header()
#learning-objectives([_단기 메모리(Short-term Memory):_ `InMemorySaver`를 사용하여 `thread_id` 기반으로 대화 상태를 유지하는 방법을 이해합니다.], [_장기 메모리(Long-term Memory):_ `InMemoryStore`를 사용하여 대화 간에 지속되는 메모리를 구현합니다.], [_메시지 트리밍:_ 긴 대화에서 토큰 예산 내로 메시지를 제한하는 방법을 배웁니다.], [_스트리밍 모드:_ `values`, `updates`, `messages`, `custom` 등 다양한 스트리밍 모드의 차이를 이해합니다.])

== 5.1 환경 설정

이 장에서 사용할 모델을 초기화합니다. 메모리와 스트리밍은 모델 자체가 아닌 _에이전트 레벨_에서 동작하므로, 모델 설정은 이전 장과 동일합니다.

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 준비 완료:", model.model_name)
`````)
#output-block(`````
모델 준비 완료: gpt-5.4
`````)

== 5.2 단기 메모리: InMemorySaver

2장에서 `InMemorySaver`를 사용하여 멀티턴 대화를 구현한 바 있습니다. 이 절에서는 그 내부 동작을 더 깊이 살펴봅니다.

단기 메모리는 _하나의 대화 세션_ 내에서 이전 메시지를 기억하는 메커니즘입니다.

- `InMemorySaver`는 체크포인터(checkpointer)로서 에이전트의 _전체 그래프 상태_(full graph state)를 메모리에 저장합니다. 여기에는 메시지 히스토리뿐 아니라 도구 호출 상태, 중단점 정보 등이 모두 포함됩니다.
- `thread_id`를 사용하여 서로 다른 대화 세션을 구분합니다.
- 같은 `thread_id`를 사용하면 이전 대화 컨텍스트가 유지됩니다.
- `invoke()` 호출 시 반드시 `{"configurable": {"thread_id": "..."}}` config를 전달해야 합니다.

== 5.3 다른 thread_id로 독립된 대화

단기 메모리의 격리 메커니즘을 확인해 봅니다. 서로 다른 `thread_id`를 사용하면 완전히 _독립된 대화 세션_이 생성됩니다. 이전 세션의 컨텍스트는 공유되지 않습니다. 이를 통해 하나의 에이전트 인스턴스로 여러 사용자의 대화를 동시에 관리할 수 있습니다.

== 5.4 메시지 트리밍

세션 격리를 확인했으니, 이제 단기 메모리의 실전적 문제를 다룹니다. 대화가 길어지면 토큰 수가 증가하여 비용과 성능에 영향을 줍니다. 특히 모델의 컨텍스트 윈도우를 초과하면 API 오류가 발생합니다. _메시지 트리밍_을 사용하면 토큰 예산 내에서 가장 관련성 높은 메시지만 유지할 수 있습니다.

`trim_messages()` 함수의 주요 매개변수:

- `messages`: 트리밍할 메시지 리스트
- `max_tokens`: 유지할 최대 토큰 수. 이 예산을 초과하면 오래된 메시지부터 제거합니다.
- `strategy="last"`: 가장 최근 메시지를 우선 유지합니다. (유일하게 지원되는 전략)
- `include_system=True`: 시스템 메시지는 항상 포함합니다. 시스템 프롬프트가 잘리면 에이전트의 행동이 달라질 수 있으므로, 일반적으로 `True`로 설정합니다.

#tip-box[`trim_messages`는 단독으로 호출하거나, 미들웨어(`@before_model`) 안에서 자동으로 적용할 수 있습니다. 미들웨어 방식은 6장에서 다룹니다.]

== 5.5 장기 메모리: InMemoryStore

단기 메모리가 _세션 내_ 대화를 기억한다면, 장기 메모리는 _세션 간_에 지속되는 정보를 저장합니다. "사용자가 어두운 테마를 선호한다", "지난주에 Python 프로젝트를 논의했다" 같은 정보를 기억하여 개인화된 경험을 제공합니다.

장기 메모리는 _대화 세션 간에 지속되는_ 정보를 저장합니다.

- `InMemoryStore`는 네임스페이스 기반 키-값 저장소로서 사용자 선호도, 설정 등을 저장합니다.
- 도구의 `ToolRuntime` 파라미터를 통해 스토어에 접근할 수 있습니다.
- `thread_id`와 무관하게 모든 세션에서 동일한 데이터에 접근 가능합니다.

주요 API는 다음과 같습니다:
- `store.put(namespace, key, value)`: 네임스페이스 아래에 키-값 쌍을 저장합니다. 예: `store.put(("user_123", "memories"), "pref_theme", {"value": "dark"})`
- `store.search(namespace, query=...)`: 네임스페이스 내에서 시맨틱 검색을 수행합니다.
- `store.get(namespace, key)`: 특정 키의 값을 조회합니다.

에이전트 생성 시 `store=InMemoryStore()`를 전달하면, `ToolRuntime`을 통해 도구에서 스토어에 접근할 수 있습니다.

==== 사용자별 네임스페이스 (context_schema + runtime.context)

실전에서는 `user_id`로 네임스페이스를 분리해 멀티 테넌트를 지원합니다. `context_schema`로 컨텍스트 클래스를 선언하고, 도구 안에서 `runtime.context.user_id`로 안전하게 접근합니다. Pydantic/dataclass 인스턴스는 그대로 저장하지 말고 `dict(user_info)`처럼 _dict로 캐스팅_한 뒤 `store.put`에 전달하는 것이 직렬화 호환성에 유리합니다.

#code-block(`````python
from dataclasses import dataclass
from langgraph.store.memory import InMemoryStore
from langchain.tools import tool, ToolRuntime

@dataclass
class Context:
    user_id: str

@tool
def remember_user(user_info: dict, runtime: ToolRuntime[Context]) -> str:
    """현재 사용자의 프로필을 저장합니다."""
    namespace = (runtime.context.user_id, "profile")
    runtime.store.put(namespace, "info", dict(user_info))  # dict 캐스팅
    return "saved"

store = InMemoryStore()
agent = create_agent(
    model=model,
    tools=[remember_user],
    store=store,
    context_schema=Context,
)

agent.invoke(
    {"messages": [{"role": "user", "content": "내 이름은 민지야"}]},
    context=Context(user_id="user_123"),
)
`````)

#tip-box[`store`를 에이전트에 전달하지 않으면 `runtime.store`가 `None`이 되어 도구에서 접근할 수 없습니다. 장기 메모리 도구를 추가했다면 `create_agent(..., store=...)` 인자를 빠뜨리지 않았는지 반드시 확인하세요.]

#tip-box[프로덕션에서는 `langgraph-checkpoint-postgres` 패키지의 `PostgresStore`(또는 `AsyncPostgresStore`)를 사용해 영구 저장과 시맨틱 검색을 함께 처리합니다. `InMemoryStore`와 동일한 인터페이스를 제공하므로 코드 변경 없이 교체할 수 있습니다.]

단기 메모리와 장기 메모리의 차이:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[단기 메모리 (Checkpointer)],
  text(weight: "bold")[장기 메모리 (Store)],
  [범위],
  [하나의 `thread_id` 내],
  [모든 세션에 걸쳐],
  [저장 대상],
  [대화 메시지 히스토리],
  [사용자 선호도, 학습 데이터],
  [수명],
  [세션 종료 시 (또는 영구)],
  [명시적 삭제 전까지 영구],
  [접근 방식],
  [자동 (에이전트 내부)],
  [도구를 통해 명시적],
)

== 5.6 스트리밍 모드

메모리 시스템을 완성했으니, 이제 에이전트의 _출력 전달 방식_을 다룹니다. 2장에서 `stream_mode="updates"`를 간단히 사용했는데, 실제로는 5가지 스트리밍 모드가 있으며 각각 다른 용도에 최적화되어 있습니다. 동기 호출에는 `stream()`, 비동기 환경에서는 `astream()`을 사용합니다.

에이전트의 실행 과정을 _실시간으로 관찰_할 수 있는 스트리밍 기능을 제공합니다. 용도에 따라 다양한 스트리밍 모드를 선택할 수 있습니다.

=== 스트리밍 모드 비교표

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[용도],
  [`values`],
  [각 단계의 전체 상태],
  [디버깅, 상태 추적],
  [`updates`],
  [각 노드의 업데이트만],
  [진행 상황 표시],
  [`messages`],
  [메시지 토큰 단위],
  [채팅 UI],
  [`custom`],
  [사용자 정의 이벤트],
  [커스텀 진행률],
)

=== stream_mode="custom" 참고

`stream_mode="custom"`은 사용자 정의 이벤트를 스트리밍하는 모드입니다. LangGraph의 `get_stream_writer()`를 사용하면 `create_agent`로 만든 에이전트의 _도구나 미들웨어 안에서도_ 커스텀 이벤트를 발행할 수 있습니다.

#code-block(`````python
from langgraph.config import get_stream_writer
from langchain.tools import tool

@tool
def long_running_task(query: str) -> str:
    """진행 상황을 스트림에 보고하는 작업."""
    writer = get_stream_writer()
    writer({"step": 1, "status": "fetching"})
    # ... 처리 로직 ...
    writer({"step": 2, "status": "done"})
    return "ok"

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "검색해줘"}]},
    stream_mode="custom",
):
    print(chunk)  # writer()로 발행한 dict가 그대로 전달됨
`````)

#tip-box[과거 일부 자료에서는 `stream_mode="custom"`이 `create_agent`에서 동작하지 않는다고 안내했지만, 현재 LangGraph는 `get_stream_writer()`를 통한 도구/미들웨어 내부 발행을 지원합니다. `StateGraph`의 `writer` 매개변수 주입 방식과 결과는 동일합니다.]

=== version="v2" 스트리밍과 GraphOutput

`agent.stream(..., version="v2")`를 지정하면 결과 청크가 _구조화된 이벤트_로 도착하고, `agent.invoke(..., version="v2")`는 `GraphOutput`을 반환합니다. `GraphOutput`은 `value`(최종 상태)와 `interrupts`(중단 정보) 두 속성을 제공해 HITL 흐름에서 활용도가 높습니다.

#code-block(`````python
# 스트림: type 필드로 이벤트 구분
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "search hello"}]},
    config={"configurable": {"thread_id": "t1"}},
    version="v2",
):
    if chunk["type"] == "updates":
        print("update:", chunk["data"])
    elif chunk["type"] == "messages":
        print("token:", chunk["data"][0].content)

# invoke: GraphOutput 반환
result = agent.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    config={"configurable": {"thread_id": "t1"}},
    version="v2",
)
print(result.value)       # 최종 상태 dict
print(result.interrupts)  # 중단된 경우 Interrupt 리스트, 아니면 []
`````)

=== 토큰 누적 패턴 (chunk_position)

`stream_mode="messages"`로 토큰을 받을 때, 마지막 청크는 `chunk_position == "last"`로 표시됩니다. 이 시점에 누적된 도구 호출이나 `content_blocks`를 한 번에 처리하면 깔끔합니다.

#code-block(`````python
buffer = []
tool_calls = []
for chunk, meta in agent.stream(
    {"messages": [{"role": "user", "content": "검색해줘"}]},
    stream_mode="messages",
):
    buffer.append(chunk.content)
    if chunk.tool_calls:
        tool_calls.extend(chunk.tool_calls)
    if meta.get("chunk_position") == "last":
        print("최종 본문:", "".join(buffer))
        print("도구 호출:", tool_calls)
`````)

=== content_blocks 기반 reasoning 필터링

확장 사고(extended thinking)를 지원하는 모델(예: Claude Sonnet 4.6)에서는 `content_blocks`의 `type`을 검사해 추론 블록만 UI에서 따로 다룰 수 있습니다.

#code-block(`````python
for chunk, _ in agent.stream(payload, stream_mode="messages"):
    for block in getattr(chunk, "content_blocks", []) or []:
        if block["type"] == "reasoning":
            ui.show_reasoning(block["reasoning"])
        elif block["type"] == "text":
            ui.show_answer(block["text"])
`````)

=== 다중 stream_mode와 인터럽트 캡처

`stream_mode`에 리스트를 전달하면 각 청크가 `(mode, payload)` 튜플로 도착합니다. HITL이 결합된 흐름에서는 `"__interrupt__"` 이벤트를 별도로 받아 사람의 결정을 기다릴 수 있습니다.

#code-block(`````python
for mode, payload in agent.stream(
    {"messages": [{"role": "user", "content": "이메일 보내줘"}]},
    config={"configurable": {"thread_id": "t1"}},
    stream_mode=["messages", "updates"],
):
    if mode == "updates" and "__interrupt__" in payload:
        interrupt = payload["__interrupt__"]
        # 사용자 승인 UI 띄우고 Command(resume=...)로 재개
`````)

#tip-box[서브그래프 이벤트도 함께 받고 싶다면 `subgraphs=True`를 지정하세요. 반대로 토큰 스트리밍이 필요 없을 때는 `disable_streaming=True`(또는 모델 생성 시 `streaming=False`)로 비용을 줄일 수 있습니다.]

#chapter-summary-header()

이 노트북에서 학습한 내용을 정리합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[구현],
  text(weight: "bold")[설명],
  [_단기 메모리_],
  [`InMemorySaver` + `thread_id`],
  [하나의 대화 세션 내 컨텍스트 유지],
  [_세션 격리_],
  [다른 `thread_id` 사용],
  [독립된 대화 세션 관리],
  [_메시지 트리밍_],
  [`trim_messages` + 미들웨어],
  [토큰 예산 내 메시지 제한],
  [_장기 메모리_],
  [`InMemoryStore` + `ToolRuntime`],
  [대화 간 지속되는 사용자 데이터],
  [_스트리밍 (values)_],
  [`stream_mode="values"`],
  [각 단계의 전체 상태 스냅샷],
  [_스트리밍 (updates)_],
  [`stream_mode="updates"`],
  [노드별 업데이트 확인],
  [_스트리밍 (messages)_],
  [`stream_mode="messages"`],
  [토큰 단위 실시간 출력],
  [_스트리밍 (custom)_],
  [`stream_mode="custom"`],
  [LangGraph `StateGraph` 수준에서만 사용 가능],
)

_핵심 포인트:_
- 단기 메모리는 `thread_id`로 격리되며, 같은 세션 내에서만 컨텍스트가 유지됩니다.
- 장기 메모리는 `InMemoryStore`를 통해 세션 간에 공유됩니다.
- `stream_mode="values"`는 각 단계의 전체 상태를 반환하여 디버깅에 유용합니다.
- `stream_mode="custom"`은 `create_agent`에서는 직접 사용할 수 없으며, LangGraph의 `StateGraph` API가 필요합니다.
- 스트리밍 모드를 적절히 선택하면 사용자 경험을 크게 향상시킬 수 있습니다.

이 장에서는 에이전트의 "기억력"과 "전달력"을 완성했습니다. 다음 장에서는 에이전트 실행 파이프라인의 각 단계에 _훅_을 삽입하는 미들웨어 시스템과, 안전하지 않은 입출력을 차단하는 가드레일 패턴을 다룹니다.

