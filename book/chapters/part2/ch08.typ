// Auto-generated from 08_multi_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "멀티 에이전트 패턴")

복잡한 작업을 단일 에이전트로 처리하면 시스템 프롬프트가 비대해지고, 도구가 넘쳐나며, 컨텍스트 윈도우가 빠르게 소진됩니다. 멀티 에이전트 아키텍처는 작업을 전문 에이전트로 분할하여 이 문제를 해결합니다. 이 장에서는 LangChain v1이 제공하는 5가지 멀티 에이전트 패턴 — Subagents, Handoffs, Skills, Router, Custom — 의 개념과 구현을 비교합니다.

단일 에이전트의 한계는 단순히 프롬프트 길이의 문제가 아닙니다. 도구가 20개를 넘어가면 LLM이 적절한 도구를 선택하는 정확도가 떨어지고, 서로 다른 도메인의 지시사항이 충돌하여 예측 불가능한 동작이 발생할 수 있습니다. 멀티 에이전트 패턴은 "관심사의 분리(Separation of Concerns)" 원칙을 에이전트 설계에 적용한 것으로, 각 에이전트가 명확한 책임 범위와 최소한의 도구 집합을 갖도록 합니다.

#learning-header()
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

== 8.2 멀티 에이전트 패턴 비교

아래 표는 5가지 멀티 에이전트 패턴을 비교합니다. 각 패턴은 서로 다른 상황에 적합하며, 프로젝트의 요구사항에 맞게 선택해야 합니다.

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

이 다섯 패턴은 복잡도와 유연성의 스펙트럼 위에 놓여 있습니다. Subagents와 Skills는 구현이 간단하지만 유연성이 제한적이고, Handoffs와 Router는 중간 수준의 복잡도로 대부분의 실전 시나리오를 커버하며, Custom은 최대한의 유연성을 제공하되 개발 비용이 가장 높습니다. 각 패턴의 동작 원리와 트레이드오프를 하나씩 살펴보겠습니다.

=== 패턴 선택 매트릭스 (요구사항 → 패턴)

비교 표가 패턴의 _속성_을 정리한 것이라면, 아래 매트릭스는 _요구사항_에서 출발하여 최적 패턴을 역으로 찾는 표입니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[요구사항],
  text(weight: "bold")[최적 패턴],
  [단일 단순 작업 (one-shot)],
  [_Skills_ (또는 단일 에이전트)],
  [같은 작업을 반복 호출],
  [_Subagents_],
  [멀티 도메인을 병렬 처리],
  [_Router_ (분류 후 fan-out)],
  [매우 큰 컨텍스트 (긴 문서·이력)],
  [_Subagents_ (컨텍스트 격리로 토큰 절약)],
  [팀 기반 — 에이전트가 서로 협업],
  [_Handoffs_ (상태 공유)],
  [에이전트와 직접 대화 (역할 유지)],
  [_Handoffs_ + supervisor],
)

=== 패턴별 토큰·호출 비용 (참고 수치)

같은 작업을 서로 다른 패턴으로 구현했을 때의 대략적인 호출 수와 누적 토큰을 비교합니다. 수치는 시나리오와 모델에 따라 달라지지만, 패턴 간 _상대적 비용_을 가늠하는 데 도움이 됩니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[시나리오],
  text(weight: "bold")[패턴],
  text(weight: "bold")[호출 수],
  text(weight: "bold")[누적 토큰],
  [One-Shot (단일 도메인)],
  [_Subagents_],
  [4–5 calls],
  [~9K],
  [Repeat (같은 작업 반복)],
  [_Skills_],
  [2–3 calls],
  [~15K],
  [Multi-Domain (협업)],
  [_Handoffs_],
  [3–7+ calls],
  [~14K+],
  [Multi-Domain (분류 후 fan-out)],
  [_Router_],
  [\~분류 1 + 도메인 N],
  [~9K],
)

#tip-box[_Router vs Supervisor_ — 두 용어는 자주 혼용되지만 구현 측면에서 다릅니다. _Router_는 입력을 한 번 분류하여 적절한 에이전트(또는 Send)로 _fan-out_ 하는 _단순 함수형_ 노드입니다. 반면 _Supervisor_는 대화 이력을 가지고 _conversation-aware_ 하게 어떤 서브에이전트를 호출할지 매 턴 결정하는 에이전트입니다. 일회성 분류라면 Router, 다단계 협업이 필요하면 Supervisor 패턴을 선택하세요.]

