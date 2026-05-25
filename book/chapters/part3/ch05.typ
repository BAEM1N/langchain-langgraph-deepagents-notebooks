// Auto-generated from 05_agents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "에이전트 구축", subtitle: "Graph API와 Functional API로 ReAct 에이전트 만들기")

4장에서 다섯 가지 워크플로 패턴을 익혔다면, 이제 LLM이 스스로 도구를 선택하고 호출하는 _자율적 에이전트_를 구축할 차례입니다. 워크플로가 개발자가 미리 정해둔 코드 경로를 따르는 것이라면, 에이전트는 LLM이 _스스로_ 다음 행동을 결정합니다. 어떤 도구를 호출할지, 언제 작업을 멈출지, 추가 정보가 필요한지를 LLM이 자율적으로 판단하는 것이 핵심입니다.

`ReAct`(Reasoning + Acting) 패턴은 LLM이 "생각 → 도구 호출 → 관찰 → 다음 행동"을 반복하는 가장 널리 쓰이는 에이전트 아키텍처입니다. 2022년 Yao et al.이 제안한 이 패턴은 LLM의 추론(reasoning) 능력과 외부 도구를 통한 행동(acting) 능력을 결합하여, 단순 프롬프트만으로는 불가능한 복잡한 작업을 수행할 수 있게 합니다. LangGraph에서 ReAct 에이전트는 "LLM 노드 → 조건부 분기 → 도구 노드 → LLM 노드"로 이어지는 순환 그래프로 자연스럽게 표현됩니다.

LangGraph는 ReAct 에이전트를 쉽게 구축할 수 있도록 두 가지 주요 사전 구축(prebuilt) 컴포넌트를 제공합니다. `tools_condition`은 LLM 응답의 `AIMessage`에 `tool_calls` 속성이 존재하는지 확인하여 도구 노드 또는 `END`로 라우팅하는 조건부 엣지 함수입니다. 내부적으로 `tool_calls` 리스트가 비어 있지 않으면 `"tools"` 경로를, 비어 있으면 `END` 경로를 반환합니다. `ToolNode`는 `AIMessage.tool_calls`를 파싱하여 해당하는 도구 함수를 실행하고, 결과를 `ToolMessage`로 변환하여 상태에 추가하는 노드입니다. 병렬 도구 호출과 에러 핸들링도 자동으로 처리합니다. 물론 이 장에서는 내부 동작을 이해하기 위해 직접 구현합니다.

이 장에서는 동일한 `ReAct` 에이전트를 `Graph API`의 조건부 엣지 방식과 `Functional API`의 `while` 루프 방식으로 각각 구현하며, 두 접근법의 차이를 체감합니다. Graph API는 노드와 엣지로 구성된 명시적 그래프 구조를 선호하는 개발자에게 적합하고, Functional API는 일반 Python 코드 흐름에 익숙한 개발자에게 더 직관적입니다.

#learning-header()
도구를 사용하는 LLM 에이전트를 두 가지 API로 구현합니다.

- _Graph API_: `StateGraph`와 조건부 엣지로 ReAct 루프를 명시적으로 구성
- _Functional API_: `@entrypoint` + `while` 루프로 간결하게 구현
- _도구 바인딩_: `@tool` 데코레이터와 `bind_tools()`로 LLM에 도구 스키마 연결
- _라우팅 로직_: `tools_condition`과 `ToolNode`의 내부 동작 이해
- _메모리_: 체크포인터로 대화 상태를 유지하는 에이전트

== 5.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 5.2 도구 정의 — \@tool 데코레이터와 bind_tools()

에이전트의 핵심 능력은 _외부 도구를 호출_할 수 있다는 점입니다. 이를 위해서는 먼저 도구를 정의하고, LLM이 그 도구의 존재와 사용법을 알 수 있도록 연결해야 합니다.

LangChain의 `@tool` 데코레이터를 사용하면 일반 Python 함수를 LLM이 호출할 수 있는 도구로 변환할 수 있습니다. 데코레이터는 함수의 이름, 독스트링(설명), 타입 힌트(인자 스키마)를 자동으로 추출하여 도구 메타데이터를 생성합니다. 따라서 함수의 독스트링과 타입 힌트를 정확하게 작성하는 것이 매우 중요합니다 --- LLM은 이 정보를 기반으로 어떤 도구를 언제 호출할지 판단하기 때문입니다.

