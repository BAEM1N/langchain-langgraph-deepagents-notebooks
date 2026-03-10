// Auto-generated from 02_multi_agent_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "멀티에이전트: Subagents", subtitle: "감독자 패턴")

단일 에이전트로는 복잡한 도메인 요구사항을 충족하기 어렵습니다. `Subagents` 패턴은 중앙 감독자(Supervisor)가 전문화된 서브에이전트들을 `@tool`로 래핑하여 호출하는 3계층 아키텍처로, 역할 분리와 확장성을 동시에 달성합니다. 이 장에서는 감독자 → 서브에이전트 → 도구의 계층 구조를 설계하고, HITL 및 비동기 디스패치 패턴까지 실전 예제로 구현합니다.

#learning-header()
#learning-objectives([감독자 → 서브에이전트 → 도구의 3계층 아키텍처를 설계한다], [서브에이전트를 `@tool`로 래핑하여 감독자에게 도구로 노출한다], [HITL, ToolRuntime, 비동기/디스패치 패턴을 이해한다])

== 2.1 환경 설정

이전 장에서 미들웨어로 단일 에이전트의 동작을 제어하는 방법을 배웠습니다. 그러나 실무에서는 캘린더 관리, 이메일 처리, CRM 조회 등 여러 도메인을 동시에 다루는 에이전트가 필요합니다. 하나의 에이전트에 모든 도구를 넣으면 시스템 프롬프트가 비대해지고 도구 선택 정확도가 떨어집니다. 실제로 도구가 15개 이상일 때 단일 에이전트의 도구 선택 정확도는 눈에 띄게 하락한다는 것이 경험적으로 알려져 있습니다.

Subagents 패턴은 중앙 감독자(Supervisor) 에이전트가 전문화된 서브에이전트들을 도구처럼 호출하여 작업을 위임하는 멀티에이전트 아키텍처입니다. 이 패턴은 소프트웨어 공학의 _위임(delegation)_ 원칙을 에이전트 세계에 적용한 것으로, 각 서브에이전트는 자신의 도메인에만 집중하고, 감독자는 작업 분해와 결과 집계에 집중합니다. 이 노트북에서는 캘린더와 이메일 도메인을 처리하는 개인 비서 시스템을 구축합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 2.2 Subagents 아키텍처 개요

Subagents 패턴은 _3계층 아키텍처_로 구성됩니다. 감독자가 모든 라우팅을 담당하고, 서브에이전트는 사용자와 직접 상호작용하지 않으며, 결과를 감독자에게 반환합니다.

#align(center)[#image("../../assets/diagrams/png/supervisor_subagents.png", width: 86%, height: 96mm, fit: "contain")]

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

이 아키텍처의 네 가지 핵심 특성을 이해하면, 설계 시 올바른 판단을 내릴 수 있습니다.

- _중앙 집중 제어_: 모든 라우팅이 감독자를 통해 흐릅니다. 사용자는 감독자하고만 대화하며, 서브에이전트의 존재를 인지하지 못합니다.
- _컨텍스트 격리_: 서브에이전트는 매번 깨끗한 컨텍스트 윈도우에서 실행되어 컨텍스트 비대화를 방지합니다. 캘린더 에이전트는 이메일 대화 내용을 알 필요가 없습니다.
- _병렬 실행_: 여러 서브에이전트를 한 턴에서 동시에 호출할 수 있습니다. "미팅 잡고 이메일 보내줘"라는 요청에서 캘린더와 이메일 서브에이전트가 병렬로 동작합니다.
- _도구 기반 호출_: 서브에이전트를 `@tool`로 래핑하여 감독자에게 일반 도구처럼 노출합니다. 이를 통해 감독자는 서브에이전트와 일반 도구를 구별 없이 사용합니다.

=== 사용 시점

서브에이전트 패턴은 여러 도메인(캘린더, 이메일, CRM 등)을 관리하면서 서브에이전트가 사용자와 직접 대화할 필요 없고, 중앙화된 워크플로 관리가 필요할 때 적합합니다. 도구가 적은 단순한 시나리오에서는 단일 에이전트로 충분합니다.

#tip-box[서브에이전트 패턴 vs. 단일 에이전트 판단 기준: 도구가 10개 이상이거나, 도메인별로 서로 다른 시스템 프롬프트가 필요하거나, 도구 간 의존성이 복잡한 경우 서브에이전트 패턴이 유리합니다.]

