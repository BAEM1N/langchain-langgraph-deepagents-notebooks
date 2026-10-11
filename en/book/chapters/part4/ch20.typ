// Auto-generated from 16_quality_profiles_rubric.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(20, "Quality Profiles and Rubrics", subtitle: "Configure runtime quality gates")

Agents need more than a final answer; they need a definition of acceptable work. This chapter separates runtime profiles from rubrics and shows how to turn quality expectations into executable checks.

_Learning goals_
- Define rubrics as completion criteria.
- Use deterministic evaluators for simple quality gates.
- Distinguish runtime profiles from answer-quality rubrics.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from deepagents import HarnessProfile, register_harness_profile

profile = HarnessProfile(system_prompt_suffix="Respond with concise Korean bullets.")
register_harness_profile("course:demo", profile)

type(profile).__name__
`````)

== 16.1 Rubrics define completion criteria

A rubric translates “good enough” into observable criteria. It helps agents and reviewers agree on what must be present before work is considered complete.


#code-block(`````python
rubric = [
    {"name": "has_summary", "check": lambda text: "summary" in text},
    {"name": "has_next_step", "check": lambda text: "next" in text},
]

rubric[0]["name"]
`````)

== 16.2 Deterministic rubric evaluator

`RubricMiddleware` requires criterion-level evaluation coverage and connects to grader hooks and a runtime self-revision loop. The evaluator in this cell is a deterministic teaching miniature, not the SDK middleware itself.

That boundary matters: the teaching evaluator shows the contract without an LLM call, while `RubricMiddleware` checks output quality during runtime.

#code-block(`````python
def evaluate(text: str) -> dict:
    results = {item["name"]: item["check"](text) for item in rubric}
    return {"passed": all(results.values()), "criteria": results}

evaluate("summary: done. next: run tests")
`````)

== 16.3 Profile versus rubric

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Role],
  [profile],
  [Tunes model/provider harness defaults, tool descriptions, excluded tools, and extra middleware],
  [rubric],
  [Defines quality criteria the final result must satisfy],
  [eval],
  [Runs batch/offline regression checks],
  [middleware],
  [Runs runtime self-revision and grader hooks],
)

A profile changes the runtime environment; a rubric changes the completion contract. Keeping them separate makes regressions easier to diagnose.

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
  [`HarnessProfile`, rubric criteria, deterministic evaluator, and the `RubricMiddleware` contract],
  [_Core idea_],
  [Profiles configure runtime behavior; rubrics define completion criteria.],
  [_Caution_],
  [Do not describe a deterministic teaching evaluator as if it were SDK `RubricMiddleware`.],
)

== Reference docs

- #link("../../docs/deepagents/profiles.md")[`profiles.md`]
- #link("../../docs/deepagents/rubric.md")[`rubric.md`]
- #link("../../docs/deepagents/going-to-production.md")[`going-to-production.md`]
