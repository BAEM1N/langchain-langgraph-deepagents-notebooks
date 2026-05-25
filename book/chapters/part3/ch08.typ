// Auto-generated from 08_interrupts_and_time_travel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "인터럽트와 타임 트래블", subtitle: "실행 중단, 승인, 되감기")

7장에서 스트리밍을 통해 에이전트 실행을 _관찰_하는 방법을 배웠다면, 이 장에서는 실행 흐름을 _직접 제어_하는 방법을 다룹니다. 자율적으로 동작하는 에이전트에도 사람의 개입이 필요한 순간이 있습니다 --- 민감한 작업의 승인, 잘못된 판단의 교정, 또는 이전 분기점으로의 회귀가 그 예입니다.

`LangGraph`의 `interrupt(value)` 함수는 현재 상태를 체크포인트에 저장하고 실행을 일시 정지합니다. `value`는 사용자에게 전달할 메시지(예: "이 작업을 승인하시겠습니까?")입니다. 이후 `Command(resume=value)`으로 사용자 입력을 전달하면, `interrupt()`가 호출된 지점에서 실행이 재개되며 `resume` 값이 `interrupt()`의 반환값이 됩니다.

`compile()` 단계에서 `interrupt_before=["node_name"]` 또는 `interrupt_after=["node_name"]`을 지정하면, 특정 노드의 실행 전후에 자동으로 인터럽트를 발생시킬 수도 있습니다. 이 장에서는 인터럽트와 함께 체크포인트 히스토리를 활용한 타임 트래블까지 다루어, 에이전트 실행의 완전한 제어권을 확보합니다.

#learning-header()
`interrupt()`로 실행을 중단하고, `Command(resume=...)`로 재개합니다. 타임 트래블로 이전 상태로 돌아갑니다.

- Human-in-the-loop 패턴을 구현할 수 있습니다
- `interrupt_before` / `interrupt_after`로 노드 전후에 자동 인터럽트를 설정할 수 있습니다
- Functional API에서도 interrupt를 사용할 수 있습니다
- 체크포인트 히스토리를 활용한 타임 트래블을 수행할 수 있습니다
- `update_state()`로 외부에서 상태를 수정할 수 있습니다

== 8.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4-mini")
print("모델 준비 완료")
`````)
#output-block(`````
모델 준비 완료
`````)

== 8.2 interrupt() — 실행을 중단하고 사람의 입력을 기다립니다

에이전트가 자율적으로 행동하더라도, 특정 시점에서는 반드시 사람의 판단이 필요합니다. 예를 들어 데이터베이스 삭제 쿼리를 실행하기 전, 또는 외부 API에 결제 요청을 보내기 전에 사용자 확인을 받아야 합니다. `interrupt()`는 바로 이런 상황을 위해 설계되었습니다.

- `interrupt(value)`: 현재 상태를 체크포인트에 저장하고 실행을 중단합니다. `value`는 사용자에게 전달할 메시지로, 보통 승인 요청이나 추가 정보 요청 내용을 담습니다.
- `Command(resume=value)`: 중단된 지점에서 값을 전달하며 재개합니다

이 패턴은 민감한 작업 전에 사람의 승인을 받거나, 추가 정보를 입력받을 때 사용합니다. `interrupt()`가 호출되면 그래프 실행이 즉시 멈추고, 현재까지의 모든 상태가 체크포인터에 저장됩니다. 이 상태는 서버가 재시작되더라도 유지되므로, 사용자가 몇 시간 후에 응답하더라도 정확히 중단된 지점에서 재개할 수 있습니다.

#warning-box[`interrupt()`는 반드시 체크포인터가 설정된 그래프에서만 사용할 수 있습니다. 체크포인터 없이 `interrupt()`를 호출하면 상태를 저장할 수 없어 `RuntimeError`가 발생합니다. `compile(checkpointer=...)` 설정을 반드시 확인하세요.]

== 8.3 Command(resume=...) — 중단된 실행을 재개합니다

`interrupt()`로 실행을 멈추는 방법을 배웠으니, 이제 멈춘 실행을 다시 시작하는 방법을 살펴봅시다.

`Command(resume=value)`를 사용하면 `interrupt()`가 호출된 지점에서 실행이 재개됩니다. `resume`에 전달한 값이 `interrupt()`의 반환값이 됩니다. 이 메커니즘 덕분에 사용자의 입력이 노드 내부의 변수로 자연스럽게 전달됩니다.

예를 들어, 노드 내부에서 `answer = interrupt("이 작업을 승인하시겠습니까?")`로 중단하고, 사용자가 `Command(resume="승인")`으로 재개하면 `answer` 변수에 `"승인"` 문자열이 할당됩니다. 이후 노드는 이 값을 기반으로 분기 로직을 수행할 수 있습니다.

`Command(resume=...)`에 전달하는 값은 boolean, 텍스트, dict 어떤 형태든 가능합니다. 응답 형태에 따라 패턴이 달라집니다.

#code-block(`````python
from langgraph.types import Command