아키텍처를 이해했으니, 이제 3계층의 최하층인 저수준 도구부터 Bottom-up으로 구현해 보겠습니다.

== 2.3 저수준 도구 정의

3계층 아키텍처의 최하층인 저수준 도구를 정의합니다. 이 도구들은 외부 서비스(Calendar API, Email API)와 직접 상호작용하는 단순한 함수 래퍼입니다. 실제 프로덕션에서는 Google Calendar API, Email Service 등과 연동하지만, 여기서는 학습을 위한 스텁(stub) 구현을 사용합니다.

도구를 설계할 때 중요한 점:
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

도구가 준비되었으면, 이제 이 도구들을 조합하여 도메인별 서브에이전트를 생성합니다. 서브에이전트는 저수준 도구를 직접 사용하여 도메인 내의 복합적인 작업을 수행하는 중간 계층입니다.

#warning-box[저수준 도구의 docstring은 서브에이전트(LLM)가 도구를 선택하는 데 사용됩니다. 모호하거나 중복된 설명은 잘못된 도구 선택의 원인이 됩니다. 각 도구의 역할이 명확히 구분되도록 docstring을 작성하세요.]

== 2.4 서브에이전트 생성

각 서브에이전트는 `create_agent()`로 생성하며, 세 가지 핵심 요소를 갖습니다:

+ _전문화된 시스템 프롬프트_: 도메인별 역할과 행동 지침을 정의합니다
+ _도메인별 도구 세트_: 해당 도메인의 도구만 할당하여 관심사를 분리합니다
+ *`name` 식별자*: 감독자가 서브에이전트를 구분하고 호출할 때 사용합니다

서브에이전트의 세분화 수준(granularity)은 도메인 단위(캘린더, 이메일 등)가 권장됩니다. 너무 세분화하면 감독자의 라우팅 부담이 증가하고, 너무 통합하면 컨텍스트 격리의 이점이 줄어듭니다.

#code-block(`````python
from langchain.agents import create_agent

