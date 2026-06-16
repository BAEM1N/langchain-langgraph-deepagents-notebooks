// Auto-generated from 01_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "미들웨어 시스템 심화", subtitle: "v1 최대 신기능")

== 학습 목표
#learning-objectives([에이전트 루프의 6단계 미들웨어 훅(`before_agent` / `before_model` / `wrap_model_call` / `wrap_tool_call` / `after_model` / `after_agent`)을 이해한다], [프로바이더 무관 빌트인(Summarization, HITL, Model/Tool Call Limit, ModelFallback, PII, LLMToolSelector, ContextEditing)과 프로바이더 전용(AnthropicPromptCaching, BedrockPromptCaching, PatchToolCalls) 미들웨어를 구분해 사용한다], [`ModelRequest` / `ToolCallRequest` / `ModelResponse` / `ExtendedModelResponse` 타입을 활용해 데코레이터·클래스 기반 커스텀 미들웨어를 작성한다], [`request.override(...)`, `@hook_config(can_jump_to=...)`, `state_schema=` 옵션으로 동적 구성과 에이전트 점프를 구현한다], [다중 미들웨어 조합 시 실행 순서(`before` 순방향, `after` 역방향, `wrap` 중첩)를 정확히 예측한다])

== 1.1 환경 설정

미들웨어는 에이전트 실행의 각 단계에 훅(hook)을 삽입하여 모니터링, 변환, 신뢰성, 거버넌스를 구현하는 v1의 핵심 기능입니다. `create_agent` 함수의 `middleware` 파라미터에 미들웨어 인스턴스 리스트를 전달해 사용합니다.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-5.4")
`````)

== 1.2 미들웨어 아키텍처 개요

에이전트 루프는 _모델 호출 → 도구 선택 → 도구 실행 → 종료 판단_의 반복 사이클입니다. 미들웨어는 이 사이클의 6단계에 훅(hook)을 삽입해 세밀하게 제어합니다.

=== 6단계 훅

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[훅],
  text(weight: "bold")[스타일],
  text(weight: "bold")[실행 시점],
  text(weight: "bold")[대표 용도],
  [`before_agent`],
  [node],
  [에이전트 실행 시작 1회],
  [인증, 사용자 컨텍스트 로드],
  [`before_model`],
  [node],
  [매 모델 호출 직전],
  [프롬프트 보강, 카운팅, 로깅],
  [`wrap_model_call`],
  [wrap],
  [모델 호출 감싸기],
  [재시도, 캐싱, `request.override(...)` 동적 구성],
  [`wrap_tool_call`],
  [wrap],
  [도구 호출 감싸기],
  [도구 재시도, 에러 변환, 감사 로그],
  [`after_model`],
  [node],
  [매 모델 응답 직후],
  [가드레일, `{"jump_to": "end"}` 점프],
  [`after_agent`],
  [node],
  [에이전트 실행 종료 1회],
  [정리, 메트릭 전송],
)

=== 두 가지 훅 스타일

- _Node-style_ (`before_*`, `after_*`): 순차 실행. 로깅·검증·상태 업데이트에 적합.
- _Wrap-style_ (`wrap_*`): 핸들러 호출 여부를 0/1/N 회로 제어. 재시도·캐싱·동적 라우팅에 적합.

=== 시그니처와 타입

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[훅],
  text(weight: "bold")[인자],
  text(weight: "bold")[반환],
  [`wrap_model_call(request, handler)`],
  [`request: ModelRequest`, `handler: Callable[[ModelRequest], ModelResponse]`],
  [`ModelResponse` 또는 `ExtendedModelResponse`],
  [`wrap_tool_call(request, handler)`],
  [`request: ToolCallRequest`, `handler: Callable[[ToolCallRequest], ToolMessage \\],
  [Command]`],
  [`ToolMessage` 또는 `Command`],
  [`before_model(state, runtime)` / `after_model(state, runtime)`],
  [`state: AgentState`, `runtime: Runtime`],
  [`dict],
  [None` (`jump_to` 지원)],
)

- `ModelRequest`는 `messages`, `tools`, `model`, `system_message`, `response_format`, `state`, `runtime` 필드를 노출합니다.
- `ToolCallRequest`는 `tool_call`, `state`, `runtime` 필드를 노출합니다.
- `ExtendedModelResponse`는 `model_response` + `command`로, `wrap_model_call`에서 영구 상태 업데이트를 보낼 때 씁니다.

미들웨어는 에이전트의 핵심 로직을 건드리지 않고도 모니터링, 변환, 신뢰성, 거버넌스 등 횡단 관심사(cross-cutting concerns)를 깔끔하게 분리할 수 있게 해줍니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    SummarizationMiddleware,
    HumanInTheLoopMiddleware,
)

agent = create_agent(
    model="gpt-5.4", tools=[],
    middleware=[
        SummarizationMiddleware(model="gpt-5.4-mini", trigger=("messages", 50)),
        HumanInTheLoopMiddleware(interrupt_on={}),
    ],
)
`````)

