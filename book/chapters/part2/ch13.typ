// Auto-generated from 13_guardrails.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "가드레일")

에이전트가 프로덕션 환경에서 사용자와 직접 상호작용하면, 악의적 입력(프롬프트 인젝션), 민감 정보 유출(PII), 부적절한 응답 등의 위험이 생깁니다. 가드레일은 에이전트의 입출력 경계에 검증과 필터링 로직을 배치하여 이러한 위험을 완화합니다. 이 장에서는 결정론적 가드레일과 모델 기반 가드레일의 차이, PII 감지, Human-in-the-Loop 승인 등 실전 가드레일 패턴을 학습합니다.

가드레일은 에이전트의 _안전 경계(safety boundary)_를 정의합니다. LLM 자체의 안전 훈련(RLHF 등)만으로는 모든 위험을 커버할 수 없으며, 특히 도메인 특화 규칙(금융 컴플라이언스, 의료 면책 등)은 애플리케이션 레벨에서 명시적으로 구현해야 합니다. LangChain v1의 미들웨어 시스템은 가드레일을 에이전트 코드와 분리하여 재사용 가능한 컴포넌트로 관리할 수 있게 합니다.

#learning-header()
에이전트의 입력과 출력을 검증하고 필터링하는 가드레일을 설정하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- 가드레일의 개념과 필요성을 이해한다
- 결정론적 가드레일과 모델 기반 가드레일의 차이를 안다
- PII 감지 미들웨어를 설정한다
- Human-in-the-Loop 가드레일을 구현한다
- 커스텀 before/after 가드레일을 작성한다

== 13.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 13.2 가드레일 개념

_가드레일(Guardrails)_은 에이전트 실행 과정에서 콘텐츠를 검증하고 필터링하는 안전 메커니즘입니다.

=== 왜 가드레일이 필요한가?

- 개인정보(PII) 유출 방지
- 프롬프트 인젝션 공격 차단
- 부적절하거나 유해한 콘텐츠 차단
- 비즈니스 규칙 및 컴플라이언스 준수
- 출력 품질 및 정확성 검증

=== 두 가지 접근법

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[접근법],
  text(weight: "bold")[방식],
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [_결정론적_],
  [정규식, 키워드 매칭, 명시적 규칙],
  [빠르고, 예측 가능하며, 비용 효율적],
  [미묘한 위반 사항 놓칠 수 있음],
  [_모델 기반_],
  [LLM이나 분류기로 의미를 분석],
  [미묘한 문제도 감지],
  [느리고 비용이 높음],
)

=== 가드레일 적용 시점

#align(center)[#image("../../assets/diagrams/png/guardrail_insertion_points.png", width: 86%, height: 96mm, fit: "contain")]

가드레일은 _한 군데에서 모든 문제를 해결하는 필터_ 가 아니라, 실패 지점을 여러 층으로 나누어 관리하는 방식입니다. 입력 단계에서는 프롬프트 인젝션과 PII를 줄이고, 도구 단계에서는 위험한 행동을 승인 흐름으로 보내며, 출력 단계에서는 누출·환각·정책 위반을 마지막으로 걸러냅니다.

#note-box[_실패 예시로 보면 더 쉽습니다_: *입력 단계*에서는 API 키/주민번호 같은 민감정보를 차단하고, *도구 단계*에서는 이메일 발송·DB 변경을 승인 대기로 보내며, *출력 단계*에서는 내부 시스템 프롬프트나 민감 필드를 마스킹합니다.]

#code-block(`````python
사용자 입력 → [입력 가드레일] → 에이전트 실행 → [출력 가드레일] → 응답
                  ↑                                    ↑
            before_agent                          after_agent