calendar_agent = create_agent(
    model="gpt-4.1",
    tools=[create_calendar_event, read_calendar_events],
    system_prompt="당신은 캘린더 어시스턴트입니다. ISO 8601 날짜 형식을 사용하세요.",
    name="calendar_agent",
)
`````)

#code-block(`````python
email_agent = create_agent(
    model="gpt-4.1",
    tools=[send_email, read_emails, search_emails],
    system_prompt="당신은 이메일 어시스턴트입니다. 메시지를 전문적으로 작성하세요.",
    name="email_agent",
)
`````)

서브에이전트가 생성되었지만, 감독자 에이전트가 이를 호출하려면 _도구 인터페이스_로 래핑해야 합니다. 이것이 3계층 아키텍처의 핵심 연결 고리이며, Subagents 패턴의 가장 중요한 구현 단계입니다.

== 2.5 서브에이전트를 도구로 래핑

서브에이전트를 감독자에게 노출하는 표준 패턴은 `@tool` 데코레이터로 감싸는 것입니다. 래핑 함수 내부에서 `subagent.invoke()`를 호출하고, 마지막 메시지의 `content`를 반환합니다. 이 래핑 패턴은 _어댑터(Adapter)_ 디자인 패턴과 유사합니다. 서브에이전트의 복잡한 인터페이스를 감독자가 이해할 수 있는 단순한 도구 인터페이스로 변환합니다.

이 패턴의 장점:
- 감독자 입장에서 서브에이전트는 일반 도구와 동일하게 취급됩니다
- 서브에이전트의 내부 구현 변경이 감독자에 영향을 주지 않습니다
- 입출력 형식을 래핑 함수에서 자유롭게 커스터마이징할 수 있습니다

_입출력 전략 선택_: 쿼리만 전달(간단)할 수도 있고, 전체 컨텍스트를 전달(정교)할 수도 있습니다. 결과 반환 시에도 최종 결과만 반환하거나 전체 히스토리를 반환하는 선택지가 있습니다.

#tip-box[래핑 함수의 docstring이 감독자의 도구 선택에 결정적인 영향을 미칩니다. "캘린더 관련 모든 작업을 처리합니다"처럼 포괄적인 설명을 작성하세요. 감독자는 이 설명만 보고 어떤 서브에이전트를 호출할지 결정합니다.]

서브에이전트가 도구로 래핑되었으므로, 이제 이들을 조율할 감독자 에이전트를 조립할 차례입니다.

== 2.6 감독자 에이전트 조립

감독자는 래핑된 서브에이전트 도구들을 `tools`에 전달받아 생성됩니다. 감독자의 시스템 프롬프트에는 작업 분해(task decomposition) 및 위임(delegation) 지침을 포함합니다. 감독자는 사용자의 복합 요청을 분석하여 어떤 서브에이전트에게 어떤 부분을 위임할지 결정하는 _오케스트레이터_ 역할을 합니다.

감독자 설계 시 고려사항:
- _에러 처리_: 서브에이전트 실패를 감독자가 우아하게 처리해야 합니다. "이메일 전송에 실패했지만 미팅은 예약되었습니다"와 같은 부분 성공 보고가 필요합니다.
- _결과 집계_: 여러 서브에이전트의 결과를 통합하여 사용자에게 일관된 응답을 제공합니다
- _승인 범위_: 상태를 변경하는 작업(이메일 전송, 이벤트 생성)에만 HITL을 적용합니다

#code-block(`````python
supervisor = create_agent(
    model="gpt-4.1",
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

기본 감독자-서브에이전트 구조가 동작하는 것을 확인했습니다. 프로덕션 환경에서는 에이전트가 수행하는 고위험 작업(이메일 전송, 일정 변경 등)에 대해 인간 승인이 필요합니다. HITL 미들웨어를 감독자 레벨에 적용하면, 서브에이전트의 도구 호출이 아닌 서브에이전트 호출 자체를 승인 대상으로 설정할 수 있습니다.

== 2.8 HITL (Human-in-the-Loop) 통합

`HumanInTheLoopMiddleware`와 `checkpointer`를 결합하면 고위험 도구 호출(이메일 전송, 일정 생성 등) 전에 사용자 승인을 요청할 수 있습니다. 에이전트가 보호된 도구를 호출하려 할 때 실행이 일시 중지되고, 사용자가 검토합니다.

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
    model="gpt-4.1",
    tools=[call_calendar, call_email],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
    system_prompt="당신은 개인 비서입니다.",
)
`````)

HITL이 감독자 레벨에서 적용되면, 서브에이전트 호출 자체가 승인 대상이 됩니다. 즉, "이메일을 보내겠습니다"라는 서브에이전트 호출 전에 사용자 승인을 요청하므로, 서브에이전트 내부의 개별 도구 호출까지 일일이 승인할 필요가 없습니다. 이제 서브에이전트에 런타임 정보를 전달하는 방법을 살펴보겠습니다.

== 2.9 컨텍스트 전달 (ToolRuntime)

`ToolRuntime`은 런타임 컨텍스트(사용자 ID, 이름, 타임존 등)를 메시지에 포함하지 않고도 도구에 전달하는 메커니즘입니다. 매 프롬프트마다 반복적인 텍스트를 넣는 대신, `ToolRuntime`으로 공유 컨텍스트를 한 번만 설정합니다. 이는 프롬프트의 토큰 비용을 절감하면서도 도구가 필요한 모든 컨텍스트 정보에 접근할 수 있게 합니다.

도구 함수에서는 `runtime_context` 키워드 인자로 컨텍스트에 접근합니다. 이를 통해:
- 사용자 신원 정보를 도구가 활용할 수 있습니다 (예: 발신자 이메일 자동 설정)
- 환경 설정(타임존 등)을 일관되게 적용할 수 있습니다
- 프롬프트 길이를 줄여 토큰 비용을 절감합니다

#code-block(`````python
# ToolRuntime은 LangChain v1 에이전트의 런타임 컨텍스트 전달 메커니즘입니다.
# 아직 릴리스되지 않은 경우를 대비하여 폴백 처리합니다.
try:
    from langchain.runtime import ToolRuntime
except ImportError:
    # ToolRuntime이 아직 릴리스되지 않은 경우 간단한 대체 구현
    class ToolRuntime:
        """사전 릴리스 버전을 위한 폴백 ToolRuntime."""
        def __init__(self, context: dict):
            self.context = context
    print("ToolRuntime 미출시 — 폴백 스텁 사용")

runtime = ToolRuntime(context={
    "user_email": "me@example.com",
    "user_name": "Alice",
    "timezone": "Asia/Seoul",
})
`````)
#output-block(`````
ToolRuntime 미출시 — 폴백 스텁 사용
`````)

#code-block(`````python
supervisor_ctx = create_agent(
    model="gpt-4.1",
    tools=[call_calendar, call_email],
    system_prompt="당신은 개인 비서입니다.",
)
`````)

#code-block(`````python
# 도구에서 런타임 컨텍스트 접근
@tool
def send_email_ctx(
    to: str, subject: str, body: str, *, runtime_context: dict
) -> str:
    """현재 사용자로 이메일을 전송합니다."""
    sender = runtime_context["user_email"]
    return f"{sender}에서 {to}로 이메일 전송됨: '{subject}'"