== 8.3 서브에이전트 패턴

메인 에이전트(감독자)가 전문 서브에이전트를 _도구로_ 호출하는 패턴입니다. 핵심 아이디어는 `create_agent()`로 생성한 에이전트를 `@tool` 데코레이터로 감싸서, 상위 에이전트가 일반 도구처럼 호출할 수 있게 만드는 것입니다.

=== 특징
- 각 서브에이전트는 도구 함수로 캡슐화됩니다.
- 메인 에이전트가 어떤 서브에이전트를 호출할지 판단합니다.
- 서브에이전트의 내부 상태는 메인 에이전트와 격리됩니다. — 서브에이전트의 중간 추론 과정이나 도구 호출 이력은 메인 에이전트의 컨텍스트를 오염시키지 않습니다.
- 병렬 실행이 가능하여 성능에 유리합니다.

#tip-box[서브에이전트 패턴은 "컨텍스트 격리"가 가장 큰 장점입니다. 서브에이전트가 내부적으로 여러 도구를 호출하더라도 메인 에이전트에는 최종 결과 문자열만 전달되므로, 메인 에이전트의 컨텍스트 윈도우를 절약할 수 있습니다.]

=== 서브에이전트 로컬 히스토리 (`checkpointer=True`)

서브에이전트를 `create_agent(..., checkpointer=True)` 로 만들면 _서브에이전트만의 대화 이력_을 별도 스레드에 보관할 수 있습니다. 메인 에이전트는 최종 결과만 전달받지만, 서브에이전트 내부에서는 멀티턴 추론이 가능해집니다. 동일 thread_id 로 재호출하면 이전 컨텍스트를 이어받아 _점진적_으로 작업을 진행할 수 있습니다.

=== 단일 dispatch 도구로 N개 서브에이전트 노출

서브에이전트가 많을 때 각각을 개별 도구로 노출하면 메인 에이전트의 도구 목록이 비대해집니다. 대안은 단일 `dispatch(agent_name, query)` 도구 하나로 묶고, 어떤 서브에이전트가 있는지를 _다른 방식_으로 알려주는 것입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[권장 규모],
  text(weight: "bold")[특징],
  [시스템 프롬프트에 enumerate],
  [< 10],
  [LLM이 이름을 텍스트로 인식. 간단·유연],
  [`Literal["a", "b", ...]` 타입 제약],
  [10–30],
  [툴 스키마로 validation. 잘못된 이름 차단],
  [Tool-based discovery (`list_agents`)],
  [> 30],
  [동적 등록. 별도 도구로 검색·필터링],
)

=== 부모 state 주입: `ToolRuntime[None, CustomState]`

서브에이전트 도구가 부모 그래프의 state 일부를 읽어야 할 때 `ToolRuntime[None, CustomState]` 를 인자로 받습니다.

#code-block(`````python
from langchain.tools import tool, ToolRuntime

@tool
def research_subagent(query: str, runtime: ToolRuntime[None, ResearchState]) -> str:
    """리서치 서브에이전트. 부모 state의 user_id를 사용."""
    user_id = runtime.state["user_id"]
    # ... 서브에이전트 호출 ...
    return result
`````)

=== 비동기 작업: start / status / get_result 3-tool 패턴

오래 걸리는 서브에이전트는 단일 동기 호출 대신 _세 개 도구_로 쪼개는 것이 안전합니다.

#code-block(`````python
@tool
def start_research_job(query: str) -> str:
    """리서치 작업을 시작하고 job_id를 반환합니다."""
    ...

@tool
def check_job_status(job_id: str) -> str:
    """작업 상태 — running / done / failed."""
    ...

@tool
def get_job_result(job_id: str) -> str:
    """완료된 작업의 결과를 가져옵니다."""
    ...
`````)

=== `Command` 반환으로 부모 state 업데이트

서브에이전트 도구가 단순 문자열 대신 `Command(update={...})` 를 반환하면 부모 그래프의 state 를 _직접_ 갱신할 수 있습니다. 메시지뿐 아니라 커스텀 필드까지 업데이트해야 할 때 유용합니다.

#code-block(`````python
from langgraph.types import Command