`bind_tools()`는 이 도구들의 JSON 스키마를 모델의 요청 파라미터에 바인딩합니다. 바인딩된 모델은 사용자 질문을 분석한 뒤, 도구 호출이 필요하다고 판단하면 응답의 `AIMessage.tool_calls` 속성에 호출할 도구 이름과 인자를 포함시킵니다. 도구 호출이 불필요한 경우에는 일반 텍스트 응답을 생성합니다.

#tip-box[`\@tool` 데코레이터의 독스트링은 LLM이 도구를 선택하는 _유일한 단서_입니다. "두 수를 더합니다"처럼 명확하고 구체적으로 작성하세요. 모호한 설명은 LLM의 도구 선택 정확도를 떨어뜨립니다.]

아래 코드에서는 세 가지 산술 도구를 정의하고, `bind_tools()`로 모델에 바인딩합니다. `tools_by_name` 딕셔너리는 이후 도구 노드에서 이름으로 도구를 빠르게 찾기 위한 준비입니다.

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

도구가 준비되었으니, 이제 이 도구들을 활용하는 에이전트를 구축할 차례입니다. 먼저 Graph API로 ReAct 루프를 명시적인 그래프 구조로 표현해 봅시다.

== 5.3 Graph API 에이전트 --- StateGraph로 ReAct 루프 구현

Graph API로 구현하는 ReAct 에이전트는 다음 세 가지 핵심 요소로 구성됩니다:

- _LLM 노드_: 현재까지 누적된 메시지를 기반으로 다음 행동을 결정합니다. 도구 호출이 필요하면 `AIMessage.tool_calls`에 호출 정보를 담아 응답하고, 최종 답변이 준비되면 일반 텍스트를 응답합니다
- _Tool 노드_: LLM이 선택한 도구를 실제로 실행합니다. `AIMessage.tool_calls` 리스트를 순회하며, 각 호출의 `name`으로 도구를 찾고 `args`를 전달하여 실행한 뒤, 결과를 `ToolMessage`로 변환합니다. LangGraph의 사전 구축 `ToolNode`는 이 과정을 자동으로 처리하지만, 여기서는 학습을 위해 직접 구현합니다
- _조건부 엣지_: LLM 노드의 출력을 검사하여 라우팅합니다. `tool_calls`가 있으면 `tool_node`로, 없으면 `END`로 보냅니다. 사전 구축 `tools_condition` 함수도 동일한 로직을 수행합니다

이 세 요소가 순환하는 구조가 바로 ReAct 루프입니다:

