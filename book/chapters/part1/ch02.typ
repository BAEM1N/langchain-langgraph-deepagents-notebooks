// Auto-generated from 02_langchain_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "LangChain 입문", subtitle: "첫 번째 에이전트")

에이전트(Agent)란 LLM이 어떤 행동을 취할지 _스스로 판단_하고, 도구를 통해 실행하고, 결과를 관찰하여, 작업이 완료될 때까지 반복하는 시스템입니다. 단순한 프롬프트-응답 상호작용과 근본적으로 다릅니다 — 모델이 어떤 도구를 어떤 순서로 사용할지 _추론_하기 때문입니다. LangChain v1의 `create_agent()` 함수는 이 과정을 ReAct(Reasoning + Acting) 루프로 구현합니다.

이 장에서는 LangChain v1의 핵심 API로 도구를 갖춘 첫 번째 에이전트를 만들어 봅니다.

#learning-header()
#learning-objectives([`@tool` 데코레이터로 커스텀 도구를 정의한다], [`create_agent()`로 에이전트를 생성한다], [`invoke()`로 에이전트를 실행하고 결과를 확인한다])

== 2.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
`````)

에이전트가 사용할 도구를 먼저 정의합니다. 도구란 에이전트가 외부 세계와 상호작용할 수 있게 해주는 함수입니다.

== 2.2 도구 만들기

`@tool` 데코레이터를 붙이면 일반 함수가 에이전트 도구가 됩니다.

도구를 정의할 때 알아야 할 핵심 규칙:
- _Docstring이 가장 중요합니다_: 모델은 이 설명을 읽고 도구 사용 여부를 결정합니다. 동료에게 설명하듯 명확하게 작성하세요 — 이 도구가 무엇을 하는지, 언제 사용해야 하는지, 제약 조건은 무엇인지.
- _타입 힌트(Type Hints)_: 함수 파라미터의 타입 힌트가 도구의 입력 스키마를 자동으로 정의합니다. `Literal` 타입으로 허용 값을 제한할 수도 있습니다 (예: `units: Literal["celsius", "fahrenheit"]`).
- _커스텀 이름/설명_: `@tool("custom_name")` 형태로 함수명을 덮어쓰거나, `@tool("calc", description="...")` 형태로 이름과 설명 모두 직접 지정할 수 있습니다.
- _복잡한 입력_: Pydantic `BaseModel`과 `Field(description="...")`를 사용하여 필드별 설명이 포함된 복잡한 입력 스키마를 정의할 수 있습니다.

#warning-box[`config`와 `runtime`은 LangChain이 내부적으로 사용하는 예약된 매개변수 이름입니다. 도구 함수의 인자 이름으로 사용하지 마세요.]

#code-block(`````python
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

@tool
def multiply(a: int, b: int) -> int:
    """두 수를 곱합니다."""
    return a * b

print("도구 목록:")
for t in [add, multiply]:
    print(f"  - {t.name}: {t.description}")
`````)
#output-block(`````
도구 목록:
  - add: 두 수를 더합니다.
  - multiply: 두 수를 곱합니다.
`````)

도구가 준비되었으니, 이제 모델과 도구를 결합하여 에이전트를 생성합니다.

== 2.3 에이전트 생성 & 실행

`create_agent()`는 모델과 도구를 결합하여 에이전트를 만듭니다. 에이전트는 내부적으로 다음과 같은 _ReAct(Reasoning + Acting) 루프_를 실행합니다:

+ 사용자가 메시지를 보냅니다.
+ 모델이 메시지를 분석하고 판단합니다: 도구를 호출할 것인가, 바로 응답할 것인가?
+ 도구 호출이 필요하면, 모델은 텍스트 대신 `tool_calls`가 포함된 `AIMessage`를 반환합니다.
+ 에이전트 프레임워크가 도구를 실행하고 결과를 `ToolMessage`로 생성합니다.
+ `ToolMessage`가 대화에 추가되고, 모델이 다시 호출됩니다.
+ 2\~5단계를 반복합니다.
+ 모델이 텍스트로 응답하거나(도구 호출 없음), 최대 반복 횟수에 도달하면 루프가 종료됩니다.

에이전트의 핵심 구성 요소:
- _모델(Model)_: LLM이 어떤 도구를 호출할지 판단합니다. 문자열(`"openai:gpt-5.4"`) 또는 모델 객체를 전달할 수 있습니다. 문자열 형식은 `"provider:model_name"`으로, 빠른 프로토타이핑에 편리합니다.
- _도구(Tools)_: 에이전트가 수행할 수 있는 액션입니다. 순차 호출, 병렬 실행, 재시도를 모두 지원합니다.
- _시스템 프롬프트(System Prompt)_: 에이전트의 행동을 안내하는 지침입니다. 수학 에이전트라면 "당신은 수학 도우미입니다. 항상 계산 과정을 보여주세요."처럼 구체적으로 작성할수록 유용한 결과를 얻습니다.

#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="당신은 수학 도우미입니다.",
)
print("\u2713 에이전트 생성 완료")
`````)
#output-block(`````
✓ 에이전트 생성 완료
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[역할],
  [`\@tool`],
  [함수를 에이전트 도구로 변환],
  [`create_agent()`],
  [모델 + 도구 → 에이전트 생성],
  [`agent.invoke()`],
  [에이전트 실행, 결과 반환],
  [`agent.stream()`],
  [중간 단계를 실시간으로 확인],
)

#tip-box[장시간 실행되는 에이전트의 경우 `agent.stream({"messages": [...]}, stream_mode="values")`를 사용하면 각 도구 호출과 응답을 실시간으로 확인할 수 있습니다.]

이 장에서 만든 에이전트는 메모리가 없어 대화를 기억하지 못합니다. 다음 장에서는 `InMemorySaver`를 사용하여 에이전트에 대화 기억 능력을 추가합니다.