# 1) 단순 boolean — Approval
graph.invoke(Command(resume=True), config=config, version="v2")

# 2) 텍스트 — Review & Edit
graph.invoke(Command(resume="The edited text"), config=config, version="v2")

# 3) 구조화 dict — Tool interrupt / 다중 응답
graph.invoke(
    Command(resume={"action": "approve", "subject": "Updated subject"}),
    config=config,
    version="v2",
)
`````)

#tip-box[하나의 노드 안에서 `interrupt()`를 여러 번 호출할 수도 있습니다. 이 경우 각 `interrupt()`마다 별도의 `Command(resume=...)`가 필요하며, 호출 순서대로 재개됩니다. 다만 코드 가독성을 위해 하나의 노드에는 하나의 `interrupt()`만 두는 것이 권장됩니다.]

=== Common Patterns --- 5가지 HITL 시나리오

실무에서 자주 등장하는 인터럽트 패턴은 다음 다섯 가지입니다.

==== 1) Approval --- 민감 작업 승인

API 호출/DB 변경 같은 critical action 직전에 중단하고, 승인 여부에 따라 라우팅합니다.

#code-block(`````python
from typing import Literal
from langgraph.types import Command, interrupt

def approval_node(state) -> Command[Literal["proceed", "cancel"]]:
    decision = interrupt({
        "question": "Approve this action?",
        "details": state["action_details"],
    })
    return Command(goto="proceed" if decision else "cancel")

graph.invoke(Command(resume=True), config=config, version="v2")   # 승인
graph.invoke(Command(resume=False), config=config, version="v2")  # 거부
`````)

==== 2) Review & Edit --- LLM 출력 검수

LLM이 생성한 텍스트를 사람이 수정한 뒤 그래프에 다시 주입합니다.

#code-block(`````python
def review_node(state):
    edited = interrupt({
        "instruction": "Review and edit this content",
        "content": state["generated_text"],
    })
    return {"generated_text": edited}

graph.invoke(Command(resume="수정된 본문 ..."), config=config, version="v2")
`````)

==== 3) Tool Interrupt --- 툴 실행 직전 승인

`@tool` 함수 내부에 interrupt를 두면, 도구 실행 직전 사람이 승인·편집할 수 있습니다. resume payload는 보통 `{"action": "approve", ...}` 형태의 decision dict입니다.

#code-block(`````python
from langchain.tools import tool

@tool
def send_email(to: str, subject: str, body: str):
    response = interrupt({
        "action": "send_email",
        "to": to, "subject": subject, "body": body,
        "message": "Approve sending this email?",
    })
    if response.get("action") == "approve":
        return f"Email sent to {response.get('to', to)}"
    return "Email cancelled by user"
`````)

==== 4) Input Validation --- 유효성 검증 루프

루프 안에서 interrupt를 반복 호출해, 유효한 값이 들어올 때까지 다시 묻습니다.

#code-block(`````python
def get_age_node(state):
    prompt = "What is your age?"
    while True:
        answer = interrupt(prompt)
        if isinstance(answer, int) and answer > 0:
            break
        prompt = f"'{answer}' is not valid. Please enter a positive number."
    return {"age": answer}
`````)

==== 5) Multiple Interrupts --- 병렬 응답 매칭

병렬 노드가 동시에 interrupt를 일으키면, interrupt id를 키로 하는 resume map을 사용해 응답을 일대일로 매칭합니다.

#code-block(`````python
result = graph.invoke({"vals": []}, config, version="v2")

