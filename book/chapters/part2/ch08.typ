// Auto-generated from 08_multi_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "멀티 에이전트 패턴")

== 학습 목표
5가지 멀티 에이전트 패턴을 이해하고 구현합니다.

이 노트북에서 다루는 내용:
- _Subagents_: 메인 에이전트가 전문 서브에이전트를 도구로 호출
- _Handoffs_: `Command(goto=...)`로 에이전트 간 상태 전환
- _Skills_: 단일 에이전트가 상황에 따라 전문 프롬프트를 로드
- _Router_: 분류기가 입력을 적절한 에이전트로 라우팅
- _Custom_: 개발자가 완전히 제어하는 복잡한 워크플로

== 8.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 준비 완료:", model.model_name)
`````)
#output-block(`````
모델 준비 완료: gpt-5.4
`````)

#code-block(`````python
# Observability 설정 (선택) - LangSmith 또는 Langfuse
# .env에 키를 설정하거나, 아래 주석을 해제하여 직접 입력하세요.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: LANGSMITH_TRACING=true 시 자동 활성화 (코드 수정 불필요)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON \u2014 project: {project}")

# Langfuse: invoke/stream 호출 시 config={"callbacks": [langfuse_handler]} 전달
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)
#output-block(`````
Langfuse tracing ON — https://lf.ddok.ai
`````)

== 8.2 멀티 에이전트 패턴 비교

아래 표는 5가지 멀티 에이전트 패턴을 비교합니다. 각 패턴은 서로 다른 상황에 적합하므로, 프로젝트 요구사항에 맞게 선택해야 합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[라우팅 주체],
  text(weight: "bold")[상태 공유],
  text(weight: "bold")[적합한 상황],
  [_Subagents_],
  [메인 에이전트],
  [도구로 격리],
  [병렬 처리, 분산 개발],
  [_Handoffs_],
  [도구 호출],
  [상태 전환],
  [순차적 멀티홉],
  [_Skills_],
  [단일 에이전트],
  [프롬프트 교체],
  [도메인 특화],
  [_Router_],
  [분류기],
  [병렬 실행],
  [멀티 도메인],
  [_Custom_],
  [개발자 정의],
  [완전 제어],
  [복잡한 워크플로],
)

=== 핵심 차이점
- _Subagents_는 각 서브에이전트가 독립적으로 실행되어 결과만 반환합니다.
- _Handoffs_는 대화 상태가 에이전트 간에 전달됩니다.
- _Skills_는 하나의 에이전트가 여러 역할을 전환합니다.
- _Router_는 입력을 분류한 뒤 적절한 에이전트에게 위임합니다.

=== 패턴 선택 매트릭스 (요구사항 → 최적 패턴)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[요구사항],
  text(weight: "bold")[최적 패턴],
  text(weight: "bold")[이유],
  [1],
  [_One-shot 단순 작업_ — 한 번의 도구 호출로 끝나는 단일 도메인],
  [_Single agent_ (멀티 에이전트 불필요)],
  [오버헤드만 늘어남. `create_agent` 한 개로 충분],
  [2],
  [_반복(repeat) 호출_ — 같은 도구를 여러 번 호출해 데이터를 축적],
  [_Subagents_],
  [메인이 결과를 모으며, 각 subagent 호출이 독립 컨텍스트로 격리됨],
  [3],
  [_병렬 멀티 도메인_ — 분류 후 도메인별 전문가에게 동시 분배],
  [_Router_ (+ `Send`)],
  [분류 노드 → fan-out. 동시 실행으로 지연 최소화],
  [4],
  [_대용량 컨텍스트_ — 문서 1만 토큰 이상을 부분별로 분석],
  [_Subagents_ (격리된 컨텍스트) 또는 _Skills_],
  [메인 에이전트 토큰을 보존. Skills는 프롬프트 교체로 추가 도구 없이 처리],
  [5],
  [_팀 기반(team-based)_ — 여러 역할이 서로 결과를 검토·반복],
  [_Handoffs_],
  [`Command(goto=...)`로 대화 상태가 다음 역할로 전달됨],
  [6],
  [_다이렉트 대화(direct conversation)_ — 사용자와 끊김 없이 대화하면서 부서 이관],
  [_Handoffs_ (subgraph + conversation history)],
  [메시지 히스토리가 보존되어 사용자가 같은 톤·맥락으로 계속 진행 가능],
)

=== 성능 비교 (3-step task 기준)

같은 3-step 작업을 패턴별로 수행했을 때 도구 호출 횟수와 컨텍스트 비용(approx.):

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[시나리오],
  text(weight: "bold")[패턴],
  text(weight: "bold")[도구 호출 수],
  text(weight: "bold")[컨텍스트(approx.)],
  text(weight: "bold")[비고],
  [_One-Shot_ (단일 질의)],
  [Single agent],
  [1 call],
  [~3K],
  [베이스라인],
  [_Repeat_ (반복 검색·집계)],
  [Subagents],
  [_4–5 calls_],
  [_~9K_],
  [권장],
  [_Multi-Domain_ (병렬 분배)],
  [Router (+ Send)],
  [3 calls],
  [_~9K_],
  [분류 1 + 도메인 fan-out 병렬],
)

#tip-box[수치는 `docs/langchain/22-multi-agent.md` 기준 추정치. 실제는 모델·프롬프트·tool schema에 따라 ±30% 변동.]

=== Router vs Supervisor 용어

#tip-box[_Router_ — _단순 함수형_ 라우팅. 입력을 분류한 뒤 결정론적으로 다음 노드를 선택합니다. 대화 상태를 인식하지 않고, 한 번 위임하면 끝납니다. (예: `classify_query()` → `math` / `code` / `general` 분기)]
\>
#tip-box[_Supervisor_ — _대화 인식(conversation-aware)_ 감독자. 메시지 히스토리를 보면서 다음 단계에 어떤 subagent를 호출할지 LLM이 판단합니다. 반복 호출, 결과 통합, 재시도 의사결정이 가능합니다. (LangChain v1에서는 `create_agent` + subagent 도구 묶음 = 사실상 supervisor 패턴)]
\>
#note-box[본 노트북의 8.3은 _Supervisor_(LLM이 위임 판단), 8.6은 _Router_(함수형 분류)입니다.]

== 8.3 서브에이전트 패턴

메인 에이전트(감독자)가 전문 서브에이전트를 _도구로_ 호출하는 패턴입니다.

=== 특징
- 각 서브에이전트는 도구 함수로 캡슐화됩니다.
- 메인 에이전트가 어떤 서브에이전트를 호출할지 판단합니다.
- 서브에이전트의 내부 상태는 메인 에이전트와 격리됩니다.
- 병렬 실행이 가능하여 성능에 유리합니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

# 전문 도구 정의
@tool
def math_expert(question: str) -> str:
    """수학 문제를 풀어줍니다. 수학적 계산이 필요할 때 사용하세요."""
    # 실제로는 계산 로직이 들어갑니다
    return f"수학 답변: '{question}'에 대한 답이 계산되었습니다."

@tool
def code_expert(question: str) -> str:
    """프로그래밍 질문에 답합니다. 코딩 관련 질문에 사용하세요."""
    return f"코드 답변: '{question}'에 대한 솔루션입니다"

@tool
def general_search(query: str) -> str:
    """일반 정보를 검색합니다."""
    return f"'{query}'에 대한 검색 결과"

# 감독자(supervisor) 에이전트
supervisor = create_agent(
    model=model,
    tools=[math_expert, code_expert, general_search],
    system_prompt="""당신은 전문가에게 작업을 위임하는 감독 에이전트입니다:
- 수학 문제는 math_expert를 사용하세요
- 프로그래밍 질문은 code_expert를 사용하세요
- 그 외에는 general_search를 사용하세요
항상 가장 적절한 전문가에게 위임하세요.""",
)

result = supervisor.invoke(
    {"messages": [{"role": "user", "content": "10의 팩토리얼은 얼마인가요?"}]},
    config=lf_config,
)
print("서브에이전트 결과:", result["messages"][-1].content)
`````)
#output-block(`````
서브에이전트 결과: 10의 팩토리얼 값은 3,628,800입니다.
`````)

=== 8.3.1 Subagent-local history — 명시적 checkpointer

도구 함수 안에서 서브에이전트를 직접 `invoke()`하면서 호출 간 _로컬 대화 히스토리_를 유지하려면 `InMemorySaver()` 같은 실제 checkpointer를 전달합니다. `checkpointer=True`는 체크포인트가 설정된 부모 그래프에 내장된 서브그래프가 부모 saver를 상속하는 continuations 모드이며, 루트 그래프로 직접 호출하면 사용할 수 없습니다.

- 메인 컨텍스트 보존 (서브의 reasoning step 미노출)
- 서브 내부에서는 도구 호출-결과-재추론 multi-turn 유지
- 직접 호출하는 부모와 자식이 별도 checkpointer를 가질 수 있음 (격리)

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool
from langgraph.checkpoint.memory import InMemorySaver

# 서브에이전트의 도구 — 여러 번 호출되며 multi-turn 추론을 유발
@tool
def calc_step(expr: str) -> str:
    """수식의 한 단계를 계산합니다 (예: '3*4', '12+5')."""
    try:
        return f"{eval(expr, {'__builtins__': {}}, {})}"
    except Exception as e:
        return f"err: {e}"

# 직접 invoke하는 서브에이전트에는 실제 saver를 전달
math_memory = InMemorySaver()
math_subagent = create_agent(
    model=model,
    tools=[calc_step],
    system_prompt="복잡한 계산은 calc_step을 여러 번 나눠서 호출하세요. 마지막에 최종 답만 한 줄로 반환합니다.",
    checkpointer=math_memory,  # subagent-local history
    name="math_subagent",
)

@tool
def math_expert_v2(question: str) -> str:
    """수학 문제를 서브에이전트에 위임합니다. 내부 추론은 외부에 노출되지 않습니다."""
    # 서브에이전트만의 thread_id 부여
    sub_cfg = {"configurable": {"thread_id": f"math-{hash(question) & 0xffff}"}}
    sub_result = math_subagent.invoke(
        {"messages": [{"role": "user", "content": question}]},
        config=sub_cfg,
    )
    return sub_result["messages"][-1].content

supervisor_v2 = create_agent(
    model=model,
    tools=[math_expert_v2],
    system_prompt="수학 문제는 math_expert_v2에 위임하세요.",
)

result = supervisor_v2.invoke(
    {"messages": [{"role": "user", "content": "(15 + 27) * 3 의 값은?"}]},
    config=lf_config,
)
print("최종 답:", result["messages"][-1].content)
print("\n메인 메시지 수 (서브 내부 turn 미노출):", len(result["messages"]))
`````)

