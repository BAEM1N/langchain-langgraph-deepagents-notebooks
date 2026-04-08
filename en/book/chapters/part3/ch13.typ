// Auto-generated from 13_api_guide_and_pregel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#13. API Selection Guide and Pregel

== Learning Objectives

- Compare the differences between Graph API and Functional API
- The same agent is implemented in both APIs.
- Understand the internal structure of Pregel runtime
- superstep Know the execution model
- Establish criteria for selecting the appropriate API for the project

== 13.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 13.2 Graph API vs Functional API Overview

LangGraph provides two APIs for building agent workflow.
Both APIs run on top of the same Pregel runtime and can be used together in a single application.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [Abstraction method],
  [Graph composed of nodes and edges],
  [decorator-based function],
  [state Management],
  [Explicit management with TypedDict schema],
  [Local variables within function scope],
  [control flow],
  [Conditional Edge, Routing],
  [General Python control statements (if/else, for)],
  [Visualization],
  [Automatic visualization of graph structure],
  [LIMITED],
  [Boilerplate],
  [Relatively many],
  [minimize],
)

== 13.3 Quick Selection Guide

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Situation],
  text(weight: "bold")[Recommendation API],
  text(weight: "bold")[Reason],
  [Complex workflow visualization required],
  [Graph API],
  [Node/edge structure automatically generates diagram],
  [parallel execution path],
  [Graph API],
  [Multiple nodes naturally run in parallel],
  [multi-agent Team],
  [Graph API],
  [Clear separation of roles between agent],
  [Minimal changes to existing code],
  [Functional API],
  [Just add a decorator],
  [Simple Linear workflow],
  [Functional API],
  [Quick implementation without boilerplate],
  [Rapid Prototyping],
  [Functional API],
  [`state_schema` No definition required],
)

== 13.4 Graph API implementation

Write an essay → Implement scoring workflow with Graph API.

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
print("Graph API results:", result)
`````)

== 13.5 Functional API implementation

Implement the same essay workflow with Functional API.

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
print("Functional API results:", result)
`````)

== 13.6 Comparative analysis

Compare the two implementations above side by side:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [state Definition],
  [`TypedDict` schema required],
  [optional (possible local variables)],
  [node connection],
  [`add_edge()`, `add_conditional_edges()`],
  [Generic function call],
  [checkpointer],
  [`compile(checkpointer=...)`],
  [`\@entrypoint(checkpointer=...)`],
  [number of lines of code],
  [Relatively many],
  [Concise],
  [Visualization],
  [`graph.get_graph().draw_mermaid()` Support],
  [LIMITED],
  [parallel execution],
  [Natural support with edge structure],
  [`\@task` Support for parallel execution],
  [Debugging],
  [Check state per node in Studio],
  [Function-level tracing],
)

== 13.7 Combining two APIs

You can use both APIs in the same application.
A common pattern is to use the Graph API for complex multi-agent coordination, and the Functional API for simpler linear data-processing flows.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Use Case],
  text(weight: "bold")[Recommended API],
  [Complex multi-agent coordination],
  [Graph API],
  [Simple preprocessing or validation pipeline],
  [Functional API],
  [Need explicit routing and visualization],
  [Graph API],
  [Need minimal boilerplate over existing code],
  [Functional API],
)

#note-box[It is normal to start with the Functional API for a small prototype and migrate to the Graph API as the workflow becomes more complex. The reverse is also possible when a graph turns out to be overdesigned.]

== 13.8 Pregel Runtime Overview

_Pregel_ is the internal execution engine of LangGraph.
Compiling `StateGraph` or using `@entrypoint` creates a Pregel instance internally.

The name comes from Google's Pregel algorithm, which efficiently handles massively parallel graph computations.

_Core Components:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Components],
  text(weight: "bold")[Role],
  [_Actor_],
  [Read data from the channel and write the processing results to the channel],
  [_Channel_],
  [Responsible for data communication between actors],
)

_3 steps of execution (every step):_

+ _Plan_ — Determine which actor to execute in this step
+ _Execute_ — Execute selected actors in parallel (until completion, failure, or timeout)
+ _Update_ — Update the channel with new values

It terminates when there are no actors to run or the maximum steps are reached.

== 13.9 Direct use of Pregel

There is generally no need to use Pregel directly;
Let's look at a simple example to understand the inner workings.

#code-block(`````python
from langgraph.channels import EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder

# Single node: repeat input twice
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
print("Pregel Results:", result)
# 'foo' + 'foo' = 'foofoo'
`````)

== 13.10 Channel Type

Pregel offers three channel types:

#code-block(`````python
from langgraph.channels import (
    EphemeralValue,
    LastValue,
    Topic,
    BinaryOperatorAggregate,
)
from langgraph.pregel import Pregel, NodeBuilder

# --- 1. LastValue: Maintain only the latest value ---
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

# --- 2. Topic: Accumulating multiple values ​​---
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

# --- 3. BinaryOperatorAggregate: Apply reducer ---
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

== 13.11 superstep Execution Model

Pregel runs in *supersteps*.
In each superstep, nodes (actors) at the same level can run in parallel. Once all of them finish, the channel state is updated and the runtime moves to the next superstep.

#note-box[Features of a superstep: nodes in the same superstep cannot see each other's new outputs, the next step begins only after all nodes finish, a checkpointer can persist state after each step, and execution stops automatically when there are no actors left to run.]

A simple mental model looks like this:

- Superstep 1: Node A and Node B run in parallel
- Channel update
- Superstep 2: Node C runs using the results from A and B
- Channel update
- Superstep 3: Node D runs
- End

== 13.12 API Selection Criteria Guide

Here is the decision framework for your final choice:

_Step 1: Complexity evaluation_
- Less than 3 nodes and linear flow → _Functional API_
- Conditional branching, parallel path, circular structure → _Graph API_

_Step 2: Team Collaboration_
- Alone or with a small team → Either way is possible
- Multiple team members are responsible for each node → _Graph API_ (separation of visualization and roles)

_Step 3: Leverage Existing Code_
- Add LangGraph function to existing procedural code → _Functional API_
- Designing a new workflow from scratch → _Graph API_

_Step 4: Potential for development_
- Start from a prototype → _Functional API_ → When it becomes complex, migrate to Graph API
- Consider scalability from the beginning → _Graph API_

== 13.13 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Concepts],
  [Graph API],
  [Node/edge based, strong in visualization, suitable for complex workflow],
  [Functional API],
  [Decorator-based, minimal boilerplate, suitable for linear workflow],
  [Compare],
  [Same runtime, can be used together, choose based on complexity],
  [Pregel],
  [LangGraph's internal execution engine, actor-channel model],
  [Channel],
  [LastValue, Topic, BinaryOperatorAggregate 3 types],
  [superstep],
  [Parallel execution of same level nodes → Channel update → Next step],
  [Selection criteria],
  [Judging by complexity, team collaboration, existing code, and development potential],
)

=== Next Steps
→ Proceed to _#link("../04_deepagents/01_introduction.ipynb")[the Deep Agents track]_!

#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langgraph/18-choosing-apis.md")[Choosing between Graph and Functional APIs]
- #link("../docs/langgraph/23-pregel.md")[Pregel Runtime]
