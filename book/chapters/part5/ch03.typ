// Auto-generated from 03_multi_agent_handoffs_router.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "멀티에이전트: Handoffs & Router", subtitle: "상태 머신과 병렬 라우팅")

멀티에이전트 시스템의 또 다른 핵심 패턴인 `Handoffs`와 `Router`를 다룹니다. `Handoffs`는 단일 에이전트가 상태 변수에 따라 프롬프트와 도구를 동적으로 교체하는 상태 머신 방식이며, `Router`는 쿼리를 분류하여 전문 에이전트들에게 `Send` API로 병렬 라우팅한 뒤 결과를 합성하는 방식입니다. 두 패턴을 비교하여 상황에 맞는 멀티에이전트 아키텍처를 선택할 수 있는 판단력을 기릅니다.

#learning-header()
#learning-objectives([Handoffs 패턴: 상태 변수 기반 동적 구성(프롬프트 + 도구 교체)을 구현한다], [`Command` 객체로 상태 전이를 도구에서 트리거한다], [Router 패턴: 구조화 출력 분류 → `Send` API 병렬 실행 → 결과 합성])

#line(length: 100%, stroke: 0.5pt + luma(200))
== Part A — Handoffs: Customer Support 상태 머신
#line(length: 100%, stroke: 0.5pt + luma(200))

== 3.1 환경 설정

이전 장의 Subagents 패턴은 감독자가 서브에이전트를 도구로 호출하는 구조였습니다. 이 장에서 다루는 두 패턴은 근본적으로 다른 접근법을 취합니다:

- _Part A — Handoffs_: 단일 에이전트가 상태 변수에 따라 동적으로 프롬프트와 도구를 교체하는 상태 머신 패턴. `Command(update={...})`로 상태 전이를 트리거합니다. 고객 지원처럼 _순차적 단계_를 거치는 워크플로에 적합합니다.
- _Part B — Router_: 쿼리를 분류하여 전문 에이전트들에게 `Send` API로 병렬 라우팅하고 결과를 합성하는 패턴. 여러 지식 소스에서 _동시에_ 정보를 수집해야 할 때 적합합니다.

이 두 패턴과 Subagents를 비교하여, 상황에 맞는 멀티에이전트 아키텍처를 선택하는 판단력을 기릅니다. 세 패턴의 핵심 차이는 _제어 흐름_에 있습니다: Subagents는 감독자가 제어하고, Handoffs는 상태가 제어하며, Router는 분류 결과가 제어합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 3.2 Handoffs 개요

Handoffs 패턴은 _단일 에이전트_가 상태 변수에 따라 동적으로 행동을 바꾸는 아키텍처입니다. 여러 에이전트를 전환하는 것이 아니라, 하나의 에이전트가 단계(step)에 따라 다른 시스템 프롬프트와 도구 세트를 사용합니다. 이를 유한 상태 머신(Finite State Machine)에 비유할 수 있습니다. 각 상태는 에이전트의 "페르소나"를 정의하고, 전이 조건은 도구가 반환하는 `Command` 객체로 결정됩니다.

#align(center)[#image("../../assets/diagrams/png/handoffs_state_machine.png", width: 92%, height: 82mm, fit: "contain")]

=== 핵심 메커니즘

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메커니즘],
  text(weight: "bold")[설명],
  [`current_step`],
  [현재 단계를 추적하는 상태 변수. 이 값에 따라 에이전트의 행동이 결정됩니다],
  [`Command(update={...})`],
  [도구가 반환하여 상태 전이를 트리거. `current_step` 변경 + 추가 데이터 저장],
  [`\@wrap_model_call`],
  [미들웨어가 `current_step`을 읽어 시스템 프롬프트와 사용 가능 도구를 동적으로 교체],
)

=== Handoffs의 핵심 특성

- _상태 주도 행동(State-driven behavior)_: 추적된 상태 변수에 따라 설정이 조정됩니다
- _도구 기반 전이(Tool-based transitions)_: 도구가 `Command` 객체를 반환하여 상태를 업데이트합니다
- _직접 사용자 상호작용_: 각 단계에서 독립적으로 메시지를 처리합니다
- _영속 상태(Persistent state)_: 상태가 대화 턴을 넘어 유지됩니다

#warning-box[도구가 `Command`를 통해 메시지를 업데이트할 때, 매칭되는 `tool_call_id`를 가진 `ToolMessage`를 포함해야 합니다.]

=== 중요한 구현 세부사항

