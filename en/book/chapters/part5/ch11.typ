// Auto-generated from 11_custom_workflow_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Custom Workflow Agent", subtitle: "Combine deterministic and agentic steps")

Many strong agent applications are not fully autonomous loops. They combine deterministic routing and validation with agentic steps only where open-ended reasoning is valuable.

_Learning goals_
- Route work deterministically before invoking an agentic step.
- Compile a small workflow from explicit stages.
- Keep predictable control flow around flexible model behavior.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END

class WorkflowState(TypedDict):
    question: str
    route: str
    answer: str
`````)

== 11.1 Deterministic router

A deterministic router handles cases where the decision rule is known. This keeps the agent from spending model calls on work that code can classify reliably.


#code-block(`````python
def route(state: WorkflowState) -> dict:
    if "sql" in state["question"].lower():
        return {"route": "database"}
    return {"route": "general"}
`````)

#code-block(`````python
def answer(state: WorkflowState) -> dict:
    text = f"{state['route']} workflow handled: {state['question']}"
    return {"answer": text}
`````)

== 11.2 Compile the workflow

A compiled workflow makes the control path reviewable. Each stage has a narrow responsibility, which makes testing and debugging easier.


#code-block(`````python
builder = StateGraph(WorkflowState)
builder.add_node("route", route)
builder.add_node("answer", answer)
builder.add_edge(START, "route")
builder.add_edge("route", "answer")
builder.add_edge("answer", END)
graph = builder.compile()
`````)

#code-block(`````python
graph.invoke({"question": "Explain the SQL result", "route": "", "answer": ""})
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
  [StateGraph workflows that mix deterministic routing with agentic answer steps],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/multi-agent/custom-workflow.md")[`custom-multi-agent.md`]
- #link("../../docs/langgraph/workflows-agents.md")[`workflows-agents.md`]
- #link("../../docs/langchain/runtime.md")[`runtime.md`]
