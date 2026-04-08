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
model = ChatOpenAI(model="gpt-4.1")
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