`````)

두 가지 접근법의 핵심적인 차이는 _검사 대상의 복잡도_입니다. "이메일 주소 포함 여부"처럼 명확한 패턴은 정규식으로 빠르게 처리하고, "우회적으로 개인정보를 유도하는 프롬프트"처럼 의미 해석이 필요한 경우에만 LLM 기반 검사를 적용합니다. 프로덕션에서는 두 방식을 조합하되, 빠르고 저렴한 결정론적 검사를 먼저 실행하여 명백한 위반을 조기에 차단하는 것이 비용 효율적입니다.

#note-box[_실패 예시로 기억하기_
- _입력 단계 실패_ — 이메일/주민번호가 포함된 요청을 마스킹하지 않고 모델에 전달
- _도구 단계 실패_ — `send_email`, `execute_sql` 같은 민감 도구를 승인 없이 실행
- _출력 단계 실패_ — 모델이 내부 정책, PII, 공격 프롬프트 일부를 그대로 응답

가드레일은 세 단계가 각각 다른 실패를 막는다는 점을 기억하세요.]

== 13.3 PII 감지 미들웨어

_PIIMiddleware_는 이메일, 신용카드 번호, IP 주소 등 개인식별정보(PII)를 자동으로 감지하고 처리합니다. PII가 에이전트의 컨텍스트에 유입되면 LLM이 이를 학습하거나 출력에 포함시킬 위험이 있으므로, _모델에 전달되기 전_에 감지하여 처리하는 것이 중요합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[결과],
  [`redact`],
  [`[REDACTED_EMAIL]`로 대체],
  [`mask`],
  [부분 가리기 (예: 마지막 4자리만 표시)],
  [`hash`],
  [결정론적 해시로 대체],
  [`block`],
  [감지 시 예외 발생],
)

#code-block(`````python
# PII 감지 미들웨어 설정 예시
print("PII 감지 미들웨어 설정:")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[customer_service_tool, email_tool],
    middleware=[
        # 이메일 주소를 [REDACTED_EMAIL]로 대체
        PIIMiddleware("email",
            strategy="redact",
            apply_to_input=True),

        # 신용카드 번호를 부분 마스킹 (****-****-****-1234)
        PIIMiddleware("credit_card",
            strategy="mask",
            apply_to_input=True),

        # API 키 감지 시 차단 (커스텀 정규식)
        PIIMiddleware("api_key",
            detector=r"sk-[a-zA-Z0-9]{32}",
            strategy="block",
            apply_to_input=True),
    ],
)
""")
print("내장 PII 타입: email, credit_card, ip, mac_address, url")
print("커스텀 감지: detector 파라미터에 정규식 또는 함수 전달")
`````)
#output-block(`````
PII 감지 미들웨어 설정:
==================================================

from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[customer_service_tool, email_tool],
    middleware=[
        # 이메일 주소를 [REDACTED_EMAIL]로 대체
        PIIMiddleware("email",
            strategy="redact",
            apply_to_input=True),

        # 신용카드 번호를 부분 마스킹 (****-****-****-1234)
        PIIMiddleware("credit_card",
            strategy="mask",
            apply_to_input=True),

        # API 키 감지 시 차단 (커스텀 정규식)
        PIIMiddleware("api_key",
            detector=r"sk-[a-zA-Z0-9]{32}",
            strategy="block",
            apply_to_input=True),
    ],
)

내장 PII 타입: email, credit_card, ip, mac_address, url
커스텀 감지: detector 파라미터에 정규식 또는 함수 전달
`````)

PII 감지가 데이터의 _내용_을 검사하는 가드레일이라면, Human-in-the-Loop(HITL)은 에이전트의 _행동_을 제어하는 가드레일입니다. 특정 도구의 실행 전에 사람의 승인을 요구하여, 되돌릴 수 없는 작업의 안전성을 확보합니다.

== 13.4 Human-in-the-Loop 가드레일

_HumanInTheLoopMiddleware_는 민감한 작업을 실행하기 전에 _사람의 승인_을 요구합니다. 내부적으로 LangGraph의 `interrupt()` 메커니즘을 사용하여 그래프 실행을 일시 중단하고, 사용자의 승인 또는 거부 결정을 받은 후 `Command(resume=...)` 으로 실행을 재개합니다. 금융 거래, 데이터 삭제, 외부 통신 등 고위험 작업에 필수적입니다.

#warning-box[HITL 가드레일은 반드시 `checkpointer`와 함께 사용해야 합니다. 체크포인터가 없으면 그래프 실행 상태를 저장할 수 없어, 중단 후 재개가 불가능합니다. 프로덕션에서는 `InMemorySaver` 대신 `SqliteSaver`나 `PostgresSaver` 같은 영속적 체크포인터를 사용하세요.]

#code-block(`````python
# Human-in-the-Loop 가드레일 예시
print("Human-in-the-Loop 가드레일:")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool, delete_db_tool],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": True,       # 승인 필요
                "delete_db": True,         # 승인 필요
                "search": False,           # 자동 실행
            }
        ),
    ],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "review-123"}}

# 1단계: 에이전트 실행 → send_email에서 중단
result = agent.invoke(
    {"messages": [{"role": "user", "content": "팀에 이메일 보내"}]},
    config=config,
)
# → 중단됨: send_email 실행 전 승인 대기

# 2단계: 승인 후 재개
result = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
)
""")
print("핵심: checkpointer가 있어야 중단/재개가 가능합니다.")
print("거부 시: {\"type\": \"reject\"}로 도구 실행을 막을 수 있습니다.")
`````)
#output-block(`````
Human-in-the-Loop 가드레일:
==================================================

