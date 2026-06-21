// Auto-generated from 14_event_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(18, "Event Streaming", subtitle: "Observe Deep Agents as structured events")

Streaming is not only a UI feature. For agent systems, structured events are the audit trail that explains what happened during planning, tool use, generation, and completion.

_Learning goals_
- Model agent progress as typed events.
- Consume events incrementally and update UI state.
- Use streaming as an operational debugging surface.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 14.1 Event model

A useful event stream has stable event types and predictable payloads. This makes it possible to build logs, UIs, and monitors on top of the same execution trace.


#code-block(`````python
events = [
    {"type": "todo", "payload": {"task": "outline", "status": "done"}},
    {"type": "tool", "payload": {"name": "read_file", "status": "done"}},
    {"type": "subagent", "payload": {"name": "researcher", "status": "running"}},
    {"type": "message", "payload": {"text": "Drafting the first version."}},
]

len(events)
`````)

== 14.2 Build an event consumer

The consumer turns raw events into readable progress. Keep this logic small and deterministic so it remains trustworthy during incidents.


#code-block(`````python
def project_event(event: dict) -> str:
    kind = event["type"]
    payload = event["payload"]
    if kind == "tool":
        return f"tool:{payload['name']}:{payload['status']}"
    if kind == "subagent":
        return f"subagent:{payload['name']}:{payload['status']}"
    return f"{kind}:{payload}"

[project_event(event) for event in events]
`````)

== 14.3 Accumulate UI state

Most interfaces need the latest message, tool status, and completion state rather than a raw event dump. Accumulating UI state makes the stream usable for learners and operators.


#code-block(`````python
state = {"todos": [], "tools": [], "subagents": [], "messages": []}
for event in events:
    bucket = event["type"] + "s"
    if bucket in state:
        state[bucket].append(event["payload"])

state
`````)

== 14.4 Operational checklist

Streaming should be designed with failure modes in mind. Check event ordering, error events, redaction, and replayability before relying on it in production.


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
  [event logs, UI projections, subagent/tool/todo events, and replayable state],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/event-streaming.md")[`event-streaming.md`]
- #link("../../docs/deepagents/streaming.md")[`streaming.md`]
- #link("../../docs/langchain/event-streaming.md")[`event-streaming.md`]
