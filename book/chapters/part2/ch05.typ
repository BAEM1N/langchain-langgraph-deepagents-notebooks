// Auto-generated from 05_memory_and_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "메모리와 스트리밍")

LangChain v1 에이전트의 _메모리 시스템_과 _스트리밍 모드_를 학습합니다.

== 학습 목표
#learning-objectives([_단기 메모리(Short-term Memory):_ `InMemorySaver`로 `thread_id` 기반 대화 상태를 유지하는 방법을 이해합니다.], [_장기 메모리(Long-term Memory):_ `InMemoryStore`로 대화 간에 지속되는 메모리를 구현합니다.], [_메시지 트리밍:_ 긴 대화에서 토큰 예산 내로 메시지를 제한하는 방법을 배웁니다.], [_스트리밍 모드:_ `values`, `updates`, `messages`, `custom` 등 다양한 스트리밍 모드의 차이를 이해합니다.])

== 5.1 환경 설정

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

== 5.2 단기 메모리: InMemorySaver

단기 메모리는 _하나의 대화 세션_ 내에서 이전 메시지를 기억하는 메커니즘입니다.

- `InMemorySaver`는 체크포인터(checkpointer)로서 에이전트의 상태를 메모리에 저장합니다.
- `thread_id`로 서로 다른 대화 세션을 구분합니다.
- 같은 `thread_id`를 사용하면 이전 대화 컨텍스트가 유지됩니다.

== 5.3 다른 thread_id로 독립된 대화

서로 다른 `thread_id`를 사용하면 완전히 _독립된 대화 세션_이 생성됩니다. 이전 세션의 컨텍스트는 공유되지 않습니다.

== 5.4 메시지 트리밍

대화가 길어지면 토큰 수가 증가하여 비용과 성능에 영향을 줍니다. _메시지 트리밍_으로 토큰 예산 내에서 가장 관련성 높은 메시지만 유지할 수 있습니다.

- `trim_messages`: 최근 N개의 메시지 또는 토큰 예산 내의 메시지만 유지합니다.
- `strategy="last"`: 가장 최근 메시지를 우선 유지합니다.
- `include_system=True`: 시스템 메시지는 항상 포함합니다.

== 5.5 장기 메모리: InMemoryStore

장기 메모리는 _대화 세션 간에 지속되는_ 정보를 저장합니다.

- `InMemoryStore`는 키-값 저장소로서 사용자 선호도, 설정 등을 저장합니다.
- 도구의 `ToolRuntime` 파라미터로 스토어에 접근할 수 있습니다.
- `thread_id`와 무관하게 모든 세션에서 동일한 데이터에 접근 가능합니다.

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

=== namespace 설계 패턴

`store.put(namespace, key, value)` 의 `namespace` 는 튜플로 다층 분리가 가능합니다. _사용자별로 격리하려면 `runtime.context.user_id` 를 namespace 의 일부로 포함_시키는 것이 권장 패턴입니다.

