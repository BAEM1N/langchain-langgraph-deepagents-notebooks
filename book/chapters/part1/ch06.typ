// Auto-generated from 06_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "세 프레임워크 비교 & 다음 단계")

각 프레임워크를 개별적으로 학습한 후, 자연스럽게 떠오르는 질문은 "어떤 것을 사용해야 하나?"입니다. 정답은 프로젝트의 복잡도, 팀 규모, 일정에 따라 달라집니다. 이 장에서는 단순한 기능 비교를 넘어, 구체적인 시나리오 기반의 의사결정 프레임워크를 제공합니다.

#learning-header()
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

세 프레임워크는 서로 배타적이지 않습니다. Deep Agents는 내부적으로 LangGraph를 사용하고, LangChain의 모델/도구 인터페이스를 공유합니다. 따라서 LangChain으로 기본기를 다지고, LangGraph로 복잡한 워크플로를 설계한 뒤, Deep Agents로 프로덕션급 에이전트를 구축하는 것이 자연스러운 학습 경로입니다.

표만으로는 선택이 어려울 수 있습니다. 구체적인 시나리오별로 어떤 프레임워크가 적합한지 살펴봅시다.

== 6.2 어떤 걸 선택해야 할까?

#align(center)[#image("../../assets/diagrams/png/framework_selection_tree.png", width: 88%, height: 105mm, fit: "contain")]

의사결정 트리를 읽는 가장 쉬운 방법은 _"어디까지 직접 제어하고 싶은가?"_ 를 먼저 묻는 것입니다. 도구 호출 몇 개와 프롬프트 조합만으로 충분하면 LangChain, 상태 전이와 재개 시점을 직접 설계해야 하면 LangGraph, 파일/계획/서브에이전트가 기본 탑재된 작업형 에이전트가 필요하면 Deep Agents가 자연스럽습니다.

#note-box[_3줄 규칙_: *빠르게 시작*이면 LangChain, *분기/루프/HITL*이 핵심이면 LangGraph, *코딩·리서치·파일 작업*까지 한 번에 다뤄야 하면 Deep Agents를 우선 검토하세요.]

#code-block(`````python
"간단한 도구 호출 에이전트가 필요해"     → LangChain
"조건 분기·루프가 있는 워크플로가 필요해" → LangGraph
"파일 조작 + 계획 기능까지 한 번에"       → Deep Agents
`````)

*LangChain 시나리오*: 주문 상태 조회와 FAQ 응답이 필요한 고객 지원 챗봇을 만들고 있습니다. 워크플로는 단순합니다 — 사용자가 질문하면, 에이전트가 적절한 도구를 호출하고, 결과를 반환합니다. `create_agent()`에 도구 두 개와 시스템 프롬프트만 있으면 20줄 미만의 코드로 완성됩니다.

*LangGraph 시나리오*: 문서 검토 파이프라인을 구축하고 있습니다. 문서를 분류하고, 유형에 따라 다른 검토 큐로 라우팅하고, LLM이 검토한 뒤, 승인하거나 인간 검토자에게 에스컬레이션해야 합니다. 조건 분기, 휴먼 인 더 루프 일시 중지, 서로 다른 처리 경로 — `StateGraph`의 자연스러운 활용 사례입니다.

*Deep Agents 시나리오*: 웹을 검색하고, 여러 문서를 읽고, 노트를 작성하고, 접근 방식을 계획하고, 구조화된 보고서를 생성하는 리서치 어시스턴트를 만들고 있습니다. 빌트인 계획(`write_todos`), 파일 관리(`write_file`/`read_file`), 서브에이전트 위임이 각 단계를 수동으로 조율하지 않아도 되게 해줍니다.

#tip-box[세 프레임워크는 _함께_ 사용하도록 설계되었습니다. 공통 패턴은 LangChain의 모델/도구 인터페이스를 기반으로, LangGraph로 정밀한 워크플로를 제어하고, Deep Agents로 고수준 에이전트 작업을 처리하는 것입니다. Deep Agents 에이전트를 LangGraph 워크플로의 노드로 사용할 수도 있습니다.]

이론적 비교를 넘어, 동일한 작업을 세 가지 방식으로 구현한 코드를 직접 비교해 봅시다.

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

이 단순한 예제에서는 세 접근 방식 모두 같은 결과를 생성하지만, 복잡도가 증가하면 차이가 극적으로 벌어집니다. LangChain의 `create_agent()`는 단순함을 유지하지만 내부가 블랙박스가 됩니다. LangGraph는 완전한 제어권을 주지만 더 많은 코드가 필요합니다. Deep Agents는 복잡성을 자동으로 처리하지만, 내부에서 정확히 무슨 일이 일어나는지 파악하기 어려울 수 있습니다.

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
  [#link("../02_langchain/")[LangChain 중급]],
  [모델 설정, 고급 도구 패턴(ToolRuntime, 상태 접근, 스트림 라이터), 전처리/후처리 미들웨어, 멀티에이전트 아키텍처],
  [10],
  [#link("../03_langgraph/")[LangGraph 중급]],
  [복합 조건 라우팅, `interrupt()`를 사용한 휴먼 인 더 루프, 모듈형 서브그래프, 데이터베이스 체크포인터를 활용한 영속적 상태, 재시도 전략],
  [10],
  [#link("../04_deepagents/")[Deep Agents 중급]],
  [커스텀 백엔드, 고급 서브에이전트 패턴, 대화 간 영속 메모리, 샌드박스 실행, 프로덕션 배포],
  [7],
)

권장 학습 순서:
+ _LangChain_ — 모델 설정, 도구 패턴, 미들웨어의 기본기를 다진다
+ _LangGraph_ — 조건 분기, 루프, 인간 검토 등 정밀한 그래프 기반 워크플로를 설계한다
+ _Deep Agents_ — 계획, 파일 관리, 서브에이전트를 활용한 프로덕션급 에이전트를 구축한다