== 1.3 SummarizationMiddleware

대화가 길어져 컨텍스트 윈도우를 초과할 때 이전 대화를 자동으로 요약·압축합니다. 장시간 실행되는 대화, 다중 턴 대화, 전체 대화 맥락을 보존해야 하는 애플리케이션에 적합합니다.

=== 주요 파라미터

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  text(weight: "bold")[예시],
  [`model`],
  [요약 생성에 사용할 경량 모델 (비용 절감)],
  [`"gpt-5.4-mini"`],
  [`trigger`],
  [요약 트리거 조건],
  [`("tokens", 4000)`, `("messages", 50)`, `("fraction", 0.8)`],
  [`keep`],
  [요약 후 유지할 최근 컨텍스트],
  [`("messages", 20)`],
  [`token_counter`],
  [커스텀 토큰 카운팅 함수],
  [선택적],
  [`summary_prompt`],
  [커스텀 요약 프롬프트 템플릿],
  [선택적],
)

`trigger`는 토큰 수, 메시지 수, 윈도우 비율 중 하나를 기준으로 설정할 수 있으며, 조건에 도달하면 `keep`에 지정된 최근 메시지를 제외한 나머지를 요약문으로 교체합니다.

#code-block(`````python
from langchain.agents.middleware import SummarizationMiddleware

summarizer = SummarizationMiddleware(
    model="gpt-5.4-mini",
    trigger=("tokens", 4000),
    keep=("messages", 20),
)
`````)

== 1.4 HumanInTheLoopMiddleware

고위험 도구 호출 전에 에이전트 실행을 멈추고 인간 승인을 기다립니다. 데이터베이스 쓰기, 금융 거래, 이메일 전송 같은 고위험 작업이나 인간 감독이 필요한 컴플라이언스 워크플로우에 씁니다.

**`checkpointer` 필수** — 중단 후 상태를 복원하려면 체크포인터가 반드시 있어야 합니다.

=== 결정 유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정],
  text(weight: "bold")[설명],
  text(weight: "bold")[사용 방법],
  [`approve`],
  [도구 호출 승인 및 실행],
  [`Command(resume="approve")`],
  [`edit`],
  [도구 인자 수정 후 실행],
  [`Command(resume={"type": "edit", "args": {...}})`],
  [`reject`],
  [도구 호출 거부],
  [`Command(resume={"type": "reject", "reason": "..."})`],
)

`interrupt_on` 딕셔너리에서 각 도구별로 승인 정책을 설정합니다. `False`로 설정하면 해당 도구는 중단 없이 실행됩니다.

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

hitl = HumanInTheLoopMiddleware(
    interrupt_on={
        "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
        "read_email": False,
    }
)
`````)