from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool, delete_db_tool],
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": True,       # 승인 필요
                "delete_db": True,         # 승인 필요
                "search": False,           # 자동 실행
            }
        ),
    ],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "review-123"}}

# 1단계: 에이전트 실행 → send_email에서 중단
result = agent.invoke(
    {"messages": [{"role": "user", "content": "팀에 이메일 보내"}]},
    config=config,
)
... (truncated)
`````)

내장 미들웨어(`PIIMiddleware`, `HumanInTheLoopMiddleware`)가 제공하지 않는 검증 로직이 필요한 경우, 커스텀 가드레일을 직접 작성할 수 있습니다. LangChain v1의 미들웨어 시스템은 `before_agent`(입력 가드레일)와 `after_agent`(출력 가드레일) 두 가지 훅 포인트를 제공합니다.

== 13.5 커스텀 입력 가드레일 — before_agent

`before_agent` 훅은 에이전트 실행 _시작 전_에 요청을 검증합니다. 이 훅이 `None`을 반환하면 정상적으로 에이전트가 실행되고, 딕셔너리를 반환하면서 `jump_to="end"`를 지정하면 에이전트 실행을 건너뛰고 즉시 응답합니다. 세션 수준의 인증, 비율 제한, 콘텐츠 필터링 등에 사용합니다.

#code-block(`````python
# 커스텀 입력 가드레일 — ContentFilterMiddleware 클래스
print("커스텀 입력 가드레일 (클래스 방식):")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

class ContentFilterMiddleware(AgentMiddleware):
    \"\"\"결정론적 가드레일: 금지 키워드가 포함된 요청을 차단합니다.\"\"\"

    def __init__(self, banned_keywords: list[str]):
        super().__init__()
        self.banned_keywords = [kw.lower() for kw in banned_keywords]

    @hook_config(can_jump_to=["end"])
    def before_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        first_message = state["messages"][0]
        if first_message.type != "human":
            return None

        content = first_message.content.lower()
        for keyword in self.banned_keywords:
            if keyword in content:
                return {
                    "messages": [{
                        "role": "assistant",
                        "content": "부적절한 내용이 포함되어 있습니다."
                    }],
                    "jump_to": "end"
                }
        return None
