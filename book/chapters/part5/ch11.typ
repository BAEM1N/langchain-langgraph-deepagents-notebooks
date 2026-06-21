// Auto-generated from 11_custom_workflow_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Custom Workflow Agent", subtitle: "deterministic workflow와 agentic step 섞기")

== 학습 목표
#learning-objectives([custom workflow가 단일 agent loop와 다른 이유를 이해합니다.], [deterministic validation node와 agentic answer node를 분리합니다.], [LangGraph로 작은 workflow agent를 구성합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END

class WorkflowState(TypedDict):
    question: str
    route: str
    answer: str
`````)

== 11.1 deterministic router

검증 가능한 규칙은 LLM이 아니라 코드 node에 둡니다.

#code-block(`````python
def route(state: WorkflowState) -> dict:
    if "sql" in state["question"].lower():
        return {"route": "database"}
    return {"route": "general"}
`````)

#code-block(`````python
def answer(state: WorkflowState) -> dict:
    text = f"{state['route']} workflow로 처리: {state['question']}"
    return {"answer": text}
`````)

== 11.2 workflow compile

각 단계가 분리되면 테스트와 관측이 쉬워집니다.

#code-block(`````python
builder = StateGraph(WorkflowState)
builder.add_node("route", route)
builder.add_node("answer", answer)
builder.add_edge(START, "route")
builder.add_edge("route", "answer")
builder.add_edge("answer", END)
graph = builder.compile()
`````)

#code-block(`````python
graph.invoke({"question": "SQL 결과를 설명해줘", "route": "", "answer": ""})
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
  [deterministic route, workflow agent, StateGraph],
  [_핵심 개념_],
  [custom workflow는 agent 자유도를 낮추는 것이 아니라, 검증 가능한 경계를 만드는 방법입니다.],
)

#references-box[
- `docs/langchain/multi-agent/custom-workflow.md`
- `docs/langchain/structured-output.md`
- `docs/langgraph/workflows-agents.md`
]
#chapter-end()
