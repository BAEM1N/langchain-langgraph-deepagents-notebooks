// Auto-generated from 16_case_studies.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(16, "Case Studies", subtitle: "Read official examples as design patterns")

Official examples are more than snippets to copy; they are compact design studies. This chapter shows how to read them for state design, node boundaries, routing choices, and evaluation criteria.

_Learning goals_
- Extract reusable architecture patterns from examples.
- Describe state, nodes, and routing decisions explicitly.
- Capture design decisions in a short record before implementation.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 16.1 Case-study review template

Use the same review template each time you study an example. Consistent questions make it easier to compare architectures across different use cases.


#code-block(`````python
review_template = {
    "problem": "What loop, branching, or state problem does this case solve?",
    "state": "Which state must be preserved over time?",
    "nodes": "How are deterministic nodes separated from agentic nodes?",
    "eval": "What counts as success?",
}

review_template
`````)

== 16.2 Break down a sample case

A case study becomes useful when you translate it into problem, state, node, and evaluation choices. This practice helps prevent cargo-cult copying.


#code-block(`````python
case = {
    "problem": "The route changes by request type: billing, technical, or general.",
    "state": ["message", "owner", "resolution"],
    "nodes": ["triage", "resolve", "approval"],
    "eval": "owner routing accuracy and resolution completeness",
}

case
`````)

== 16.3 Design decision record

A short decision record preserves why a pattern was chosen. Future maintainers can then revisit the tradeoff without reverse-engineering the original reasoning.


#code-block(`````python
decision = {
    "chosen": "StateGraph",
    "because": "handoff state and approval gates must be explicit",
    "rejected": "single create_agent loop",
    "risk": "routing policy drift",
}

decision
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
  [case-study review, architecture templates, state design, and decision records],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langgraph/case-studies.md")[`case-studies.md`]
- #link("../../docs/langgraph/thinking-in-langgraph.md")[`thinking-in-langgraph.md`]
- #link("../../docs/langgraph/workflows-agents.md")[`workflows-agents.md`]