도구가 `Command`를 통해 메시지를 업데이트할 때, 매칭되는 `tool_call_id`를 가진 `ToolMessage`를 포함해야 합니다. LLM은 도구 호출과 응답이 쌍을 이루길 기대하므로, 이를 누락하면 대화 히스토리가 잘못된 형태(malformed)가 됩니다.

=== 사용 시점

순차적 제약(sequential constraints)이 필요하거나, 각 상태에서 사용자와 직접 대화하거나, 다단계 플로우(예: 고객 지원)에서 정보를 특정 순서로 수집해야 할 때 적합합니다. 반면, 단계 간 순서가 유연하거나 병렬 실행이 필요한 경우에는 Subagents나 Router 패턴이 더 적합합니다.

#tip-box[Handoffs vs. Subagents 선택 기준: 사용자가 각 단계에서 에이전트와 _직접_ 대화해야 하면 Handoffs, 사용자가 감독자와만 대화하고 서브에이전트는 백그라운드에서 동작하면 Subagents를 선택하세요.]

개념을 이해했으니, 이제 고객 지원 시나리오를 예제로 Handoffs 패턴을 단계별로 구현합니다. 먼저 상태 스키마를 정의합니다.

== 3.3 SupportState 정의

`AgentState`를 상속하여 `current_step` 필드를 추가합니다. 이 필드가 상태 머신의 현재 노드를 결정하며, `Literal` 타입으로 유효한 단계를 제한합니다.

기본값은 `"identify_customer"`로, 모든 대화가 고객 식별 단계에서 시작됩니다. 이후 도구가 `Command(update={"current_step": "..."})` 를 반환하면 자동으로 다음 단계로 전이됩니다.

#code-block(`````python
from langchain.agents import AgentState
from typing import Literal

class SupportState(AgentState):
    current_step: Literal[
        "identify_customer", "diagnose_issue",
        "resolve_issue", "close_ticket",
    ] = "identify_customer"
`````)

상태 스키마가 정의되었으므로, 이제 각 단계에서 사용할 도구를 정의합니다. 도구는 Handoffs 패턴에서 상태 전이를 트리거하는 핵심 메커니즘입니다.

== 3.4 단계별 도구 정의

각 단계(step)에는 해당 단계의 역할에 맞는 도구들이 할당됩니다. 도구는 두 가지 유형으로 나뉩니다:

- _상태 전이 도구_: `Command(update={...})`를 반환하여 `current_step`을 변경하고 추가 데이터를 상태에 저장합니다. `result` 필드로 LLM에게 보여줄 문자열 결과도 함께 전달합니다.
- _일반 도구_: 문자열을 반환하며 상태를 변경하지 않습니다. 정보 조회 등에 사용됩니다.

설계 권장사항:
- 상태 전이는 `Command`를 반환하는 도구를 통해서만 이루어져야 합니다
- 역방향 전이(이전 단계로 되돌아가기)도 필요 시 허용합니다
- 미들웨어에서 유효하지 않은 전이를 검증하여 단계 건너뛰기를 방지합니다

#code-block(`````python
from langchain_core.tools import tool
from langgraph.types import Command

# --- Identify Customer ---
@tool
def lookup_customer(email: str) -> Command:
    """이메일로 고객을 조회합니다."""
    return Command(
        update={"customer": {"name": "Alice", "id": "C-1234"}, "current_step": "diagnose_issue"},
        result="고객 찾음: Alice (C-1234). 진단 단계로 이동합니다.",
    )
`````)

#code-block(`````python
# --- Diagnose Issue ---
@tool
def check_service_status(service_name: str) -> str:
    """서비스의 현재 상태를 확인합니다."""
    return f"서비스 '{service_name}': 정상 (99.9% 가동률)"
`````)

#code-block(`````python
@tool
def escalate_to_resolve(diagnosis: str) -> Command:
    """진단 후 해결 단계로 이동합니다."""
    return Command(
        update={"diagnosis": diagnosis, "current_step": "resolve_issue"},
        result=f"진단 완료: {diagnosis}. 해결 단계로 이동합니다.",
    )
`````)

#code-block(`````python
# --- Resolve Issue ---
@tool
def apply_fix(fix_type: str, customer_id: str) -> Command:
    """고객 계정에 수정 사항을 적용합니다."""
    return Command(
        update={"resolution": {"type": fix_type}},
        result=f"수정 적용됨: {customer_id}에 {fix_type}",
    )
