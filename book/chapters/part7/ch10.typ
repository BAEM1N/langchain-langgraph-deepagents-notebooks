// Auto-generated from 10_personal_assistant_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Personal Assistant Subagents", subtitle: "역할별 위임 패턴")

== 학습 목표
#learning-objectives([supervisor가 사용자 요청을 역할별 subagent로 나누는 방식을 이해합니다.], [각 subagent의 책임과 tool scope를 좁게 정의합니다.], [실제 LLM 호출 없이 routing과 fan-in 결과 형식을 검증합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 10.1 역할 정의

개인 비서는 하나의 거대한 agent보다 calendar, email, research처럼 역할을 나누면 안전합니다.

#code-block(`````python
subagents = {
    "calendar": {"tools": ["check_availability"], "risk": "approval"},
    "email": {"tools": ["draft_reply"], "risk": "review"},
    "research": {"tools": ["search_notes"], "risk": "allow"},
}

subagents
`````)

== 10.2 요청 라우팅

실제 모델 라우터 대신 keyword router로 구조를 먼저 확인합니다.

#code-block(`````python
def route_request(text: str) -> str:
    lowered = text.lower()
    if "meeting" in lowered or "일정" in lowered:
        return "calendar"
    if "email" in lowered or "메일" in lowered:
        return "email"
    return "research"

route_request("내일 일정 확인하고 메일 초안도 준비해줘")
`````)

== 10.3 복합 요청 분해

하나의 요청이 여러 역할을 건드리면 supervisor가 task list를 만듭니다.

#code-block(`````python
def plan_tasks(text: str) -> list[dict]:
    tasks = []
    for name in subagents:
        if name == route_request(text) or name in text.lower():
            tasks.append({"subagent": name, "input": text})
    return tasks or [{"subagent": "research", "input": text}]

plan_tasks("calendar 확인 후 email 초안 작성")
`````)

== 10.4 fan-in 결과 합치기

subagent 결과는 사용자에게 바로 노출하기 전에 supervisor가 정리합니다.

#code-block(`````python
results = [
    {"subagent": "calendar", "result": "화요일 3시 가능"},
    {"subagent": "email", "result": "회의 제안 메일 초안 생성"},
]

summary = "\n".join(f"- {r['subagent']}: {r['result']}" for r in results)
print(summary)
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
  [supervisor, subagent role, routing, fan-in],
  [_핵심 개념_],
  [subagent는 역할과 권한을 좁혀 전체 assistant의 위험을 줄입니다.],
  [_다음 단계_],
  [`11_customer_support_handoffs.ipynb`],
)

#references-box[
- `docs/langchain/multi-agent/subagents.md`
- `docs/langchain/multi-agent/subagents-personal-assistant.md`
- `docs/deepagents/subagents.md`
]
#chapter-end()