=== 8.3.2 단일 dispatch tool — 서브에이전트 노출 방식 3가지

서브에이전트가 많아지면 도구 슬롯 폭증을 막기 위해 단일 `dispatch` 도구 하나로 묶고, 어떤 서브를 호출할지는 인자로 받습니다. 노출 방식은 세 가지가 있습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[적합 규모],
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [_(A) System prompt 열거_],
  [\\\< 10개],
  [간단·즉시 발견],
  [프롬프트 토큰 증가, 대규모 시 흐려짐],
  [_(B) `Literal` 인자 제약_],
  [10–30개],
  [tool schema가 enum을 강제 → 모델 hallucination 감소],
  [명단을 코드에서 관리해야 함],
  [_(C) Tool-based discovery_],
  [30+ 개],
  [`list_subagents()` / `describe(name)` 도구로 동적 탐색. 무한 확장],
  [호출 1–2회 추가],
)

#code-block(`````python
from typing import Literal

# 서브에이전트 레지스트리
SUBAGENTS = {
    "math": math_subagent,
    "code": create_agent(model=model, tools=[], system_prompt="코딩 전문가입니다.", name="code"),
    "search": create_agent(model=model, tools=[], system_prompt="검색 전문가입니다.", name="search"),
}

# (A) System prompt 열거 — 소규모
SYSTEM_PROMPT_A = """다음 서브에이전트에 위임하세요:
- math: 수학·계산
- code: 프로그래밍
- search: 일반 검색
필요한 서브에이전트 이름과 함께 dispatch를 호출하세요."""

