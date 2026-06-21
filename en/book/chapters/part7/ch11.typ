// Auto-generated from 11_customer_support_handoffs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Customer Support Handoffs", subtitle: "Multi-agent state transitions")

Customer support agents often need to move a case between general support, billing, technical support, and human approval. This example models handoffs as explicit state transitions.

_Learning goals_
- Define handoff criteria for support workflows.
- Represent ownership changes as graph transitions.
- Add approval gates for sensitive actions.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END

class SupportState(TypedDict):
    message: str
    owner: str
    resolution: str
`````)

== 11.1 Handoff criteria

Handoffs should be based on clear signals such as refund requests, technical errors, or escalation language. Ambiguous ownership creates slow and inconsistent support.


#code-block(`````python
def triage(state: SupportState) -> dict:
    msg = state["message"].lower()
    if "refund" in msg or "refund" in msg:
        return {"owner": "billing"}
    if "error" in msg or "error" in msg:
        return {"owner": "technical"}
    return {"owner": "general"}
`````)

#code-block(`````python
def resolve(state: SupportState) -> dict:
    templates = {
        "billing": "Check the refund policy and prepare an approval request.",
        "technical": "Ask for reproduction steps and logs.",
        "general": "Provide the standard guidance.",
    }
    return {"resolution": templates[state["owner"]]}
`````)

== 11.2 Represent the flow as a graph

A graph makes ownership and transition rules visible. Each route can be tested without relying on a full support transcript.


#code-block(`````python
builder = StateGraph(SupportState)
builder.add_node("triage", triage)
builder.add_node("resolve", resolve)
builder.add_edge(START, "triage")
builder.add_edge("triage", "resolve")
builder.add_edge("resolve", END)
graph = builder.compile()
`````)

#code-block(`````python
result = graph.invoke({
    "message": "I would like a subscription refund.",
    "owner": "", "resolution": "",
})
result
`````)

== 11.3 Approval gate

Some support actions require human confirmation. An approval gate records why the case is paused and what decision is needed next.


#code-block(`````python
def needs_approval(state: SupportState) -> bool:
    return state["owner"] == "billing"

print("approval required:", needs_approval(result))
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
  [handoff state machines, escalation, owner transitions, and approval gates],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/multi-agent/handoffs.md")[`handoffs.md`]
- #link("../../docs/langgraph/interrupts.md")[`interrupts.md`]
- #link("../../docs/langchain/human-in-the-loop.md")[`human-in-the-loop.md`]
