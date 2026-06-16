// Auto-generated from 06_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "미들웨어와 가드레일")

LangChain v1 에이전트의 _미들웨어(Middleware)_ 시스템과 _가드레일(Guardrails)_을 학습합니다.

== 학습 목표
#learning-objectives([_미들웨어 개념:_ 에이전트 실행 파이프라인의 각 단계에 훅(hook)을 추가하는 방법을 이해합니다.], [_빌트인 미들웨어:_ `SummarizationMiddleware` 등 기본 제공 미들웨어를 사용합니다.], [_커스텀 미들웨어:_ `@before_model`, `@after_model`, `@wrap_model_call`, `@dynamic_prompt` 데코레이터로 커스텀 미들웨어를 구현합니다.], [_가드레일:_ 안전하지 않은 입력/출력을 차단하는 방법을 배웁니다.])

== 6.1 환경 설정

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

== 6.2 미들웨어 개념

미들웨어는 에이전트 실행 파이프라인의 _각 단계에 훅(hook)을 추가_하여 동작을 제어하는 메커니즘입니다.

#image("../../assets/images/middleware_pipeline.png")

_5가지 미들웨어 훅:_

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[훅],
  text(weight: "bold")[실행 시점],
  text(weight: "bold")[주요 용도],
  [`\@before_model`],
  [모델 호출 전],
  [입력 검증, 메시지 수정, 가드레일],
  [`\@after_model`],
  [모델 응답 후],
  [출력 로깅, 응답 필터링],
  [`\@wrap_model_call`],
  [모델 호출 감싸기],
  [재시도, 폴백, 캐싱],
  [`\@wrap_tool_call`],
  [도구 호출 감싸기],
  [도구 실행 제어],
  [`\@dynamic_prompt`],
  [프롬프트 생성 시],
  [런타임 프롬프트 변경],
)

== 6.3 빌트인 미들웨어

LangChain v1은 자주 쓰는 패턴을 _빌트인 미들웨어_로 제공합니다. `SummarizationMiddleware`는 대화가 길어지면 이전 메시지를 자동으로 요약하여 토큰 사용량을 줄입니다.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """정보를 검색합니다."""
    return f"'{query}'에 대한 검색 결과"

# SummarizationMiddleware — 긴 대화를 자동 요약
from langchain.agents.middleware import SummarizationMiddleware

summarization = SummarizationMiddleware(
    model=model,
    trigger=("messages", 10),
)

agent_with_summary = create_agent(
    model=model,
    tools=[search],
    system_prompt="당신은 유용한 어시스턴트입니다.",
    middleware=[summarization],
)
print("SummarizationMiddleware 에이전트 생성 완료")
`````)
#output-block(`````
SummarizationMiddleware 에이전트 생성 완료
`````)

=== 빌트인 미들웨어 카탈로그

`SummarizationMiddleware` 외에도 v1 은 자주 쓰는 패턴을 빌트인으로 제공합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어],
  text(weight: "bold")[용도],
  text(weight: "bold")[비고],
  [`SummarizationMiddleware`],
  [대화 요약],
  [`trigger=("messages", N)` 또는 `("tokens", N)`],
  [`AnthropicPromptCachingMiddleware`],
  [Anthropic 프롬프트 캐싱],
  [시스템 메시지·도구 정의 캐시 → 비용 절감],
  [`BedrockPromptCachingMiddleware`],
  [AWS Bedrock 프롬프트 캐싱],
  [Anthropic 모델을 Bedrock 으로 호출할 때],
  [`ModelFallbackMiddleware`],
  [모델 폴백],
  [첫 모델 실패 시 다음 모델로 자동 전환],
  [`ContextEditingMiddleware`],
  [컨텍스트 동적 편집],
  [오래된 tool_use 메시지 제거 등],
  [`PatchToolCallsMiddleware`],
  [도구 호출 후처리],
  [Deep Agents 의 핵심 컴포넌트 — tool call 결과를 상태에 반영],
)

`ContextSize` 트리거 튜플은 어디서나 동일한 형식입니다:
- `("tokens", 100_000)` — 토큰 수 임계값
- `("messages", 20)` — 메시지 개수 임계값
- `("fraction", 0.8)` — 모델 `.profile["max_input_tokens"]` 대비 비율

#code-block(`````python
# Anthropic / Bedrock 프롬프트 캐싱 — 시스템 프롬프트가 크거나 도구가 많을 때 효과적
from langchain.agents.middleware import (
    AnthropicPromptCachingMiddleware,
    BedrockPromptCachingMiddleware,
)