# (B) Literal 인자 제약 — 중규모. 모델이 enum 밖의 이름을 못 만들도록 schema 단에서 차단
@tool
def dispatch(
    subagent: Literal["math", "code", "search"],  # ← schema 레벨 enum
    question: str,
) -> str:
    """선택한 서브에이전트에게 질문을 위임합니다."""
    agent = SUBAGENTS[subagent]
    cfg = {"configurable": {"thread_id": f"{subagent}-{hash(question) & 0xffff}"}}
    res = agent.invoke({"messages": [{"role": "user", "content": question}]}, config=cfg)
    return res["messages"][-1].content

# (C) Tool-based discovery — 대규모
@tool
def list_subagents() -> str:
    """등록된 서브에이전트 목록을 반환합니다."""
    return ", ".join(SUBAGENTS.keys())

@tool
def describe_subagent(name: str) -> str:
    """특정 서브에이전트의 역할 설명을 반환합니다."""
    descriptions = {"math": "수학 계산 전문가", "code": "코딩 전문가", "search": "일반 검색"}
    return descriptions.get(name, "unknown")

# 패턴 B 사용 예시
dispatcher_b = create_agent(
    model=model,
    tools=[dispatch],  # 단일 dispatch tool, schema에 enum 박힘
    system_prompt="질문을 적절한 서브에이전트에 위임하세요.",
)

