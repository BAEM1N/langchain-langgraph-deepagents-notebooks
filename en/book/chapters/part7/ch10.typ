// Auto-generated from 10_personal_assistant_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Personal Assistant Subagents", subtitle: "Delegate by role")

A personal assistant often handles mixed requests: calendar work, email drafting, research, and follow-up planning. This example uses role-based subagents to keep those responsibilities separate.

_Learning goals_
- Define subagent roles around user-facing responsibilities.
- Route requests to the right role.
- Merge multiple role outputs into one assistant response.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 10.1 Define roles

Good subagent design starts with role boundaries. Each role should have a clear job, input shape, and output expectation.


#code-block(`````python
subagents = {
    "calendar": {"tools": ["check_availability"], "risk": "approval"},
    "email": {"tools": ["draft_reply"], "risk": "review"},
    "research": {"tools": ["search_notes"], "risk": "allow"},
}

subagents
`````)

== 10.2 Route requests

Routing turns a user request into an ownership decision. Deterministic routing is enough for this small example and keeps the behavior easy to inspect.


#code-block(`````python
def route_request(text: str) -> str:
    lowered = text.lower()
    if "meeting" in lowered or "schedule" in lowered:
        return "calendar"
    if "email" in lowered or "email" in lowered:
        return "email"
    return "research"

route_request("Check tomorrow schedule and prepare an email draft")
`````)

== 10.3 Decompose compound requests

Real requests often contain more than one job. Decomposition lets the assistant delegate each part without losing the overall user intent.


#code-block(`````python
def plan_tasks(text: str) -> list[dict]:
    tasks = []
    for name in subagents:
        if name == route_request(text) or name in text.lower():
            tasks.append({"subagent": name, "input": text})
    return tasks or [{"subagent": "research", "input": text}]

plan_tasks("Check calendar and draft email")
`````)

== 10.4 Merge fan-in results

The final response should read like one assistant, not a pile of subagent logs. Fan-in synthesis combines role outputs into a useful summary.


#code-block(`````python
results = [
    {"subagent": "calendar", "result": "Tuesday at 3 PM is available"},
    {"subagent": "email", "result": "Drafted a meeting proposal email"},
]

summary = "\n".join(f"- {r['subagent']}: {r['result']}" for r in results)
print(summary)
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
  [supervisor routing, role-specific subagents, tool scopes, and fan-in summaries],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/multi-agent/subagents-personal-assistant.md")[`multi-agent-middleware.md`]
- #link("../../docs/deepagents/subagents.md")[`subagents.md`]
- #link("../../docs/deepagents/async-subagents.md")[`async-subagents.md`]