""")
print("핵심: jump_to='end'로 에이전트 실행을 건너뛰고 즉시 응답합니다.")
print("None을 반환하면 다음 단계(에이전트 실행)로 진행합니다.")
`````)
#output-block(`````
커스텀 입력 가드레일 (클래스 방식):
==================================================

from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

class ContentFilterMiddleware(AgentMiddleware):
    """결정론적 가드레일: 금지 키워드가 포함된 요청을 차단합니다."""

    def __init__(self, banned_keywords: list[str]):
        super().__init__()
        self.banned_keywords = [kw.lower() for kw in banned_keywords]

    @hook_config(can_jump_to=["end"])
    def before_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        first_message = state["messages"][0]
        if first_message.type != "human":
            return None

        content = first_message.content.lower()
        for keyword in self.banned_keywords:
            if keyword in content:
... (truncated)
`````)

입력 가드레일이 _요청의 적절성_을 검증한다면, 출력 가드레일은 에이전트가 생성한 _응답의 안전성과 품질_을 검증합니다.

== 13.6 커스텀 출력 가드레일 — after_agent

`after_agent` 훅은 에이전트 _실행 완료 후_ 최종 출력을 검증합니다. 모델 기반 안전성 검사, 품질 검증 등에 사용합니다. 출력 가드레일에서 응답 내용을 직접 수정하거나, `jump_to="end"`로 안전한 대체 응답을 반환할 수 있습니다.

#tip-box[출력 가드레일에서 모델 기반 검사를 수행할 때는, 에이전트 본체보다 경량 모델(예: `gpt-4.1-mini`)을 사용하는 것이 비용과 지연 시간 면에서 유리합니다. 안전성 분류는 복잡한 추론이 필요하지 않으므로, 작은 모델로도 충분히 정확한 판별이 가능합니다.]

#code-block(`````python
# 커스텀 출력 가드레일 — SafetyGuardrailMiddleware 클래스
print("커스텀 출력 가드레일 (클래스 방식):")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model
from typing import Any

class SafetyGuardrailMiddleware(AgentMiddleware):
    \"\"\"모델 기반 가드레일: LLM으로 응답 안전성을 평가합니다.\"\"\"

    def __init__(self):
        super().__init__()
        self.safety_model = init_chat_model("gpt-4.1-mini")

    @hook_config(can_jump_to=["end"])
    def after_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        last_message = state["messages"][-1]
        if not isinstance(last_message, AIMessage):
            return None

        safety_prompt = f\"\"\"Evaluate if this response is safe.
        Respond with only 'SAFE' or 'UNSAFE'.

        Response: {last_message.content}\"\"\"

        result = self.safety_model.invoke(
            [{"role": "user", "content": safety_prompt}]
        )

        if "UNSAFE" in result.content:
            last_message.content = (
                "안전하지 않은 응답입니다. 다시 질문해주세요."
            )
        return None
""")
print("핵심: 별도의 경량 모델(gpt-4.1-mini)로 안전성을 평가합니다.")
print("UNSAFE 판정 시 응답 내용을 안전한 메시지로 교체합니다.")
`````)
#output-block(`````
커스텀 출력 가드레일 (클래스 방식):
==================================================

from langchain.agents.middleware import (
    AgentMiddleware, AgentState, hook_config
)
from langgraph.runtime import Runtime
from langchain.messages import AIMessage
from langchain.chat_models import init_chat_model
from typing import Any