# Anthropic 직접 호출 (claude-sonnet-4-6 등)
anthropic_cache = AnthropicPromptCachingMiddleware()
# Bedrock 경유 호출
bedrock_cache = BedrockPromptCachingMiddleware()

# 예: Anthropic 모델 + 프롬프트 캐싱
# from langchain_anthropic import ChatAnthropic
# anthropic_model = ChatAnthropic(model="claude-sonnet-4-6")
# agent_cached = create_agent(
#     model=anthropic_model,
#     tools=[search],
#     system_prompt="...",
#     middleware=[anthropic_cache],
# )

print("Anthropic/Bedrock 프롬프트 캐싱 미들웨어 생성 완료")
`````)

#code-block(`````python
# ModelFallbackMiddleware — 첫 모델 호출이 실패하면 추가 모델로 순차 폴백
from langchain.agents.middleware import ModelFallbackMiddleware

primary = ChatOpenAI(model="gpt-5.4")
backup_1 = ChatOpenAI(model="gpt-5-nano")
# backup_2 = ChatAnthropic(model="claude-sonnet-4-6")  # 다른 프로바이더 폴백도 가능

fallback = ModelFallbackMiddleware(primary, backup_1)

agent_fallback = create_agent(
    model=primary,
    tools=[search],
    system_prompt="당신은 유용한 어시스턴트입니다.",
    middleware=[fallback],
)
print("ModelFallbackMiddleware 에이전트 생성 완료 — primary 실패 시 backup_1 로 폴백")
`````)

#code-block(`````python
# ContextEditingMiddleware — 토큰 임계값 초과 시 오래된 tool_use 메시지를 자동 제거
# trigger=("tokens", 100_000) 처럼 ContextSize 튜플로 시점을 결정합니다.
from langchain.agents.middleware import ContextEditingMiddleware, ClearToolUsesEdit

context_editor = ContextEditingMiddleware(
    edits=[
        ClearToolUsesEdit(
            trigger=("tokens", 100_000),   # 100K 토큰 넘으면 발동
            keep=("messages", 3),           # 가장 최근 3개 메시지의 tool_use 는 유지
        ),
    ],
)

agent_edited = create_agent(
    model=model,
    tools=[search],
    system_prompt="당신은 유용한 어시스턴트입니다.",
    middleware=[context_editor],
)
print("ContextEditingMiddleware 에이전트 생성 완료")
print("  → 100K 토큰 초과 시 최근 3개 외 오래된 tool_use 메시지를 자동 제거")
`````)

== 6.4 커스텀 미들웨어: \@before_model

`@before_model` 데코레이터는 _모델이 호출되기 전_에 실행됩니다.

주요 용도:
- 입력 메시지 로깅
- 메시지 수정 또는 필터링
- 입력 검증 (가드레일)
- 컨텍스트 추가

== 6.5 커스텀 미들웨어: \@after_model

`@after_model` 데코레이터는 _모델 응답이 생성된 후_에 실행됩니다.

주요 용도:
- 모델 출력 로깅
- 응답 필터링 또는 수정
- 도구 호출 감시
- 출력 품질 검증

== 6.6 \@wrap_model_call

`@wrap_model_call` 데코레이터는 _모델 호출 자체를 감싸서_ 재시도, 폴백, 캐싱 등의 로직을 구현할 수 있습니다.

`handler` 함수로 원래의 모델 호출을 실행하며, 이 호출 전후에 커스텀 로직을 추가합니다.

#code-block(`````python
from langchain.agents.middleware import (
    wrap_model_call,
    ModelRequest,
    ModelResponse,
)
import time