#code-block(`````python
namespace = ("preferences", runtime.context.user_id)  # 사용자별 격리
`````)

이렇게 하지 않으면 모든 사용자가 같은 메모리 영역을 공유하게 됩니다.

=== Production 환경 — PostgreSQL Store

프로덕션에서는 메모리 휘발성이 없는 `PostgresStore` 를 권장합니다.

#code-block(`````bash
pip install langgraph-checkpoint-postgres
`````)

#code-block(`````python
from langgraph.store.postgres import PostgresStore
store = PostgresStore.from_conn_string("postgresql://...")
`````)

#warning-box[⚠️ _주의_: `create_agent(..., store=store)` 로 명시적으로 전달하지 않으면 도구 내부의 `runtime.store` 는 `None` 이 됩니다. 도구 호출이 실패하므로 반드시 store 를 전달하세요.]

== 5.6 스트리밍 모드

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

=== version="v2" + GraphOutput — 백엔드 스트리밍 표준 패턴

LangChain v1 의 새 스트리밍 API 는 `version="v2"` 플래그를 사용합니다. 이 모드에서는 `invoke()` 가 dict 가 아닌 _`GraphOutput`_ 객체를 반환하며, `.value`(최종 상태)와 `.interrupts`(HITL 인터럽트 리스트)로 접근합니다.

`stream(..., version="v2")` 는 각 청크에 `type` 필드를 포함하므로 `updates`/`messages`/`custom` 을 한 스트림에서 식별 가능합니다.

=== tool_calls 누적과 chunk_position == "last"

토큰 단위 스트리밍에서 tool call 인자는 청크별로 부분 JSON 으로 도착합니다. _마지막 청크_에서만 완전한 인자 형태가 보장되므로, `chunk_position == "last"` 가 표시되는 시점까지 누적해야 안전합니다.

=== content_blocks 로 reasoning vs text 분리

Claude / OpenAI o-series 등 reasoning 모델은 메시지 내용을 _블록 단위_로 반환합니다. `msg.content_blocks` 로 `text` / `reasoning` / `tool_use` 를 분리해 UI 에서 다르게 렌더링할 수 있습니다 (예: reasoning 은 접기, text 만 강조).

=== 멀티 모드 스트리밍 · 서브그래프 · 토글

`stream_mode` 는 리스트로 전달하면 여러 모드를 동시에 받을 수 있고, 각 청크가 `(mode, data)` 튜플로 도착합니다. HITL 인터럽트는 `"__interrupt__"` 라는 특수 키로 `updates` 모드에 섞여 옵니다.

- `subgraphs=True` — 멀티 에이전트/서브그래프 사용 시 자식 그래프의 청크까지 받습니다.
- `model = ChatOpenAI(model="...", disable_streaming=True)` — 모델 자체의 토큰 스트리밍을 끄고 싶을 때.

=== stream_mode="custom" — get_stream_writer 로 도구에서 진행률 발행

`stream_mode="custom"` 은 도구 또는 미들웨어 안에서 _임의의 진행률·중간 결과_를 스트림으로 흘려보내는 모드입니다. `create_agent` 로 만든 에이전트에서도 동작하며, 도구 내부에서 `get_stream_writer()` 로 writer 를 얻어 호출하면 됩니다.

#code-block(`````python
from langgraph.config import get_stream_writer
from langchain.tools import tool

@tool
def long_running_search(query: str) -> str:
    """진행률을 스트림으로 보고하는 검색 도구."""
    writer = get_stream_writer()
    writer({"event": "search_start", "query": query})
    # ... 실제 검색 로직 ...
    writer({"event": "search_done", "hits": 42})
    return f"'{query}' 결과 42건"

# 스트리밍 — stream_mode="custom" 으로 받기
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "LangChain 문서 검색"}]},
    stream_mode="custom",
):
    print(chunk)
`````)

여러 모드를 동시에 받으려면 `stream_mode=["updates", "custom"]` 처럼 리스트로 지정하면 됩니다.

#chapter-summary-header()

이 노트북에서 학습한 내용:

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
  [namespace 에 `runtime.context.user_id` 포함으로 사용자별 격리],
  [_Production Store_],
  [`PostgresStore` (`langgraph-checkpoint-postgres`)],
  [영속화된 장기 메모리],
  [_스트리밍 (values/updates/messages)_],
  [`stream_mode=...`],
  [단계 전체 / 노드별 / 토큰 단위],
  [_스트리밍 (custom)_],
  [`get_stream_writer()`],
  [도구 안에서 진행률 직접 발행],
  [_버전 v2_],
  [`version="v2"` + `GraphOutput`],
  [`result.value` / `result.interrupts` 로 접근],
  [_tool_calls 누적_],
  [`chunk_position == "last"`],
  [AIMessageChunk + 연산자로 누적],
  [_content_blocks_],
  [`msg.content_blocks`],
  [reasoning / text / tool_use 분리],
  [_멀티 모드_],
  [`stream_mode=["updates", "messages"]` + `"__interrupt__"`],
  [HITL 인터럽트 캡처],
)

_핵심 포인트:_
- 단기 메모리는 `thread_id`로 격리되며, 같은 세션 내에서만 컨텍스트가 유지됩니다.
- 장기 메모리는 `("preferences", user_id)` 처럼 namespace 의 일부에 `user_id` 를 포함해 사용자별로 격리합니다.
- `store` 를 `create_agent` 에 전달하지 않으면 `runtime.store` 가 `None` 이라 도구가 실패합니다.
- `get_stream_writer()` 는 `create_agent` 안의 도구에서도 사용 가능합니다 — 별도 `StateGraph` 가 필요하지 않습니다.
- `version="v2"` 로 받은 결과는 `GraphOutput` — `result.value["messages"]` / `result.interrupts` 로 접근하세요.
- 토큰 스트리밍에서 tool_calls 의 args 는 `chunk_position == "last"` 시점까지 누적해야 완전합니다.
