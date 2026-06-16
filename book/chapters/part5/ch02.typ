// Auto-generated from 02_multi_agent_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "멀티에이전트: Subagents", subtitle: "감독자 패턴")

== 학습 목표
#learning-objectives([감독자 → 서브에이전트 → 도구의 3계층 아키텍처를 설계한다], [서브에이전트를 `@tool`로 래핑하거나 Deep Agents의 `SubAgentMiddleware`로 일괄 등록한다], [서브에이전트 상태 관리(상속 vs `checkpointer=True`), HITL, `ToolRuntime[None, CustomState]` 컨텍스트 주입을 익힌다], [디스패치 도구 노출 3가지(시스템 프롬프트 열거 / `Literal` 제약 / 도구 기반 발견)와 비동기 5-tool 패턴(start/check/update/cancel/list)을 구분해 적용한다])

== 2.1 환경 설정

Subagents 패턴은 중앙 감독자(Supervisor) 에이전트가 전문화된 서브에이전트들을 도구처럼 호출해 작업을 위임하는 멀티에이전트 아키텍처입니다. 캘린더와 이메일 도메인을 처리하는 개인 비서 시스템을 구축합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-5.4")
`````)

== 2.2 Subagents 아키텍처 개요

Subagents 패턴은 _3계층 아키텍처_로 구성됩니다. 감독자가 모든 라우팅을 담당하고, 서브에이전트는 사용자와 직접 상호작용하지 않으며, 결과를 감독자에게 반환합니다.

#image("../../assets/images/supervisor_subagents.png")

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[계층],
  text(weight: "bold")[역할],
  text(weight: "bold")[특징],
  [_저수준 도구_],
  [외부 서비스 직접 호출 (Calendar API, Email API)],
  [단순한 함수 래퍼],
  [_서브에이전트_],
  [도메인별 추론 + 도구 조합],
  [전문 시스템 프롬프트, 독립적 도구 세트],
  [_감독자_],
  [작업 분해, 위임, 결과 집계],
  [전체 대화 기억, 서브에이전트 = 도구로 취급],
)

=== 핵심 특성

- _중앙 집중 제어_: 모든 라우팅이 감독자를 통해 흐릅니다
- _컨텍스트 격리_: 서브에이전트는 매번 깨끗한 컨텍스트 윈도우에서 실행되어 컨텍스트 비대화를 방지합니다
- _병렬 실행_: 여러 서브에이전트를 한 턴에서 동시에 호출할 수 있습니다
- _도구 기반 호출_: 서브에이전트를 `@tool`로 래핑하여 감독자에게 일반 도구처럼 노출합니다

=== 사용 시점

서브에이전트 패턴은 여러 도메인(캘린더, 이메일, CRM 등)을 관리하면서 서브에이전트가 사용자와 직접 대화할 필요 없고, 중앙화된 워크플로 관리가 필요할 때 적합합니다. 도구가 적은 단순한 시나리오에서는 단일 에이전트로 충분합니다.

== 2.3 저수준 도구 정의

3계층 아키텍처의 최하층인 저수준 도구를 정의합니다. 외부 서비스(Calendar API, Email API)와 직접 상호작용하는 단순한 함수 래퍼입니다. 실제 프로덕션에서는 Google Calendar API, Email Service 등과 연동하지만, 여기서는 학습용 스텁(stub) 구현을 사용합니다.

도구 설계 시 주의할 점:
- 하나의 도구는 하나의 기능만 담당 (단일 책임 원칙)
- 동일한 도구를 여러 서브에이전트에 중복 할당하지 않아야 합니다
- docstring을 명확하게 작성하여 LLM이 도구를 올바르게 선택할 수 있게 합니다

#code-block(`````python
from langchain_core.tools import tool

@tool
def create_calendar_event(
    title: str, start_time: str, end_time: str,
    attendees: list[str] = None,
) -> str:
    """새 캘린더 이벤트를 생성합니다."""
    return f"이벤트 '{title}' 생성됨: {start_time} ~ {end_time}"
`````)

#code-block(`````python
@tool
def read_calendar_events(date: str) -> str:
    """날짜(YYYY-MM-DD)의 캘린더 이벤트를 조회합니다."""
    return f"{date}에 이벤트가 없습니다."
`````)

#code-block(`````python
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """이메일 메시지를 전송합니다."""
    return f"{to}에게 이메일 전송됨: '{subject}'"

