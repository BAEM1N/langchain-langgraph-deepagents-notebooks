// Auto-generated from 16_case_studies.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(16, "Case Studies", subtitle: "공식 사례를 설계 패턴으로 읽기")

== 학습 목표
#learning-objectives([LangGraph 공식 case study를 구현 복붙이 아니라 architecture pattern으로 분해합니다.], [문제, state, nodes, persistence, evaluation 관점의 리뷰 템플릿을 만듭니다.], [새 agent 프로젝트 시작 전에 case study checklist를 적용합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 16.1 case study 리뷰 템플릿

공식 사례는 “무엇을 만들었나”보다 “왜 graph가 필요했나”를 중심으로 읽습니다.

#code-block(`````python
review_template = {
    "problem": "어떤 반복/분기/상태 문제가 있었나?",
    "state": "장기적으로 보존해야 할 state는 무엇인가?",
    "nodes": "결정적 node와 agentic node는 어떻게 나뉘나?",
    "eval": "성공 기준은 무엇인가?",
}

review_template
`````)

== 16.2 샘플 사례 분해

아래는 고객지원 그래프를 case study 형식으로 요약한 예시입니다.

#code-block(`````python
case = {
    "problem": "문의 유형에 따라 billing/technical/general 경로가 달라진다.",
    "state": ["message", "owner", "resolution"],
    "nodes": ["triage", "resolve", "approval"],
    "eval": "owner routing accuracy and resolution completeness",
}

case
`````)

== 16.3 설계 결정 기록

case study를 읽고 내 프로젝트에 적용할 때는 decision record를 남깁니다.

#code-block(`````python
decision = {
    "chosen": "StateGraph",
    "because": "handoff state and approval gates must be explicit",
    "rejected": "single create_agent loop",
    "risk": "routing policy drift",
}

decision
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
  [case study review, architecture template, decision record],
  [_핵심 개념_],
  [사례는 기능 목록이 아니라 설계 선택의 근거로 읽어야 합니다.],
)

#references-box[
- `docs/langgraph/case-studies.md`
- `docs/langgraph/thinking-in-langgraph.md`
- `docs/langgraph/workflows-agents.md`
]
#chapter-end()
