// Auto-generated from 13_programmatic_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(17, "Programmatic Subagents", subtitle: "Code-controlled fan-out/fan-in")

Subagents do not always need to be selected by an LLM at runtime. In many systems, code should decide when to fan out work, how to collect results, and how to merge them.

_Learning goals_
- Identify when programmatic delegation is preferable to model-driven delegation.
- Implement a deterministic fan-out/fan-in pattern.
- Define promotion checks before using live subagents in production.


#code-block(`````python
from dotenv import load_dotenv
import importlib.util, os

load_dotenv(override=True)
`````)

#code-block(`````python
import deepagents

capabilities = {
    "deepagents_version": getattr(deepagents, "__version__", "unknown"),
    "quickjs_available": importlib.util.find_spec("langchain_quickjs") is not None,
    "SubAgent": hasattr(deepagents, "SubAgent"),
    "AsyncSubAgent": hasattr(deepagents, "AsyncSubAgent"),
}
capabilities
`````)

== 13.1 When programmatic subagents are useful

Programmatic subagents are useful when the task boundaries are known in advance. Code can then enforce parallelism, ownership, and merge rules deterministically.


#code-block(`````python
tasks = [
    {"name": "coverage", "question": "What is missing between official and local docs?"},
    {"name": "tests", "question": "How should verification be handled?"},
    {"name": "risks", "question": "What are the external service risks?"},
]

[t["name"] for t in tasks]
`````)

== 13.2 Practice fan-out/fan-in with a deterministic fallback

This section simulates delegation without depending on external model calls. The structure is the same pattern you would use around real subagents.


#code-block(`````python
def worker(task: dict) -> dict:
    return {
        "name": task["name"],
        "finding": f"{task['question']} → manage with a checklist",
    }

worker_results = [worker(task) for task in tasks]
worker_results
`````)

== 13.3 Fan-in synthesis

Fan-in is where independent results become a single answer. Keep the merge step explicit so contradictions, gaps, and ownership are easy to see.


#code-block(`````python
summary = {
    "total_workers": len(worker_results),
    "findings": [item["finding"] for item in worker_results],
    "next_action": "Turn the official slug action matrix into an implementation checklist",
}

summary
`````)

== 13.4 Before promoting to live features

Before live rollout, define tests for routing, result shape, failure handling, and observability. Subagents multiply both capability and operational surface area.


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
  [dependency gates, deterministic fallback, fan-out/fan-in, and subagent orchestration],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/programmatic-subagents.md")[`programmatic-subagents.md`]
- #link("../../docs/deepagents/subagents.md")[`subagents.md`]
- #link("../../docs/deepagents/async-subagents.md")[`async-subagents.md`]
