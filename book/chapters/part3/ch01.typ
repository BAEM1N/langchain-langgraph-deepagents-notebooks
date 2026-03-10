// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangGraph 소개", subtitle: "상태 기반 에이전트 오케스트레이션 프레임워크")

Part 2에서 `LangChain`의 구성 요소를 익혔다면, 이제 그 위에서 에이전트를 설계하고 실행하는 오케스트레이션 계층으로 넘어갈 차례입니다. `LangChain`의 체인(`LCEL`)은 입력을 받아 출력을 내는 단방향 파이프라인에 최적화되어 있지만, 에이전트에게는 _조건 분기_, _반복_, _병렬 실행_, 그리고 _중간 상태의 저장과 복원_이 필요합니다. 단순한 체인으로는 "도구 호출 결과를 보고 다시 판단하는" 루프나, "사람의 승인을 기다리며 실행을 멈추는" 패턴을 자연스럽게 표현하기 어렵습니다.

`LangGraph`는 이 문제를 _상태 그래프(State Graph)_라는 추상화로 해결합니다. 상태(state)를 중심으로 노드와 엣지를 연결하여 복잡한 에이전트 워크플로를 선언적으로 표현하는 프레임워크입니다. 내부적으로는 Google의 Pregel 알고리즘에서 영감을 받은 _메시지 패싱 기반 실행 모델_을 사용하며, 각 노드가 슈퍼스텝(super-step) 단위로 활성화되어 상태를 읽고 쓰는 구조입니다. 이 장에서는 `LangGraph`가 왜 필요한지, 기존 체인 방식과 무엇이 다른지, 그리고 `Graph API`와 `Functional API`라는 두 가지 핵심 인터페이스의 전체 그림을 먼저 살펴봅니다.

#learning-header()
LangGraph의 핵심 개념과 두 가지 API(Graph API, Functional API)를 이해합니다.

== 1.1 LangGraph란?

LangGraph는 LangChain 생태계의 _저수준 오케스트레이션 프레임워크_입니다. "저수준"이라 함은 개발자가 노드, 엣지, 상태를 직접 정의하여 실행 흐름을 완전히 제어할 수 있다는 뜻입니다. Deep Agents와 같은 고수준 프레임워크가 사전 구축된 에이전트를 제공하는 것과 달리, LangGraph는 에이전트의 _내부 구조 자체_를 설계하는 도구입니다.

=== LangChain 3계층 구조

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[계층],
  text(weight: "bold")[역할],
  text(weight: "bold")[설명],
  [Deep Agents],
  [고수준],
  [사전 구축된 에이전트 시스템],
  [LangChain],
  [에이전트],
  [LLM 에이전트 구축 도구],
  [_LangGraph_],
  [_워크플로_],
  [_상태 기반 오케스트레이션_],
)

=== 핵심 특징

- _상태 관리_: `TypedDict` 또는 Pydantic 모델로 상태를 정의하고, 리듀서(reducer)로 값 병합 전략을 지정합니다
- _지속성_: 체크포인터를 통한 상태 자동 저장 --- 매 슈퍼스텝마다 스냅샷이 생성됩니다
- _스트리밍_: `values`, `updates`, `messages`, `custom`, `debug` 등 5가지 모드의 실시간 출력
- _Human-in-the-loop_: `interrupt()` 함수로 실행을 일시 정지하고, `Command(resume=...)` 으로 사람의 입력을 받아 재개합니다
- _내구성 실행_: 장애 발생 시 마지막 체크포인트에서 자동 복구합니다

== 1.2 핵심 개념

LangGraph의 핵심 특징들을 살펴보았으니, 이제 이 프레임워크를 구성하는 세 가지 기본 요소(primitive)를 자세히 알아봅시다. LangGraph는 _그래프 구조_를 기반으로 워크플로를 정의하며, 모든 것은 *State*, *Node*, *Edge*라는 세 가지 기본 요소로 구성됩니다.

=== 구성 요소

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [_노드(Node)_],
  [처리 단위 — Python 함수로 정의],
  [_엣지(Edge)_],
  [노드 간 연결, 조건부 분기 가능],
  [_상태(State)_],
  [TypedDict로 정의, 노드 간 공유 데이터],
  [_체크포인터(Checkpointer)_],
  [각 단계 상태 자동 저장],
)