result = dispatcher_b.invoke(
    {"messages": [{"role": "user", "content": "12 * 9 는?"}]},
    config=lf_config,
)
print("패턴 B 결과:", result["messages"][-1].content)
`````)

=== 8.3.3 부모 state 주입 — `ToolRuntime[None, CustomState]`

서브에이전트 도구가 부모 그래프의 커스텀 state(예: `user_id`, `tenant`, 누적 결과)에 접근해야 할 때 `ToolRuntime[ContextSchema, StateSchema]`로 의존성을 주입합니다. 도구 인자 시그니처에 명시하면 LangChain이 자동으로 그래프 state를 전달합니다.

#code-block(`````python
from langchain.tools import tool, ToolRuntime
from langchain.agents import AgentState
from typing import Annotated


# 부모 그래프의 커스텀 state — AgentState 확장
class SupportState(AgentState):
    user_id: str
    tenant: str
    audit_log: list[str]


@tool
def lookup_account(query: str, runtime: ToolRuntime[None, SupportState]) -> str:
    """현재 사용자의 계정 정보를 조회합니다. 부모 state에서 user_id를 읽습니다."""
    state = runtime.state
    user_id = state.get("user_id", "unknown")
    tenant = state.get("tenant", "default")
    # 실제로는 DB 조회. 여기선 데모용.
    result = f"[{tenant}] user={user_id} → 활성 계정, 마지막 로그인 2025-05-24"
    return result


# state_schema에 SupportState를 명시 → ToolRuntime이 자동 주입
support_agent_v2 = create_agent(
    model=model,
    tools=[lookup_account],
    system_prompt="사용자 계정 문의에 lookup_account로 답하세요. user_id를 묻지 마세요(state에 이미 있음).",
    state_schema=SupportState,
)

result = support_agent_v2.invoke(
    {
        "messages": [{"role": "user", "content": "내 계정 상태 알려줘"}],
        "user_id": "u-42",
        "tenant": "acme-corp",
        "audit_log": [],
    },
    config=lf_config,
)
print("부모 state 주입 결과:", result["messages"][-1].content)
`````)

=== 8.3.4 비동기 서브에이전트 — 3-tool 패턴

장시간(분 단위) 실행되는 서브에이전트는 동기 호출로 메인을 블록하면 안 됩니다. _`start_job` / `check_status` / `get_result`_ 세 도구로 분리하면 메인 에이전트가 백그라운드 작업을 폴링하면서 다른 일을 병행할 수 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  text(weight: "bold")[반환],
  [`start_job(task)`],
  [작업 제출 (즉시 반환)],
  [`job_id`],
  [`check_status(job_id)`],
  [진행 상태 폴링],
  [`pending` / `running` / `done` / `failed`],
  [`get_result(job_id)`],
  [완료된 결과 회수],
  [최종 출력 (미완료 시 에러)],
)

#code-block(`````python
import threading
import uuid
import time

# 인메모리 잡 큐 — 실전에선 Redis/Celery 등
JOBS: dict[str, dict] = {}


def _background_worker(job_id: str, task: str):
    """백그라운드 스레드에서 서브에이전트를 실행."""
    JOBS[job_id]["status"] = "running"
    try:
        # 무거운 작업 시뮬레이션
        time.sleep(0.5)
        # 실제로는 서브에이전트 invoke
        JOBS[job_id]["status"] = "done"
        JOBS[job_id]["result"] = f"'{task}' 작업 완료: 분석 결과 23 페이지 생성"
    except Exception as e:
        JOBS[job_id]["status"] = "failed"
        JOBS[job_id]["error"] = str(e)


@tool
def start_job(task: str) -> str:
    """장시간 분석 작업을 시작합니다. 즉시 job_id를 반환합니다."""
    job_id = uuid.uuid4().hex[:8]
    JOBS[job_id] = {"status": "pending", "task": task}
    threading.Thread(target=_background_worker, args=(job_id, task), daemon=True).start()
    return f"started: job_id={job_id}"


@tool
def check_status(job_id: str) -> str:
    """작업의 현재 상태를 폴링합니다."""
    j = JOBS.get(job_id)
    if not j:
        return f"unknown job_id: {job_id}"
    return j["status"]


@tool
def get_result(job_id: str) -> str:
    """완료된 작업의 결과를 가져옵니다. 미완료 시 에러 안내."""
    j = JOBS.get(job_id)
    if not j:
        return f"unknown job_id: {job_id}"
    if j["status"] != "done":
        return f"not ready (status={j['status']}). check_status로 다시 확인하세요."
    return j["result"]


async_dispatcher = create_agent(
    model=model,
    tools=[start_job, check_status, get_result],
    system_prompt=(
        "긴 분석 작업은 start_job으로 시작하고, check_status로 폴링한 뒤 "
        "done이 되면 get_result로 결과를 가져오세요. 한 턴에 한두 번만 폴링하세요."
    ),
)

