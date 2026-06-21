// Auto-generated from 10_deep_agent_from_scratch.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Deep Agent from Scratch", subtitle: "harness 구성요소 직접 조립하기")

== 학습 목표
#learning-objectives([Deep Agents의 planning, filesystem, subagent 개념을 LangChain/LangGraph 관점에서 분해합니다.], [완성된 SDK를 쓰기 전 harness가 어떤 책임을 갖는지 이해합니다.], [작은 deterministic harness skeleton을 만들어 봅니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 10.1 Deep Agent의 최소 구성요소

SDK는 많은 기능을 제공하지만, 개념적으로는 plan → act → observe → revise 루프입니다.

#code-block(`````python
harness_parts = [
    "planner", "tool_registry", "state", "filesystem", "subagent_dispatch", "quality_gate",
]

harness_parts
`````)

== 10.2 Todo planner skeleton

복잡한 요청을 todo list로 바꾸는 단계부터 분리합니다.

#code-block(`````python
def plan(request: str) -> list[dict]:
    return [
        {"task": "understand", "status": "done"},
        {"task": "draft", "status": "pending"},
        {"task": "verify", "status": "pending"},
    ]

plan("공식 문서 반영")
`````)

== 10.3 tool registry skeleton

도구는 이름과 실행 함수를 분리해 registry에 둡니다.

#code-block(`````python
def echo_tool(text: str) -> str:
    return f"echo: {text}"

tool_registry = {"echo": echo_tool}
print(tool_registry["echo"]("hello"))
`````)

== 10.4 quality gate

Deep Agent가 “끝났다”고 말하기 전에 검증 기준을 확인합니다.

#code-block(`````python
def quality_gate(result: dict) -> bool:
    return bool(result.get("answer")) and result.get("verified") is True

quality_gate({"answer": "done", "verified": True})
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_다룬 기술_],
  [planner, tool registry, quality gate skeleton],
  [_핵심 개념_],
  [Deep Agents SDK는 harness 책임을 제품화한 것이며, 직접 조립해 보면 경계가 선명해집니다.],
)

#references-box[
- `docs/langchain/deep-agent-from-scratch.md`
- `docs/deepagents/overview.md`
- `docs/concepts/products.md`
]
#chapter-end()
