// Auto-generated from 05_agents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "에이전트 구축", subtitle: "Graph API와 Functional API로 ReAct 에이전트 만들기")

== 학습 목표
도구를 사용하는 LLM 에이전트를 두 가지 API로 구현합니다.

- _Graph API_: `StateGraph`와 조건부 엣지로 ReAct 루프를 명시적으로 구성
- _Functional API_: `@entrypoint` + `while` 루프로 간결하게 구현
- _도구 바인딩_: `@tool` 데코레이터와 `bind_tools()`로 LLM에 도구 연결
- _메모리_: 체크포인터로 대화 상태를 유지하는 에이전트

== 5.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 5.2 도구 정의 — \@tool 데코레이터와 bind_tools()

LangChain의 `@tool` 데코레이터를 사용하면 일반 Python 함수를 LLM이 호출할 수 있는 도구로 바꿀 수 있습니다.
`bind_tools()`는 이 도구들의 스키마를 모델에 바인딩하여, LLM이 적절한 시점에 도구를 선택하고 인자를 생성하게 합니다.

#code-block(`````python
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, ToolMessage, AnyMessage

@tool
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

@tool
def multiply(a: int, b: int) -> int:
    """두 수를 곱합니다."""
    return a * b

@tool
def divide(a: int, b: int) -> float:
    """a를 b로 나눕니다."""
    return a / b

tools = [add, multiply, divide]
tools_by_name = {t.name: t for t in tools}
model_with_tools = model.bind_tools(tools)

print("모델에 바인딩된 도구:")
for t in tools:
    print(f"  - {t.name}: {t.description}")
`````)
#output-block(`````
모델에 바인딩된 도구:
  - add: 두 수를 더합니다.
  - multiply: 두 수를 곱합니다.
  - divide: a를 b로 나눕니다.
`````)

== 5.3 Graph API 에이전트 — StateGraph로 ReAct 루프 구현

ReAct(Reasoning + Acting) 패턴은 세 가지 요소로 구성됩니다:

- _LLM 노드_: 현재 메시지를 보고 도구 호출 여부를 결정합니다
- _Tool 노드_: LLM이 선택한 도구를 실제로 실행합니다
- _조건부 엣지_: `tool_calls`가 있으면 `tool_node`로, 없으면 `END`로 라우팅합니다

#code-block(`````python
START → llm → [tool_calls?] → tools → llm → ... → END
`````)

== 5.4 실행 흐름 시각화 — 스트리밍으로 각 단계 관찰

`stream_mode="updates"`를 사용하면 각 노드가 실행될 때마다 업데이트를 받을 수 있습니다.
에이전트가 어떤 순서로 도구를 호출하고 결과를 처리하는지 단계별로 볼 수 있습니다.

== 5.5 Functional API 에이전트 — \@entrypoint + while 루프

Functional API는 그래프를 명시적으로 구성하지 않고, 일반 Python 코드처럼 에이전트를 작성합니다.

- `@entrypoint`: 에이전트의 진입점을 정의합니다
- `@task`: 개별 작업 단위를 정의합니다
- `while` 루프: 도구 호출이 없을 때까지 반복합니다

== 5.6 메모리가 있는 에이전트 — 체크포인터로 대화 유지

체크포인터(`InMemorySaver`)를 `compile()`에 전달하면 에이전트가 이전 대화를 기억합니다.
같은 `thread_id`를 사용하면 이전 대화 컨텍스트가 자동으로 유지됩니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [`\@tool`],
  [Python 함수를 LLM 호출 가능한 도구로 변환],
  [`bind_tools()`],
  [도구 스키마를 모델에 바인딩],
  [_Graph API 에이전트_],
  [`StateGraph` + 조건부 엣지로 ReAct 루프 명시적 구현],
  [_Functional API 에이전트_],
  [`\@entrypoint` + `while` 루프로 간결하게 구현],
  [`tool_calls`],
  [LLM 응답에 포함된 도구 호출 정보],
  [`ToolMessage`],
  [도구 실행 결과를 LLM에게 전달하는 메시지],
  [_체크포인터_],
  [대화 상태를 저장하여 멀티턴 에이전트 구현],
)