#code-block(`````python
agent = create_agent(
    model="gpt-5.4", tools=[],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
)
`````)

== 1.5 ModelCallLimitMiddleware & ToolCallLimitMiddleware

무한 루프나 과도한 API 비용을 막는 호출 제한 미들웨어입니다.

=== ModelCallLimitMiddleware

에이전트가 모델을 호출하는 횟수를 제한합니다. 폭주하는 에이전트 방지, 프로덕션 비용 제어, 테스트 시 호출 예산 관리에 씁니다.

=== ToolCallLimitMiddleware

도구 호출 횟수를 전역적으로 또는 특정 도구별로 제한합니다. 비용이 높은 외부 API 호출 제한, 검색/DB 쿼리 빈도 제어, 특정 도구의 레이트 리밋 적용에 유용합니다.

=== 공통 파라미터

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  [`thread_limit`],
  [전체 스레드(모든 invoke)에서의 최대 호출 수],
  [`run_limit`],
  [단일 invoke 실행에서의 최대 호출 수],
  [`exit_behavior`],
  [`"end"` (정상 종료), `"error"` (예외 발생), `"continue"` (에러 메시지와 함께 계속 — ToolCallLimit 전용)],
)

ToolCallLimitMiddleware는 추가로 `tool_name` 파라미터를 받아 특정 도구에만 제한을 적용할 수 있습니다.

#code-block(`````python
from langchain.agents.middleware import ModelCallLimitMiddleware

model_limit = ModelCallLimitMiddleware(
    thread_limit=10,
    run_limit=5,
    exit_behavior="end",
)
`````)

#code-block(`````python
from langchain.agents.middleware import ToolCallLimitMiddleware

# 전역 제한
global_tool_limit = ToolCallLimitMiddleware(thread_limit=20, run_limit=10)

# 특정 도구 제한
search_limit = ToolCallLimitMiddleware(
    tool_name="search",
    thread_limit=5, run_limit=3,
    exit_behavior="continue",
)
`````)

== 1.6 ModelFallbackMiddleware

주 모델 실패 시 대체 모델 체인으로 자동 전환합니다. 프로덕션 장애 대응, 비용 최적화(비싼 모델 → 저렴한 모델 폴백), 멀티 프로바이더 중복성(OpenAI + Anthropic 등) 확보에 유용합니다.

생성자에 폴백 모델을 순서대로 전달하면, 주 모델 호출이 실패할 때 지정된 순서로 대체 모델을 시도합니다. 모든 폴백이 실패하면 최종 에러가 발생합니다.

#code-block(`````python
from langchain.agents.middleware import ModelFallbackMiddleware

# gpt-5.4 실패 -> gpt-5.4-mini -> claude
fallback = ModelFallbackMiddleware(
    "gpt-5.4-mini",
    "claude-sonnet-4-6",
)
`````)

== 1.7 PIIMiddleware

개인 식별 정보(PII)를 자동 탐지하고 설정된 전략에 따라 처리합니다. 의료/금융 컴플라이언스, 고객 서비스 에이전트의 로그 세정, 민감한 사용자 데이터 처리에 씁니다.

=== 빌트인 PII 타입
`email`, `credit_card`, `ip`, `mac_address`, `url`

=== 처리 전략

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[동작],
  text(weight: "bold")[예시 (이메일)],
  [`block`],
  [예외 발생 — PII 발견 시 실행 중단],
  [에러 발생],
  [`redact`],
  [`[REDACTED_TYPE]`으로 교체],
  [`[REDACTED_EMAIL]`],
  [`mask`],
  [부분 마스킹],
  [`u***\@example.com`],
  [`hash`],
  [결정적 해싱],
  [`a1b2c3d4...`],
)

=== 적용 범위
- `apply_to_input`: 사용자 입력 메시지 검사
- `apply_to_output`: AI 응답 메시지 검사
- `apply_to_tool_results`: 도구 실행 결과 검사

=== 커스텀 탐지기
빌트인 PII 타입 외에 세 가지 방식으로 커스텀 탐지기를 만들 수 있습니다:
+ _정규식 문자열_: 간단한 패턴 매칭
+ **컴파일된 정규식 (`re.compile`)**: 복잡한 정규식
+ _함수_: 검증 로직이 필요한 고급 탐지 (반환: `list[dict]` — `text`, `start`, `end` 키 포함)

#code-block(`````python
from langchain.agents.middleware import PIIMiddleware

