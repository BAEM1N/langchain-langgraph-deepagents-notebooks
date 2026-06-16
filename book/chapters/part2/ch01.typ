// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangChain 소개")

_LangChain v1 프레임워크 개요_

== 학습 목표
LangChain 프레임워크의 구조와 핵심 컴포넌트를 이해합니다.

이 노트북을 마치면 다음을 알게 됩니다:

- LangChain v1 프레임워크의 3가지 레이어 구조
- ReAct 에이전트 패턴의 동작 방식
- 핵심 컴포넌트와 주요 API
- 개발 환경 설정 및 검증 방법

== 1.1 LangChain 프레임워크 개요

LangChain v1은 LLM 기반 에이전트를 구축하는 통합 프레임워크입니다. 3가지 레이어로 구성되며, 각 레이어는 서로 다른 수준의 추상화를 제공합니다.

=== 3가지 레이어 구조

#image("../../assets/images/langchain_3layer.png")

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[레이어],
  text(weight: "bold")[역할],
  text(weight: "bold")[대상 사용자],
  [_LangChain_],
  [에이전트 생성의 핵심 API (`create_agent`, `tool`, `ChatOpenAI`)],
  [모든 개발자],
  [_LangGraph_],
  [복잡한 워크플로 구현 (상태 그래프, 체크포인터, 스트리밍)],
  [중급 이상],
  [_Deep Agents_],
  [사전 구축된 에이전트 (코딩, 리서치 등)],
  [빠른 프로토타이핑],
)

=== LangChain v1에서 변경된 주요 사항

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[이전 (v0.x)],
  text(weight: "bold")[현재 (v1)],
  [에이전트 생성],
  [`create_react_agent()`],
  [**`create_agent()`**],
  [에이전트 임포트],
  [`from langchain.agents import ...` (다양)],
  [**`from langchain.agents import create_agent`**],
  [모델 초기화],
  [`ChatOpenAI(...)` 직접 사용],
  [`init_chat_model()` 또는 `ChatOpenAI(...)`],
  [메모리],
  [`ConversationBufferMemory` 등],
  [**`InMemorySaver`** (LangGraph 체크포인터)],
  [실행 엔진],
  [AgentExecutor],
  [_LangGraph 그래프_ (내부적으로)],
)

=== 핵심 설계 철학

LangChain v1의 핵심은 _모든 에이전트가 LangGraph 그래프로 실행된다_는 점입니다. `create_agent()`로 생성된 에이전트는 내부적으로 LangGraph의 `StateGraph`로 구현되며, 이로 인해:

- _스트리밍_: `stream()` 메서드로 실시간 응답
- _상태 관리_: 체크포인터를 통한 대화 히스토리 유지
- _확장성_: 커스텀 노드와 엣지 추가 가능

== 1.2 ReAct 에이전트 패턴

ReAct (Reasoning + Acting) 패턴은 LangChain v1 에이전트의 기본 동작 방식입니다. 에이전트는 다음 루프를 반복합니다:

#image("../../assets/images/react_loop.png")

=== 핵심 특징

- _자율적 판단_: 에이전트가 도구 사용 여부를 스스로 결정합니다
- _다단계 추론_: 복잡한 작업을 여러 단계로 분해하여 처리합니다
- _관찰 기반 학습_: 도구 결과를 관찰하고 다음 행동을 결정합니다

== 1.3 주요 컴포넌트 개요

LangChain v1의 핵심 컴포넌트를 표로 정리합니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[컴포넌트],
  text(weight: "bold")[설명],
  text(weight: "bold")[주요 API],
  [_Model_],
  [LLM 또는 Chat 모델. 에이전트의 "두뇌" 역할],
  [`ChatOpenAI`, `init_chat_model()`],
  [_Tools_],
  [에이전트가 사용할 수 있는 함수. 검색, 계산, API 호출 등],
  [`\@tool` 데코레이터, `TavilySearch`],
  [_Agent_],
  [모델과 도구를 결합한 실행 단위. 내부적으로 LangGraph 그래프],
  [`create_agent()`],
  [_Memory_],
  [대화 히스토리를 저장하고 관리하는 체크포인터],
  [`InMemorySaver`, `SqliteSaver`],
  [_Middleware_],
  [요청/응답 처리 파이프라인에 로직 삽입],
  [`prompt`, `before_tool`, `after_model`],
  [_State_],
  [에이전트 실행 중 관리되는 상태 (메시지, 컨텍스트 등)],
  [`AgentState`, `messages`],
  [_Streaming_],
  [실시간 응답 스트리밍 지원],
  [`stream()`, `stream_mode="updates"`],
)

