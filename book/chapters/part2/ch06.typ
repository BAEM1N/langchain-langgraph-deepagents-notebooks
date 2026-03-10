// Auto-generated from 06_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "미들웨어와 가드레일")

에이전트의 모든 요청과 응답이 지나가는 _파이프라인_에 로직을 삽입하고 싶을 때가 있습니다 — 입력을 검증하거나, 모델 호출 전에 컨텍스트를 추가하거나, 응답에서 민감 정보를 제거하는 등. LangChain v1의 미들웨어 시스템은 바로 이 목적을 위해 설계되었습니다. 이 장에서는 미들웨어 훅의 종류와 가드레일 구현 패턴을 학습합니다.

앞 장에서 메모리와 스트리밍으로 에이전트의 기본 인프라를 완성했습니다. 그러나 프로덕션 환경에서는 에이전트가 "무엇을 할 수 있는가"뿐 아니라 "무엇을 하면 안 되는가"도 중요합니다. 미들웨어는 에이전트 실행의 각 단계에 _가로채기(interception)_ 로직을 삽입하여, 로깅·검증·필터링·캐싱 등 횡단 관심사(cross-cutting concerns)를 깔끔하게 처리합니다. 웹 프레임워크의 미들웨어와 유사한 개념입니다.

#learning-header()
#learning-objectives([_미들웨어 개념:_ 에이전트 실행 파이프라인의 각 단계에 훅(hook)을 추가하는 방법을 이해합니다.], [_빌트인 미들웨어:_ `SummarizationMiddleware` 등 기본 제공 미들웨어를 사용합니다.], [_커스텀 미들웨어:_ `@before_model`, `@after_model`, `@wrap_model_call`, `@dynamic_prompt` 데코레이터로 커스텀 미들웨어를 구현합니다.], [_가드레일:_ 안전하지 않은 입력/출력을 차단하는 방법을 배웁니다.])

== 6.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

print("모델 준비 완료:", model.model_name)
`````)
#output-block(`````
모델 준비 완료: gpt-4.1
`````)

== 6.2 미들웨어 개념

미들웨어의 동작 원리를 이해하기 위해, 에이전트의 실행 파이프라인을 시각적으로 살펴봅니다.

미들웨어는 에이전트 실행 파이프라인의 _각 단계에 훅(hook)을 추가_하여 동작을 제어하는 메커니즘입니다. `create_agent()`의 `middleware` 매개변수에 미들웨어 리스트를 전달하면, 에이전트의 매 실행 주기마다 해당 훅이 자동으로 호출됩니다. 미들웨어의 훅 종류는 `prompt`, `before_model`, `after_model`, `before_tool`, `after_tool`, `wrap_model_call` 등이 있으며, 아래 다이어그램에서 각 훅이 파이프라인의 어느 시점에 실행되는지 확인할 수 있습니다.

#align(center)[#image("../../assets/diagrams/png/middleware_pipeline.png", width: 54%, height: 128mm, fit: "contain")]

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

훅의 종류를 확인했으니, 가장 쉽게 시작할 수 있는 _빌트인 미들웨어_부터 살펴봅니다. LangChain v1은 자주 사용되는 패턴을 빌트인 미들웨어로 제공합니다. `SummarizationMiddleware`는 대화가 길어지면 자동으로 이전 메시지를 요약하여 토큰 사용량을 줄입니다. 5장에서 `trim_messages()`로 수동 트리밍을 했다면, 이 미들웨어는 _자동 요약_ 방식으로 컨텍스트를 압축합니다. `trigger=("messages", 10)` 설정은 메시지가 10개를 초과하면 요약을 트리거합니다.

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

== 6.4 커스텀 미들웨어: \@before_model

빌트인 미들웨어로 해결되지 않는 요구사항이 있을 때, 커스텀 미들웨어를 작성합니다. 가장 많이 사용되는 훅은 `@before_model`입니다.

`@before_model` 데코레이터는 _모델이 호출되기 전_에 실행됩니다. 이 훅의 함수는 메시지 리스트를 받아 수정된 메시지 리스트를 반환합니다. 메시지를 추가하거나, 필터링하거나, 변환할 수 있습니다.

주요 용도:
- 입력 메시지 로깅
- 메시지 수정 또는 필터링
- 입력 검증 (가드레일)
- 컨텍스트 추가 (현재 시간, 사용자 프로필 등)

== 6.5 커스텀 미들웨어: \@after_model

`@before_model`이 입력 쪽을 제어한다면, `@after_model`은 출력 쪽을 제어합니다. `@after_model` 데코레이터는 _모델 응답이 생성된 후_에 실행됩니다. 이 훅의 함수는 `AIMessage`를 받아 수정된 `AIMessage`를 반환합니다.

주요 용도:
- 모델 출력 로깅 및 모니터링
- 응답에서 민감 정보(PII) 제거
- 도구 호출 감시 및 차단
- 출력 품질 검증 (환각 탐지 등)

== 6.6 \@wrap_model_call

`@before_model`과 `@after_model`은 모델 호출의 전/후에 각각 동작하지만, 모델 호출 _자체_를 대체하거나 감싸야 할 때가 있습니다. 예를 들어 응답을 캐싱하거나, 실패 시 다른 모델로 폴백하는 경우입니다.

`@wrap_model_call` 데코레이터는 _모델 호출 자체를 감싸서_ 재시도, 폴백, 캐싱 등의 로직을 구현할 수 있습니다.

`handler` 함수를 통해 원래의 모델 호출을 실행하며, 이 호출 전후로 커스텀 로직을 추가합니다. `handler(request)`를 호출하지 않으면 모델이 전혀 호출되지 않으므로, 캐시 히트 시 저장된 응답을 바로 반환하는 식으로 활용할 수 있습니다.

#code-block(`````python
from langchain.agents.middleware import wrap_model_call
import time

