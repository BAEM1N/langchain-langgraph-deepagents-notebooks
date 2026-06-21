// Auto-generated from 15_backward_compatibility.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(15, "Backward Compatibility", subtitle: "Handle LangGraph version changes safely")

LangGraph applications often live longer than the version of LangGraph they were first written against. This chapter turns compatibility into an explicit engineering practice rather than an after-the-fact debugging task.

_Learning goals_
- Separate import compatibility from behavioral compatibility.
- Build migration checklists and version matrices.
- Use smoke tests to make framework upgrades safer.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
import inspect
from langgraph.graph import StateGraph
from langgraph.types import RetryPolicy

features = {
    "add_node_retry_policy": "retry_policy" in inspect.signature(StateGraph.add_node).parameters,
    "retry_policy_class": RetryPolicy.__name__,
}
features
`````)

== 15.1 Compatibility is more than successful imports

A graph can import successfully and still behave differently after an upgrade. Treat compatibility as a combination of imports, state shape, checkpoint behavior, and runtime semantics.


#code-block(`````python
def require_feature(name: str, ok: bool) -> str:
    if not ok:
        return f"SKIP: {name} is not available"
    return f"OK: {name}"

require_feature("add_node.retry_policy", features["add_node_retry_policy"])
`````)

== 15.2 Migration checklist

A migration checklist keeps upgrades concrete. It forces you to review changelogs, deprecated APIs, smoke tests, and representative examples before changing production code.


#code-block(`````python
migration_checklist = [
    "Review the official changelog",
    "Run existing notebook smoke tests",
    "Search for deprecated imports",
    "Add one new API example",
]

for item in migration_checklist:
    print("-", item)
`````)

== 15.3 Compatibility matrix

A version matrix makes support boundaries visible. It records which application paths were tested against which framework versions and what evidence supports the decision.


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
  [feature detection, migration notes, changelog review, and version-safe smoke tests],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langgraph/backward-compatibility.md")[`backward-compatibility.md`]
- #link("../../docs/langgraph/changelog-py.md")[`changelog-py.md`]
- #link("../../docs/langgraph/test.md")[`test.md`]
