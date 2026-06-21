// Auto-generated from 10_deep_agent_from_scratch.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Deep Agent from Scratch", subtitle: "Assemble harness responsibilities manually")

Building a Deep Agent from scratch is a way to understand what the SDK normally gives you. This chapter decomposes an agent into planning, tools, state, and quality gates.

_Learning goals_
- Identify the responsibilities hidden inside an agent harness.
- Sketch a planner, tool registry, and quality gate.
- Understand why production agents need explicit control surfaces.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 10.1 Minimal Deep Agent components

Start by naming the pieces: instructions, tools, memory or state, planning, execution, and verification. A clear parts list makes the harness easier to reason about.


#code-block(`````python
harness_parts = [
    "planner", "tool_registry", "state", "filesystem", "subagent_dispatch", "quality_gate",
]

harness_parts
`````)

== 10.2 Todo planner skeleton

A todo planner gives the agent a visible working structure. Even a simple list helps separate intent, execution, and completion evidence.


#code-block(`````python
def plan(request: str) -> list[dict]:
    return [
        {"task": "understand", "status": "done"},
        {"task": "draft", "status": "pending"},
        {"task": "verify", "status": "pending"},
    ]

plan("sync official docs")
`````)

== 10.3 Tool registry skeleton

A registry makes tool availability explicit. It is also the natural place to attach descriptions, risk levels, and permission rules.


#code-block(`````python
def echo_tool(text: str) -> str:
    return f"echo: {text}"

tool_registry = {"echo": echo_tool}
print(tool_registry["echo"]("hello"))
`````)

== 10.4 Quality gate

A quality gate keeps the agent from treating any output as finished. It checks whether required evidence and next-step clarity are present.


#code-block(`````python
def quality_gate(result: dict) -> bool:
    return bool(result.get("answer")) and result.get("verified") is True

quality_gate({"answer": "done", "verified": True})
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
  [planner, tool registry, state, filesystem, subagent dispatch, and quality gate skeletons],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/deep-agent-from-scratch.md")[`deep-agent-from-scratch.md`]
- #link("../../docs/deepagents/overview.md")[`overview.md`]
- #link("../../docs/deepagents/customization.md")[`customization.md`]