#code-block(`````python
START → llm → [tool_calls?] → tools → llm → ... → END
`````)

#warning-box[조건부 엣지의 라우팅 로직은 `AIMessage.tool_calls` 리스트의 _존재 여부_만 확인합니다. 도구 호출의 _결과_를 보고 판단하는 것이 아닙니다. LLM이 도구 호출을 요청했으면 무조건 도구 노드로 가고, 요청하지 않았으면 대화가 종료됩니다. 이 단순한 이진 분기가 ReAct 루프의 핵심입니다.]

그래프를 구성했으니, 에이전트가 실제로 어떤 순서로 동작하는지 눈으로 확인해 봅시다. 스트리밍을 통해 각 노드의 실행 과정을 실시간으로 관찰할 수 있습니다.

== 5.4 실행 흐름 시각화 — 스트리밍으로 각 단계 관찰

`stream_mode="updates"`를 사용하면 각 노드가 실행될 때마다 해당 노드가 반환한 업데이트만 실시간으로 받을 수 있습니다. 이를 통해 에이전트가 어떤 순서로 도구를 호출하고 결과를 처리하는지 단계별로 관찰할 수 있습니다. 출력에서 `llm` 노드와 `tools` 노드가 번갈아 나타나는 것을 확인하세요 --- 이것이 바로 ReAct 루프가 동작하는 모습입니다.

#tip-box[스트리밍 출력에서 `llm` 노드의 결과에 `tool_calls`가 포함되어 있으면 다음에 `tools` 노드가 실행되고, 포함되어 있지 않으면 그래프가 종료됩니다. 이 패턴을 관찰하면 에이전트의 의사결정 과정을 직관적으로 이해할 수 있습니다.]

Graph API에서 ReAct 에이전트의 동작을 확인했습니다. 이제 동일한 에이전트를 Functional API로 구현하여 두 접근법의 차이를 체감해 봅시다.

== 5.5 Functional API 에이전트 --- \@entrypoint + while 루프

Graph API로 구현한 동일한 ReAct 에이전트를 Functional API로 작성하면 코드가 얼마나 달라지는지 비교해 봅시다. Functional API는 `StateGraph`, `add_node()`, `add_edge()` 등의 그래프 구성 코드 없이, 일반 Python 코드처럼 에이전트를 작성할 수 있습니다. 그래프 구조가 아니라 함수 호출 흐름으로 로직을 표현하므로, Python에 익숙한 개발자에게 더 직관적일 수 있습니다.

Functional API의 핵심 구성 요소는 다음 세 가지입니다:

- `@entrypoint`: 에이전트의 진입점을 정의합니다. Graph API의 `graph.invoke()`에 해당하며, 체크포인터와의 연동도 여기서 설정합니다
- `@task`: 개별 작업 단위를 정의합니다. LLM 호출, 도구 실행 등 각 단계를 독립적인 태스크로 분리하면, 체크포인터가 태스크 단위로 상태를 저장하여 실패 시 재개가 가능합니다
- `while` 루프: `tool_calls`가 없을 때까지 반복합니다. Graph API의 조건부 엣지 → LLM 노드 순환이 여기서는 단순한 `while` 조건으로 표현됩니다

#tip-box[Graph API에서는 ReAct 루프가 "LLM 노드 → 조건부 엣지 → 도구 노드 → LLM 노드"라는 그래프 구조로 _암시적_으로 표현됩니다. Functional API에서는 동일한 루프가 `while` 문으로 _명시적_으로 드러납니다. 어느 쪽이 더 읽기 쉬운지는 프로젝트의 복잡도와 팀의 선호에 따라 다릅니다. 일반적으로, 단순한 에이전트는 Functional API가 간결하고, 복잡한 멀티 에이전트 시스템은 Graph API가 구조를 파악하기 쉽습니다.]

두 가지 API로 ReAct 에이전트를 구현해 보았습니다. 하지만 지금까지 구축한 에이전트에는 중요한 한계가 있습니다 --- 매 호출마다 상태가 초기화된다는 점입니다. 이제 체크포인터를 도입하여 이 문제를 해결합시다.

== 5.6 메모리가 있는 에이전트 --- 체크포인터로 대화 유지

지금까지 구축한 에이전트는 매 호출마다 상태가 초기화되는 _무상태(stateless)_ 에이전트였습니다. 사용자가 "3 더하기 5"를 물은 뒤 "거기에 2를 곱해줘"라고 하면, 에이전트는 이전 결과를 모르기 때문에 올바른 답을 줄 수 없습니다. 실제 채팅 애플리케이션에서는 이전 대화를 기억하는 _유상태(stateful)_ 에이전트가 필수적입니다.

체크포인터(`InMemorySaver`)를 `compile(checkpointer=checkpointer)`로 전달하면, 그래프의 각 노드 실행 후 자동으로 상태가 스냅샷됩니다. 동일한 `thread_id`로 후속 요청을 보내면, 체크포인터가 이전 대화의 메시지 이력을 자동으로 복원하여 대화 컨텍스트가 유지됩니다. 서로 다른 `thread_id`를 사용하면 완전히 독립된 대화가 생성됩니다.

#warning-box[`InMemorySaver`는 메모리에만 상태를 저장하므로, 프로세스가 종료되면 모든 대화 이력이 사라집니다. 개발 및 테스트 용도로만 사용하고, 프로덕션에서는 `PostgresSaver`나 `SqliteSaver`를 사용하세요. 체크포인터의 상세한 동작 원리는 다음 장에서 깊이 다룹니다.]

이 장에서 LLM 에이전트의 핵심 아키텍처인 ReAct 패턴을 두 가지 API로 구현하고, 체크포인터를 통해 멀티턴 대화까지 지원하는 에이전트를 완성했습니다. `@tool`로 도구를 정의하고, `bind_tools()`로 모델에 바인딩하며, 조건부 엣지 또는 `while` 루프로 ReAct 순환을 구성하는 것이 에이전트 구축의 기본 뼈대입니다.

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

#next-step-box[다음 장에서는 체크포인터의 내부 동작을 깊이 파고듭니다. `get_state()`, `get_state_history()`, `update_state()` API로 저장된 상태를 조회하고 수정하며, `InMemoryStore`를 활용한 스레드 간 장기 메모리까지 다룹니다.]

#chapter-end()