@tool
def read_emails(folder: str = "inbox", limit: int = 10) -> str:
    """폴더에서 최근 이메일을 읽습니다."""
    return f"{folder}에 이메일 3개"
`````)

#code-block(`````python
@tool
def search_emails(query: str, limit: int = 10) -> str:
    """검색어로 이메일을 검색합니다."""
    return f"'{query}' 검색 결과 2건"
`````)

== 2.4 서브에이전트 생성

각 서브에이전트는 `create_agent()`로 생성하며, 세 가지 핵심 요소를 갖습니다:

+ _전문화된 시스템 프롬프트_: 도메인별 역할과 행동 지침을 정의합니다
+ _도메인별 도구 세트_: 해당 도메인의 도구만 할당하여 관심사를 분리합니다
+ _`name` 식별자_: 감독자가 서브에이전트를 구분하고 호출할 때 사용합니다

서브에이전트의 세분화 수준(granularity)은 도메인 단위(캘린더, 이메일 등)가 권장됩니다. 너무 세분화하면 감독자의 라우팅 부담이 커지고, 너무 통합하면 컨텍스트 격리의 이점이 줄어듭니다.

=== 상태 관리 모드

서브에이전트는 두 가지 체크포인트 모드를 지원합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설정],
  text(weight: "bold")[동작],
  [_상속(Inherited)_ — 기본],
  [`checkpointer` 미지정],
  [매 호출이 깨끗한 상태로 시작. 부모 체크포인터를 투명하게 공유. 인터럽트·병렬 실행에 안전],
  [_영구(Persistent)_],
  [`checkpointer=True`],
  [서브에이전트가 호출 간 자체 대화 히스토리를 유지. 이전 턴을 부모와 독립적으로 기억해야 할 때],
)

#code-block(`````python
calendar_agent_persistent = create_agent(
    model="claude-sonnet-4-6",
    tools=[create_calendar_event, read_calendar_events],
    system_prompt="당신은 캘린더 어시스턴트입니다.",
    name="calendar_agent",
    checkpointer=True,   # 호출 간 자체 히스토리 유지
)
`````)

#tip-box[서브그래프의 `get_state`는 nested agent state 를 반환하지 않습니다(정적 발견 한계). 인터럽트 중에는 노드 함수에서 상태를 확인하세요.]

#code-block(`````python
from langchain.agents import create_agent

calendar_agent = create_agent(
    model="gpt-5.4",
    tools=[create_calendar_event, read_calendar_events],
    system_prompt="당신은 캘린더 어시스턴트입니다. ISO 8601 날짜 형식을 사용하세요.",
    name="calendar_agent",
)
`````)

#code-block(`````python
email_agent = create_agent(
    model="gpt-5.4",
    tools=[send_email, read_emails, search_emails],
    system_prompt="당신은 이메일 어시스턴트입니다. 메시지를 전문적으로 작성하세요.",
    name="email_agent",
)
`````)

== 2.5 서브에이전트를 도구로 래핑

서브에이전트를 감독자에게 노출하는 표준 패턴은 `@tool` 데코레이터로 감싸는 것입니다. 래핑 함수 내부에서 `subagent.invoke()`를 호출하고, 마지막 메시지의 `content`를 반환합니다.

이 패턴의 장점:
- 감독자 입장에서 서브에이전트는 일반 도구와 동일하게 취급됩니다
- 서브에이전트의 내부 구현이 바뀌어도 감독자에 영향을 주지 않습니다
- 입출력 형식을 래핑 함수에서 자유롭게 커스터마이징할 수 있습니다

_입출력 전략 선택_: 쿼리만 전달(간단)할 수도 있고, 전체 컨텍스트를 전달(정교)할 수도 있습니다. 결과 반환 시에도 최종 결과만 반환하거나 전체 히스토리를 반환하는 선택지가 있습니다.

== 2.6 감독자 에이전트 조립

감독자는 래핑된 서브에이전트 도구들을 `tools`에 전달받아 생성됩니다. 감독자의 시스템 프롬프트에는 작업 분해(task decomposition) 및 위임(delegation) 지침을 포함합니다.

감독자 설계 시 고려사항:
- _에러 처리_: 서브에이전트 실패를 감독자가 적절히 처리해야 합니다
- _결과 집계_: 여러 서브에이전트의 결과를 통합하여 사용자에게 일관된 응답을 제공합니다
- _승인 범위_: 상태를 변경하는 작업(이메일 전송, 이벤트 생성)에만 HITL을 적용합니다

#code-block(`````python
supervisor = create_agent(
    model="gpt-5.4",
    tools=[call_calendar, call_email],
    system_prompt=(
        "당신은 개인 비서입니다. 복잡한 요청을 "
        "하위 작업으로 분해하고 적절한 에이전트에 위임하세요."
    ),
)
`````)

== 2.7 실행 테스트

#code-block(`````python
User: "내일 2시 Sarah 미팅 잡고 초대 이메일 보내줘"
Supervisor → call_calendar → create_calendar_event
Supervisor → call_email → send_email
Supervisor: "미팅과 초대 이메일 완료"
`````)

== 2.8 HITL (Human-in-the-Loop) 통합

`HumanInTheLoopMiddleware`와 `checkpointer`를 결합하면 고위험 도구 호출(이메일 전송, 일정 생성 등) 전에 사용자 승인을 요청할 수 있습니다. 에이전트가 보호된 도구를 호출하려 하면 실행이 일시 중지되고, 사용자가 검토합니다.

=== 승인 응답 유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[응답],
  text(weight: "bold")[설명],
  text(weight: "bold")[코드],
  [_승인(Approve)_],
  [도구 호출을 그대로 실행],
  [`Command(resume="approve")`],
  [_편집(Edit)_],
  [도구 인자를 수정 후 실행],
  [`Command(resume={"type": "edit", "args": {...}})`],
  [_거부(Reject)_],
  [도구 호출을 취소],
  [`Command(resume={"type": "reject", "reason": "..."})`],
)

HITL은 상태를 변경하는 작업(send_email, create_calendar_event 등)에만 적용하는 것이 권장됩니다. 읽기 전용 작업에는 불필요한 마찰을 줄이기 위해 적용하지 않습니다.

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

hitl = HumanInTheLoopMiddleware(interrupt_on={
    "schedule_event": {"allowed_decisions": ["approve", "edit", "reject"]},
    "manage_email": {"allowed_decisions": ["approve", "reject"]},
})
`````)

