// Auto-generated from 14_fault_tolerance.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "Fault Tolerance", subtitle: "RetryPolicy, Timeout, Error Handler")

== 학습 목표
#learning-objectives([LangGraph의 _재시도_, _타임아웃_, _에러 핸들러_를 구분한다], [`RetryPolicy`로 일시적 장애를 자동 재시도한다], [async node timeout과 `NodeTimeoutError`를 안전하게 관찰한다], [`error_handler`와 `Command`로 실패 후 보정 경로를 구성한다], [`set_node_defaults()`와 노드별 설정의 우선순위를 이해한다])

== 개요

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[사용 상황],
  [_Retries_],
  [`RetryPolicy`],
  [네트워크/Rate limit/일시적 5xx],
  [_Timeouts_],
  [`timeout=...`, `NodeTimeoutError`],
  [외부 호출이 오래 멈추는 경우],
  [_Error handling_],
  [`error_handler=...`, `Command`],
  [실패 후 보정·fallback 라우팅],
  [_Graph defaults_],
  [`set_node_defaults(...)`],
  [여러 노드에 공통 정책 적용],
)

이 장은 외부 API를 실제로 느리게 만들지 않고, deterministic fake node로 장애를 재현합니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.types import RetryPolicy, Command
from langgraph.errors import NodeError, NodeTimeoutError
`````)

== 1) 재시도 — transient failure를 시스템이 흡수

실패해도 같은 입력으로 다시 시도해도 안전한 작업에는 `RetryPolicy`를 붙입니다. 아래 node는 첫 호출에서만 실패하고 두 번째 호출에서 성공합니다.

#code-block(`````python
class FaultState(TypedDict):
    result: str
    attempts: int
    error: str

calls = {"n": 0}

def flaky_api(state: FaultState) -> dict:
    calls["n"] += 1
    if calls["n"] < 2:
        raise ValueError("temporary network error")
    return {"result": "ok", "attempts": calls["n"]}
`````)

#code-block(`````python
retry_graph = (
    StateGraph(FaultState)
    .add_node("flaky_api", flaky_api, retry_policy=RetryPolicy(
        max_attempts=3, initial_interval=0.01, jitter=False, retry_on=ValueError,
    ))
    .add_edge(START, "flaky_api")
    .add_edge("flaky_api", END)
    .compile()
)
`````)

#code-block(`````python
retry_result = retry_graph.invoke({"result": "", "attempts": 0, "error": ""})
print(retry_result)
assert retry_result["attempts"] == 2
`````)

== 2) 타임아웃 — 오래 멈춘 async node 중단

LangGraph의 node timeout은 _async node_에서 안전하게 동작합니다. sync Python 함수는 같은 프로세스에서 강제 취소할 수 없으므로 timeout 대상이 아닙니다.

#code-block(`````python
import asyncio

async def slow_api(state: FaultState) -> dict:
    await asyncio.sleep(0.05)
    return {"result": "too late"}

timeout_graph = (
    StateGraph(FaultState)
    .add_node("slow_api", slow_api, timeout=0.01)
    .add_edge(START, "slow_api")
    .add_edge("slow_api", END)
    .compile()
)
`````)

#code-block(`````python
try:
    await timeout_graph.ainvoke({"result": "", "attempts": 0, "error": ""})
except NodeTimeoutError as exc:
    print(type(exc).__name__, str(exc).split("(")[0].strip())
`````)

== 3) 에러 핸들러 — 실패를 fallback 경로로 라우팅

재시도를 모두 소진했거나, 재시도하면 안 되는 실패라면 `error_handler`가 보정 경로를 만들 수 있습니다. 핸들러는 `Command(update=..., goto=...)`로 상태 업데이트와 다음 노드를 동시에 지정합니다.

#code-block(`````python
def broken_service(state: FaultState) -> dict:
    raise RuntimeError("downstream unavailable")

def recover(state: FaultState, error: NodeError) -> Command:
    return Command(
        update={"error": str(error.error), "result": "fallback"},
        goto="finalize",
    )

def finalize(state: FaultState) -> dict:
    return {"result": state["result"] + " | finalized"}
`````)

#code-block(`````python
handler_graph = (
    StateGraph(FaultState)
    .add_node("broken_service", broken_service, error_handler=recover)
    .add_node("finalize", finalize)
    .add_edge(START, "broken_service")
    .add_edge("finalize", END)
    .compile()
)
handler_result = handler_graph.invoke({"result": "", "attempts": 0, "error": ""})
print(handler_result)
`````)

== 4) Graph defaults — 공통 정책과 노드별 override

동일한 retry/timeout 정책을 여러 노드에 붙일 때는 `set_node_defaults()`를 먼저 선언합니다. 특정 노드에 별도 정책을 주면 노드 설정이 우선합니다.

#code-block(`````python
def stable_node(state: FaultState) -> dict:
    return {"result": "stable"}

common_retry = RetryPolicy(
    max_attempts=2, initial_interval=0.01, jitter=False, retry_on=ValueError,
)
default_graph = (
    StateGraph(FaultState)
    .set_node_defaults(retry_policy=common_retry)
    .add_node("stable", stable_node)
    .add_edge(START, "stable")
    .add_edge("stable", END)
    .compile()
)
print(default_graph.invoke({"result": "", "attempts": 0, "error": ""}))
`````)

== 운영 체크리스트

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[질문],
  text(weight: "bold")[판단 기준],
  [_재시도해도 안전한가?_],
  [멱등성, 중복 결제/중복 쓰기 위험 확인],
  [_얼마나 기다릴 것인가?_],
  [사용자 SLA, 외부 API p95, graph 전체 timeout],
  [_실패 후 보정이 필요한가?_],
  [취소, 환불, fallback, 사용자 안내],
  [_어디까지 기본 정책으로 둘 것인가?_],
  [전역 defaults vs 노드별 override],
)


#references-box[
- LangGraph Fault Tolerance: https://docs.langchain.com/oss/python/langgraph/fault-tolerance
- LangGraph Durable Execution: ../docs/langgraph/06-durable-execution.md
- LangGraph Graph API: ../docs/langgraph/19-graph-api.md
]
#chapter-end()