@tool
def research_with_state_update(query: str) -> Command:
    result = run_research(query)
    return Command(update={
        "research_results": result,
        "messages": [{"role": "tool", "content": result}],
    })
`````)

서브에이전트 패턴이 도구 호출을 통해 결과만 받아오는 "위임" 방식이라면, 핸드오프 패턴은 대화의 _흐름 자체_를 다른 에이전트로 넘기는 방식입니다.

== 8.4 핸드오프 패턴

`Command(goto=...)`로 에이전트 간 _상태를 전환_하는 패턴입니다. 핸드오프는 LangGraph의 노드 전환 메커니즘을 활용합니다. 에이전트 내부의 도구가 `Command(goto="target_agent")` 객체를 반환하면, LangGraph 런타임이 현재 에이전트의 실행을 중단하고 대상 에이전트 노드로 제어를 이동시킵니다.

=== 특징
- 도구가 `Command` 객체를 반환하여 다른 에이전트로 전환합니다.
- 대화 상태(메시지 히스토리)가 다음 에이전트로 전달됩니다. — 서브에이전트 패턴과 달리 이전 대화의 전체 맥락을 유지합니다.
- `StateGraph`를 사용하여 에이전트 간 흐름을 정의합니다.
- 고객 서비스의 부서 이관 같은 순차적 멀티홉 시나리오에 적합합니다.

#warning-box[핸드오프 패턴에서 대화 상태가 모든 에이전트에 공유되므로, 에이전트 수가 많아지면 컨텍스트 윈도우가 빠르게 소진될 수 있습니다. 핸드오프 체인이 3단계 이상 필요하다면, 중간에 상태를 요약하거나 서브에이전트 패턴과 조합하는 것을 고려하세요.]

=== 단일 에이전트 + 미들웨어 핸드오프 (권장 1순위)

LangChain v1 docs 의 1순위 권장 핸드오프 패턴은 _여러 subgraph_ 가 아니라 _단일 에이전트 + `@wrap_model_call` 미들웨어_입니다. 라우팅 결과에 따라 시스템 프롬프트와 도구 집합을 동적으로 _override_ 하여, 하나의 에이전트 노드 안에서 페르소나를 전환합니다.

#code-block(`````python
from langchain.agents.middleware import wrap_model_call, ModelRequest
from langchain.agents import create_agent

@wrap_model_call
def role_router(request: ModelRequest, handler):
    state = request.state
    role = state.get("active_role", "general")

    if role == "billing":
        return handler(request.override(
            system_prompt="당신은 결제 전문 상담원입니다.",
            tools=[refund_tool, charge_tool],
        ))
    elif role == "tech":
        return handler(request.override(
            system_prompt="당신은 기술 지원 상담원입니다.",
            tools=[diagnose_tool, escalate_tool],
        ))
    return handler(request)

agent = create_agent(model="gpt-5.4", tools=ALL_TOOLS, middleware=[role_router])
`````)

기존의 다중 subgraph 핸드오프 패턴은 _부서 간 명시적 그래프 흐름_을 보여줘야 할 때 여전히 유효하지만, 단순한 페르소나 전환이라면 위 미들웨어 패턴이 훨씬 가볍습니다.

=== 핸드오프 도구의 `ToolRuntime` + `tool_call_id` 에코백

핸드오프 도구는 `ToolRuntime[None, SupportState]` 로 부모 state 와 현재 `tool_call_id` 에 접근해야 합니다. `Command(goto=..., update={"messages": [...]})` 로 전환할 때, _현재 도구 호출에 대응하는 `ToolMessage`_ 를 반드시 함께 넣어야 OpenAI tool-call 규약이 깨지지 않습니다.

#code-block(`````python
from langchain.tools import tool, ToolRuntime
from langchain_core.messages import ToolMessage
from langgraph.types import Command

@tool
def transfer_to_billing(reason: str, runtime: ToolRuntime[None, SupportState]) -> Command:
    """결제팀으로 상담을 이관합니다."""
    return Command(
        goto="billing_agent",
        update={
            "messages": [
                ToolMessage(
                    content=f"결제팀으로 이관: {reason}",
                    tool_call_id=runtime.tool_call_id,
                ),
            ],
            "active_role": "billing",
        },
    )