@wrap_model_call
def retry_on_error(request: ModelRequest, handler) -> ModelResponse:
    """실패 시 지수 백오프로 모델 호출을 재시도합니다.

    - request: ModelRequest — messages / tools / system_message / response_format 보유
    - handler: 다음 단계를 실행하는 콜러블 (request 를 받아 ModelResponse 반환)
    """
    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            return handler(request)
        except Exception as e:
            if attempt < max_retries:
                wait = 2 ** attempt
                print(f"  재시도 {attempt + 1}/{max_retries} ({wait}초 대기)")
                time.sleep(wait)
            else:
                raise

agent_retry = create_agent(
    model=model,
    tools=[search],
    system_prompt="당신은 유용한 어시스턴트입니다.",
    middleware=[retry_on_error],
)
print("재시도 미들웨어 에이전트 생성 완료")
`````)

=== request.override — 요청을 변경해서 핸들러로 전달

`ModelRequest` 는 불변(immutable)에 가까운 객체로 다뤄지므로, 일부 필드만 바꾸려면 `request.override(...)` 로 새 객체를 만들어 핸들러에 넘깁니다. 변경 가능한 필드:

- `messages` — 메시지 리스트
- `tools` — 사용 가능한 도구 리스트
- `system_message` — 시스템 프롬프트
- `response_format` — 구조화 출력 스키마

#code-block(`````python
# request.override 로 시스템 메시지·도구 필터를 동적으로 조정
from langchain.agents.middleware import wrap_model_call, ModelRequest, ModelResponse


@wrap_model_call
def restrict_tools_for_anonymous(request: ModelRequest, handler) -> ModelResponse:
    """비로그인 사용자에게는 검색 도구만 허용하고 시스템 프롬프트도 교체합니다."""
    user_id = request.runtime.context.get("user_id") if hasattr(request, "runtime") else None

    if not user_id:
        # 비로그인 — 도구 화이트리스트 적용 + 시스템 메시지 교체
        safe_tools = [t for t in request.tools if t.name == "search"]
        new_request = request.override(
            tools=safe_tools,
            system_message="당신은 비로그인 사용자를 돕는 제한된 어시스턴트입니다.",
        )
        return handler(new_request)

    return handler(request)