result = async_dispatcher.invoke(
    {"messages": [{"role": "user", "content": "Q1 매출 데이터 분석을 시작하고 결과를 알려줘."}]},
    config=lf_config,
)
print("비동기 결과:", result["messages"][-1].content)
`````)

=== 8.3.5 `Command` 반환으로 부모 state 업데이트

도구가 단순 문자열 대신 `Command(update={...})`를 반환하면, 부모 그래프의 state를 직접 갱신할 수 있습니다. 누적 로그·집계 결과·중간 산출물을 메시지 히스토리 밖에 두고 싶을 때 유용합니다.

#code-block(`````python
from langgraph.types import Command
from langchain_core.messages import ToolMessage


@tool
def record_finding(
    finding: str,
    runtime: ToolRuntime[None, SupportState],
) -> Command:
    """발견 사항을 부모 state의 audit_log에 누적합니다."""
    existing = runtime.state.get("audit_log", [])
    tool_call_id = runtime.tool_call_id  # ToolMessage 매칭용
    return Command(
        update={
            "audit_log": existing + [finding],
            # 부모 메시지에는 짧은 확인만 흘림
            "messages": [
                ToolMessage(
                    content=f"기록됨: {finding[:30]}...",
                    tool_call_id=tool_call_id,
                )
            ],
        }
    )


audit_agent = create_agent(
    model=model,
    tools=[record_finding],
    system_prompt="중요한 발견은 record_finding으로 기록하세요.",
    state_schema=SupportState,
)

result = audit_agent.invoke(
    {
        "messages": [{"role": "user", "content": "보안 점검 결과 두 건을 기록해줘: 1) 로그인 실패 다수 감지, 2) 미사용 관리자 계정 발견"}],
        "user_id": "auditor-1",
        "tenant": "acme",
        "audit_log": [],
    },
    config=lf_config,
)
print("최종 audit_log:", result.get("audit_log"))
print("최종 응답:", result["messages"][-1].content)
`````)

== 8.4 핸드오프 패턴

`Command(goto=...)`로 에이전트 간 _상태를 전환_하는 패턴입니다.

=== 특징
- 도구가 `Command` 객체를 반환하여 다른 에이전트로 전환합니다.
- 대화 상태(메시지 히스토리)가 다음 에이전트로 전달됩니다.
- `StateGraph`로 에이전트 간 흐름을 정의합니다.
- 고객 서비스의 부서 이관 같은 순차적 멀티홉 시나리오에 적합합니다.

#code-block(`````python
from langgraph.types import Command
from langgraph.graph import StateGraph, START, END, MessagesState

# 핸드오프를 위한 도구
@tool
def transfer_to_sales() -> Command:
    """대화를 영업 부서로 전환합니다."""
    return Command(goto="sales_agent", graph=Command.PARENT)

@tool
def transfer_to_support() -> Command:
    """대화를 기술 지원 부서로 전환합니다."""
    return Command(goto="support_agent", graph=Command.PARENT)

@tool
def resolve_query(answer: str) -> str:
    """사용자에게 최종 답변을 제공합니다."""
    return answer

# 라우터 에이전트
router_agent = create_agent(
    model=model,
    tools=[transfer_to_sales, transfer_to_support],
    system_prompt="당신은 안내 데스크입니다. 고객을 적절한 부서로 안내하세요.",
    name="router",
)

# 영업 에이전트
sales_agent = create_agent(
    model=model,
    tools=[resolve_query],
    system_prompt="당신은 영업 에이전트입니다. 가격 및 제품 문의를 도와주세요.",
    name="sales_agent",
)

# 지원 에이전트
support_agent = create_agent(
    model=model,
    tools=[resolve_query],
    system_prompt="당신은 기술 지원 에이전트입니다. 기술적 문제를 도와주세요.",
    name="support_agent",
)

# 핸드오프 그래프 구성
builder = StateGraph(MessagesState)
builder.add_node(router_agent)
builder.add_node(sales_agent)
builder.add_node(support_agent)
builder.add_edge(START, "router")

graph = builder.compile()

result = graph.invoke(
    {"messages": [{"role": "user", "content": "엔터프라이즈 플랜 가격을 알고 싶습니다."}]},
    config=lf_config,
)
print("핸드오프 결과:", result["messages"][-1].content)
`````)
#output-block(`````
핸드오프 결과: 엔터프라이즈 플랜 가격 문의 주셔서 감사합니다.

엔터프라이즈 플랜은 고객님의 요구 사항에 따라 맞춤 견적이 제공됩니다. 사용하실 인원 수, 필요한 기능, 또는 요청 사항을 알려주시면 보다 정확한 견적을 안내해 드릴 수 있습니다.

