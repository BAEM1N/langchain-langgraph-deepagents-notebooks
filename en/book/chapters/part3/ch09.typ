// Auto-generated from 09_subgraphs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Subgraph", subtitle: "Graph within a graph")

== Learning Objectives

Modularize complex workflow with subgraphs.

== 9.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 9.2 Subgraph concept

- _Subgraph_: Independent graph used as a node in another graph
- _Advantages_: Modularization, reuse, independent development by team
- Each subgraph has its own state(State)
- state between parent \<-\> subgraph is mapped to _shared key_

== 9.3 Creating a subgraph

== 9.4 Adding a subgraph to the parent graph

== 9.4.1 Pattern 1: Subgraph call through wrapper node (if `state_schema` is different)

In the above example (9.4), the parent graph and subgraph shared _the same keys_ (`text`, `word_count`, `char_count`), so the compiled subgraph could be passed directly to `add_node()`.

However, in practice, the *`state_schema`* of the parent graph and subgraph is often completely different. In this case, use a *wrapper function*:

+ _Extract_ the required fields from the parent state and convert them to subgraph input.
+ _Run_ the subgraph
+ _Map_ the subgraph output to the parent state format.

Use the pattern. This is how the official documentation calls it _Pattern 1: Call Subgraph Inside a Node_.

== 9.5 LLM-based subgraph

Organize the full text agent into subgraphs.

== 9.6 Subgraph streaming

Steps inside a subgraph are also streaming possible.

With v2 streaming (`version="v2"`) subgraph chunks arrive as a uniform `StreamPart` dict. Three fields cover everything:

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

- `chunk["type"]` — mode identifier (`"updates"`, `"values"`, `"messages"`, ...)
- `chunk["ns"]` — namespace tuple. `()` for root, `("node_2:<uuid>",)` for a subgraph
- `chunk["data"]` — mode-specific payload

#tip-box[In v1 the return shape changed (tuple vs dict) depending on `subgraphs=True`. v2 always returns the same dict, so root- and subgraph-handling code can be unified.]

=== Subgraph checkpointer — three modes

The `checkpointer=` argument on subgraph compile controls memory and interrupt behavior.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[`checkpointer=`],
  text(weight: "bold")[Behavior],
  text(weight: "bold")[Fit],
  [Per-invocation (default)],
  [`None`],
  [Fresh per call; inherits parent's checkpointer for interrupts within a single invocation],
  [Tool-wrapped subagents, multi-agent routing],
  [Per-thread (stateful)],
  [`True`],
  [Accumulates state across calls on the same thread],
  [Specialized subagents with long-running conversation],
  [Stateless],
  [`False`],
  [No checkpointing — plain function call; no interrupt support],
  [Pure transforms with no side effects],
)

#warning-box[Per-thread subgraphs do not support _parallel tool calls_. When the LLM tries to invoke the same subagent in parallel, both calls write to the same namespace and conflict. Use `ToolCallLimitMiddleware(tool_name="...", run_limit=1)` to cap simultaneous invocations.]

=== Namespace isolation — multiple per-thread subgraphs

When several per-thread subgraphs coexist, wrap each one in its own `StateGraph` with a unique node name so namespaces don't collide. `StateGraph(MessagesState).add_node(name, agent)` is the standard pattern.

#code-block(`````python
from langgraph.graph import MessagesState, StateGraph
from langchain.agents import create_agent

def create_sub_agent(model, *, name, **kwargs):
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)          # unique name → stable namespace
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

Each subagent writes checkpoints only under its own name, so subgraphs never collide.

== 9.7 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [Subgraph],
  [Using independently compiled graphs as nodes],
  [shared key],
  [state mapping between parent and subgraph],
  [Modularization],
  [Separating complex workflow into smaller units],
  [streaming],
  [Track internal steps with `subgraphs=True`],
)

=== Next Steps
→ _#link("./10_production.ipynb")[10_production.ipynb]_: Learn production deployment.