== 1.4 환경 설정 및 설치 확인

LangChain v1 개발에 필요한 패키지와 API 키를 확인합니다.

=== 설치

LangChain v1 기반 실습에 필요한 핵심 패키지를 설치합니다. `uv` 또는 `pip` 중 환경에 맞는 명령을 쓰면 됩니다.

#code-block(`````bash
# uv 사용자
uv add langchain deepagents langgraph langchain-openai langchain-anthropic

# pip 사용자
pip install -U langchain deepagents langgraph langchain-openai langchain-anthropic
`````)

#note-box[노트북 안에서 바로 설치하려면 첫 셀에 `%pip install -U langchain deepagents`를 넣어도 됩니다.]

=== 자주 쓰는 기본 모델 ID

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[프로바이더],
  text(weight: "bold")[권장 모델 ID],
  text(weight: "bold")[메모],
  [OpenAI],
  [`gpt-5.4`],
  [`init_chat_model("openai:gpt-5.4")` 형태로도 호출],
  [Anthropic],
  [`claude-sonnet-4-6`],
  [안정적 추론 + 도구 사용 균형],
  [Google],
  [`gemini-2.5-flash-lite`],
  [경량·저지연용],
)

본문 예시는 별다른 언급이 없으면 `gpt-5.4`를 기본 모델로 씁니다.

#code-block(`````python
# 환경 설정
import subprocess
import importlib

packages = {
    "langchain": "langchain",
    "langchain_openai": "langchain-openai",
    "langchain_community": "langchain-community",
    "langgraph": "langgraph",
}

print("=" * 50)
print("LangChain v1 환경 확인")
print("=" * 50)

for module_name, package_name in packages.items():
    try:
        mod = importlib.import_module(module_name)
        version = getattr(mod, "__version__", "installed")
        print(f"\u2713 {package_name}: {version}")
    except ImportError:
        print(f"\u2717 {package_name}: 미설치 \u2192 pip install {package_name}")
`````)
#output-block(`````
==================================================
LangChain v1 환경 확인
==================================================
✓ langchain: 1.2.10

✓ langchain-openai: installed
✓ langchain-community: 0.4.1
✓ langgraph: installed
`````)

#code-block(`````python
# API 키 확인
from dotenv import load_dotenv
import os

load_dotenv(override=True)

required_keys = ["OPENAI_API_KEY"]
optional_keys = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]

print("필수 API 키:")
for key in required_keys:
    status = "\u2713 설정됨" if os.environ.get(key) else "\u2717 미설정"
    print(f"  {key}: {status}")

print("\n선택 API 키:")
for key in optional_keys:
    status = "\u2713 설정됨" if os.environ.get(key) else "- 미설정 (선택)"
    print(f"  {key}: {status}")
`````)
#output-block(`````
필수 API 키:
  OPENAI_API_KEY: ✓ 설정됨

선택 API 키:
  TAVILY_API_KEY: ✓ 설정됨
  LANGSMITH_API_KEY: - 미설정 (선택)
`````)

#code-block(`````python
# LangChain v1 핵심 import 확인
from langchain.agents import create_agent
from langchain.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import InMemorySaver

print("\u2713 모든 핵심 모듈 임포트 성공")
print("  - create_agent: LangChain v1 에이전트 생성")
print("  - tool: 도구 데코레이터")
print("  - ChatOpenAI: OpenAI 호환 모델")
print("  - InMemorySaver: 메모리 체크포인터")
`````)
#output-block(`````
✓ 모든 핵심 모듈 임포트 성공
  - create_agent: LangChain v1 에이전트 생성
  - tool: 도구 데코레이터
  - ChatOpenAI: OpenAI 호환 모델
  - InMemorySaver: 메모리 체크포인터
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [LangChain v1],
  [에이전트 중심 프레임워크, `create_agent()` API 기반],
  [3계층 구조],
  [모델 → 도구 → 미들웨어],
  [ReAct 패턴],
  [추론(Reasoning) → 행동(Action) → 관찰(Observation) 반복],
  [핵심 API],
  [`create_agent()`, `\@tool`, `invoke()`, `stream()`],
)
