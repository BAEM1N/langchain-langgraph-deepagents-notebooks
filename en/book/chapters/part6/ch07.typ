// Auto-generated from 07_testing_strategy.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Testing Strategy", subtitle: "Separate unit, integration, and eval")

Agent testing works best when different test types do different jobs. This chapter separates deterministic unit tests, provider integration checks, and behavioral evaluations.

_Learning goals_
- Decide what belongs in unit, integration, and eval layers.
- Use fake models for fast deterministic tests.
- Keep expensive or stateful checks behind explicit gates.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain_core.language_models.fake_chat_models import FakeListChatModel
from langchain_core.messages import HumanMessage

model = FakeListChatModel(responses=["test response"])
model.invoke([HumanMessage(content="ping")]).content
`````)

== 7.1 Testing pyramid

The testing pyramid still applies to agent systems, but the top layer often contains evaluations rather than only end-to-end tests. Put cheap deterministic checks at the base.


== 7.2 Unit test pure functions first

Pure functions are the easiest place to build confidence. Test routing, formatting, and scoring logic before introducing model variability.


#code-block(`````python
def normalize_question(text: str) -> str:
    return " ".join(text.strip().lower().split())

assert normalize_question("  Hello   Agent  ") == "hello agent"
print("unit test passed")
`````)

== 7.3 Integration gate

Integration tests prove that external providers and runtime wiring still work. Keep them clearly marked because they may require credentials, network access, or cost.


#code-block(`````python
def can_run_openai_integration() -> bool:
    return bool(os.getenv("OPENAI_API_KEY")) and os.getenv("RUN_LIVE_TESTS") == "1"

print("run live integration:", can_run_openai_integration())
`````)

== 7.4 Eval checks behavior paths, not only answer strings

Agent evaluations should inspect behavior, not just final text. Tool calls, routing choices, and recovery paths often matter more than exact wording.


#code-block(`````python
trajectory = [
    {"role": "user", "content": "weather in Seoul"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather"}]},
    {"role": "tool", "name": "get_weather", "content": "clear"},
]

assert trajectory[1]["tool_calls"][0]["name"] == "get_weather"
`````)

== 7.5 Separate CI and manual verification

CI should stay fast and reliable. Manual or scheduled runs can cover heavier evaluations, live providers, and mutation-prone resources.


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
  [fake models, unit tests, integration gates, evals, and smoke-test boundaries],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/test/unit-testing.md")[`unit-testing.md`]
- #link("../../docs/langchain/test/integration-testing.md")[`integration-testing.md`]
- #link("../../docs/langchain/test/evals.md")[`evals.md`]