email_pii = PIIMiddleware("email", strategy="redact", apply_to_input=True)
card_pii = PIIMiddleware("credit_card", strategy="mask", apply_to_input=True)
`````)

#code-block(`````python
# 커스텀 탐지기: 정규식 문자열
api_key_pii = PIIMiddleware(
    "api_key",
    detector=r"sk-[a-zA-Z0-9]{32}",
    strategy="block",
)
`````)

#code-block(`````python
import re

# 커스텀 탐지기: 컴파일된 정규식
phone_pii = PIIMiddleware(
    "phone_number",
    detector=re.compile(r"\+?\d{1,3}[\s.-]?\d{3,4}[\s.-]?\d{4}"),
    strategy="mask",
)
`````)

#code-block(`````python
# 커스텀 탐지기: 함수 (SSN 예시)
def detect_ssn(content: str) -> list[dict]:
    matches = []
    for m in re.finditer(r"\d{3}-\d{2}-\d{4}", content):
        first = int(m.group(0)[:3])
        if first not in [0, 666] and not (900 <= first <= 999):
            matches.append({"text": m.group(0), "start": m.start(), "end": m.end()})
    return matches

ssn_pii = PIIMiddleware("ssn", detector=detect_ssn, strategy="hash")
`````)

== 1.8 LLMToolSelectorMiddleware

도구가 10개 이상일 때, 경량 LLM이 사용자 쿼리를 분석해 관련 도구만 선별합니다. 불필요한 도구 설명으로 인한 토큰 낭비를 줄이고, 모델이 관련 도구에 집중해 정확도를 높입니다.

=== 주요 파라미터

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[설명],
  text(weight: "bold")[기본값],
  [`model`],
  [도구 선택용 모델],
  [에이전트의 메인 모델],
  [`system_prompt`],
  [커스텀 선택 지침],
  [내장 프롬프트],
  [`max_tools`],
  [최대 선택 도구 수],
  [전체],
  [`always_include`],
  [항상 포함할 도구 이름 리스트],
  [`[]`],
)

선택 모델로 `gpt-5.4-mini` 같은 경량 모델을 쓰면 비용을 절감하면서도 효과적인 도구 필터링이 가능합니다.

#code-block(`````python
from langchain.agents.middleware import LLMToolSelectorMiddleware

tool_selector = LLMToolSelectorMiddleware(
    model="gpt-5.4-mini",
    max_tools=3,
    always_include=["search"],
)
`````)

== 1.8b 신규 빌트인 — 프로바이더 캐싱·도구 호출 복구·컨텍스트 편집

기본 7종 외에 v1.1+에서 추가된 빌트인 미들웨어들입니다. 비용과 신뢰성에 직접 영향을 주므로 프로덕션 스택의 핵심입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[패키지],
  text(weight: "bold")[목적],
  [`AnthropicPromptCachingMiddleware`],
  [`langchain_anthropic.middleware`],
  [Claude 시스템 프롬프트/도구 정의/이전 턴 캐시 히트화],
  [`BedrockPromptCachingMiddleware`],
  [`langchain_aws.middleware.prompt_caching`],
  [Bedrock 호스팅 Claude에 동일 캐싱 적용],
  [`PatchToolCallsMiddleware`],
  [`deepagents.middleware.patch_tool_calls`],
  [모델이 만든 잘못된 도구 호출(타입 오류, 알 수 없는 이름, 잘린 args)을 도구 노드 도달 전에 보정],
  [`ModelFallbackMiddleware` (재)],
  [`langchain.agents.middleware`],
  [1차 모델 실패 시 순차 폴백],
  [`ContextEditingMiddleware`],
  [`langchain.agents.middleware`],
  [토큰 한도 도달 시 오래된 도구 출력 정리],
)

`AnthropicPromptCachingMiddleware`의 `ttl`은 `"5m"` 또는 `"1h"`, `min_messages_to_cache`로 캐싱 활성화 메시지 수를 조정합니다. `PatchToolCallsMiddleware`는 `create_deep_agent(...)` 사용 시 기본 스택에 자동 포함됩니다.

#code-block(`````python
# AnthropicPromptCachingMiddleware — 긴 시스템 프롬프트/도구를 캐시 히트로
from langchain_anthropic import ChatAnthropic
from langchain_anthropic.middleware import AnthropicPromptCachingMiddleware
from langchain.agents import create_agent

