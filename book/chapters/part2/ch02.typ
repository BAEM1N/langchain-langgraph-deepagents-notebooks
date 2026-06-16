// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "첫 번째 에이전트")

_`create_agent()`로 시작하기_

== 학습 목표
LangChain v1의 `create_agent()`로 에이전트를 생성하고 실행합니다.

이 노트북을 마치면 다음을 할 수 있습니다:

- `@tool` 데코레이터로 커스텀 도구를 정의
- `create_agent()`로 에이전트를 생성
- `invoke()`로 에이전트를 실행하고 결과를 확인
- `stream()`으로 실시간 스트리밍 응답을 받기
- `InMemorySaver`로 멀티턴 대화를 구현

== 설치

처음 실행하는 환경이라면 핵심 패키지를 먼저 깔아 둡니다. 이미 깔려 있다면 다음 셀은 건너뛰어도 됩니다.

#code-block(`````python
# uv 환경이라면 아래 한 줄로 충분합니다.
# !uv add langchain deepagents langgraph langchain-openai

# pip 환경이라면 다음을 씁니다.
%pip install -q -U langchain deepagents langgraph langchain-openai
`````)

== 2.1 환경 설정

OpenAI를 통해 모델을 설정합니다. `ChatOpenAI`는 OpenAI 호환 API를 지원하므로, `base_url`을 변경하여 OpenAI를 사용할 수 있습니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)
print("✓ 모델 설정 완료:", model.model_name)
`````)

== 2.2 간단한 도구 만들기

`@tool` 데코레이터로 에이전트가 사용할 도구를 정의합니다.

도구를 정의할 때 주의할 점:
- _docstring_은 필수입니다. 에이전트가 도구의 용도를 이해하는 데 씁니다.
- _타입 힌트_를 쓰면 에이전트가 올바른 인자를 전달할 수 있습니다.
- 도구 이름은 함수명에서 자동으로 생성됩니다.

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

== 2.3 에이전트 생성

`create_agent()`로 모델과 도구를 결합합니다.

생성된 에이전트는 내부적으로 LangGraph 그래프로 구현되며, `invoke()`, `stream()` 등의 메서드를 제공합니다.

#tip-box[LangChain v1에서는 `create_react_agent()` 대신 `create_agent()`를 사용합니다.]

#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="당신은 수학 도우미입니다. 제공된 도구를 사용하여 계산하세요.",
)
print("\u2713 에이전트 생성 완료")
print(f"  타입: {type(agent).__name__}")
`````)
#output-block(`````
✓ 에이전트 생성 완료
  타입: CompiledStateGraph
`````)

== 2.4 에이전트 실행

`invoke()`로 에이전트를 실행합니다.

에이전트에 메시지를 전달하면, 내부적으로 ReAct 루프가 실행됩니다:
+ 모델이 질문을 분석하고 도구 호출을 결정
+ 도구가 실행되고 결과를 반환
+ 모델이 결과를 바탕으로 최종 응답을 생성

#code-block(`````python
# 전체 메시지 흐름 확인
print("전체 메시지 흐름:")
print("=" * 50)
for msg in result["messages"]:
    role = msg.type if hasattr(msg, 'type') else msg.get('role', 'unknown')
    content = msg.content if hasattr(msg, 'content') else msg.get('content', '')
    print(f"[{role}] {content[:200]}")
    print("-" * 50)
`````)
#output-block(`````
전체 메시지 흐름:
==================================================
[human] 15 + 27은 얼마인가요?
--------------------------------------------------
[ai] 
--------------------------------------------------
[tool] 42
--------------------------------------------------
[ai] 15 + 27은 42입니다.
--------------------------------------------------
`````)

== 2.5 스트리밍 실행

`stream()`으로 실시간 응답을 받습니다.

스트리밍을 쓰면 에이전트의 각 단계(모델 추론, 도구 호출, 최종 응답)를 실시간으로 확인할 수 있습니다. `stream_mode="updates"`로 각 노드의 업데이트를 순차적으로 받을 수 있습니다.

== 2.6 멀티턴 대화

`InMemorySaver`로 대화 상태를 유지합니다.

`InMemorySaver`는 메모리 내에서 상태를 저장하며, `thread_id`로 대화 세션을 구분합니다.

#tip-box[LangChain v1에서는 LangGraph의 체크포인터로 대화 히스토리를 관리합니다.]

== 2.7 Tavily 검색 도구 연동 (선택)

웹 검색 도구를 추가하여 실제 정보를 검색합니다.

Tavily는 AI 에이전트를 위해 설계된 검색 API입니다.

`TAVILY_API_KEY`가 설정된 경우에만 이 셀이 실행됩니다.

== 2.8 컨텍스트 주입 — `context_schema`와 `context`

호출 시점마다 달라지는 정보(사용자 ID, 권한, 부서 등)는 `context_schema`로 타입을 정의하고 `invoke()` 시 `context=...`로 전달합니다. 시스템 프롬프트나 도구 안에서 `runtime.context`로 꺼내 쓸 수 있어, 상태(state)와 메시지 이력을 어지럽히지 않고 메타데이터를 주입하기 좋습니다.

#tip-box[_state_schema는 TypedDict 서브클래스여야 합니다._ dataclass·Pydantic은 `context_schema` 쪽에 쓰고, 상태 그래프 본문은 `TypedDict`로 정의하는 것이 LangChain v1 / LangGraph의 권장 패턴입니다.]

#tip-box[_에이전트 네이밍은 snake_case로._ `name="research_assistant"`처럼 단일 단어 또는 snake_case가 트레이싱과 멀티에이전트 라우팅에서 깔끔하게 보입니다. 공백·하이픈·대문자는 피하세요.]

#chapter-summary-header()

이 노트북에서 다룬 내용:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[설명],
  [도구 정의],
  [`\@tool`],
  [함수에 데코레이터를 추가하여 에이전트 도구로 변환],
  [에이전트 생성],
  [`create_agent()`],
  [모델 + 도구 + 시스템 프롬프트를 결합],
  [동기 실행],
  [`agent.invoke()`],
  [완전한 응답을 한 번에 반환],
  [스트리밍 실행],
  [`agent.stream()`],
  [각 단계의 업데이트를 실시간으로 반환],
  [멀티턴 대화],
  [`InMemorySaver` + `thread_id`],
  [체크포인터로 대화 상태를 저장/복원],
  [검색 도구],
  [`TavilySearch`],
  [웹 검색으로 실시간 정보에 접근],
  [컨텍스트 주입],
  [`context_schema` + `context=`],
  [호출별 메타데이터를 상태와 분리해 전달],
)