LangGraph의 내부 실행 엔진은 _Pregel_ 모델을 따릅니다. Pregel에서 각 노드는 메시지(상태)를 읽고, 처리 후 결과를 채널에 쓰는 _액터(actor)_입니다. 하나의 _슈퍼스텝(super-step)_ 에서 동일 레벨의 노드들이 병렬로 실행되고, 모든 노드가 완료되면 리듀서를 통해 상태가 병합된 뒤 다음 슈퍼스텝으로 넘어갑니다. 이 메시지 패싱 아키텍처 덕분에 LangGraph는 복잡한 분기와 병렬 처리를 효율적으로 수행할 수 있습니다.

#tip-box[Pregel 런타임은 개발자가 직접 다룰 일이 거의 없습니다. Graph API와 Functional API가 이를 추상화하므로, 여기서는 "슈퍼스텝 단위로 실행된다"는 멘탈 모델만 갖추면 충분합니다. 심화 내용은 13장에서 다룹니다.]

=== 그래프 구조 다이어그램

#align(center)[#image("../../assets/diagrams/png/stategraph_structure.png", width: 60%, height: 132mm, fit: "contain")]

== 1.3 두 가지 API

그래프 구조를 이해했으니, 이 구조를 _어떤 방식으로_ 코드로 표현할지 살펴봅시다. LangGraph는 동일한 Pregel 런타임 위에서 동작하는 두 가지 프로그래밍 인터페이스를 제공합니다. 하나의 애플리케이션에서 두 API를 혼용할 수도 있으므로, 각각의 특성을 이해하고 상황에 맞게 선택하는 것이 중요합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[특성],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [접근 방식],
  [선언적 (노드+엣지)],
  [명령적 (Python 제어 흐름)],
  [상태 관리],
  [명시적 State + 리듀서],
  [함수 스코프, 리듀서 불필요],
  [시각화],
  [그래프 시각화 지원],
  [미지원],
  [체크포인팅],
  [슈퍼스텝마다 새 체크포인트],
  [태스크별, 기존 체크포인트에 저장],
  [적합 상황],
  [복잡한 워크플로, 팀 개발],
  [기존 코드 마이그레이션, 간단한 흐름],
)

#note-box[두 API의 가장 큰 차이는 _체크포인팅 단위_입니다. Graph API는 매 슈퍼스텝마다 새로운 체크포인트를 생성하는 반면, Functional API는 `\@task` 단위로 기존 체크포인트에 결과를 저장합니다. 이 차이가 장애 복구와 타임 트래블에서 미묘한 동작 차이를 만들어냅니다.]

== 1.4 환경 설정 및 설치 확인

이론적인 개념을 파악했으니, 실제 코드를 실행할 환경을 준비합시다. 필요한 패키지가 올바르게 설치되어 있는지 확인합니다.

#code-block(`````python
import importlib

packages = {
    "langgraph": "langgraph",
    "langchain": "langchain",
    "langchain_openai": "langchain-openai",
}

print("=" * 50)
print("LangGraph 환경 확인")
print("=" * 50)

for module_name, package_name in packages.items():
    try:
        mod = importlib.import_module(module_name)
        version = getattr(mod, "__version__", "installed")
        print(f"  OK  {package_name}: {version}")
    except ImportError:
        print(f"  ERR {package_name}: 설치되지 않음")
`````)
#output-block(`````
==================================================
LangGraph 환경 확인
==================================================
  OK  langgraph: installed
  OK  langchain: 1.2.10

  OK  langchain-openai: installed
`````)

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

required = ["OPENAI_API_KEY"]
optional = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]

print("API 키 상태:")
for key in required:
    print(f"  {'OK' if os.environ.get(key) else 'MISSING'} {key} (필수)")
for key in optional:
    print(f"  {'OK' if os.environ.get(key) else '--'} {key} (선택)")
`````)
#output-block(`````
API 키 상태:
  OK OPENAI_API_KEY (필수)
  OK TAVILY_API_KEY (선택)
  -- LANGSMITH_API_KEY (선택)
