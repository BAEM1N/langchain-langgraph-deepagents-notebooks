// Auto-generated from 09_runtime_rubric_evaluation.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Runtime Rubric Evaluation", subtitle: "Build quality gates during execution")

Offline evaluations are valuable, but some quality checks should run while the agent is working. This chapter shows how to use runtime rubrics as lightweight gates.

_Learning goals_
- Express quality criteria as runtime checks.
- Build a deterministic evaluator for structural requirements.
- Relate runtime gates to offline evaluation suites.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 9.1 Rubric criteria

A runtime rubric should focus on criteria that can be checked quickly. Examples include sources, verification evidence, next steps, and forbidden omissions.


#code-block(`````python
criteria = {
    "has_sources": lambda text: "References" in text,
    "has_tests": lambda text: "verification" in text,
    "has_next_step": lambda text: "next" in text,
}

list(criteria)
`````)

== 9.2 Evaluator

The evaluator turns rubric criteria into a pass/fail signal. Keep its output explainable so failures can guide the next agent step.


#code-block(`````python
def grade(text: str) -> dict:
    checks = {name: fn(text) for name, fn in criteria.items()}
    feedback = [name for name, passed in checks.items() if not passed]
    return {"passed": all(checks.values()), "checks": checks, "feedback": feedback}

grade("The response has a summary and next step, but no verification evidence.")
`````)

== 9.3 Relationship to offline evals

Runtime gates and offline evals serve different purposes. Runtime gates protect individual runs, while offline evals measure behavior across many examples.


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
  [runtime rubric criteria, deterministic grading, feedback lists, and offline-eval boundaries],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/deepagents/rubric.md")[`rubric.md`]
- #link("../../docs/deepagents/profiles.md")[`profiles.md`]
- #link("../../docs/langchain/test/evals.md")[`evals.md`]
