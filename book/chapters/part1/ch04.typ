// Auto-generated from 04_langgraph_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "LangGraph 입문", subtitle: "워크플로 만들기")

2장의 `create_agent()`는 단순한 ReAct 루프를 제공하지만, 실제 애플리케이션에서는 조건 분기(예: 긴급도에 따라 고객 이메일을 다른 처리기로 라우팅), 병렬 실행, 인간 승인 단계, 오류 복구 등이 필요합니다. LangGraph는 이러한 복잡한 워크플로를 _방향 그래프(directed graph)_로 모델링합니다. 노드는 처리 단계이고, 엣지는 노드 간의 흐름을 정의합니다. 이 분해(decomposition) 방식을 통해 스트리밍, 일시 중지/재개가 가능한 내구적 실행, 단계 간 상태 검사를 통한 명확한 디버깅이 가능해집니다.

이 장에서는 LangGraph의 `StateGraph`로 노드와 엣지를 연결하는 워크플로를 직접 만들어 봅니다.

#learning-header()
#learning-objectives([`StateGraph`로 상태 기반 그래프를 정의한다], [노드(함수)를 등록하고 엣지로 연결한다], [`compile()` → `invoke()`로 그래프를 실행한다])

== 4.1 환경 설정

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

== 4.2 첫 번째 그래프

LangGraph의 기본 흐름은 5단계입니다:

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

_StateGraph의 핵심 개념:_

LangGraph는 에이전트 워크플로를 _그래프_로 모델링하며, 세 가지 기본 구성 요소를 사용합니다:

+ _State(상태)_: 애플리케이션의 현재 스냅샷을 나타내는 공유 데이터 구조입니다. 보통 `TypedDict`나 Pydantic 모델로 정의합니다.
+ _Node(노드)_: 상태를 받아 연산을 수행하고 업데이트된 상태를 반환하는 함수입니다. 즉, _노드가 실제 작업을 수행_합니다.
+ _Edge(엣지)_: 현재 상태를 기반으로 다음에 실행할 노드를 결정합니다. 즉, _엣지가 다음 할 일을 지시_합니다.

`StateGraph`는 주요 그래프 클래스로, 사용자 정의 State 객체를 매개변수로 받습니다. 그래프는 반드시 `.compile()` 메서드를 통해 컴파일한 후 사용해야 하며, 컴파일 시 도달 불가능한 노드나 누락된 엣지 등 구조적 오류가 검증됩니다.

`compile()`은 선택적 매개변수도 지원합니다:
- `checkpointer=InMemorySaver()` — 상태 영속성 활성화 (3장에서 다룸)
- `interrupt_before=["node_name"]` — 특정 노드 실행 전 일시 중지 (휴먼 인 더 루프)
- `interrupt_after=["node_name"]` — 특정 노드 실행 후 일시 중지

=== LangGraph 워크플로 설계 5단계

LangGraph로 워크플로를 설계할 때는 다음 5단계 프로세스를 따릅니다:

+ *워크플로를 개별 단계로 분해*: 각 독립적 작업을 노드 후보로 식별합니다.
+ *작업 유형 분류*: LLM 단계(추론), 데이터 단계(검색), 액션 단계(부수 효과), 사용자 입력 단계(인간 개입)로 구분합니다.
+ *상태 구조 설계*: 단계 간에 유지해야 할 데이터를 정의합니다. 원시 데이터를 저장하고, 포매팅은 노드 내부에서 수행합니다.
+ *노드 함수 구현*: 각 함수는 상태를 받아 변경된 키만 포함한 상태 업데이트를 반환합니다.
+ *연결 및 실행*: 엣지로 연결하고, 컴파일하고, 실행합니다.

아래 예제는 텍스트의 단어 수를 세는 간단한 1노드 그래프입니다.

1개 노드 그래프로 기본 구조를 이해했으니, 노드를 연결하여 파이프라인을 구성해 봅시다.

== 4.3 2노드 그래프

두 개의 노드를 순서대로 연결합니다.
첫 번째 노드가 텍스트를 대문자로 변환하고, 두 번째 노드가 단어 수를 셉니다.

#code-block(`````python
START → uppercase → counter → END
`````)

지금까지는 노드가 항상 같은 다음 노드로 진행했습니다. 하지만 실제 워크플로에서는 조건에 따라 다른 경로로 분기해야 할 때가 많습니다. `add_conditional_edges()`를 사용하면 라우팅 함수가 현재 상태를 검사하고 다음 노드의 이름을 반환하여 동적 분기를 구현할 수 있습니다. 예를 들어, LangGraph가 제공하는 `tools_condition` 함수는 LLM이 도구 호출을 요청했으면 "tools" 노드로, 아니면 END로 라우팅합니다. 조건부 엣지는 5장 이후에서 본격적으로 다룹니다.

조건 분기의 가장 흔한 사용 사례는 LLM이 도구를 호출할지 결정하는 것입니다. `MessagesState`를 사용하면 이를 쉽게 구현할 수 있습니다.

== 4.4 LLM을 노드로 사용하기

`MessagesState`를 사용하면 LLM 대화를 그래프로 구성할 수 있습니다.

_MessagesState란?_

`MessagesState`는 LangGraph가 제공하는 _사전 정의 상태 클래스_로, `messages`라는 단일 키를 가지며 `add_messages`를 리듀서로 사용합니다. 내부적으로 다음과 같이 정의되어 있습니다:

#code-block(`````python
class MessagesState(TypedDict):
    messages: Annotated[list, add_messages]
`````)

`add_messages` 리듀서는 메시지 ID를 추적하여 중복 없이 메시지를 누적하고, JSON 딕셔너리를 LangChain Message 객체로 자동 역직렬화합니다. 추가 필드(예: `documents: list`, `user_id: str`)가 필요하면 `MessagesState`를 서브클래싱하여 메시지 처리 동작을 유지하면서 커스텀 필드를 추가할 수 있습니다.

_노드의 구조:_

노드는 현재 상태(`state`)를 받아 상태 업데이트를 반환하는 일반 Python 함수(동기/비동기)입니다. LangGraph는 노드를 자동으로 `RunnableLambda` 객체로 변환하여 배치 처리, 비동기 지원, 네이티브 트레이싱 기능을 추가합니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[역할],
  [`StateGraph(State)`],
  [상태 스키마로 그래프 빌더 생성],
  [`add_node()`],
  [노드(함수) 등록],
  [`add_edge()`],
  [노드 간 연결],
  [`compile()`],
  [실행 가능한 그래프 생성],
  [`invoke()`],
  [그래프 실행],
  [`add_conditional_edges()`],
  [조건부 분기 — 라우팅 함수로 다음 노드 결정],
)

LangGraph로 워크플로를 세밀하게 제어할 수 있지만, 매번 노드와 엣지를 직접 구성하는 것은 번거로울 수 있습니다. 다음 장에서는 이 모든 것을 한 줄로 해결하는 Deep Agents를 소개합니다.