#code-block(`````python
supervisor_hitl = create_agent(
    model="gpt-5.4",
    tools=[call_calendar, call_email],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
    system_prompt="당신은 개인 비서입니다.",
)
`````)

== 2.9 컨텍스트 주입 — `ToolRuntime[None, CustomState]`

서브에이전트를 호출하는 도구는 `ToolRuntime[ContextSchema, StateSchema]` 시그니처로 _부모 에이전트의 상태와 컨텍스트_에 접근할 수 있습니다. 두 번째 타입 매개변수가 부모 `state_schema`이므로, 여기서 메시지 히스토리·사용자 ID·임의의 상태 키를 끌어와 서브에이전트 입력에 주입합니다.

- 첫 번째 매개변수가 `None`이면 컨텍스트 스키마 없이 상태만 주입합니다.
- `runtime.context.<field>` 로 정적 런타임 컨텍스트(사용자 ID, DB 연결)에 접근합니다.
- `runtime.state["messages"]` 등 부모 상태 키를 그대로 읽을 수 있습니다.

#code-block(`````python
from langchain.tools import tool, ToolRuntime
from langchain.agents import AgentState

class SupervisorState(AgentState):
    user_id: str

@tool
def call_research_agent(query: str, runtime: ToolRuntime[None, SupervisorState]) -> str:
    """부모 상태의 메시지 히스토리를 함께 전달."""
    history = runtime.state["messages"]
    result = research_agent.invoke({"messages": history + [{"role": "user", "content": query}]})
    return result["messages"][-1].content
`````)

매 프롬프트마다 텍스트로 반복 주입하지 않고도 사용자 신원·타임존·중간 결과를 서브에이전트에 흘려보낼 수 있어 토큰 비용과 일관성이 모두 개선됩니다.

#code-block(`````python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime
from langchain.agents import AgentState, create_agent

@dataclass
class UserContext:
    user_email: str
    user_name: str
    timezone: str

class SupervisorState(AgentState):
    # 부모 에이전트가 보유한 추가 상태 키 예시
    user_id: str
