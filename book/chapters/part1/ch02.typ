// Auto-generated from 02_langchain_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "LangChain 입문", subtitle: "첫 번째 에이전트")

LangChain v1의 핵심 API로 도구를 갖춘 에이전트를 만들어 봅니다.

== 학습 목표
#learning-objectives([`@tool` 데코레이터로 커스텀 도구를 정의한다], [`create_agent()`로 에이전트를 생성한다], [`invoke()`로 에이전트를 실행하고 결과를 확인한다])

== 2.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
print("\u2713 모델 준비 완료")
`````)
#output-block(`````
✓ 모델 준비 완료
`````)

== 2.2 도구 만들기

`@tool` 데코레이터를 붙이면 일반 함수가 에이전트 도구가 됩니다.

도구를 정의할 때 알아야 할 핵심 규칙:
- _타입 힌트(Type Hints)_: 파라미터의 타입 힌트가 도구 입력 스키마를 자동으로 결정합니다. 예를 들어 `a: int`는 정수형 입력임을 모델에 알려줍니다.
- _Docstring_: 함수의 docstring이 도구 설명(description)으로 쓰입니다. 모델은 이 설명을 보고 어떤 도구를 쓸지 판단하므로, 간결하고 명확하게 적어 두세요.
- _커스텀 이름/설명_: `@tool("custom_name", description="...")` 형태로 이름과 설명을 직접 지정할 수도 있습니다.
- _복잡한 입력_: Pydantic `BaseModel`과 `Field`로 복잡한 입력 스키마를 정의할 수 있습니다.

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

== 2.3 에이전트 생성 & 실행

`create_agent()`는 모델과 도구를 결합해 에이전트를 만듭니다.
에이전트는 내부적으로 _ReAct(Reasoning + Acting) 루프_를 실행합니다:

#code-block(`````python
질문 → 모델이 도구 호출 결정 → 도구 실행 → 결과 관찰 → 반복 또는 최종 응답 생성
`````)

에이전트의 핵심 구성 요소:
- _모델(Model)_: LLM이 어떤 도구를 호출할지 판단합니다. 문자열(`"openai:gpt-5"`) 또는 모델 객체를 전달할 수 있습니다.
- _도구(Tools)_: 에이전트가 수행할 수 있는 액션입니다. 단순 바인딩과 달리 순차 호출, 병렬 실행, 재시도 등을 지원합니다.
- _시스템 프롬프트(System Prompt)_: 에이전트의 행동을 안내하는 지침입니다.

에이전트는 도구를 여러 번 순차 호출하거나 병렬로 실행할 수 있습니다. 최종 응답을 생성하거나 반복 횟수 제한에 도달하면 루프가 끝납니다.

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
)
