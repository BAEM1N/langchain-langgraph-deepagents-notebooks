// Auto-generated from 08_langgraph_testing.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "LangGraph Testing", subtitle: "Assert state and checkpoint behavior")

LangGraph applications should be tested at the node, graph, and persistence layers. This chapter shows how to make state transitions and checkpoint behavior explicit.

_Learning goals_
- Unit test a node as a state transformation.
- Integration test a small graph path.
- Smoke test checkpoint persistence and resume assumptions.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

class CounterState(TypedDict):
    count: int
`````)

== 8.1 Node unit test

A node is easiest to test when you treat it as a function from state to state update. This catches schema and transformation mistakes early.


#code-block(`````python
def increment(state: CounterState) -> dict:
    return {"count": state["count"] + 1}

assert increment({"count": 1}) == {"count": 2}
print("node unit test passed")
`````)

== 8.2 Graph integration test

A graph test verifies that nodes and edges work together. It should focus on a representative path rather than every possible conversation.


#code-block(`````python
builder = StateGraph(CounterState)
builder.add_node("increment", increment)
builder.add_edge(START, "increment")
builder.add_edge("increment", END)
graph = builder.compile()

assert graph.invoke({"count": 0})["count"] == 1
`````)

== 8.3 Checkpoint smoke test

Checkpoint tests protect durability assumptions. They confirm that saved state can be retrieved and used as the next execution boundary.


#code-block(`````python
checkpointer = InMemorySaver()
graph_with_memory = builder.compile(checkpointer=checkpointer)
config = {"configurable": {"thread_id": "test-1"}}

result = graph_with_memory.invoke({"count": 2}, config=config)
assert result["count"] == 3
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Covered_],
  [node unit tests, graph integration tests, checkpointer smoke tests, and state assertions],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langgraph/test.md")[`test.md`]
- #link("../../docs/langgraph/checkpointers.md")[`checkpointers.md`]
- #link("../../docs/langgraph/persistence.md")[`persistence.md`]
