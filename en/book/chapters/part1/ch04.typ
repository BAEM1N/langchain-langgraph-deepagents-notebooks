// Auto-generated from 04_langgraph_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "LangGraph Basics", subtitle: "Building a Workflow")

Use LangGraph's `StateGraph` to build a workflow by connecting nodes and edges.


== Learning Objectives

- Define a state-based graph with `StateGraph`
- Register nodes (functions) and connect them with edges
- Run the graph with `compile()` → `invoke()`


== 4.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
print("✓ Model ready")

`````)

== 4.2 Your First Graph

The basic LangGraph flow has five steps:

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

*Core ideas behind `StateGraph`:*

LangGraph models agent workflows as _graphs_, and it relies on three core building blocks:

+ _State_: A shared data structure that represents the current snapshot of the application. It is usually defined with `TypedDict` or a Pydantic model.
+ _Node_: A function that receives state, performs some work, and returns an updated state. In other words, _nodes do the actual work_.
+ _Edge_: A transition that determines which node runs next based on the current state. In other words, _edges decide what happens next_.

`StateGraph` is the primary graph builder class, and it takes a user-defined state object. A graph must be compiled with `.compile()` before it can run, and compilation also validates the graph structure.

The example below is a one-node graph that counts the number of words in a piece of text.


== 4.3 A Two-Node Graph

Connect two nodes in sequence.
The first node converts the text to uppercase, and the second node counts the words.

#code-block(`````python
START → uppercase → counter → END
`````)


== 4.4 Using an LLM as a Node

If you use `MessagesState`, you can model an LLM conversation as a graph.

*What is `MessagesState`?*

`MessagesState` is a _predefined state class_ provided by LangGraph. It contains a single `messages` key and uses `add_messages` as its reducer. Internally, it looks like this:

#code-block(`````python
class MessagesState(TypedDict):
    messages: Annotated[list, add_messages]
`````)

The `add_messages` reducer tracks message IDs, accumulates messages without duplication, and automatically deserializes JSON into LangChain message objects. If you need additional fields such as documents or metadata, you can subclass `MessagesState`.

_How nodes are structured:_

A node is a normal Python function (sync or async) that receives the current state and returns a state update. LangGraph automatically wraps nodes as `RunnableLambda` objects, which adds batch support, async support, and native tracing.


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Core API],
  text(weight: "bold")[Role],
  [`StateGraph(State)`],
  [Creates a graph builder from a state schema],
  [`add_node()`],
  [Registers a node (function)],
  [`add_edge()`],
  [Connects nodes],
  [`compile()`],
  [Produces an executable graph],
  [`invoke()`],
  [Runs the graph],
)

=== Next Steps
→ _#link("./05_deep_agents_basics_en.ipynb")[05_deep_agents_basics_en.ipynb]_: Build an all-in-one agent with Deep Agents.