@wrap_model_call
def retry_on_error(request, handler):
    """실패 시 지수 백오프로 모델 호출을 재시도합니다."""
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
#output-block(`````
재시도 미들웨어 에이전트 생성 완료
`````)

== 6.7 \@dynamic_prompt

지금까지의 미들웨어가 메시지나 모델 호출을 제어했다면, `@dynamic_prompt`는 에이전트의 _근본적인 행동 지침_ --- 시스템 프롬프트 --- 를 런타임에 변경합니다.

`@dynamic_prompt` 데코레이터는 _런타임에 시스템 프롬프트를 동적으로 변경_합니다. 이 훅의 함수는 런타임 컨텍스트를 받아 새로운 시스템 프롬프트 문자열을 반환합니다.

주요 용도:
- 현재 날짜/시간 정보 추가 (예: "오늘은 2026년 3월 8일입니다")
- 사용자별 맞춤 프롬프트 (역할, 권한 레벨에 따라)
- 상태에 따른 행동 변경 (예: 오류 발생 시 보수적 모드)
- A/B 테스트 (다른 프롬프트의 효과 비교)

== 6.8 \@wrap_tool_call

모델 호출뿐 아니라 _도구 호출_도 감쌀 수 있습니다. `@wrap_tool_call` 데코레이터는 _도구 호출 자체를 감싸서_ 실행 전후에 커스텀 로직을 추가할 수 있습니다.

`@wrap_model_call`이 모델 호출을 감싸는 것처럼, `@wrap_tool_call`은 도구 실행을 감쌉니다. `handler` 함수를 호출하면 원래 도구가 실행되며, 그 전후로 타이밍 측정, 로깅, 에러 핸들링 등을 구현할 수 있습니다.

주요 용도:
- _실행 시간 측정:_ 도구별 성능 모니터링
- _로깅:_ 도구 입력/출력 기록
- _에러 핸들링:_ 도구 실패 시 폴백 처리
- _접근 제어:_ 특정 도구 호출 차단 또는 제한

== 6.9 가드레일

미들웨어의 모든 훅을 배웠으니, 이를 조합하여 에이전트의 _안전성_을 확보하는 방법을 다룹니다. 가드레일은 _안전하지 않은 입력이나 출력을 차단_하는 메커니즘입니다. 미들웨어를 활용하여 구현하며, 금지된 키워드 감지, 프롬프트 인젝션 방어, 민감 정보(PII) 필터링 등에 사용됩니다.

가드레일은 `@before_model` 훅에서 구현하는 것이 가장 효과적입니다. 모델에 전달되기 전에 위험한 입력을 차단할 수 있기 때문입니다. 출력 가드레일은 `@after_model` 훅에서 구현하며, 모델이 민감 정보를 포함한 응답을 생성했을 때 이를 마스킹하거나 차단합니다.

#tip-box[가드레일은 여러 계층으로 구성하는 것이 좋습니다. 입력 검증(`@before_model`), 출력 필터링(`@after_model`), 도구 접근 제어(`@wrap_tool_call`)를 조합하면 _심층 방어(defense in depth)_ 전략을 구현할 수 있습니다.]

#chapter-summary-header()

이 노트북에서 학습한 미들웨어 타입을 정리합니다:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[미들웨어 타입],
  text(weight: "bold")[데코레이터],
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
  [_Builtin_],
  [`SummarizationMiddleware`],
  [자동],
  [대화 요약],
  [_Guardrail_],
  [`\@before_model` 활용],
  [모델 호출 전],
  [안전성 확보],
)

_핵심 포인트:_
- 미들웨어는 에이전트 실행 파이프라인의 각 단계를 제어합니다.
- 여러 미들웨어를 조합하여 복잡한 로직을 구현할 수 있습니다.
- `@wrap_tool_call`을 사용하면 도구 실행을 감싸서 타이밍 측정, 로깅, 에러 핸들링 등을 구현할 수 있습니다.
- 가드레일은 `@before_model` 훅에서 구현하는 것이 가장 효과적입니다.
- `@dynamic_prompt`를 사용하면 런타임 정보를 시스템 프롬프트에 주입할 수 있습니다.

이 장에서는 에이전트 실행 파이프라인의 모든 단계를 제어하는 미들웨어 시스템을 학습했습니다. 다음 장에서는 에이전트가 _위험한 작업을 실행하기 전에 사람의 승인을 받는_ Human-in-the-Loop 패턴과, `ToolRuntime`을 통한 런타임 컨텍스트 주입, 그리고 MCP를 통한 외부 도구 서버 연동을 다룹니다.