cached_agent = create_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="<긴 시스템 프롬프트>",
    middleware=[AnthropicPromptCachingMiddleware(ttl="5m", min_messages_to_cache=0)],
)
`````)

#code-block(`````python
# BedrockPromptCachingMiddleware — Bedrock 호스팅 Claude 동일 캐싱
from langchain_aws import ChatBedrockConverse
from langchain_aws.middleware.prompt_caching import BedrockPromptCachingMiddleware

bedrock_agent = create_agent(
    model=ChatBedrockConverse(model="us.anthropic.claude-sonnet-4-5-20250929-v1:0"),
    system_prompt="<긴 시스템 프롬프트>",
    middleware=[BedrockPromptCachingMiddleware(ttl="1h")],
)
`````)

#code-block(`````python
# PatchToolCallsMiddleware — 잘못된 도구 호출을 도구 노드 도달 전에 보정
from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware

patched_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[],
    middleware=[PatchToolCallsMiddleware()],
)
# 참고: create_deep_agent(...) 사용 시 기본 미들웨어 스택에 자동 포함
`````)

#code-block(`````python
# ContextEditingMiddleware — 토큰 임계 도달 시 오래된 도구 출력을 placeholder로 교체
from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit

ctx_edit_agent = create_agent(
    model="gpt-5.4",
    tools=[],
    middleware=[
        ContextEditingMiddleware(
            edits=[ClearToolUsesEdit(trigger=100_000, keep=3)],
        ),
    ],
)
`````)

== 1.9 커스텀 미들웨어 작성

두 가지 구현 방식이 있습니다:

=== 1. 데코레이터 방식
단일 훅, 간단한 로직에 적합합니다. `@before_model`, `@after_model`, `@wrap_model_call`, `@wrap_tool_call` 데코레이터를 사용합니다.

=== 2. 클래스 방식 (`AgentMiddleware`)
여러 훅을 조합하거나 설정이 필요한 경우 `AgentMiddleware`를 상속합니다. sync/async 구현을 동시에 제공할 수 있습니다.

=== 커스텀 상태
미들웨어는 `NotRequired` 타입 힌트로 에이전트 상태를 확장할 수 있습니다. 실행 간 값 추적, 훅 간 데이터 공유, 레이트 리밋이나 감사 로깅 같은 횡단 관심사 구현에 활용합니다.

=== 에이전트 점프
`after_model` 등에서 딕셔너리를 반환하여 에이전트 흐름을 제어할 수 있습니다:
- `{"jump_to": "end"}` — 에이전트 즉시 종료
- `{"jump_to": "tools"}` — 도구 실행 단계로 이동
- `{"jump_to": "model"}` — 모델 호출 단계로 이동

#code-block(`````python
from langchain.agents.middleware import before_model

@before_model
def log_before(state, runtime):
    """모델 호출 전 메시지 수를 기록합니다."""
    print(f"[LOG] 메시지 {len(state.get('messages', []))}개")
`````)

#code-block(`````python
from langchain.agents.middleware import after_model

