// Auto-generated from 11_customer_support_handoffs.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Customer Support Handoffs", subtitle: "상태 전환형 멀티에이전트")

== 학습 목표
#learning-objectives([handoff가 subagent delegation과 어떻게 다른지 구분합니다.], [고객지원 상태 머신을 deterministic하게 설계합니다.], [escalation과 approval 조건을 명시합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END

class SupportState(TypedDict):
    message: str
    owner: str
    resolution: str
`````)

== 11.1 Handoff 기준

handoff는 “누가 다음 응답의 주체인가”가 바뀌는 패턴입니다.

#code-block(`````python
def triage(state: SupportState) -> dict:
    msg = state["message"].lower()
    if "refund" in msg or "환불" in msg:
        return {"owner": "billing"}
    if "error" in msg or "오류" in msg:
        return {"owner": "technical"}
    return {"owner": "general"}
`````)

#code-block(`````python
def resolve(state: SupportState) -> dict:
    templates = {
        "billing": "환불 정책을 확인하고 승인 요청을 준비합니다.",
        "technical": "오류 재현 정보와 로그를 요청합니다.",
        "general": "기본 안내를 제공합니다.",
    }
    return {"resolution": templates[state["owner"]]}
`````)

== 11.2 그래프로 표현하기

LangGraph를 쓰면 handoff 기록이 state에 남고 테스트하기 쉽습니다.

#code-block(`````python
builder = StateGraph(SupportState)
builder.add_node("triage", triage)
builder.add_node("resolve", resolve)
builder.add_edge(START, "triage")
builder.add_edge("triage", "resolve")
builder.add_edge("resolve", END)
graph = builder.compile()
`````)

#code-block(`````python
result = graph.invoke({
    "message": "구독 환불을 요청합니다.",
    "owner": "", "resolution": "",
})
result
`````)

== 11.3 승인 게이트

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[조건],
  text(weight: "bold")[처리],
  [환불/결제],
  [human approval],
  [기술 오류],
  [로그 요청 후 재현],
  [일반 문의],
  [자동 응답 가능],
)

#code-block(`````python
def needs_approval(state: SupportState) -> bool:
    return state["owner"] == "billing"

print("approval required:", needs_approval(result))
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
  [handoff, state machine, approval gate],
  [_핵심 개념_],
  [handoff는 작업 위임이 아니라 대화 주체와 상태의 전환입니다.],
  [_다음 단계_],
  [`12_router_knowledge_base.ipynb`],
)

#references-box[
- `docs/langchain/multi-agent/handoffs.md`
- `docs/langchain/multi-agent/handoffs-customer-support.md`
- `docs/langgraph/workflows-agents.md`
]
#chapter-end()
