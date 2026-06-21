// Auto-generated from 14_event_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(18, "Event Streaming", subtitle: "Deep Agents 실행을 관찰 가능한 이벤트로 보기")

== 학습 목표
#learning-objectives([일반 streaming과 event streaming의 차이를 구분합니다.], [todo, tool, subagent, filesystem 이벤트를 UI/로그 친화적 형태로 정리합니다.], [실제 장기 실행 agent 없이도 event consumer를 먼저 설계합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 14.1 이벤트 모델

Deep Agents frontend와 운영 로그에서는 “최종 답변”보다 중간 이벤트가 중요합니다.

#code-block(`````python
events = [
    {"type": "todo", "payload": {"task": "outline", "status": "done"}},
    {"type": "tool", "payload": {"name": "read_file", "status": "done"}},
    {"type": "subagent", "payload": {"name": "researcher", "status": "running"}},
    {"type": "message", "payload": {"text": "초안을 작성합니다."}},
]

len(events)
`````)

== 14.2 이벤트 consumer 만들기

consumer는 provider별 raw event를 받아 UI나 로그에 필요한 projection으로 바꿉니다.

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

== 14.3 UI 상태로 누적하기

event stream은 append-only log로 보존하고, 화면 상태는 projection으로 만듭니다.

#code-block(`````python
state = {"todos": [], "tools": [], "subagents": [], "messages": []}
for event in events:
    bucket = event["type"] + "s"
    if bucket in state:
        state[bucket].append(event["payload"])

state
`````)

== 14.4 운영 체크리스트

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[질문],
  [event schema],
  [type과 payload가 안정적인가?],
  [replay],
  [같은 event log로 UI 상태를 복원할 수 있는가?],
  [privacy],
  [tool input/output에 민감정보가 섞이지 않는가?],
  [fallback],
  [streaming 미지원 환경에서 final output만으로 동작하는가?],
)

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
  [event log, projection, UI state accumulation],
  [_핵심 개념_],
  [Event streaming은 답변 생성보다 “진행 상태를 안전하게 관찰하는 계약”입니다.],
  [_다음 단계_],
  [`08_integration/26_deepagents_frontend/` 후보],
)

#references-box[
- `docs/deepagents/event-streaming.md`
- `docs/deepagents/streaming.md`
- `docs/deepagents/frontend/subagent-streaming.md`
- `docs/langchain/event-streaming.md`
]
#chapter-end()