`````)

#tip-box[_subgraph 핸드오프 시 흘려야 할 메시지는 정확히 2개_ — (1) 핸드오프 도구를 호출한 `AIMessage(tool_calls=[...])` 와 (2) 그에 대한 `ToolMessage` _두 개만_ 다음 subgraph로 전달되어야 합니다. 그 사이에 다른 메시지를 끼워 넣으면 OpenAI provider가 tool_call 짝이 맞지 않는다고 거부합니다.]

핸드오프가 여러 에이전트 사이에서 대화를 이동시키는 것이라면, 스킬 패턴은 하나의 에이전트가 _역할을 전환_하는 보다 경량화된 접근법입니다.

== 8.5 스킬 패턴

단일 에이전트가 상황에 따라 _전문 프롬프트를 로드_하는 패턴입니다. 여러 에이전트를 별도로 생성하는 대신, 하나의 에이전트가 도메인별 시스템 프롬프트를 교체하며 전문가처럼 동작합니다.

=== 특징
- 하나의 에이전트가 여러 "스킬"을 가집니다.
- 각 스킬은 특화된 시스템 프롬프트입니다.
- 에이전트가 필요한 스킬을 동적으로 로드합니다.
- 여러 에이전트를 관리할 필요 없이 하나의 에이전트로 다양한 작업을 처리할 수 있습니다.

#tip-box[스킬 패턴은 오버헤드가 가장 적은 멀티 에이전트 패턴입니다. 에이전트 인스턴스가 하나뿐이므로 상태 관리와 그래프 구성이 불필요합니다. 도메인 간 도구 집합이 겹치지 않고, 프롬프트 전환만으로 충분한 경우에 가장 효율적입니다.]

스킬 패턴이 하나의 에이전트 내부에서 프롬프트를 전환하는 것이라면, 라우터 패턴은 입력 단계에서 _어느 에이전트가 처리할지를 먼저 결정_하는 방식입니다.

== 8.6 라우터 패턴

분류기가 입력을 적절한 에이전트로 _라우팅_하는 패턴입니다. 라우터 노드는 사용자의 쿼리를 분석하여 카테고리를 판별한 뒤, 해당 카테고리 전문 에이전트로 요청을 전달합니다. 분류 로직은 LLM을 사용할 수도 있고, 키워드 매칭이나 임베딩 유사도 같은 규칙 기반으로도 구현할 수 있습니다.

=== 특징
- 먼저 쿼리를 분류(classify)합니다.
- 분류 결과에 따라 적절한 전문 에이전트(도구)로 위임합니다.
- 멀티 도메인 시스템에서 유용합니다.
- 분류 로직은 규칙 기반 또는 LLM 기반으로 구현할 수 있습니다.

#tip-box[라우터의 분류기를 LLM 기반으로 구현할 때는 경량 모델(예: `gpt-5.4-mini`)을 사용하는 것이 비용 효율적입니다. 분류 작업은 복잡한 추론이 필요하지 않으므로, 빠르고 저렴한 모델로도 충분한 정확도를 얻을 수 있습니다.]

=== `Send`로 멀티 도메인 fan-out

쿼리가 _여러 도메인_을 동시에 다뤄야 할 때는 단일 라우팅 대신 `Send` 로 _병렬 fan-out_ 합니다. `add_conditional_edges` 의 라우팅 함수가 `list[Send]` 를 반환하면 LangGraph 런타임이 해당 노드들을 _병렬_로 실행합니다.

#code-block(`````python
from langgraph.types import Command, Send

def route_to_agents(state: RouterState) -> list[Send]:
    """분류 결과에 포함된 모든 카테고리로 fan-out."""
    return [
        Send(c["agent"], {"query": c["query"]})
        for c in state["classifications"]
    ]

graph.add_conditional_edges("classifier", route_to_agents,
                             ["billing_agent", "tech_agent", "general_agent"])
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

다음 장에서는 이 패턴들 중 _Custom_ 패턴의 핵심인 `StateGraph`를 본격적으로 활용하여, 에이전트를 워크플로 노드로 통합하고 RAG(Retrieval-Augmented Generation) 파이프라인을 구현하는 방법을 학습합니다.