`````)

#code-block(`````python
@tool
def mark_resolved(summary: str) -> Command:
    """이슈를 해결 완료로 표시하고 종료 단계로 이동합니다."""
    return Command(
        update={"current_step": "close_ticket", "resolution_summary": summary},
        result="해결됨. 종료 단계로 이동합니다.",
    )
`````)

#code-block(`````python
# --- Close Ticket ---
@tool
def send_satisfaction_survey(customer_id: str) -> str:
    """만족도 설문을 전송합니다."""
    return "설문 전송 완료."

@tool
def close_ticket(ticket_id: str, notes: str) -> str:
    """지원 티켓을 종료합니다."""
    return f"티켓 {ticket_id} 종료됨."
`````)

모든 단계의 도구가 준비되었습니다. 이제 이 도구들을 `current_step` 상태에 따라 동적으로 할당하는 미들웨어를 구현합니다. 이 미들웨어가 Handoffs 패턴의 "두뇌" 역할을 합니다.

== 3.5 \@wrap_model_call 미들웨어

`@wrap_model_call` 미들웨어는 Handoffs 패턴의 핵심입니다. LLM 호출을 가로채어 `current_step`에 따라 시스템 프롬프트와 사용 가능 도구를 동적으로 교체합니다. Chapter 1에서 배운 `wrap_model_call`의 실전 적용 사례입니다.

_동작 순서:_
+ 미들웨어가 상태에서 `current_step` 값을 읽습니다
+ `STEP_CONFIG` 딕셔너리에서 해당 단계의 설정(프롬프트 + 도구)을 조회합니다
+ `config`를 오버라이드하여 LLM에 전달합니다
+ `next_fn(state, config)`으로 수정된 설정으로 LLM을 호출합니다

이것이 Handoffs의 핵심 메커니즘입니다: 단일 에이전트가 상태에 따라 완전히 다른 페르소나와 능력을 갖게 됩니다. 다중 에이전트를 만들 필요 없이, 미들웨어 하나로 동적 행동 변경을 달성합니다.

#warning-box[`STEP_CONFIG`에 정의되지 않은 `current_step` 값이 설정되면 `KeyError`가 발생합니다. 프로덕션 코드에서는 반드시 디폴트 처리나 유효성 검증을 추가하세요. 예: `cfg = STEP_CONFIG.get(step, STEP_CONFIG["identify_customer"])`]

다음 코드는 단계별 설정 딕셔너리와 이를 활용하는 미들웨어 구현입니다.

#code-block(`````python
STEP_CONFIG = {
    "identify_customer": {
        "tools": [lookup_customer],
        "system_prompt": "고객을 식별하세요. 이메일 또는 계정 ID를 요청하세요.",
    },
    "diagnose_issue": {
        "tools": [check_service_status, escalate_to_resolve],
        "system_prompt": "이슈를 진단하세요. 도구를 사용한 후 escalate_to_resolve를 호출하세요.",
    },
}
`````)

#code-block(`````python
STEP_CONFIG["resolve_issue"] = {
    "tools": [apply_fix, mark_resolved],
    "system_prompt": "이슈를 해결하세요. 수정을 적용한 후 mark_resolved를 호출하세요.",
}
STEP_CONFIG["close_ticket"] = {
    "tools": [send_satisfaction_survey, close_ticket],
    "system_prompt": "고객에게 감사를 전하고, 설문을 보내고, 티켓을 종료하세요.",
}
`````)

#code-block(`````python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def step_middleware(request, handler):
    """current_step에 따라 에이전트를 동적으로 구성합니다."""
    step = request.state.get("current_step", "identify_customer")
    cfg = STEP_CONFIG[step]
    request = request.override(
        system_prompt=cfg["system_prompt"],
        tools=cfg["tools"],
    )
    return handler(request)
`````)

== 3.6 에이전트 생성 및 실행 흐름

에이전트 생성 시 모든 도구를 등록하되, `state_schema=SupportState`와 미들웨어를 지정합니다. 미들웨어가 런타임에 `current_step`에 따라 도구를 필터링하므로, 각 단계에서는 해당 단계의 도구만 LLM에 노출됩니다.

_실행 흐름 예시:_
#code-block(`````python
[identify_customer] User: "로그인이 안 돼요. 이메일: alice@example.com"
  → lookup_customer("alice@example.com")
  ← Command(update={customer: {...}, current_step: "diagnose_issue"})

[diagnose_issue] Agent: "계정을 찾았습니다. 어떤 문제가 있나요?"
  → check_service_status("auth-service") → "healthy"
  → escalate_to_resolve("3회 로그인 실패로 잠김")