`````)

#code-block(`````python
supervisor_ctx = create_agent(
    model="gpt-5.4",
    tools=[call_calendar, call_email],
    system_prompt="당신은 개인 비서입니다.",
    context_schema=UserContext,
    state_schema=SupervisorState,
)
`````)

#code-block(`````python
# 도구에서 부모 상태 + 컨텍스트 동시 접근
@tool
def send_email_ctx(
    to: str, subject: str, body: str,
    runtime: ToolRuntime[UserContext, SupervisorState],
) -> str:
    """현재 사용자로 이메일을 전송합니다."""
    sender = runtime.context.user_email
    user_id = runtime.state.get("user_id", "anon")
    return f"[{user_id}] {sender}에서 {to}로 이메일 전송: '{subject}'"
`````)

== 2.10 비동기 실행 패턴 — 5-tool 워크플로

서브에이전트의 실행 모드는 두 가지입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[동작],
  text(weight: "bold")[사용 시점],
  [_동기(Synchronous)_],
  [감독자가 서브에이전트 완료를 대기 후 다음 진행],
  [결과가 다음 작업에 필요할 때 (기본값)],
  [_비동기(Asynchronous)_],
  [즉시 task id 반환, 백그라운드 실행, 도중에 지시·취소 가능],
  [장시간 작업, 병렬 다중 서브에이전트, mid-flight steering 필요 시],
)

Deep Agents 0.5+ 의 `AsyncSubAgentMiddleware` 는 감독자에게 다음 _5개 도구_를 자동 주입합니다 — 비동기 라이프사이클의 단위 연산을 그대로 매핑한 형태입니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  [`start_async_task`],
  [서브에이전트 백그라운드 기동, task id 즉시 반환],
  [`check_async_task`],
  [상태 조회, 완료 시 최종 출력 추출],
  [`update_async_task`],
  [같은 thread 에 follow-up 지시 주입 (interrupt)],
  [`cancel_async_task`],
  [서버에 cancel 신호 전송],
  [`list_async_tasks`],
  [추적 중 모든 task 의 live 상태 일괄 조회],
)

비동기 모드는 Agent Protocol 서버(LangSmith Deployments, `langgraph dev`)를 요구합니다. `async_tasks` state 채널이 메시지 히스토리와 분리되어 있어, 감독자 컨텍스트가 요약되어도 task id 가 유실되지 않습니다.

아래 학습용 스텁은 5개 도구의 시그니처와 흐름을 직접 구현해 본 예시입니다. 실제 프로덕션에서는 `AsyncSubAgent(name=..., graph_id=...)` 를 `create_deep_agent(subagents=...)` 에 넘기면 충분합니다.

#code-block(`````python
import uuid
from datetime import datetime

job_store: dict[str, dict] = {}

@tool("start_async_task", description="서브에이전트 백그라운드 기동, task id 반환")
def start_async_task(agent_name: str, instruction: str) -> str:
    """비동기 서브에이전트 작업을 시작하고 task id를 반환합니다."""
    task_id = "task_" + uuid.uuid4().hex[:12]
    job_store[task_id] = {
        "agent": agent_name,
        "status": "running",
        "instruction": instruction,
        "result": None,
        "created_at": datetime.utcnow().isoformat(),
    }
    return f"started {task_id} (agent={agent_name})"

@tool("check_async_task", description="task 상태 조회 / 완료 시 결과 추출")
def check_async_task(task_id: str) -> str:
    job = job_store.get(task_id)
    if not job:
        return f"not_found: {task_id}"
    # 학습용 스텁: 한 번 호출되면 완료로 표시
    if job["status"] == "running":
        job["status"] = "success"
        job["result"] = f"{job['agent']} 결과: {job['instruction'][:60]}"
    return f"{task_id} status={job['status']} result={job.get('result')!r}"
`````)

#code-block(`````python
@tool("update_async_task", description="실행 중 task 에 follow-up 지시 주입")
def update_async_task(task_id: str, instruction: str) -> str:
    job = job_store.get(task_id)
    if not job:
        return f"not_found: {task_id}"
    job["instruction"] = instruction
    job["status"] = "running"   # interrupt 기반 재기동
    return f"updated {task_id} with new instruction"

@tool("cancel_async_task", description="task 취소")
def cancel_async_task(task_id: str) -> str:
    job = job_store.get(task_id)
    if not job:
        return f"not_found: {task_id}"
    job["status"] = "cancelled"
    return f"cancelled {task_id}"

@tool("list_async_tasks", description="추적 중 task 일괄 조회")
def list_async_tasks() -> str:
    if not job_store:
        return "no tasks"
    return "\n".join(
        f"{tid} agent={j['agent']} status={j['status']}"
        for tid, j in job_store.items()
    )
