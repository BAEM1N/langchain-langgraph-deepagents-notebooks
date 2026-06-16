// Auto-generated from 14_fault_tolerance.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "Fault Tolerance", subtitle: "RetryPolicy, Timeout, Error Handler")

== Learning goals

- Distinguish LangGraph _retries_, _timeouts_, and _error handlers_
- Use `RetryPolicy` to absorb transient failures
- Observe async node timeout and `NodeTimeoutError` safely
- Route fallback recovery with `error_handler` and `Command`
- Understand `set_node_defaults()` and node-level override precedence

== Overview

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Feature],
  text(weight: "bold")[Core API],
  text(weight: "bold")[Use case],
  [_Retries_],
  [`RetryPolicy`],
  [Network/rate-limit/transient 5xx failures],
  [_Timeouts_],
  [`timeout=...`, `NodeTimeoutError`],
  [External calls that hang too long],
  [_Error handling_],
  [`error_handler=...`, `Command`],
  [Recovery and fallback routing],
  [_Graph defaults_],
  [`set_node_defaults(...)`],
  [Shared policy across many nodes],
)

This chapter reproduces failures with deterministic fake nodes instead of relying on slow or unreliable external APIs.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"
`````)

#code-block(`````python
# LangSmith — graph runs are logged when LANGSMITH_TRACING=true.
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGSMITH_PROJECT", "langchain-langgraph-deepagents-notebooks")
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.types import RetryPolicy, Command
from langgraph.errors import NodeError, NodeTimeoutError
`````)

== 1) Retries — let the system absorb transient failures

Attach `RetryPolicy` to work that is safe to retry with the same input. This fake node fails once, then succeeds on the second attempt.

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

== 2) Timeouts — stop async nodes that hang

LangGraph node timeouts are supported for _async nodes_. Sync Python functions cannot be safely cancelled in-process, so keep timeout demonstrations async.

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

== 3) Error handlers — route failures to a fallback path

When retries are exhausted, or when a failure should not be retried, `error_handler` can return `Command(update=..., goto=...)` to update state and continue on a recovery path.

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

== 4) Graph defaults — shared policy and node overrides

Use `set_node_defaults()` when multiple nodes share retry or timeout policy. A node-level setting overrides the graph default when both are present.

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

== Operations checklist

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Question],
  text(weight: "bold")[Decision criteria],
  [_Is it safe to retry?_],
  [Idempotency and duplicate write/charge risk],
  [_How long should the node wait?_],
  [User SLA, external API p95, graph-level timeout],
  [_Does failure need compensation?_],
  [Cancel, refund, fallback, user-facing notice],
  [_Where should defaults live?_],
  [Global defaults versus node-specific overrides],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- LangGraph Fault Tolerance: https://docs.langchain.com/oss/python/langgraph/fault-tolerance
- LangGraph Durable Execution: ../../docs/langgraph/06-durable-execution.md
- LangGraph Graph API: ../../docs/langgraph/19-graph-api.md