추가 정보를 공유해 주시면 맞춤 견적서를 전달드리겠습니다.
`````)

=== 8.4.1 단일 에이전트 핸드오프 — `\@wrap_model_call` 미들웨어

위의 multi-subgraph 방식은 부서가 많아질수록 노드 수가 폭증합니다. _docs 권장 1순위_는 단일 에이전트에 `@wrap_model_call` 미들웨어를 붙여, 모드(`role`)에 따라 `system_prompt`와 `tools`를 동적으로 교체하는 방식입니다.

- _노드 1개_ — `StateGraph` 불필요
- _상태 자연 전이_ — `role` 필드만 업데이트하면 다음 호출부터 새 프롬프트·도구 셋 적용
- _핸드오프 = 도구 호출_ — `transfer_to_sales`가 state의 `role`을 바꾸고 다음 모델 호출 시 sales 페르소나로 작동

#code-block(`````python
from langchain.agents.middleware import wrap_model_call
from langchain.agents import AgentState
from langchain_core.messages import ToolMessage


# role을 가진 state
class HandoffState(AgentState):
    role: str  # "router" / "sales" / "support"


# 역할별 페르소나
PERSONAS = {
    "router": {
        "system": "당신은 안내 데스크입니다. 문의 유형에 따라 transfer_to_sales/transfer_to_support를 호출하세요.",
        "tool_names": ["transfer_to_sales", "transfer_to_support"],
    },
    "sales": {
        "system": "당신은 영업 에이전트입니다. 가격·제품 문의에 답하세요.",
        "tool_names": ["resolve_query"],
    },
    "support": {
        "system": "당신은 기술 지원 에이전트입니다. 기술적 문제를 해결하세요.",
        "tool_names": ["resolve_query"],
    },
}


@tool
def transfer_to_sales_v2(runtime: ToolRuntime[None, HandoffState]) -> Command:
    """대화를 영업으로 전환합니다."""
    return Command(
        update={
            "role": "sales",
            "messages": [
                ToolMessage(content="영업 부서로 전환합니다.", tool_call_id=runtime.tool_call_id)
            ],
        }
    )


@tool
def transfer_to_support_v2(runtime: ToolRuntime[None, HandoffState]) -> Command:
    """대화를 기술 지원으로 전환합니다."""
    return Command(
        update={
            "role": "support",
            "messages": [
                ToolMessage(content="기술 지원으로 전환합니다.", tool_call_id=runtime.tool_call_id)
            ],
        }
    )


@tool
def resolve_query_v2(answer: str) -> str:
    """사용자에게 최종 답변을 제공합니다."""
    return answer


ALL_TOOLS = {
    "transfer_to_sales": transfer_to_sales_v2,
    "transfer_to_support": transfer_to_support_v2,
    "resolve_query": resolve_query_v2,
}


# 핵심: 매 모델 호출 직전, state.role에 맞춰 system_prompt와 tools를 교체
@wrap_model_call
def persona_router(request, handler):
    role = request.state.get("role", "router")
    persona = PERSONAS[role]
    request = request.override(
        system_prompt=persona["system"],
        tools=[ALL_TOOLS[n] for n in persona["tool_names"]],
    )
    return handler(request)


unified_agent = create_agent(
    model=model,
    tools=list(ALL_TOOLS.values()),  # 모든 도구를 등록, 실제 노출은 미들웨어가 조정
    middleware=[persona_router],
    state_schema=HandoffState,
)

result = unified_agent.invoke(
    {
        "messages": [{"role": "user", "content": "엔터프라이즈 플랜 가격을 알고 싶습니다."}],
        "role": "router",
    },
    config=lf_config,
)
print("최종 role:", result.get("role"))
print("최종 응답:", result["messages"][-1].content)
`````)

=== 8.4.2 Subgraph 핸드오프의 conversation history 규칙

서브그래프 방식(8.4 원본 예제)으로 핸드오프를 만들 때는 _부모 그래프의 메시지 히스토리에 정확히 2개만 흘러야_ 다음 에이전트가 정상 작동합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[메시지],
  text(weight: "bold")[누가 만드는가],
  text(weight: "bold")[역할],
  [1],
  [`AIMessage(tool_calls=[transfer_to_X])`],
  [라우터 에이전트의 LLM],
  ["이관 결정"의 흔적],
  [2],
  [`ToolMessage(tool_call_id=...)`],
  [`transfer_to_X` 도구 자체],
  [OpenAI tool-call 규칙: 모든 tool_call에는 짝 ToolMessage 필요],
)

_부모 history에 흘리지 말아야 할 것:_
- 라우터의 중간 reasoning 메시지 (서브그래프 내부에서 처리)
- 도구의 길고 자세한 결과 (요약만 ToolMessage로)

_왜 중요한가:_
- 다음 에이전트(sales/support)는 이 2개 메시지를 보고 _방금 이관됐다_를 인지함
- OpenAI/Anthropic은 짝 없는 `tool_calls`가 있으면 다음 turn에서 에러를 냅니다
- 부모 history가 깨끗할수록 컨텍스트가 가볍고, 같은 thread에서 추가 이관이 가능

→ 위 8.4.1의 `wrap_model_call` 패턴은 이 규칙을 자동으로 따릅니다 (도구가 `ToolMessage` 하나만 흘리고 state.role을 갱신).

== 8.5 스킬 패턴

단일 에이전트가 상황에 따라 _전문 프롬프트를 로드_하는 패턴입니다.

=== 특징
- 하나의 에이전트가 여러 "스킬"을 가집니다.
- 각 스킬은 특화된 시스템 프롬프트입니다.
- 에이전트가 필요한 스킬을 동적으로 로드합니다.
- 여러 에이전트를 관리하지 않고도 하나의 에이전트로 다양한 작업을 처리할 수 있습니다.

#code-block(`````python
# 스킬 정의
skills = {
    "translator": "당신은 전문 번역가입니다. 언어 간 텍스트를 정확하게 번역하세요.",
    "summarizer": "당신은 전문 요약가입니다. 긴 텍스트를 간결하게 요약하세요.",
    "coder": "당신은 전문 프로그래머입니다. 깔끔하고 효율적인 코드를 작성하세요.",
}

