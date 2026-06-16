// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangGraph 소개", subtitle: "상태 기반 에이전트 오케스트레이션 프레임워크")

== 학습 목표
LangGraph의 핵심 개념과 두 가지 API(Graph API, Functional API)를 이해합니다.

== 1.1 LangGraph란?

LangGraph는 LangChain 생태계의 _저수준 오케스트레이션 프레임워크_입니다.

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

- _상태 관리_: TypedDict 기반 상태 정의 및 리듀서
- _지속성_: checkpointer로 상태를 자동 저장
- _스트리밍_: 실시간 토큰 단위 출력
- _Human-in-the-loop_: 실행 중 사람이 개입할 수 있도록 중단·재개
- _내구성 실행_: 장애 발생 시 자동 복구

== 1.2 핵심 개념

LangGraph는 _그래프 구조_를 기반으로 워크플로를 정의합니다.

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

=== 그래프 구조 다이어그램

#image("../../assets/images/stategraph_structure.png")

== 1.3 두 가지 API

LangGraph는 동일한 기능을 두 가지 스타일로 구현할 수 있습니다.

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

== 1.4 환경 설정 및 설치 확인

필요한 패키지가 올바르게 설치되어 있는지 확인합니다.

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

Graph API는 _선언적_ 방식으로 워크플로를 정의합니다.

+ `StateGraph(State)` — 상태 스키마로 그래프 빌더 생성
+ `add_node()` — 노드(함수) 등록
+ `add_edge()` — 노드 간 연결
+ `compile()` — 실행 가능한 그래프 생성
+ `invoke()` — 그래프 실행

== 1.6 Functional API 맛보기

Functional API는 _명령적_ 방식으로 워크플로를 정의합니다.

- `@task` — 단위 작업 정의 (체크포인팅 단위)
- `@entrypoint` — 워크플로 진입점 정의
- 일반 Python 제어 흐름(`if`, `for`, `while` 등)을 그대로 사용

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
