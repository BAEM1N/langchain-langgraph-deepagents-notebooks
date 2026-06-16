// Auto-generated from 04_langgraph_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "LangGraph 입문", subtitle: "워크플로 만들기")

LangGraph의 `StateGraph`로 노드와 엣지를 연결하는 워크플로를 만들어 봅니다.

== 학습 목표
#learning-objectives([`StateGraph`로 상태 기반 그래프를 정의한다], [노드(함수)를 등록하고 엣지로 연결한다], [`compile()` → `invoke()`로 그래프를 실행한다])

== 4.1 환경 설정

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

== 4.2 첫 번째 그래프

LangGraph의 기본 흐름은 5단계입니다:

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

_StateGraph의 핵심 개념:_

LangGraph는 에이전트 워크플로를 _그래프_로 모델링하며, 세 가지 기본 구성 요소를 씁니다:

+ _State(상태)_: 애플리케이션의 현재 스냅샷을 담는 공유 데이터 구조입니다. 보통 `TypedDict`나 Pydantic 모델로 정의합니다.
+ _Node(노드)_: 상태를 받아 연산을 수행하고 업데이트된 상태를 돌려주는 함수입니다. _노드가 실제 작업을 담당_합니다.
+ _Edge(엣지)_: 현재 상태를 보고 다음에 실행할 노드를 결정합니다. _엣지가 다음 방향을 지시_합니다.

`StateGraph`는 사용자 정의 State 객체를 받는 주요 그래프 클래스입니다. `.compile()` 메서드로 컴파일한 뒤 사용해야 하며, 이 단계에서 구조 검증이 이뤄집니다.

아래 예제는 텍스트의 단어 수를 세는 간단한 1노드 그래프입니다.

== 4.3 2노드 그래프

두 개의 노드를 순서대로 연결합니다.
첫 번째 노드가 텍스트를 대문자로 변환하고, 두 번째 노드가 단어 수를 셉니다.

#code-block(`````python
START → uppercase → counter → END
`````)

== 4.4 LLM을 노드로 사용하기

`MessagesState`를 사용하면 LLM 대화를 그래프로 구성할 수 있습니다.

_MessagesState란?_

`MessagesState`는 LangGraph가 제공하는 _사전 정의 상태 클래스_로, `messages`라는 단일 키와 `add_messages` 리듀서를 씁니다. 내부적으로 다음과 같이 정의되어 있습니다:

#code-block(`````python
class MessagesState(TypedDict):
    messages: Annotated[list, add_messages]
`````)

`add_messages` 리듀서는 메시지 ID를 추적해 중복 없이 메시지를 누적하고, JSON을 LangChain Message 객체로 자동 역직렬화합니다. 문서, 메타데이터 같은 추가 필드가 필요하면 `MessagesState`를 서브클래싱하면 됩니다.

_노드의 구조:_

노드는 현재 상태(`state`)를 받아 상태 업데이트를 돌려주는 일반 Python 함수(동기/비동기)입니다. LangGraph는 노드를 자동으로 `RunnableLambda` 객체로 변환하여 배치 처리, 비동기 지원, 네이티브 트레이싱 기능을 더합니다.

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
)