@tool
def load_skill(skill_name: str) -> str:
    """전문 스킬을 로드합니다. 사용 가능한 스킬: translator, summarizer, coder."""
    if skill_name in skills:
        return f"스킬 로드 완료: {skill_name}. 지침: {skills[skill_name]}"
    return f"알 수 없는 스킬: {skill_name}. 사용 가능: {list(skills.keys())}"

skill_agent = create_agent(
    model=model,
    tools=[load_skill],
    system_prompt="""당신은 전문 기술에 접근할 수 있는 다재다능한 어시스턴트입니다.
사용자의 요청을 처리하기 전에 적절한 스킬을 로드하세요.""",
)

result = skill_agent.invoke(
    {"messages": [{"role": "user", "content": "'Hello World'를 한국어와 일본어로 번역해 주세요."}]},
    config=lf_config,
)
print("스킬 패턴 결과:", result["messages"][-1].content)
`````)
#output-block(`````
스킬 패턴 결과: "Hello World"를 한국어와 일본어로 번역해 드리겠습니다.

- 한국어: 안녕하세요, 세계!
- 일본어: こんにちは、世界！

추가로 번역이 필요한 문장이 있다면 말씀해 주세요.
`````)

== 8.6 라우터 패턴

분류기가 입력을 적절한 에이전트로 _라우팅_하는 패턴입니다.

=== 특징
- 먼저 쿼리를 분류(classify)합니다.
- 분류 결과에 따라 적절한 전문 에이전트(도구)로 위임합니다.
- 멀티 도메인 시스템에서 유용합니다.
- 분류 로직은 규칙 기반 또는 LLM 기반으로 구현할 수 있습니다.

#code-block(`````python
from langgraph.types import Send

@tool
def classify_query(query: str) -> str:
    """쿼리를 카테고리로 분류합니다: math, code, general."""
    query_lower = query.lower()
    if any(w in query_lower for w in ["calculate", "math", "sum", "multiply"]):
        return "math"
    elif any(w in query_lower for w in ["code", "program", "function", "python"]):
        return "code"
    return "general"

# 라우터: 분류 결과에 따라 전문 에이전트로 전달
router = create_agent(
    model=model,
    tools=[classify_query, math_expert, code_expert, general_search],
    system_prompt="""당신은 라우팅 에이전트입니다. 먼저 쿼리를 분류한 다음 적절한 전문가에게 전달하세요:
- 수학 쿼리 -> math_expert 사용
- 코드 쿼리 -> code_expert 사용
- 일반 쿼리 -> general_search 사용""",
)

result = router.invoke(
    {"messages": [{"role": "user", "content": "리스트를 정렬하는 Python 함수를 작성해 주세요."}]},
    config=lf_config,
)
print("라우터 결과:", result["messages"][-1].content)
`````)
#output-block(`````
라우터 결과: 리스트를 정렬하는 Python 함수에 대해 문의해주셨네요. 아래는 예시 코드입니다:

```python
def sort_list(lst):
    return sorted(lst)
```