resume_map = {
    i.id: f"answer for {i.value}" for i in result.interrupts
}
graph.invoke(Command(resume=resume_map), config, version="v2")
`````)

== 8.4 interrupt_before / interrupt_after --- 컴파일 시점 인터럽트

코드 내부에 `interrupt()`를 직접 작성하는 방식 외에도, 그래프를 컴파일할 때 특정 노드의 전후에 자동으로 인터럽트를 설정할 수 있습니다. 이 방식은 기존 노드 코드를 수정하지 않고도 인터럽트를 추가할 수 있어, 이미 작성된 노드를 재사용할 때 특히 유용합니다.

`interrupt_before=["node_name"]`을 지정하면 해당 노드가 실행되기 _직전_에, `interrupt_after=["node_name"]`을 지정하면 노드 실행이 _완료된 직후_에 그래프가 자동으로 멈춥니다. 두 옵션 모두 `compile()` 메서드에 전달합니다.

#tip-box[`interrupt_before`와 `interrupt_after`는 노드 코드 내부의 `interrupt()` 호출과 달리, 사용자에게 값을 전달하거나 사용자로부터 값을 받을 수 없습니다. 단순히 "멈추기"만 합니다. 사용자 입력을 받아야 한다면 노드 내부에서 `interrupt(value)`를 직접 호출하세요.]

== 8.5 Functional API에서의 interrupt

Graph API에서 인터럽트를 사용하는 방법을 배웠으니, 이제 Functional API에서의 사용법을 살펴봅시다. Functional API(`@entrypoint`, `@task`)에서도 동일하게 `interrupt()`를 사용할 수 있습니다. `@task` 함수나 `@entrypoint` 함수 내부에서 `interrupt()`를 호출하면 동일한 중단/재개 패턴이 작동합니다.

Functional API의 장점은 데코레이터 기반의 간결한 구문으로 인터럽트를 설정할 수 있다는 점입니다. `@task` 함수는 자동으로 체크포인트 경계가 되므로, 함수 내부 어디서든 `interrupt()`를 호출할 수 있습니다.

#warning-box[Functional API에서 `interrupt()`를 사용할 때는 반드시 `\@entrypoint`에 체크포인터가 연결되어 있어야 합니다. 체크포인터 없이 `interrupt()`를 호출하면 상태를 저장할 수 없어 에러가 발생합니다.]

== 8.6 타임 트래블 --- 이전 체크포인트로 되돌아가기

인터럽트와 재개를 통해 실행 흐름을 _멈추고 다시 시작_하는 방법을 익혔습니다. 이제 한 걸음 더 나아가, 이미 지나간 시점으로 _되돌아가는_ 타임 트래블을 살펴봅시다.

인터럽트가 "실행을 멈추고 재개"하는 메커니즘이라면, 타임 트래블은 "이전 시점으로 _되돌아가서_ 다른 경로를 탐색"하는 메커니즘입니다. LangGraph의 체크포인트 시스템은 그래프 실행의 매 단계(슈퍼스텝)마다 상태를 자동으로 저장합니다. `get_state_history()`로 이전 체크포인트 목록을 조회하고, 특정 시점의 `config`를 사용하여 해당 시점에서 그래프를 다시 실행할 수 있습니다.

이 기능은 디버깅에 특히 유용합니다. 에이전트가 잘못된 판단을 한 지점을 찾아 해당 체크포인트로 돌아간 뒤, `update_state()`로 상태를 수정하고 다시 실행하면 됩니다. Git의 `checkout`이 특정 커밋으로 되돌아가는 것과 비슷하지만, LangGraph의 타임 트래블은 되돌아간 시점에서 _다른 경로로 분기_할 수 있다는 점이 다릅니다.

#tip-box[`get_state_history()`는 가장 최근 체크포인트부터 역순으로 반환합니다. 각 체크포인트에는 `config`, `values`(상태 값), `next`(다음 실행될 노드), `created_at`(생성 시각) 등의 메타데이터가 포함되어 있어, 어떤 시점으로 돌아갈지 정확히 판단할 수 있습니다.]

== 8.7 update_state() --- 타임 트래블 + 상태 수정

타임 트래블로 이전 시점을 확인할 수 있다면, `update_state()`로 해당 시점의 상태를 _수정_한 뒤 실행을 재개하는 것도 가능합니다. 이는 디버깅, 테스트, 또는 수동 개입이 필요한 경우에 유용합니다.

`update_state(config, values)`는 두 개의 인자를 받습니다. `config`는 수정할 체크포인트를 지정하고, `values`는 변경할 상태 필드를 딕셔너리로 전달합니다. 선택적으로 `as_node` 인자를 전달하면, 해당 노드가 상태를 업데이트한 것처럼 처리되어 리듀서가 올바르게 적용됩니다.

#warning-box[`update_state()`는 기존 체크포인트를 변경하는 것이 아니라 _새로운_ 체크포인트를 생성합니다. 따라서 원본 실행 이력은 그대로 보존되며, 수정 후에도 원래 경로로 돌아갈 수 있습니다. 이는 불변(immutable) 로그 방식으로 감사 추적(audit trail)에 적합합니다.]

=== Replay vs Fork --- 두 가지 타임 트래블 동작

LangGraph의 타임 트래블은 두 가지 동작으로 나뉩니다.

- *Replay* --- 이전 체크포인트에서 그대로 다시 실행합니다. `next`로 지정된 노드부터 재실행되며, LLM/API 호출도 다시 일어납니다(결과가 달라질 수 있음).
- *Fork* --- 이전 체크포인트에서 state를 수정한 새 branch를 만들어 대체 경로를 탐색합니다. 원본 thread는 그대로 보존됩니다.

#code-block(`````python
# Replay — checkpoint config 그대로 invoke
history = list(graph.get_state_history(config))
before_joke = next(s for s in history if s.next == ("write_joke",))
replay_result = graph.invoke(None, before_joke.config)