`````)

컨텍스트 전달 메커니즘을 이해했으니, 이제 서브에이전트의 실행 모드에 대해 알아보겠습니다. 기본적으로 서브에이전트는 동기적으로 실행되지만, 일부 시나리오에서는 비동기 실행이 더 효율적입니다.

== 2.10 비동기 실행 패턴

서브에이전트의 실행 모드는 두 가지입니다. 작업의 성격과 의존 관계에 따라 적절한 모드를 선택합니다:

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
  [즉시 Job ID 반환, 백그라운드 실행, 나중에 결과 조회],
  [독립적인 작업, 장시간 소요 작업],
)

비동기 패턴은 _Job ID → Status → Result_ 구조를 따릅니다. 서브에이전트가 즉시 Job ID를 반환하면, 감독자는 다른 작업을 계속 진행하다가 나중에 결과를 조회합니다.

#code-block(`````python
import uuid
job_store = {}

@tool("schedule_async", description="이벤트 예약 (비동기)")
def call_calendar_async(query: str) -> str:
    """비동기 캘린더 작업을 시작하고 작업 ID를 반환합니다."""
    job_id = str(uuid.uuid4())[:8]
    job_store[job_id] = {"status": "done", "result": "이벤트 생성됨"}
    return f"작업 시작됨: {job_id}"
`````)

#code-block(`````python
@tool("check_job", description="비동기 작업 상태 확인")
def check_job(job_id: str) -> str:
    """비동기 작업의 상태를 확인합니다."""
    job = job_store.get(job_id, {"status": "not_found"})
    return f"상태: {job['status']}, 결과: {job.get('result')}"
`````)

#warning-box[비동기 패턴에서 `job_store`는 메모리에 저장되므로, 서버 재시작 시 작업 상태가 유실됩니다. 프로덕션에서는 Redis나 데이터베이스 기반 작업 큐(Celery, RQ 등)를 사용하세요.]

비동기 패턴까지 이해했다면, 마지막으로 서브에이전트 호출 방식의 확장성을 높이는 단일 디스패치 패턴을 살펴보겠습니다.

== 2.11 단일 디스패치 도구 패턴

서브에이전트가 늘어날수록 각각을 개별 도구로 래핑하는 것이 번거로워집니다. 단일 디스패치 패턴은 이 문제를 해결하는 확장 가능한 접근법입니다. 도구 패턴에는 두 가지 접근법이 있습니다:

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

단일 디스패치 패턴은 `agent_name` 파라미터로 호출 대상을 지정합니다. 에이전트 레지스트리에 등록된 서브에이전트를 이름으로 조회하여 호출하므로, 분산 팀에서 서브에이전트를 독립적으로 추가하거나 제거할 수 있어 확장성이 뛰어납니다.

#code-block(`````python
supervisor_dispatch = create_agent(
    model="gpt-4.1",
    tools=[dispatch],
    system_prompt=(
        "delegate 도구를 사용하여 작업을 라우팅하세요. "
        "에이전트: 'calendar'(일정), 'email'(이메일)."
    ),
)
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
  [_래핑_],
  [`\@tool` + `subagent.invoke()` → 마지막 content 반환],
  [_격리_],
  [서브에이전트 = 깨끗한 컨텍스트, 감독자만 전체 기억],
  [_HITL_],
  [`HumanInTheLoopMiddleware` + `InMemorySaver`],
  [_컨텍스트_],
  [`ToolRuntime(context={...})` → `runtime_context`],
  [_비동기_],
  [Job ID → Status → Result 패턴],
  [_디스패치_],
  [단일 `dispatch(agent_name, query)` 도구],
)

Subagents 패턴은 감독자가 모든 라우팅을 제어하는 _중앙 집중형_ 아키텍처입니다. 그러나 에이전트가 사용자와 직접 대화하면서 단계적으로 상태를 전이해야 하거나, 여러 소스에서 병렬로 정보를 수집해야 하는 경우에는 다른 패턴이 더 적합합니다. 다음 장에서는 `Command(goto=...)`로 상태를 전이하는 Handoffs 패턴과, `Send` API로 병렬 디스패치하는 Router 패턴을 학습합니다.