[resolve_issue] → apply_fix("reset_password", "C-1234")
  → mark_resolved("비밀번호 재설정 완료")

[close_ticket] → send_satisfaction_survey("C-1234")
  → close_ticket("T-5678", notes="비밀번호 재설정")
`````)

각 단계 전이는 `Command`를 반환하는 도구에 의해 자동으로 이루어집니다.

#code-block(`````python
from langchain.agents import create_agent

all_tools = [
    lookup_customer, check_service_status,
    escalate_to_resolve, apply_fix, mark_resolved,
    send_satisfaction_survey, close_ticket,
]
support_agent = create_agent(
    model="gpt-4.1", tools=all_tools,
    state_schema=SupportState, middleware=[step_middleware],
)
`````)

#code-block(`````python
# [identify_customer]
#   User: "Can't log in. Email: alice@example.com"
#   Agent -> lookup_customer("alice@example.com")
#        <- Command(update={current_step: "diagnose_issue"})
#
# [diagnose_issue] (auto transition)
#   Agent -> check_service_status("auth-service")
#   Agent -> escalate_to_resolve("Locked out")
#
# [resolve_issue] -> [close_ticket]
`````)

Part A에서는 단일 에이전트가 상태 전이를 통해 다단계 워크플로를 처리하는 Handoffs 패턴을 살펴보았습니다. Part B에서는 이와 대조적인 접근법인 Router 패턴을 다룹니다. Router는 _병렬 실행_이 핵심이며, 여러 지식 소스에서 동시에 정보를 수집하여 합성하는 데 최적화되어 있습니다.

#line(length: 100%, stroke: 0.5pt + luma(200))
== Part B — Router: 병렬 라우팅과 결과 합성
#line(length: 100%, stroke: 0.5pt + luma(200))

== 3.7 Router 개요

Router 패턴은 입력을 분류하여 전문 에이전트들에게 라우팅하는 아키텍처입니다. Subagents 패턴과 달리, Router는 _전용 분류 단계_(단일 LLM 호출 또는 규칙 기반 로직)를 거쳐 쿼리를 배분합니다. 이 패턴은 검색 엔진의 _fan-out/fan-in_ 아키텍처와 유사합니다. 쿼리를 여러 인덱스에 동시에 보내고(fan-out), 결과를 수집하여 통합합니다(fan-in).

#align(center)[#image("../../assets/diagrams/png/router_fanout_fanin.png", width: 68%, height: 122mm, fit: "contain")]

=== 파이프라인

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[역할],
  text(weight: "bold")[구현],
  [_분류(Classification)_],
  [쿼리를 분석하여 관련 소스와 서브쿼리를 생성],
  [`with_structured_output(QueryClassification)`],
  [_병렬 디스패치_],
  [분류된 각 소스에 동시에 서브쿼리 전달],
  [`Send` API],
  [_결과 합성(Reduction)_],
  [모든 에이전트 결과를 수집하여 통합 응답 생성],
  [Reducer 노드 + LLM],
)

=== Router vs. Subagents 비교

Router는 "전용 라우팅 단계(분류)"가 있고, Subagents는 "감독자 에이전트가 동적으로" 호출 대상을 결정합니다. 별개의 지식 도메인(vertical)이 명확히 구분되어 있고 병렬 조회가 필요할 때 Router가 적합합니다. 반면, 여러 도메인을 조율하면서 대화형 상호작용이 필요하면 Subagents가 더 적합합니다.

#tip-box[Router의 분류 단계에서 `with_structured_output`을 사용하면 분류 결과가 Pydantic 모델로 반환되어 타입 안전한 라우팅이 가능합니다. 규칙 기반 분류(if/else)는 빠르지만 유연성이 떨어지고, LLM 기반 분류는 느리지만 복잡한 쿼리도 처리할 수 있습니다.]

=== 아키텍처 모드

- _Stateless_: 각 요청이 독립적으로 라우팅됩니다 (메모리 없음)
- _Stateful_: 대화 히스토리를 유지하여 멀티턴 상호작용을 지원합니다. Stateless 라우터를 도구로 래핑하거나, 라우터 자체가 상태를 직접 관리하는 방식이 있습니다

Router의 전체 아키텍처를 이해했으니, 이제 분류 스키마와 상태를 정의합니다. 분류 스키마의 품질이 라우팅의 정확도를 직접적으로 결정하므로, 필드 설계에 신중해야 합니다.

== 3.8 RouterState 및 분류 스키마

`QueryClassification`은 Pydantic 모델로, LLM의 `with_structured_output()`을 통해 쿼리를 구조화된 형태로 분류합니다. `RouterState`는 분류 결과, 소스 목록, 서브쿼리, 에이전트 결과를 추적합니다.

분류 스키마의 핵심 필드:
- `sources`: 어떤 지식 소스가 관련 있는지 (복수 선택 가능)
- `reasoning`: 왜 해당 소스를 선택했는지 설명
- `sub_queries`: 소스별로 최적화된 서브쿼리 (원래 쿼리를 각 소스에 맞게 재구성)

#code-block(`````python
from pydantic import BaseModel, Field
from typing import Literal