class SafetyGuardrailMiddleware(AgentMiddleware):
    """모델 기반 가드레일: LLM으로 응답 안전성을 평가합니다."""

    def __init__(self):
        super().__init__()
        self.safety_model = init_chat_model("gpt-4.1-mini")

    @hook_config(can_jump_to=["end"])
    def after_agent(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        if not state["messages"]:
            return None

        last_message = state["messages"][-1]
        if not isinstance(last_message, AIMessage):
            return None

        safety_prompt = f"""Evaluate if this response is safe.
... (truncated)
`````)

클래스 방식은 상태 관리와 초기화 로직이 필요한 복잡한 가드레일에 적합하지만, 단순한 검증 로직에는 과할 수 있습니다. 이런 경우 데코레이터 방식이 더 간결합니다.

== 13.7 데코레이터 방식 가드레일

클래스 대신 _데코레이터_를 사용하면 간결하게 가드레일을 정의할 수 있습니다. `@before_agent()`와 `@after_agent()` 데코레이터는 일반 함수를 미들웨어 호환 객체로 변환합니다.

#code-block(`````python
# 데코레이터 방식 가드레일
print("데코레이터 방식 가드레일:")
print("=" * 50)
print("""
from langchain.agents.middleware import (
    before_agent, after_agent, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

banned_keywords = ["hack", "exploit", "malware"]

# 입력 가드레일 — 데코레이터
@before_agent(can_jump_to=["end"])
def content_filter(
    state: AgentState, runtime: Runtime
) -> dict[str, Any] | None:
    \"\"\"금지 키워드를 차단합니다.\"\"\"
    if not state["messages"]:
        return None
    content = state["messages"][0].content.lower()
    for kw in banned_keywords:
        if kw in content:
            return {
                "messages": [{"role": "assistant",
                    "content": "부적절한 요청입니다."}],
                "jump_to": "end"
            }
    return None

# 출력 가드레일 — 데코레이터
@after_agent(can_jump_to=["end"])
def safety_check(
    state: AgentState, runtime: Runtime
) -> dict[str, Any] | None:
    \"\"\"응답에 민감한 내용이 없는지 확인합니다.\"\"\"
    last = state["messages"][-1]
    if hasattr(last, 'content') and '비밀번호' in last.content:
        last.content = "민감한 정보가 포함된 응답입니다."
    return None

# 에이전트에 적용
agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool],
    middleware=[content_filter, safety_check],
)
""")
print("데코레이터 방식은 간단한 가드레일에 적합합니다.")
print("복잡한 로직(상태 관리, 초기화 등)은 클래스 방식을 사용하세요.")
`````)
#output-block(`````
데코레이터 방식 가드레일:
==================================================

from langchain.agents.middleware import (
    before_agent, after_agent, AgentState, hook_config
)
from langgraph.runtime import Runtime
from typing import Any

banned_keywords = ["hack", "exploit", "malware"]

# 입력 가드레일 — 데코레이터
@before_agent(can_jump_to=["end"])
def content_filter(
    state: AgentState, runtime: Runtime
) -> dict[str, Any] | None:
    """금지 키워드를 차단합니다."""
    if not state["messages"]:
        return None
    content = state["messages"][0].content.lower()
    for kw in banned_keywords:
        if kw in content:
            return {
                "messages": [{"role": "assistant",
                    "content": "부적절한 요청입니다."}],
                "jump_to": "end"
            }
    return None

# 출력 가드레일 — 데코레이터
... (truncated)
`````)

개별 가드레일의 작성 방법을 익혔다면, 이제 여러 가드레일을 조합하여 _다층 방어(defense in depth)_ 전략을 구성하는 방법을 살펴보겠습니다. 보안에서는 단일 방어선에 의존하지 않는 것이 원칙이며, 가드레일도 마찬가지입니다.

== 13.8 다중 가드레일 조합

여러 가드레일을 `middleware` 리스트에 순서대로 추가하여 _다층 방어_를 구성합니다. `middleware` 리스트의 순서가 실행 순서를 결정하므로, 빠르고 저렴한 결정론적 가드레일을 앞에, 느리고 비용이 높은 모델 기반 가드레일을 뒤에 배치하는 것이 중요합니다.

#code-block(`````python
# 다중 가드레일 조합
print("다중 가드레일 조합 (다층 방어):")
print("=" * 50)
print("""
from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, HumanInTheLoopMiddleware
)

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool],
    middleware=[
        # Layer 1: 결정론적 입력 필터
        ContentFilterMiddleware(
            banned_keywords=["hack", "exploit"]
        ),

        # Layer 2: PII 보호 (입력 + 출력)
        PIIMiddleware("email",
            strategy="redact", apply_to_input=True),
        PIIMiddleware("email",
            strategy="redact", apply_to_output=True),

        # Layer 3: 민감 도구 사람 승인
        HumanInTheLoopMiddleware(
            interrupt_on={"send_email": True}
        ),

        # Layer 4: 모델 기반 안전성 검사
        SafetyGuardrailMiddleware(),
    ],
)
""")
print("실행 순서:")
print("  입력 → [ContentFilter] → [PII 입력] → 에이전트 실행")
print("       → [HITL 승인] → [PII 출력] → [Safety] → 응답")
print()
print("팁: 빠른 결정론적 가드레일을 앞에, 느린 모델 기반을 뒤에 배치")
`````)
#output-block(`````
다중 가드레일 조합 (다층 방어):
==================================================

from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, HumanInTheLoopMiddleware
)

agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, send_email_tool],
    middleware=[
        # Layer 1: 결정론적 입력 필터
        ContentFilterMiddleware(
            banned_keywords=["hack", "exploit"]
        ),

        # Layer 2: PII 보호 (입력 + 출력)
        PIIMiddleware("email",
            strategy="redact", apply_to_input=True),
        PIIMiddleware("email",
            strategy="redact", apply_to_output=True),

        # Layer 3: 민감 도구 사람 승인
        HumanInTheLoopMiddleware(
            interrupt_on={"send_email": True}
        ),

        # Layer 4: 모델 기반 안전성 검사
        SafetyGuardrailMiddleware(),
... (truncated)
`````)

== 13.9 프로덕션 가드레일 패턴

지금까지 학습한 개별 가드레일 기법을 프로덕션 환경에 적용할 때 따라야 할 모범 사례와 도메인별 가이드라인을 정리합니다.

=== 모범 사례

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[설명],
  text(weight: "bold")[구현 방식],
  [_다층 방어_],
  [여러 가드레일을 조합하여 단일 실패점 제거],
  [`middleware=[layer1, layer2, ...]`],
  [_빠른 실패_],
  [결정론적 검사를 먼저 실행하여 비용 절감],
  [결정론적 → 모델 기반 순서],
  [_입출력 분리_],
  [입력과 출력에 각각 적합한 가드레일 적용],
  [`before_agent` + `after_agent`],
  [_그레이스풀 거부_],
  [차단 시 사용자에게 친절한 안내 제공],
  [`jump_to="end"` + 안내 메시지],
  [_로깅 및 모니터링_],
  [가드레일 트리거 이벤트를 기록],
  [LangSmith 트레이싱 연동],
  [_폴백 전략_],
  [가드레일 자체가 실패할 경우의 대비책],
  [`try/except` + 기본 정책],
  [_테스트_],
  [가드레일 동작을 단위 테스트로 검증],
  [`GenericFakeChatModel` 활용],
)

=== 도메인별 가드레일 예시

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도메인],
  text(weight: "bold")[주요 가드레일],
  [_의료_],
  [PII(환자정보), 의학적 조언 면책, 응급상황 감지],
  [_금융_],
  [PII(계좌정보), 투자 면책, HITL(거래 승인)],
  [_고객서비스_],
  [감정 분석, 에스컬레이션 감지, PII 마스킹],
  [_교육_],
  [연령 적합성 검사, 학술 정직성, 콘텐츠 필터링],
)

#chapter-summary-header()

이 노트북에서 배운 내용:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_가드레일 개념_],
  [에이전트 실행 과정에서 콘텐츠를 검증하고 필터링하는 안전 메커니즘입니다],
  [_PII 감지_],
  [`PIIMiddleware`로 이메일, 신용카드 등 개인정보를 자동 감지/처리합니다],
  [_HITL_],
  [`HumanInTheLoopMiddleware`로 민감한 도구 실행 전 사람의 승인을 요구합니다],
  [_커스텀 입력_],
  [`before_agent` 훅으로 에이전트 실행 전 요청을 검증합니다],
  [_커스텀 출력_],
  [`after_agent` 훅으로 에이전트 실행 후 응답을 검증합니다],
  [_데코레이터_],
  [`\@before_agent`, `\@after_agent` 데코레이터로 간결하게 정의합니다],
  [_다중 조합_],
  [여러 가드레일을 `middleware` 리스트에 추가하여 다층 방어를 구성합니다],
)


#references-box[
- #link("../docs/langchain/13-guardrails.md")[Guardrails]
]
#chapter-end()