@after_model
def validate_output(state, runtime):
    """가드: 금지된 콘텐츠를 차단합니다."""
    last = state["messages"][-1].content
    if "FORBIDDEN" in last:
        return {"jump_to": "end"}
`````)

#code-block(`````python
from typing import Callable
from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse

@wrap_model_call
def retry_on_error(
    request: ModelRequest,
    handler: Callable[[ModelRequest], ModelResponse],
) -> ModelResponse:
    """실패 시 모델 호출을 최대 2회 재시도합니다."""
    for attempt in range(3):
        try:
            return handler(request)
        except Exception:
            if attempt == 2: raise
`````)

#code-block(`````python
# wrap_tool_call — 도구 호출을 감싸 감사 로그/에러 변환
from typing import Callable
from langchain.agents.middleware import wrap_tool_call, ToolCallRequest
from langchain.messages import ToolMessage
from langgraph.types import Command

@wrap_tool_call
def audit_tool(
    request: ToolCallRequest,
    handler: Callable[[ToolCallRequest], ToolMessage | Command],
) -> ToolMessage | Command:
    """도구 호출 전후로 감사 로그를 남기고 예외를 ToolMessage 로 변환."""
    name = request.tool_call["name"]
    print(f"[AUDIT] tool={name} args={request.tool_call['args']}")
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"도구 오류: {e}",
            tool_call_id=request.tool_call["id"],
        )
`````)

#code-block(`````python
# request.override(...) — wrap_model_call 에서 모델/도구/시스템 프롬프트를 단일 호출 한정으로 교체
@wrap_model_call
def dynamic_config(
    request: ModelRequest,
    handler: Callable[[ModelRequest], ModelResponse],
) -> ModelResponse:
    """상태 기반으로 모델 호출 시 system_prompt 와 tools 를 동적으로 교체."""
    if request.state.get("expert_mode"):
        request = request.override(
            system_prompt="당신은 시니어 분석가입니다.",
            # tools=[...specialist_tools],
        )
    return handler(request)
`````)

#code-block(`````python
# @hook_config(can_jump_to=[...]) — after_model 에서 합법 점프 대상 선언
from typing import Any
from langchain.agents.middleware import after_model, hook_config, AgentState
from langchain.messages import AIMessage
from langgraph.runtime import Runtime

