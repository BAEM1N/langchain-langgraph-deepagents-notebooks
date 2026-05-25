// Auto-generated from 12_durable_execution.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "durable execution")

== Learning Objectives

- Understand the concept and necessity of durable execution (Durable Execution)
- Know the relationship between checkpointer and durable execution
- Learn how to ensure durability with `@entrypoint` + `@task`
- Understand the difference between endurance modes (exit, async, sync)
- Know the recovery process in failure scenarios

== 12.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 12.2 durable execution Concept

A process called _durable execution(Durable Execution)_ or workflow saves progress state at key points,
This is a technique that allows you to pause and then later interrupt at the exact resume position.

_Why do you need it?_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Scenario],
  text(weight: "bold")[Description],
  [Disaster recovery],
  [In case of server failure, instead of restarting from the beginning, interrupt point resume],
  [state persistent],
  [Preserve intermediate results of workflow with long running time],
  [Human-in-the-loop],
  [Keep state while waiting for human approval],
)

LangGraph supports durable execution via checkpointer(checkpointer).

== 12.3 Core requirements

Implementing durable execution requires three elements:

+ _Persistence Layer_
Log state progressing workflow through checkpointer.
Example: `InMemorySaver` (for development), `PostgresSaver` (for production)

+ _Thread ID (Thread ID)_
workflow A unique ID that tracks the execution history of the instance.
Using the same `thread_id`, you can continue resume from previous executions.

+ *`@task` wrapping (task wrapping)*
Non-deterministic operations and side-effect operations
Wrap it in `@task` to prevent re-execution on resume.

== 12.4 Endurance Mode Comparison

LangGraph provides three modes that balance performance and consistency:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mode],
  text(weight: "bold")[Action],
  text(weight: "bold")[Trade-offs],
  [`"exit"`],
  [Persist only on completion/error/interrupt],
  [Highest performance, no intermediate recovery],
  [`"async"`],
  [Next Steps Persist asynchronously while running],
  [Good balance, slight crash risk],
  [`"sync"`],
  [Next Steps Persist with pre-execution synchronization],
  [Maximum durability, performance cost],
)

For most use cases, the default mode (`"exit"`) is sufficient.
For mission-critical workflow, consider `"sync"` mode.

== 12.5 Problematic code

If you do not wrap side effects (API calls, etc.) in `@task`,
The same API call may be executed again at resume.

#code-block(`````python
# Problematic approach: calling side effects directly
print("""# BAD: Side effects not wrapped in `@task`
def call_api(state: State):
    # This API call will be executed again on resume!
    result = requests.get(state['url']).text[:100]
    return {"result": result}""")
print("Problem:")
print("1. API is called again at resume after failure")
print("2. Non-deterministic results may vary")
print("3. Side effects may occur due to duplicate requests.")
`````)

== 12.6 Improvements to \@task

If you wrap the side effect with the `@task` decorator,
At resume, restore previous results from checkpoint to prevent re-execution.

#code-block(`````python
# Improved approach: wrapping side effects with @task
print("""# GOOD: Wrap side effects with @task
from langgraph.func import task

@task
def _make_request(url: str):
    return requests.get(url).text[:100]

def call_api(state: State):
    # Each request is executed as a separate `@task`
    requests = [_make_request(url) for url in state['urls']]
    results = [req.result() for req in requests]
    return {"results": results}""")
print("Improvement effect:")
print("1. Restore results from checkpoint at resume")
print("2. Avoid duplicate API calls")
print("3. Each `@task` is tracked independently")
`````)

== 12.7 Durability in Graph API

Connecting checkpointer to StateGraph will automatically save state after each node execution.

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

# Execution (track execution by thread_id)
config = {"configurable": {"thread_id": "doc-1"}}
result = graph.invoke({"topic": "LangGraph"}, config)
print("result:", result)
`````)

== 12.8 Durability in Functional API

By combining `@entrypoint` and `@task`, durability can be guaranteed even in Functional API.

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
print("result:", result)
`````)

== 12.9 Failover Scenario

If you rerun with the same `thread_id`, it restores the previous state from the checkpoint and continues execution.

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
    print(f"  step_one executed (call count: {call_count})")
    return {"data": state["data"].upper(), "step": 1}


def step_two(state: PipelineState) -> dict:
    print("  step_two executed")
    return {"result": f"Processed: {state['data']}", "step": 2}


recovery_saver = InMemorySaver()

builder = StateGraph(PipelineState)
builder.add_node("step_one", step_one)
builder.add_node("step_two", step_two)
builder.add_edge(START, "step_one")
builder.add_edge("step_one", "step_two")
builder.add_edge("step_two", END)

pipeline = builder.compile(checkpointer=recovery_saver)

# first run
config = {"configurable": {"thread_id": "recovery-1"}}
print("=== First Run ===")
result = pipeline.invoke(
    {"data": "hello", "step": 0, "result": ""},
    config
)
print(f"Result: {result}")

# Check checkpoint
print("=== Restore state from checkpoint ===")
saved = pipeline.get_state(config)
print(f"Saved state: {saved.values}")
print(f"Total step_one call count: {call_count}")
`````)

== 12.10 resume Starting point

When workflow becomes resume, the starting point varies depending on the API:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[API],
  text(weight: "bold")[resume Starting point],
  text(weight: "bold")[Description],
  [StateGraph],
  [Start of interrupt node],
  [Rerun that node from scratch],
  [Subgraph],
  [Parent node → interrupt node in subgraph],
  [Start from the parent node and then move to the corresponding node in the subgraph],
  [Functional API],
  [`\@entrypoint` Start],
  [Starting at `\@entrypoint`, `\@task` results restored from cache],
)