print("request.override 패턴 미들웨어 등록 준비 완료")
`````)

== 6.7 \@dynamic_prompt

`@dynamic_prompt` 데코레이터는 _런타임에 시스템 프롬프트를 동적으로 변경_합니다.

주요 용도:
- 현재 날짜/시간 정보 추가
- 사용자별 맞춤 프롬프트
- 상태에 따른 행동 변경
- A/B 테스트

== 6.8 \@wrap_tool_call

`@wrap_tool_call` 데코레이터는 _도구 호출 자체를 감싸서_ 실행 전후에 커스텀 로직을 추가할 수 있습니다.

`@wrap_model_call`이 모델 호출을 감싸듯, `@wrap_tool_call`은 도구 실행을 감쌉니다. `handler` 함수를 호출하면 원래 도구가 실행되며, 그 전후로 타이밍 측정, 로깅, 에러 핸들링 등을 구현할 수 있습니다.

주요 용도:
- _실행 시간 측정:_ 도구별 성능 모니터링
- _로깅:_ 도구 입력/출력 기록
- _에러 핸들링:_ 도구 실패 시 폴백 처리
- _접근 제어:_ 특정 도구 호출 차단 또는 제한

== 6.9 가드레일

가드레일은 _안전하지 않은 입력이나 출력을 차단_하는 메커니즘입니다. 미들웨어로 구현하며, 금지된 키워드 감지, 프롬프트 인젝션 방어, 민감 정보 필터링 등에 씁니다.

`@before_model` 훅에서 구현하는 것이 가장 효과적입니다. 모델에 전달되기 전에 위험한 입력을 차단할 수 있기 때문입니다.

=== \@hook_config(can_jump_to=...) — 조건부 그래프 점프

가드레일이 위험 감지 후 단순히 예외를 던지는 대신, _그래프의 특정 노드로 점프_하도록 만들 수 있습니다. `@hook_config` 로 점프 가능한 대상을 선언하고, 훅에서 `{"jump_to": "end"}` 같은 dict 를 반환하면 됩니다.

점프 대상:
- `"end"` — 즉시 종료
- `"tools"` — 도구 노드로 점프
- `"model"` — 모델 노드로 재진입

=== 비동기 미들웨어 컨벤션

`ainvoke` / `astream` 환경에서는 비동기 변형을 사용합니다. 데코레이터 또는 클래스 메서드 모두 `a-` 프리픽스로 통일됩니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[동기],
  text(weight: "bold")[비동기],
  [`\@before_model`],
  [`\@abefore_model`],
  [`\@after_model`],
  [`\@aafter_model`],
  [`\@wrap_model_call`],
  [`\@awrap_model_call`],
  [`\@wrap_tool_call`],
  [`\@awrap_tool_call`],
  [`\@dynamic_prompt`],
  [`\@adynamic_prompt`],
)

비동기 핸들러 안에서 `await handler(request)` 처럼 await 해야 합니다.

#chapter-summary-header()

이 노트북에서 학습한 미들웨어 타입:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어 타입],
  text(weight: "bold")[데코레이터 / 클래스],
  text(weight: "bold")[실행 시점],
  text(weight: "bold")[주요 용도],
  [_Before Model_],
  [`\@before_model`],
  [모델 호출 전],
  [입력 로깅, 검증, 가드레일],
  [_After Model_],
  [`\@after_model`],
  [모델 응답 후],
  [출력 로깅, 필터링],
  [_Wrap Model_],
  [`\@wrap_model_call`],
  [모델 호출 감싸기],
  [재시도, 폴백, 캐싱],
  [_Wrap Tool_],
  [`\@wrap_tool_call`],
  [도구 호출 감싸기],
  [타이밍, 로깅, 에러 핸들링],
  [_Dynamic Prompt_],
  [`\@dynamic_prompt`],
  [프롬프트 생성 시],
  [런타임 프롬프트 변경],
  [_Builtin (요약)_],
  [`SummarizationMiddleware`],
  [trigger 충족 시],
  [대화 요약],
  [_Builtin (캐싱)_],
  [`AnthropicPromptCachingMiddleware`, `BedrockPromptCachingMiddleware`],
  [모델 호출 전],
  [프롬프트 캐싱 비용 절감],
  [_Builtin (폴백)_],
  [`ModelFallbackMiddleware(primary, *backups)`],
  [모델 호출 실패 시],
  [다른 모델로 자동 폴백],
  [_Builtin (편집)_],
  [`ContextEditingMiddleware(edits=[...])`],
  [트리거 충족 시],
  [오래된 tool_use 제거],
  [_Builtin (Deep Agents)_],
  [`PatchToolCallsMiddleware`],
  [도구 호출 후],
  [tool 결과를 상태에 반영],
  [_Guardrail_],
  [`\@hook_config(can_jump_to=[...])` + `{"jump_to": "end"}`],
  [모델 호출 전],
  [위험 입력 시 그래프 점프],
)

_핵심 포인트:_
- `ModelRequest` 는 `request.override(messages=..., tools=..., system_message=..., response_format=...)` 로 부분 변경합니다.
- `ContextSize` 트리거 튜플은 `("tokens", N)` / `("messages", N)` / `("fraction", 0~1)` 형식이며 `model.profile["max_input_tokens"]` 와 결합해 동적 임계값을 만들 수 있습니다.
- 가드레일은 예외 대신 `@hook_config(can_jump_to=[...])` + `{"jump_to": "end"}` 패턴이 더 안전합니다 (사용자에게 거절 메시지를 남길 수 있음).
- 비동기 환경에서는 `@abefore_model`, `@aafter_model`, `@awrap_model_call` 처럼 `a-` 프리픽스 변형을 씁니다.
- 커스텀 미들웨어 시그니처: `def hook(request: ModelRequest, handler) -> ModelResponse`.