class SubQuery(BaseModel):
    """소스별 하위 쿼리."""
    source: Literal["github", "notion", "slack"] = Field(description="지식 소스.")
    query: str = Field(description="해당 소스에 최적화된 검색 쿼리.")

class QueryClassification(BaseModel):
    """사용자 쿼리의 분류 결과."""
    sources: list[Literal["github", "notion", "slack"]] = Field(
        description="관련 지식 소스."
    )
    reasoning: str = Field(description="해당 소스를 선택한 이유.")
    sub_queries: list[SubQuery] = Field(description="소스별 하위 쿼리.")
`````)

#code-block(`````python
from langchain.agents import AgentState

class RouterState(AgentState):
    classification: QueryClassification = None
    sources: list[str] = []
    sub_queries: list[SubQuery] = []
    agent_results: list[dict] = []
`````)

== 3.9 분류 노드

`with_structured_output`으로 쿼리를 소스별로 분류하고, 각 소스에 최적화된 서브쿼리를 생성합니다.

=== 분류 예시

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[사용자 쿼리],
  text(weight: "bold")[분류 소스],
  text(weight: "bold")[이유],
  ["auth 서비스 배포 방법"],
  [`["github", "notion"]`],
  [배포 코드는 GitHub, 절차 문서는 Notion에 존재],
  ["API 변경 결정 경위"],
  [`["slack", "notion"]`],
  [논의는 Slack, 결정 문서는 Notion에 기록],
  ["로그인 버그 PR"],
  [`["github"]`],
  [PR은 GitHub에만 존재],
  ["온보딩 프로세스와 스타터 레포"],
  [`["github", "notion", "slack"]`],
  [레포는 GitHub, 프로세스는 Notion, 맥락은 Slack],
)

서브쿼리 생성이 중요합니다: "auth 서비스 배포"라는 원본 쿼리를 GitHub에는 `"auth service deployment scripts CI/CD pipeline"`, Notion에는 `"auth service deployment process procedure runbook"`으로 각각 최적화합니다.

분류가 완료되면, 각 소스에 서브쿼리를 동시에 전달하는 병렬 라우팅 단계로 진입합니다. 이 단계가 Router 패턴의 성능 이점을 실현하는 핵심입니다.

== 3.10 병렬 라우팅 (Send API)

`Send` API는 분류된 각 소스에 동시에 서브쿼리를 디스패치합니다. `Send(node_name, payload)` 형태로, 그래프의 특정 노드에 데이터를 병렬로 전달합니다. LangGraph의 `Send`는 MapReduce 패턴의 Map 단계에 해당합니다.

이 병렬 실행이 Router 패턴의 핵심 강점입니다: 여러 지식 소스를 순차적으로 조회하면 지연 시간이 합산되지만, `Send`를 통한 병렬 실행은 가장 느린 소스의 응답 시간만큼만 걸립니다. 예를 들어, GitHub(2초), Notion(1초), Slack(3초)을 순차 조회하면 6초가 걸리지만, 병렬 실행하면 3초면 충분합니다.

#warning-box[`Send` API로 병렬 실행할 때, 각 에이전트 노드의 상태는 독립적입니다. 에이전트 간에 상태를 공유하려면 Reducer 노드에서 결과를 수집한 후 처리해야 합니다.]

=== 새로운 소스 추가하기

Router 패턴은 확장이 간단합니다:
+ 소스별 도구를 정의합니다
+ 전문 에이전트를 생성합니다
+ `QueryClassification.sources`에 새 소스를 추가합니다
+ 그래프에 에이전트 노드를 추가합니다
+ Reducer에 연결합니다

#code-block(`````python
from langchain_core.tools import tool
from langchain.agents import create_agent

