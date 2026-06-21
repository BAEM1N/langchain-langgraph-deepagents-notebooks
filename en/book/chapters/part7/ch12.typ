// Auto-generated from 12_router_knowledge_base.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "Router Knowledge Base", subtitle: "Send questions to the right source")

A knowledge-base assistant is only useful if it searches the right source. This example routes questions to policy, product, or troubleshooting knowledge before retrieval.

_Learning goals_
- Define source-specific knowledge boundaries.
- Route questions before searching.
- Evaluate router decisions separately from answer quality.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 12.1 Define knowledge sources

Knowledge sources should have clear scope. Separating policy, product, and troubleshooting content reduces irrelevant retrieval.


#code-block(`````python
knowledge_sources = {
    "billing": ["Refunds are available within 7 days of payment."],
    "technical": ["Error reports require logs and reproduction steps."],
    "product": ["Deep Agents include planning, files, and subagents."],
}

list(knowledge_sources)
`````)

== 12.2 Deterministic router

The router chooses where to search. In production this could be model-assisted, but deterministic routing is ideal for learning and testing the contract.


#code-block(`````python
def route_source(question: str) -> str:
    q = question.lower()
    if "refund" in q or "refund" in q:
        return "billing"
    if "error" in q or "error" in q:
        return "technical"
    return "product"

route_source("What features does Deep Agents provide?")
`````)

== 12.3 Source-local search

Once a source is selected, search only inside that source. This makes retrieval behavior easier to debug and evaluate.


#code-block(`````python
def retrieve(question: str) -> dict:
    source = route_source(question)
    docs = knowledge_sources[source]
    return {"source": source, "documents": docs}

retrieve("Tell me the refund conditions")
`````)

== 12.4 Router evaluation

Router evaluation asks a narrow question: did the system choose the right source? Keeping this separate from answer evaluation makes failures easier to diagnose.


#code-block(`````python
cases = [
    ("Can I get a refund?", "billing"),
    ("The app has an error", "technical"),
    ("What are Deep Agents?", "product"),
]

for question, expected in cases:
    actual = route_source(question)
    print(question, actual, actual == expected)
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
  [source routing, source-local retrieval, routing tests, and knowledge-base specialization],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/multi-agent/custom-workflow.md")[`custom-multi-agent.md`]
- #link("../../docs/langchain/retrieval.md")[`retrieval.md`]
- #link("../../docs/langgraph/workflows-agents.md")[`workflows-agents.md`]