@after_model
@hook_config(can_jump_to=["end"])
def block_forbidden(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    last = state["messages"][-1]
    if "BLOCKED" in getattr(last, "content", ""):
        return {
            "messages": [AIMessage("요청에 응답할 수 없습니다.")],
            "jump_to": "end",
        }
    return None
`````)

#code-block(`````python
# ExtendedModelResponse — wrap_model_call 에서 모델 응답 + 영구 상태 업데이트를 함께 반환
from langchain.agents.middleware import ExtendedModelResponse

@wrap_model_call
def track_tokens(
    request: ModelRequest,
    handler: Callable[[ModelRequest], ModelResponse],
) -> ExtendedModelResponse:
    response = handler(request)
    return ExtendedModelResponse(
        model_response=response,
        command=Command(update={"last_model_call_tokens": 150}),
    )
`````)

#code-block(`````python
from langchain.agents.middleware import AgentMiddleware

class AuditMiddleware(AgentMiddleware):
    def __init__(self, log_file="audit.log"):
        self.log_file = log_file
    def before_model(self, state, config):
        print(f"[AUDIT] before -> {self.log_file}")
    def after_model(self, state, config):
        print(f"[AUDIT] after -> {self.log_file}")
`````)

== 1.10 미들웨어 실행 순서

다중 미들웨어 등록 시 실행 순서를 정확히 이해해야 예상치 못한 동작을 막을 수 있습니다.

`middleware=[A, B, C]` 등록 시:

#image("../../assets/images/middleware_execution_order.png")

=== 실전 팁
- _PII 검출은 로깅보다 먼저_ 등록해야 로그에 PII가 포함되지 않습니다.
- _폴백 미들웨어는 재시도 미들웨어보다 뒤에_ 배치하여, 재시도 실패 후 폴백이 작동하도록 합니다.
- `wrap` 훅에서 `next_fn`을 호출하지 않으면 이후 미들웨어와 실제 호출이 모두 건너뛰어집니다.

#code-block(`````python
@before_model
def mw_a(state, runtime): print("before A")

@before_model
def mw_b(state, runtime): print("before B")

@before_model
def mw_c(state, runtime): print("before C")

# 실행: A -> B -> C (after_model이면 C -> B -> A)
`````)

== 1.11 미들웨어 조합 (Stacking)

프로덕션 환경에서는 여러 미들웨어를 함께 사용해 종합적인 에이전트 거버넌스를 구현합니다. 미들웨어는 등록 순서에 따라 실행되므로, 보안(PII) → 신뢰성(폴백) → 비용 제어(호출 제한) → 컨텍스트 관리(요약) → 최적화(도구 선택) → 감독(HITL) 순으로 배치하는 것이 권장됩니다.

이런 조합에서 각 미들웨어는 단일 책임 원칙을 지키면서도, 전체적으로 강력한 프로덕션 에이전트 파이프라인을 구성합니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import (
    PIIMiddleware, ModelFallbackMiddleware,
    ModelCallLimitMiddleware, SummarizationMiddleware,
    HumanInTheLoopMiddleware, LLMToolSelectorMiddleware,
    ContextEditingMiddleware, ClearToolUsesEdit,
)
from deepagents.middleware.patch_tool_calls import PatchToolCallsMiddleware
from langgraph.checkpoint.memory import InMemorySaver
`````)

#code-block(`````python
middleware_stack = [
    PIIMiddleware("email", strategy="redact", apply_to_input=True),
    PatchToolCallsMiddleware(),
    ModelFallbackMiddleware("gpt-5.4-mini", "claude-sonnet-4-6"),
    ModelCallLimitMiddleware(thread_limit=50, run_limit=10),
    ContextEditingMiddleware(edits=[ClearToolUsesEdit(trigger=100_000, keep=3)]),
    SummarizationMiddleware(model="gpt-5.4-mini", trigger=("fraction", 0.8)),
]

production_agent = create_agent(
    model="gpt-5.4", tools=[], checkpointer=InMemorySaver(), middleware=middleware_stack,
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
  text(weight: "bold")[핵심 내용],
  [_아키텍처_],
  [6단계 훅: `before_agent` / `before_model` / `wrap_model_call` / `wrap_tool_call` / `after_model` / `after_agent`],
  [_타입_],
  [`ModelRequest`, `ToolCallRequest`, `ModelResponse`, `ExtendedModelResponse`],
  [_프로바이더 무관 빌트인_],
  [Summarization, HITL, ModelCallLimit, ToolCallLimit, ModelFallback, PII, LLMToolSelector, ContextEditing],
  [_프로바이더 전용_],
  [AnthropicPromptCaching, BedrockPromptCaching, PatchToolCalls (Deep Agents 기본 스택)],
  [_커스텀_],
  [데코레이터(`\@before_model`, `\@wrap_model_call`, `\@wrap_tool_call` 등) / `AgentMiddleware` 클래스],
  [_동적 구성_],
  [`request.override(system_prompt=, tools=, model=, response_format=)`],
  [_상태 점프_],
  [`\@hook_config(can_jump_to=["end"],
  ["tools"],
  ["model"])`],
  [_영구 상태_],
  [`ExtendedModelResponse(model_response=..., command=Command(update={...}))`],
  [_실행 순서_],
  [`before`: 순방향, `after`: 역방향, `wrap`: 중첩],
  [_프로덕션 스택_],
  [PII → PatchToolCalls → Fallback → Limit → ContextEditing → Summarization → ToolSelector → HITL],
)
