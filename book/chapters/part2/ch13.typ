// Auto-generated from 13_guardrails.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "가드레일")

== 학습 목표
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
    model="gpt-5.4",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
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

#code-block(`````python
사용자 입력 → [입력 가드레일] → 에이전트 실행 → [출력 가드레일] → 응답
                  ↑                                    ↑
            before_agent                          after_agent
`````)

== 13.3 PII 감지 미들웨어

_PIIMiddleware_는 이메일, 신용카드 번호, IP 주소 등 개인식별정보(PII)를 자동으로 감지하고 처리합니다.

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
    model="gpt-5.4",
    tools=[customer_service_tool, email_tool],
    middleware=[
        # 이메일 주소를 [REDACTED_EMAIL]로 대체
        PIIMiddleware("email",
            strategy="redact",
            apply_to_input=True,
            apply_to_output=False,         # default
            apply_to_tool_results=False),  # default

        # 신용카드 번호를 부분 마스킹 (****-****-****-1234)
        PIIMiddleware("credit_card",
            strategy="mask",
            apply_to_input=True,
            apply_to_tool_results=False),  # default

        # API 키 감지 시 차단 (커스텀 정규식)
        PIIMiddleware("api_key",
            detector=r"sk-[a-zA-Z0-9]{32}",
            strategy="block",
            apply_to_input=True,
            apply_to_tool_results=False),  # default
    ],
)
""")
print("내장 PII 타입: email, credit_card, ip, mac_address, url")
print("커스텀 감지: detector 파라미터에 정규식 또는 함수 전달")
print()
print("apply_to_* 파라미터 (기본값 False):")
print("  - apply_to_input          사용자 메시지 검사")
print("  - apply_to_output         LLM 최종 응답 검사")
print("  - apply_to_tool_results   도구 반환값 검사")
print("→ 최소 하나는 True로 명시해야 미들웨어가 동작합니다.")
`````)

== 13.4 Human-in-the-Loop 가드레일

_HumanInTheLoopMiddleware_는 민감한 작업을 실행하기 전에 _사람의 승인_을 요구합니다. 금융 거래, 데이터 삭제, 외부 통신 등 고위험 작업에 씁니다.

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
    model="gpt-5.4",
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
    model="gpt-5.4",
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

== 13.5 커스텀 입력 가드레일 — before_agent

`before_agent` 훅은 에이전트 실행 _시작 전_에 요청을 검증합니다. 세션 수준의 인증, 비율 제한, 콘텐츠 필터링 등에 씁니다.

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

== 13.6 커스텀 출력 가드레일 — after_agent

`after_agent` 훅은 에이전트 _실행 완료 후_ 최종 출력을 검증합니다. 모델 기반 안전성 검사, 품질 검증 등에 씁니다.

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
        self.safety_model = init_chat_model("gpt-5.4-mini")

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
print("핵심: 별도의 경량 모델(gpt-5.4-mini)로 안전성을 평가합니다.")
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

== 13.7 데코레이터 방식 가드레일

클래스 대신 _데코레이터_를 쓰면 간결하게 가드레일을 정의할 수 있습니다.

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
    model="gpt-5.4",
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

== 13.8 다중 가드레일 조합

여러 가드레일을 `middleware` 리스트에 순서대로 추가하여 _다층 방어_를 구성합니다.

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
    model="gpt-5.4",
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
    model="gpt-5.4",
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