_Key differences:_
- StateGraph: Node unit resume (re-execute only interrupt nodes)
- Functional API: Rerun from `@entrypoint`, but use cache results for completed `@task`

== 12.11 Production Durability Pattern

Best practices for ensuring durability in a production environment:

+ _Implementation of idempotent operation_
Design the results to be the same even when executing the same request multiple times.
Prevent duplicate processing by utilizing an idempotency key.

+ _Isolate Side Effects_
Separate side effects such as API calls, file writes, etc. into individual `@task`.
Make a clear distinction between pure logic and side effects.

+ _Non-deterministic code wrapping_
Non-deterministic operations such as random number generation and timestamps are also wrapped in `@task`.

+ _Use persistent storage_
Developed by: `InMemorySaver`
Production: `PostgresSaver` or external database

+ _thread ID Management_
Give each workflow instance a unique `thread_id`.
Upon failover, use resume with the same `thread_id`.

== 12.12 Per-node fault tolerance --- `TimeoutPolicy` + `heartbeat`

Durable execution preserves _how far_ a run has progressed via checkpoints. The fault-tolerance features in LangGraph 1.2 control _when to give up and how to compensate_ at the level of an individual node attempt. `add_node(..., timeout=TimeoutPolicy(...))` applies a per-attempt time budget; on overrun, `NodeTimeoutError` is raised and the retry policy (if any) advances to the next attempt. Partial writes from the failing attempt are discarded.

Long-running nodes combine `Runtime.heartbeat()` with `refresh_on="heartbeat"` to refresh the idle timeout.

#code-block(`````python
from langgraph.func import task
from langgraph.runtime import Runtime
from langgraph.types import TimeoutPolicy

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
`````)

== 12.13 Graceful shutdown --- `RunControl` / `GraphDrained`

To stop a long-running graph cleanly on signals like SIGTERM --- finishing the current superstep and persisting a checkpoint instead of force-killing the process --- use `RunControl.request_drain()`. When drain is requested, the run stops with `GraphDrained` and can later be resumed with the _same config_. Inside a node, branch on `Runtime.drain_requested` to add safe-shutdown handling.

#code-block(`````python
from langgraph.runtime import RunControl, Runtime
from langgraph.errors import GraphDrained

# 1) Caller side --- request drain on an external signal (e.g., SIGTERM)
control = RunControl()
control.request_drain("sigterm")

try:
    result = graph.invoke(inputs, config, control=control)
except GraphDrained as e:
    print(f"Drained: {e.reason}")
    # The checkpoint has already been saved.

# Resume with the same config
graph.invoke(None, config)

# 2) Inside a node --- detect the drain signal directly
async def my_node(state: State, runtime: Runtime) -> dict:
    if runtime.drain_requested:
        return {"status": "skipped"}
    # ... normal processing
    return {"status": "done"}
`````)

#tip-box[Drain is distinct from interrupt. Interrupt is an _application-level_ signal that pauses to await user input; drain is an _operational_ signal that stops cleanly at a superstep boundary. Combining both means rolling deploys and maintenance windows never lose in-flight progress.]

== 12.14 DeltaChannel (beta) --- checkpoint size optimization

Standard checkpoints persist the _full_ value of every channel on each superstep. For append-heavy channels (e.g., message lists), storage grows quickly on long-lived threads. `DeltaChannel` (introduced in `langgraph≥1.2`) stores incremental deltas instead, and writes a full snapshot every `snapshot_frequency` steps to bound reconstruction cost.

#code-block(`````python
from typing import Annotated, Sequence
from typing_extensions import TypedDict
from langgraph.channels import DeltaChannel

def list_reducer(state: list, writes: Sequence[list]) -> list:
    # bulk reducer signature: (current_state, sequence_of_writes) -> new_state
    result = list(state)
    for write in writes:
        result.extend(write)
    return result

class State(TypedDict):
    messages: Annotated[
        list[str],
        DeltaChannel(list_reducer, snapshot_frequency=5),
    ]
`````)

#warning-box[`DeltaChannel` is a `langgraph≥1.2` beta feature. The reducer must be associative and runs _at reconstruction time, not at write time_. Measure storage, recovery latency, and migration cost before adopting it in production. Treat `DeltaChannel` as a _storage optimization_ and `TimeoutPolicy` / `error_handler` as _failure-recovery controls_ --- they are independent dimensions of the durability design.]

== 12.15 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Concepts],
  [Durability concept],
  [Execution technique that can resume at interrupt point],
  [Core Requirements],
  [persistence layer + thread ID + `\@task` wrapping],
  [Endurance Mode],
  [exit (default), async (balanced), sync (maximum durability)],
  [\@task],
  [Prevent replay by wrapping side effects],
  [Graph API],
  [`checkpointer` Automatic saving for each node by connection],
  [Functional API],
  [Durability guaranteed with `\@entrypoint` + `\@task`],
  [Disaster recovery],
  [At checkpoint with same `thread_id` resume],
  [Node timeout],
  [`TimeoutPolicy(idle_timeout=..., refresh_on="heartbeat")` per-attempt budget],
  [Graceful shutdown],
  [`RunControl.request_drain()` → `GraphDrained` → resume with same config],
  [DeltaChannel (beta)],
  [`langgraph≥1.2`. Store deltas + `snapshot_frequency` to bound reconstruction],
)

=== Next Steps
→ Proceed to _#link("13_api_guide_and_pregel.ipynb")[13. API Selection Guide and Pregel]_!

#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langgraph/06-durable-execution.md")[Durable Execution]
