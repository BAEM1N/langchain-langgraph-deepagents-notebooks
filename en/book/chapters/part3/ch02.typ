// Auto-generated from 02_graph_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Graph API Basics", subtitle: "Creating workflow with StateGraph")

== Learning Objectives

Understand StateGraph, nodes, edges, conditional branches, and state reducers.

== 2.1 Environment Setup

Load the LLM model and required modules.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 2.2 StateGraph basic structure

The basic flow using StateGraph is as follows:

+ Create a graph builder with `StateGraph(State)` — `state_schema`
+ `add_node()` — Node (function) registration
+ `add_edge()` — Connections between nodes
+ `compile()` — Create an executable graph
+ `invoke()` — Graph execution
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
#code-block(`````python

`````)

== 2.3 state Reducer

Specifies the state update method with `Annotated`.

=== What is a reducer?

- The reducer determines _how_ the fields in state are updated.
- No reducer: simple override
- `operator.add`: Accumulate (append) list items
- Reducers can also be defined as custom functions.

== 2.4 Conditional Edge

Branch to another node according to state.

- `add_conditional_edges(source, routing_function)` — The return value of the routing function is the next node name.
- Routing functions can be visualized using the `Literal` type hint.
START → classify → [route] → weather → END
→ math    → END
→ general → END
#code-block(`````python

`````)

== 2.5 Message-based state

Use `MessagesState` as appropriate for LLM agent.

- `MessagesState` is a predefined state that includes `messages: Annotated[list[AnyMessage], add_messages]`
- `add_messages` Reducer automatically accumulates the message list
- Naturally add LLM responses to message history

== 2.6 Input/Output Schema

Separate the graph's input and output from its internal state.

- `StateGraph(InternalState, input_schema=InputSchema, output_schema=OutputSchema)`
- Input schema: Includes only data received from external sources
- Output schema: Includes only data exported externally
- Internal state: Includes fields for intermediate processing (not exposed to the outside)

== 2.7 add_node() advanced options

`add_node()` accepts production-grade policy parameters for per-node control.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Description],
  [`retry_policy`],
  [`RetryPolicy(max_attempts=..., retry_on=...)` — auto retry on failure],
  [`timeout`],
  [`TimeoutPolicy(run_timeout=..., idle_timeout=...)` — async nodes only; raises `NodeTimeoutError`],
  [`cache_policy`],
  [`CachePolicy(ttl=..., key_func=...)` — input-hash result caching; requires `cache=` at compile],
  [`error_handler`],
  [Callback receiving `NodeError`, returning a recovery `Command`],
  [`defer`],
  [Wait until other pending tasks complete — useful for asymmetric fan-out/fan-in],
)

#code-block(`````python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import RetryPolicy, CachePolicy

builder.add_node(
    "expensive_node",
    expensive_node,
    retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError),
    cache_policy=CachePolicy(ttl=3),
)
graph = builder.compile(cache=InMemoryCache())
`````)

== 2.8 Runtime context with context_schema

Pass dependencies that aren't part of graph state (LLM providers, user IDs, DB handles) via `context_schema` + `Runtime[ContextSchema]`. Context lives outside the checkpointed state.

- `StateGraph(State, context_schema=ContextSchema)` declares the context schema
- Node signature `runtime: Runtime[ContextSchema]` exposes `runtime.context`
- Invoke with `graph.invoke(inputs, context={...})`
- `runtime.execution_info` exposes `attempt`, `thread_id`, `run_id`, checkpoint info
- `runtime.server_info` carries LangGraph Server assistant/graph/user info
- `runtime.drain_requested` signals graceful shutdown

#code-block(`````python
from dataclasses import dataclass
from langgraph.runtime import Runtime

@dataclass
class ContextSchema:
    llm_provider: str = "openai"
    user_id: str | None = None

def node(state: State, runtime: Runtime[ContextSchema]):
    if runtime.execution_info.attempt > 1:
        # fallback on retry
        ...
    print("thread:", runtime.execution_info.thread_id)
    return {"results": "processed"}

graph = StateGraph(State, context_schema=ContextSchema).compile()
graph.invoke({...}, context={"llm_provider": "anthropic", "user_id": "u-1"})
`````)

== 2.9 Send and Command.PARENT

`Send("worker", {...})` returned from a conditional-edge function spawns a worker instance with its own state at runtime — the Map step of Map-Reduce. From inside a subgraph, `Command(graph=Command.PARENT, goto="...", update={...})` routes to a parent-graph node.

#code-block(`````python
from langgraph.types import Send, Command

def fan_out(state):
    return [Send("worker", {"task": t}) for t in state["tasks"]]

def sub_node(state):
    return Command(
        graph=Command.PARENT,
        goto="parent_aggregator",
        update={"sub_result": state["value"]},
    )
`````)

== 2.10 Summary

We summarize what we learned in this Note book.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [_StateGraph_],
  [`state_schema` based graph builder],
  [_Node_],
  [Processing units defined as Python functions],
  [_Edge_],
  [Fixed connection between nodes (`add_edge`)],
  [_Conditional Edge_],
  [state based dynamic branch (`add_conditional_edges`)],
  [_Reducer_],
  [Define state accumulation method with `Annotated` + `operator.add`],
  [_MessagesState_],
  [Predefined state for LLM dialog],
  [_Input/Output Schema_],
  [Separation of internal state and external input/output],
)

=== Next Steps
→ _#link("./03_functional_api.ipynb")[03_functional_api.ipynb]_: Learn Functional API.