@tool
def search_github_code(query: str) -> str:
    """GitHub 저장소를 검색합니다."""
    return f"'{query}'에 대한 GitHub 결과"

@tool
def search_notion_pages(query: str) -> str:
    """Notion 워크스페이스를 검색합니다."""
    return f"'{query}'에 대한 Notion 결과"
`````)

#code-block(`````python
@tool
def search_slack_messages(query: str) -> str:
    """Slack 메시지를 검색합니다."""
    return f"'{query}'에 대한 Slack 결과"
`````)

#code-block(`````python
github_agent = create_agent(
    model="gpt-4.1", tools=[search_github_code],
    system_prompt="GitHub에서 코드와 PR을 검색합니다.",
    name="github_agent",
)
notion_agent = create_agent(
    model="gpt-4.1", tools=[search_notion_pages],
    system_prompt="Notion에서 문서를 검색합니다.",
    name="notion_agent",
)
`````)

#code-block(`````python
slack_agent = create_agent(
    model="gpt-4.1", tools=[search_slack_messages],
    system_prompt="Slack에서 토론을 검색합니다.",
    name="slack_agent",
)
`````)

#code-block(`````python
from langgraph.types import Send

def dispatch_to_agents(state):
    """하위 쿼리를 에이전트들에게 병렬로 전달합니다."""
    cls = state["classification"]
    sq_dict = {sq.source: sq.query for sq in cls.sub_queries}
    return [
        Send(src, {"messages": [{"role": "user", "content": sq_dict.get(src, "")}], "source": src})
        for src in cls.sources
    ]
`````)

== 3.11 결과 합성

모든 에이전트의 결과가 수집되면 Reducer 노드에서 통합 응답을 합성합니다. 이 단계는 MapReduce의 Reduce에 해당하며, 단순한 결과 나열이 아닌 _의미 있는 통합_이 목표입니다. Reducer는 LLM을 사용하여 통합된 응답을 합성합니다. 합성 시 각 정보의 출처(source)를 인용하여 사용자가 어디서 온 정보인지 파악할 수 있게 합니다.

합성 프롬프트에서는 소스를 명시하도록 지시합니다. 예를 들어, "배포 스크립트는 GitHub의 `payment-service` 레포에 있고(GitHub), 배포 절차는 Notion의 'Payment Service Ops' 문서를 참고하세요(Notion)"와 같이 응답합니다.

#code-block(`````python
from langgraph.graph import StateGraph, START, END

graph = StateGraph(RouterState)
graph.add_node("router", route_query)
graph.add_node("github", github_agent)
graph.add_node("notion", notion_agent)
graph.add_node("slack", slack_agent)
graph.add_node("reducer", reduce_results)
`````)
#output-block(`````
<langgraph.graph.state.StateGraph at 0x1bfb57ab230>
`````)

#code-block(`````python
graph.add_edge(START, "router")
graph.add_conditional_edges("router", dispatch_to_agents)
graph.add_edge("github", "reducer")
graph.add_edge("notion", "reducer")
graph.add_edge("slack", "reducer")
graph.add_edge("reducer", END)

app = graph.compile()
`````)

#chapter-summary-header()

=== Part A — Handoffs

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_패턴_],
  [단일 에이전트 + `current_step` 기반 동적 구성],
  [_전이_],
  [`Command(update={"current_step": "next"})`],
  [_동적 구성_],
  [`\@wrap_model_call`로 프롬프트 + 도구 교체],
)

=== Part B — Router

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_분류_],
  [`with_structured_output(QueryClassification)`],
  [_병렬_],
  [`Send(source, payload)` API],
  [_합성_],
  [Reducer 노드에서 LLM 통합 응답],
)

Handoffs, Router, Subagents 세 가지 멀티에이전트 패턴을 모두 학습했습니다. 패턴 선택의 핵심 기준을 정리하면: _순차적 다단계 워크플로_에는 Handoffs, _중앙 집중 위임과 대화형 상호작용_에는 Subagents, _병렬 지식 검색과 결과 합성_에는 Router가 적합합니다. 실제 프로젝트에서는 이 패턴들을 조합하여 사용하는 경우도 많습니다. 예를 들어, 감독자(Subagents)가 Router를 서브에이전트로 호출하여 병렬 검색 후 결과를 통합하는 구성이 가능합니다.

다음 장에서는 이 모든 패턴의 기반이 되는 컨텍스트 엔지니어링과 장기 메모리 시스템을 심층적으로 다룹니다.