# Fork — update_state로 새 branch 생성
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
)
fork_result = graph.invoke(None, fork_config)
`````)

#tip-box[`update_state()`의 반환값(`fork_config`)을 그대로 `invoke()`에 넘기면, 수정된 새 체크포인트에서 실행이 이어집니다. `before.config`가 아니라 `fork_config`를 사용한다는 점이 중요합니다.]

=== as_node --- 업데이트의 출처 노드 지정

`update_state(config, values, as_node="...")`로 "이 업데이트를 발생시킨 것으로 간주할" 노드를 명시할 수 있습니다. 다음 상황에서 유용합니다.

- 병렬 branch 때문에 어느 노드가 update를 만들었는지 모호할 때
- 새 thread에 초기 state를 주입하는 테스트 시나리오
- 의도적으로 특정 노드를 건너뛰고, 그 노드 _이후_부터 재개하고 싶을 때

#code-block(`````python
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
    as_node="generate_topic",  # 이 노드의 후속 노드부터 재개
)
graph.invoke(None, fork_config)
`````)

=== Reducer 동작 --- 병합 vs 덮어쓰기

`update_state()`로 전달한 `values`는 채널의 reducer 여부에 따라 적용 방식이 달라집니다.

- _리듀서가 설정된 채널_(예: `MessagesState`의 `messages` --- `add_messages` 리듀서) → 기존 값과 _병합(merge)_. 메시지를 추가하면 누적됩니다.
- _리듀서가 없는 채널_(평범한 `TypedDict` 필드 등) → _덮어쓰기(overwrite)_. 새 값이 그대로 대체합니다.

따라서 메시지 한 건을 _교체_하려면 `RemoveMessage(id=...)` + 새 메시지를 함께 보내야 하고, 단순 dict 필드는 그냥 `values={"field": new_value}`로 덮어쓰면 됩니다.

#chapter-summary-header()

이 장에서는 에이전트 실행의 _제어권_을 확보하는 두 가지 핵심 메커니즘을 학습했습니다. `interrupt()`와 `Command(resume=...)`를 통한 Human-in-the-loop 패턴, 그리고 `get_state_history()`와 `update_state()`를 통한 타임 트래블입니다. 이 기능들은 체크포인터 시스템 위에 구축되어 있으며, 프로덕션 환경에서 에이전트의 안전성과 디버깅 가능성을 보장합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[API],
  text(weight: "bold")[설명],
  [`interrupt(value)`],
  [양쪽],
  [실행 중단, 값 전달],
  [`Command(resume=value)`],
  [양쪽],
  [중단 지점에서 재개],
  [`get_state_history()`],
  [Graph],
  [체크포인트 이력 조회],
  [`update_state()`],
  [Graph],
  [외부에서 상태 수정],
)

_interrupt와 타임 트래블_은 프로덕션 AI 애플리케이션에서 핵심적인 기능입니다:
- _interrupt_: 민감한 작업 전 사람의 승인을 받을 수 있습니다
- _타임 트래블_: 이전 상태로 되돌아가 다른 경로를 탐색할 수 있습니다
- _update_state_: 외부에서 상태를 수정하여 실행 흐름을 조정할 수 있습니다

#next-step-box[다음 장에서는 복잡한 워크플로를 _모듈화_하는 서브그래프를 다룹니다. 독립적인 그래프를 부모 그래프의 노드로 삽입하고, 상태 매핑과 서브그래프 내부의 인터럽트 전파까지 살펴봅니다.]

#chapter-end()
