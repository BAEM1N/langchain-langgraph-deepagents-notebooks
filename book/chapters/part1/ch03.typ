// Auto-generated from 03_langchain_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "LangChain 대화", subtitle: "멀티턴 메모리")

앞 장에서 만든 에이전트는 매 호출마다 모든 것을 잊습니다. "내 이름은 철수야"라고 말한 뒤 "내 이름이 뭐야?"라고 물으면, 에이전트는 답하지 못합니다. `invoke()`는 기본적으로 상태를 유지하지 않기 때문입니다. 이 장에서는 체크포인터를 사용하여 에이전트에 대화 기억 능력을 추가합니다.

#learning-header()
#learning-objectives([`InMemorySaver`로 대화 상태를 저장한다], [`thread_id`로 대화 세션을 구분한다], [에이전트가 이전 문맥을 기억하는 멀티턴 대화를 실행한다])

== 3.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
`````)

먼저 메모리가 없는 에이전트의 한계를 직접 확인해 봅시다.

== 3.2 메모리 없는 에이전트의 한계

기본 에이전트는 _상태를 저장하지 않습니다_. 매번 새로운 대화로 취급하므로, 이전 대화에서 사용자가 제공한 정보(이름, 선호도 등)를 전혀 기억하지 못합니다. `invoke()`는 입력 메시지를 처리하고 결과를 반환한 뒤 아무것도 보존하지 않기 때문입니다.

이 문제를 해결하기 위해 LangGraph의 체크포인터 시스템을 사용합니다.

== 3.3 InMemorySaver로 메모리 추가

_단기 메모리(Short-term Memory)_란 단일 대화 스레드 내에서 이전 상호작용의 정보를 유지하는 기능입니다. `InMemorySaver`는 그래프의 전체 상태(메시지 히스토리 포함)를 Python 딕셔너리에 저장하는 체크포인터입니다. 각 항목은 `thread_id`로 구분됩니다.

에이전트가 `thread_id`와 함께 호출되면, LangGraph는 이전 상태를 로드하고, 새 메시지를 추가하고, 에이전트를 실행한 뒤, 업데이트된 상태를 다시 저장합니다. 이것이 의미하는 바는:
- 같은 `thread_id` = 연속된 대화 (이전 맥락 유지)
- 다른 `thread_id` = 완전히 별개의 대화
- `InMemorySaver`의 데이터는 Python 프로세스가 종료되면 사라집니다 (메모리 내 저장)

프로덕션 환경에서는 프로세스 재시작 후에도 대화가 유지되어야 합니다. LangGraph는 `PostgresSaver`(PostgreSQL)와 `SqliteSaver`(SQLite) 같은 영속적 체크포인터를 제공합니다. API는 동일하므로 `InMemorySaver()`를 `PostgresSaver(connection_string)`으로 교체하기만 하면 됩니다. 체크포인터는 "타임 트래블" 기능도 지원하여, 이전 체크포인트에서 에이전트 실행을 재생할 수 있습니다.

=== 대화 히스토리 관리 전략

LLM은 유한한 컨텍스트 윈도우를 가지고 있으므로, 긴 대화는 토큰 제한을 초과하여 오류를 발생시킬 수 있습니다. 이를 방지하기 위한 세 가지 전략이 있습니다:

- _트리밍(Trimming)_: 최근 N개의 메시지만 유지합니다. 구현이 단순하지만 초기 맥락이 손실됩니다.
- _요약(Summarization)_: 오래된 메시지를 주기적으로 하나의 요약 메시지로 압축합니다. 핵심 정보를 보존하면서 토큰을 절약합니다.
- _삭제(Deletion)_: 특정 메시지(예: 중간 도구 호출)를 제거하여 노이즈를 줄입니다.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    model=model,
    tools=[add],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "session-1"}}
print("\u2713 메모리 에이전트 생성 완료")
`````)
#output-block(`````
✓ 메모리 에이전트 생성 완료
`````)

메모리가 추가된 에이전트를 스트리밍으로 실행하면, 각 단계에서 에이전트가 이전 대화를 기억하는 모습을 실시간으로 관찰할 수 있습니다.

== 3.4 스트리밍으로 실시간 확인

`agent.stream()`으로 에이전트의 각 단계를 실시간으로 관찰합니다. LangGraph는 여러 스트리밍 모드를 제공합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  [`"updates"`],
  [각 노드의 변경 사항만 반환 — "모델이 도구 X를 호출함", "도구가 Y를 반환함" 등. 가장 간결한 출력],
  [`"values"`],
  [각 노드 실행 후 전체 상태를 반환. 더 자세하지만 전체 그림 파악에 유용],
  [`"messages"`],
  [개별 LLM 토큰과 메타데이터를 반환. 실시간 UI 렌더링에 최적],
)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [`InMemorySaver`],
  [메모리 내 대화 상태 저장 (체크포인터)],
  [`thread_id`],
  [대화 세션 구분 키],
  [`checkpointer=`],
  [`create_agent()`에 체크포인터 전달],
  [`stream(mode="updates")`],
  [에이전트 실행 단계를 실시간 확인],
)

지금까지 LangChain의 `create_agent()`가 내부적으로 처리해주던 것들을 직접 구성해보고 싶다면, 다음 장에서 배울 LangGraph의 `StateGraph`가 그 방법입니다.

