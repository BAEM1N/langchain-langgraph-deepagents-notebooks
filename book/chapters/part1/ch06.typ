// Auto-generated from 06_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "세 프레임워크 비교 & 다음 단계")

LangChain, LangGraph, Deep Agents를 한눈에 비교하고 중급 과정을 안내합니다.

== 학습 목표
#learning-objectives([LangChain, LangGraph, Deep Agents 세 프레임워크의 _핵심 차이점_을 이해한다], [각 프레임워크의 _적합한 사용 사례_를 판단할 수 있다], [중급 과정으로의 _학습 경로_를 선택할 수 있다])

== 6.1 프레임워크 비교

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[_추상화 수준_],
  text(weight: "bold")[높음],
  text(weight: "bold")[중간],
  text(weight: "bold")[매우 높음],
  [_핵심 개념_],
  [에이전트 + 도구],
  [그래프 + 상태 + 노드],
  [올인원 에이전트],
  [_에이전트 생성_],
  [`create_agent()`],
  [`StateGraph` → `compile()`],
  [`create_deep_agent()`],
  [_실행_],
  [`agent.invoke()`],
  [`graph.invoke()`],
  [`agent.invoke()`],
  [_커스터마이징_],
  [도구/프롬프트/메모리],
  [노드/엣지/상태/리듀서],
  [도구/백엔드/서브에이전트],
  [_적합 상황_],
  [빠른 프로토타이핑],
  [복잡한 워크플로],
  [파일/태스크 관리가 필요한 에이전트],
)

_추가 비교 정보:_

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[LangChain],
  text(weight: "bold")[LangGraph],
  text(weight: "bold")[Deep Agents],
  [_모델 지원_],
  [모델 무관 (100개 이상 프로바이더)],
  [LangChain 모델 공유],
  [LangChain 모델 공유],
  [_라이선스_],
  [MIT],
  [MIT],
  [MIT],
  [_샌드박스 통합_],
  [기본 지원 없음],
  [기본 지원 없음],
  [에이전트가 샌드박스에서 작업 실행 가능],
  [_상태 관리_],
  [메모리 기반],
  [체크포인터 기반 (타임 트래블 지원)],
  [LangGraph 체크포인터 활용],
  [_관측성_],
  [LangSmith 연동],
  [LangSmith 네이티브 트레이싱],
  [LangSmith 지원],
)

세 프레임워크는 서로 배타적이지 않습니다. Deep Agents는 내부적으로 LangGraph를 쓰고, LangChain의 모델/도구 인터페이스를 공유합니다. LangChain으로 기본기를 다지고, LangGraph로 복잡한 워크플로를 설계한 뒤, Deep Agents로 프로덕션급 에이전트를 구축하는 순서가 자연스럽습니다.

== 6.2 어떤 걸 선택해야 할까?

#code-block(`````python
"간단한 도구 호출 에이전트가 필요해"     → LangChain
"조건 분기·루프가 있는 워크플로가 필요해" → LangGraph
"파일 조작 + 계획 기능까지 한 번에"       → Deep Agents
`````)

#tip-box[세 프레임워크는 서로 배타적이지 않습니다. Deep Agents는 내부적으로 LangGraph를 사용하고, LangChain의 모델·도구 인터페이스를 공유합니다.]

== 6.3 코드 비교 — 같은 질문, 세 가지 방식

아래는 동일한 작업을 세 프레임워크로 처리하는 최소 코드입니다.

=== LangChain
#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

agent = create_agent(model=model, tools=[add])
agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)

=== LangGraph
#code-block(`````python
from langgraph.graph import StateGraph, START, END, MessagesState

def chatbot(state):
    return {"messages": [model.invoke(state["messages"])]}

builder = StateGraph(MessagesState)
builder.add_node("chat", chatbot)
builder.add_edge(START, "chat")
builder.add_edge("chat", END)
graph = builder.compile()
graph.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)

=== Deep Agents
#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
agent.invoke({"messages": [{"role": "user", "content": "3+4?"}]})
`````)

#chapter-summary-header()

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[LangChain],
  text(weight: "bold")[LangGraph],
  text(weight: "bold")[Deep Agents],
  [핵심 역할],
  [에이전트 생성 (ReAct 루프)],
  [워크플로 오케스트레이션 (상태 그래프)],
  [올인원 에이전트 (빌트인 도구)],
  [상태 관리],
  [미들웨어 기반],
  [StateGraph 명시적 상태],
  [자동 (파일시스템 + 메모리)],
  [적합 대상],
  [빠른 프로토타이핑, 도구 호출],
  [복잡한 워크플로, 조건 분기],
  [코딩 에이전트, 데이터 분석],
  [학습 곡선],
  [낮음],
  [중간],
  [낮음],
)


=== 미니 프로젝트
→ _#link("./07_mini_project.ipynb")[07_mini_project.ipynb]_: 검색 + 요약 에이전트를 만드는 실습

=== 중급 과정

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[과정],
  text(weight: "bold")[설명],
  text(weight: "bold")[노트북 수],
  [\#link("../02_langchain/")[LangChain 중급]],
  [모델/메시지/도구/메모리/미들웨어/멀티에이전트],
  [10],
  [\#link("../03_langgraph/")[LangGraph 중급]],
  [Graph API/워크플로/에이전트/퍼시스턴스/서브그래프],
  [10],
  [\#link("../04_deepagents/")[Deep Agents 중급]],
  [커스터마이징/백엔드/서브에이전트/메모리/고급 기능],
  [7],
)

권장 학습 순서:
+ _LangChain_ — 모델/도구의 기본기를 다진다
+ _LangGraph_ — 그래프 기반 워크플로를 설계한다
+ _Deep Agents_ — 프로덕션급 에이전트를 구축한다