`````)

== 2.11 단일 디스패치 도구 패턴

도구 패턴에는 두 가지 접근법이 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[설명],
  text(weight: "bold")[장점],
  [_에이전트별 도구_],
  [서브에이전트마다 별도의 래핑 도구 생성],
  [세밀한 제어, description 커스터마이징 용이],
  [_단일 디스패치 도구_],
  [하나의 파라미터화된 도구로 모든 서브에이전트 호출],
  [확장성 우수, 서브에이전트 추가/제거가 독립적],
)

단일 디스패치 도구가 감독자에게 _어떤 서브에이전트가 있는지 알려주는 방식_은 3가지로 나뉩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[적합한 규모],
  text(weight: "bold")[트레이드오프],
  [_시스템 프롬프트 열거_],
  [10개 미만, 정적 레지스트리],
  [가장 단순. 프롬프트 수동 업데이트 필요],
  [_`Literal` / Enum 제약_],
  [10개 미만, 타입 안전],
  [스키마 레벨 검증, 프롬프트 부담 없음],
  [_도구 기반 발견_],
  [대규모/동적 레지스트리],
  [Progressive disclosure, 와이어링 복잡],
)

`Literal` 제약 패턴은 `agent_name` 파라미터에 가능한 값을 타입으로 못박아 LLM 이 잘못된 이름을 만들 수 없게 합니다. 대규모 레지스트리라면 `list_agents` 도구를 따로 두고 감독자가 필요할 때 조회하도록 합니다.

=== Deep Agents — `SubAgentMiddleware` 로 일괄 등록

수동으로 `@tool` 래핑하는 대신, Deep Agents 의 `SubAgentMiddleware` 가 `task` 디스패치 도구와 표준 시스템 프롬프트를 자동 주입합니다. 동기 서브에이전트가 하나라도 있으면 자동 부착되며 `excluded_middleware` 로 제거할 수 없습니다.

#code-block(`````python
supervisor_dispatch = create_agent(
    model="gpt-5.4",
    tools=[dispatch],
    system_prompt=(
        "delegate 도구를 사용하여 작업을 라우팅하세요. "
        "에이전트: 'calendar'(일정), 'email'(이메일)."
    ),
)
`````)

#code-block(`````python
# Deep Agents — SubAgentMiddleware 로 일괄 등록 (수동 @tool 래핑 불필요)
from deepagents.middleware.subagents import SubAgentMiddleware

supervisor_dag = create_agent(
    model="claude-sonnet-4-6",
    middleware=[
        SubAgentMiddleware(
            default_model="claude-sonnet-4-6",
            default_tools=[],
            subagents=[
                {
                    "name": "calendar",
                    "description": "캘린더 이벤트 생성/조회",
                    "system_prompt": "당신은 캘린더 어시스턴트입니다. ISO 8601 사용.",
                    "tools": [create_calendar_event, read_calendar_events],
                },
                {
                    "name": "email",
                    "description": "이메일 전송/읽기/검색",
                    "system_prompt": "당신은 이메일 어시스턴트입니다.",
                    "tools": [send_email, read_emails, search_emails],
                    "model": "gpt-5.4",   # 서브에이전트별 모델 오버라이드
                },
            ],
        ),
    ],
)
# 감독자는 자동 주입된 `task(subagent_name, instruction)` 도구로 위임
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_3계층_],
  [도구 → 서브에이전트(`create_agent`) → 감독자],
  [_수동 래핑_],
  [`\@tool` + `subagent.invoke()` → 마지막 content 반환],
  [_Deep Agents_],
  [`SubAgentMiddleware`(`subagents=[{...}]`) — `task` 디스패치 도구 자동 주입],
  [_체크포인트 모드_],
  [상속(기본) vs `checkpointer=True`(서브에이전트 자체 히스토리)],
  [_격리_],
  [서브에이전트 = 깨끗한 컨텍스트, 감독자만 전체 기억],
  [_HITL_],
  [`HumanInTheLoopMiddleware` + 체크포인터, decision: approve/edit/reject],
  [_컨텍스트_],
  [`ToolRuntime[ContextSchema, ParentState]` — 부모 state·context 동시 주입],
  [_비동기 5-tool_],
  [`start_async_task` / `check_async_task` / `update_async_task` / `cancel_async_task` / `list_async_tasks`],
  [_디스패치 노출_],
  [프롬프트 열거 / `Literal` 제약 / 도구 기반 발견],
)