`````)

#code-block(`````python
# Core import verification
from langgraph.graph import StateGraph, START, END
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, interrupt
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, AIMessage
from langchain_openai import ChatOpenAI

print("모든 핵심 임포트 완료")
`````)
#output-block(`````
모든 핵심 임포트 완료
`````)

== 1.5 Graph API 맛보기

환경이 준비되었으니, 두 API를 간단한 예제로 체험해 봅시다. 먼저 Graph API입니다. Graph API는 _선언적_ 방식으로 워크플로를 정의합니다. 개발자는 상태 스키마를 `TypedDict`로 선언하고, 노드(Python 함수)를 등록한 뒤, 엣지로 노드 간 흐름을 연결합니다. LangGraph가 지원하는 엣지 유형은 네 가지입니다:

- *Normal Edge* --- `add_edge(A, B)`: A 실행 후 항상 B로 이동
- *Conditional Edge* --- `add_conditional_edges(A, routing_fn)`: 라우팅 함수의 반환값에 따라 분기
- *Entry Edge* --- `add_edge(START, A)`: 그래프의 시작점 지정
- *Parallel Edge* --- 하나의 노드에서 여러 노드로 동시 연결 시 병렬 실행

기본적인 Graph API 사용 흐름은 다음 다섯 단계입니다:

+ `StateGraph(State)` — 상태 스키마로 그래프 빌더 생성
+ `add_node()` — 노드(함수) 등록
+ `add_edge()` — 노드 간 연결
+ `compile()` — 실행 가능한 그래프 생성
+ `invoke()` — 그래프 실행

== 1.6 Functional API 맛보기

Graph API가 노드와 엣지를 명시적으로 등록하는 방식이었다면, Functional API는 일반 Python 함수 위에 데코레이터를 붙이는 것만으로 동일한 기능을 구현합니다. 그래프 구조를 선언할 필요가 없으므로 보일러플레이트가 크게 줄어들며, 기존 Python 코드를 LangGraph로 마이그레이션할 때 특히 유용합니다.

- `@task` — 단위 작업 정의 (체크포인팅 단위). 호출하면 `Future`와 유사한 객체를 반환하며, `.result()`로 결과를 대기합니다. 여러 태스크를 먼저 호출한 뒤 `.result()`를 한꺼번에 호출하면 _동시 실행_이 가능합니다.
- `@entrypoint` — 워크플로 진입점 정의. 체크포인터를 연결하면 자동으로 상태가 저장됩니다.
- 일반 Python 제어 흐름(`if`, `for`, `while` 등)을 그대로 사용

#warning-box[Functional API에서 `\@task` 밖의 코드는 체크포인트에 저장되지 않습니다. 비결정적 연산(API 호출, 난수 생성 등)은 반드시 `\@task`로 감싸야 재개 시 동일한 결과를 보장할 수 있습니다. 이 주제는 12장 "내구성 실행"에서 자세히 다룹니다.]


이 장에서 LangGraph의 전체 그림을 파악했습니다. 세 가지 기본 요소(State, Node, Edge), Pregel 기반 실행 모델, 그리고 Graph API와 Functional API라는 두 가지 프로그래밍 인터페이스가 LangGraph를 이해하는 출발점입니다.

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [LangGraph],
  [상태 기반 에이전트 오케스트레이션 프레임워크],
  [Graph API],
  [`StateGraph`로 명시적 상태 흐름 정의],
  [Functional API],
  [`\@entrypoint` + `\@task`로 함수형 워크플로],
  [핵심 개념],
  [State (상태), Node (노드), Edge (엣지)],
  [체크포인터],
  [상태 지속성, 멀티턴 대화, 타임 트래블 지원],
)

#next-step-box[다음 장에서는 Graph API의 핵심인 `StateGraph`를 본격적으로 다룹니다. 상태 리듀서, 조건부 엣지, `MessagesState`, 입출력 스키마 분리 등 Graph API로 워크플로를 구성하는 모든 기초를 단계별로 익힙니다.]

#chapter-end()