이 함수에 리스트를 넘기면, 정렬된 새로운 리스트를 반환합니다.
`````)

=== 8.6.1 진짜 fan-out 라우터 — `Send`로 병렬 분배

위 8.6 예제의 `from langgraph.types import Send`는 사실 dead import였습니다(분류 후 단일 분기만 실행). 실제 라우터의 강점은 _분류 결과를 여러 노드에 동시에 fan-out_하는 능력입니다. 한 질문이 여러 도메인에 걸칠 때 `Send(node, payload)` 리스트를 반환하면 LangGraph가 병렬로 실행합니다.

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.types import Command, Send
from typing import TypedDict, Annotated
import operator


class FanOutState(TypedDict):
    query: str
    # 여러 도메인에서 비동기로 결과가 쌓이도록 reducer 사용
    results: Annotated[list[str], operator.add]


def classifier(state: FanOutState) -> Command:
    """질문에서 도메인을 여러 개 뽑아 각 전문가 노드로 Send."""
    q = state["query"].lower()
    domains = []
    if any(w in q for w in ["수학", "계산", "math", "+", "*"]):
        domains.append({"agent": "math_node", "query": state["query"]})
    if any(w in q for w in ["코드", "함수", "python", "code"]):
        domains.append({"agent": "code_node", "query": state["query"]})
    if not domains:
        domains.append({"agent": "general_node", "query": state["query"]})

    # 핵심: Send 리스트로 fan-out
    return Command(
        goto=[Send(c["agent"], {"query": c["query"]}) for c in domains]
    )


def math_node(state: dict) -> dict:
    return {"results": [f"[math] {state['query']} → 결과 계산됨"]}


def code_node(state: dict) -> dict:
    return {"results": [f"[code] {state['query']} → 코드 스니펫 생성됨"]}


def general_node(state: dict) -> dict:
    return {"results": [f"[general] {state['query']} → 일반 답변"]}


def aggregator(state: FanOutState) -> dict:
    return {"results": state["results"]}  # 그대로 통합


builder = StateGraph(FanOutState)
builder.add_node("classifier", classifier)
builder.add_node("math_node", math_node)
builder.add_node("code_node", code_node)
builder.add_node("general_node", general_node)
builder.add_node("aggregator", aggregator)

builder.add_edge(START, "classifier")
# classifier가 Command(goto=[Send(...), Send(...)])로 분배 → 동적 엣지
builder.add_edge("math_node", "aggregator")
builder.add_edge("code_node", "aggregator")
builder.add_edge("general_node", "aggregator")
builder.add_edge("aggregator", END)

fanout_graph = builder.compile()

# 수학 + 코드 두 도메인에 동시 fan-out되는 질문
result = fanout_graph.invoke(
    {"query": "리스트 합계를 계산하는 python 함수를 작성해줘", "results": []},
    config=lf_config,
)
print("fan-out 결과:")
for r in result["results"]:
    print(" -", r)
`````)

== 8.7 패턴 선택 가이드

어떤 멀티 에이전트 패턴을 선택해야 할까요? 아래 가이드를 참고하세요.

=== 결정 트리

+ _에이전트가 독립적으로 작업 가능한가?_
- YES -\> _Subagents_ (병렬 실행, 결과 취합)
- NO -\> 다음 질문으로

+ _대화 상태가 에이전트 간에 전달되어야 하는가?_
- YES -\> _Handoffs_ (상태 전환, 멀티홉)
- NO -\> 다음 질문으로

+ _하나의 에이전트가 여러 역할을 전환하면 되는가?_
- YES -\> _Skills_ (프롬프트 교체)
- NO -\> 다음 질문으로

+ _입력을 분류한 뒤 적절한 처리기로 보내면 되는가?_
- YES -\> _Router_ (분류 후 위임)
- NO -\> _Custom_ (완전 커스텀 그래프)

=== 실용적 권장사항
- 처음에는 _가장 단순한 패턴_(Subagents 또는 Skills)으로 시작하세요.
- 요구사항이 복잡해지면 Handoffs나 Router로 전환하세요.
- Custom 패턴은 다른 패턴으로 해결할 수 없을 때만 사용하세요.
- 패턴을 _조합_할 수도 있습니다 (예: Router + Handoffs).

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[사용 시기],
  [_Subagents_],
  [`create_agent` + 도구 함수],
  [독립적 병렬 작업],
  [_Handoffs_],
  [`Command(goto=...)`, `StateGraph`],
  [상태 전환이 필요한 멀티홉],
  [_Skills_],
  [도구로 프롬프트 로드],
  [단일 에이전트 다중 역할],
  [_Router_],
  [분류 도구 + 전문 도구],
  [멀티 도메인 분류],
  [_Custom_],
  [`StateGraph` 완전 제어],
  [복잡한 비즈니스 로직],
)

=== 핵심 원칙
- 단순한 것부터 시작하고, 필요에 따라 복잡도를 높이세요.
- 각 에이전트는 _하나의 책임_만 가지도록 설계하세요.
- 에이전트 간 _인터페이스_(입력/출력)를 명확히 정의하세요.
