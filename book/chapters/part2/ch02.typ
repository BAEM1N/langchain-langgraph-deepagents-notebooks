// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "첫 번째 에이전트")

앞 장에서 LangChain v1의 아키텍처를 개괄적으로 살펴봤습니다. 이 장에서는 그 핵심 API인 `create_agent()`를 사용하여 도구, 메모리, 스트리밍이 포함된 완전한 에이전트를 처음부터 끝까지 구축합니다. Part I에서 다룬 기본 패턴을 확장하여, 프로덕션에 가까운 에이전트의 기반을 만들어 봅니다.

`create_agent()`는 LangChain v1에서 에이전트를 만드는 단일 진입점(single entry point)입니다. 내부적으로 LangGraph의 `CompiledStateGraph`를 반환하며, 모델·도구·메모리·미들웨어를 하나의 실행 그래프로 결합합니다. 이 장에서는 가장 기본적인 매개변수(`model`, `tools`, `system_prompt`)부터 시작하여, 메모리(`checkpointer`)와 스트리밍까지 단계별로 확장해 나갑니다.

#learning-header()
LangChain v1의 `create_agent()`로 에이전트를 생성하고 실행합니다.

이 장을 완료하면 다음을 수행할 수 있습니다:

- `@tool` 데코레이터로 커스텀 도구를 정의
- `create_agent()`로 에이전트를 생성
- `invoke()`로 에이전트를 실행하고 결과를 확인
- `stream()`으로 실시간 스트리밍 응답을 받기
- `InMemorySaver`로 멀티턴 대화를 구현

== 2.1 환경 설정

이번 장의 예제를 실행하려면 LangChain v1과 Deep Agents 패키지를 먼저 설치합니다. 다음 명령 중 환경에 맞는 하나를 선택하세요:

#code-block(`````bash
# uv 사용 시
uv add langchain deepagents

# pip 사용 시
pip install -U langchain deepagents
`````)

#tip-box[`langchain`을 설치하면 `langchain-core`, `langgraph`, `langchain-openai`(OpenAI 통합)가 함께 설치됩니다. Anthropic·Google 등 다른 프로바이더는 `langchain-anthropic`, `langchain-google-genai`를 별도로 추가하세요.]

본격적인 에이전트 구축에 앞서, 모델 객체를 준비합니다. `create_agent()`의 `model` 매개변수는 `ChatModel` 인스턴스뿐 아니라 `"openai:gpt-5.4"` 같은 _프로바이더:모델명_ 문자열도 받을 수 있습니다. 여기서는 명시적으로 `ChatOpenAI` 인스턴스를 생성하여 사용합니다.

OpenAI를 통해 모델을 설정합니다. `ChatOpenAI`는 OpenAI 호환 API를 지원하므로, `base_url`을 변경하여 OpenAI를 사용할 수 있습니다.

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)
print("\u2713 모델 설정 완료:", model.model_name)
`````)
#output-block(`````
✓ 모델 설정 완료: gpt-5.4
`````)

== 2.2 간단한 도구 만들기

모델이 준비되었으니, 에이전트가 호출할 수 있는 _도구(tool)_를 정의합니다. 도구는 에이전트가 외부 세계와 상호작용하는 수단이며, LangChain은 `@tool` 데코레이터 하나로 일반 Python 함수를 에이전트용 도구로 변환합니다.

`@tool` 데코레이터로 에이전트가 사용할 도구를 정의합니다.

도구를 정의할 때 중요한 점:
- _docstring_은 필수입니다. 에이전트가 도구의 용도를 이해하는 데 사용됩니다.
- _타입 힌트_를 사용하면 에이전트가 올바른 인자를 전달할 수 있습니다.
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

도구가 준비되었으면, 이제 모델과 도구를 하나의 에이전트로 결합합니다. `create_agent()`는 다음과 같은 전체 시그니처를 가집니다:

`create_agent(model, tools, system_prompt, name, response_format, state_schema, checkpointer, store, middleware, context_schema)`

이 중 `model`과 `tools`만 필수이며, 나머지는 모두 선택입니다. `system_prompt`는 에이전트의 행동 지침을 설정하고, `checkpointer`는 대화 상태 저장을, `middleware`는 실행 파이프라인 훅을 담당합니다. 이 장에서는 기본 세 가지(`model`, `tools`, `system_prompt`)만 사용하고, 나머지 매개변수는 이후 장에서 하나씩 추가합니다.

생성된 에이전트는 내부적으로 LangGraph 그래프로 구현되며, `invoke()`, `stream()` 등의 메서드를 제공합니다.

#tip-box[LangChain v1에서는 `create_react_agent()` 대신 `create_agent()`를 사용합니다.]

#tip-box[에이전트에 `name="research_assistant"` 처럼 _snake_case_ 이름을 주면 LangSmith 트레이스·서브에이전트 라우팅·로그에서 식별이 쉬워집니다. 공백·하이픈·대문자는 피하고, 의미 있는 짧은 이름을 권장합니다.]

#tip-box[`state_schema`를 직접 정의할 때는 반드시 `langgraph.graph.MessagesState` 또는 `langchain.agents.AgentState`를 상속한 *TypedDict* 서브클래스여야 합니다. 일반 `dataclass` 나 Pydantic `BaseModel`은 허용되지 않습니다.]

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

에이전트가 생성되었으니, 실제로 질문을 던져 결과를 확인해 봅니다. `invoke()`는 동기 호출 메서드로, 에이전트가 모든 추론과 도구 호출을 완료한 뒤 최종 결과를 _한 번에_ 반환합니다.

`invoke()`의 반환값은 `dict`이며, 핵심 키는 `"messages"`입니다. 이 리스트에는 대화의 전체 흐름 --- `HumanMessage` → `AIMessage`(도구 호출) → `ToolMessage`(도구 결과) → `AIMessage`(최종 응답) --- 이 순서대로 담겨 있습니다. `response_format`을 설정한 경우 `"structured_response"` 키도 추가됩니다.

에이전트에 메시지를 전달하면, 내부적으로 ReAct 루프가 실행됩니다:
+ 모델이 질문을 분석하고 도구 호출을 결정
+ 도구가 실행되고 결과를 반환
+ 모델이 결과를 바탕으로 최종 응답을 생성

#warning-box[메모리를 사용하지 않는 에이전트에서는 `invoke()`에 config를 전달하지 않아도 됩니다. 하지만 `InMemorySaver`를 사용하는 경우, 반드시 `{"configurable": {"thread_id": "..."}}` 형태의 config를 함께 전달해야 합니다. 이 부분은 2.6절에서 다룹니다.]

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

`invoke()`가 결과를 한 번에 반환하는 반면, `stream()`은 에이전트의 실행 과정을 _단계별로_ 실시간 전달합니다. 챗봇 UI처럼 사용자에게 즉각적인 피드백을 제공해야 하는 경우에 필수적입니다.

`stream()`으로 실시간 응답을 받습니다.

스트리밍을 사용하면 에이전트의 각 단계(모델 추론, 도구 호출, 최종 응답)를 실시간으로 확인할 수 있습니다. `stream_mode="updates"`를 사용하면 각 노드의 업데이트를 순차적으로 받을 수 있습니다. 호출 형태는 `agent.stream(input, config, stream_mode="updates")`이며, 이터레이터를 반환합니다. 각 이터레이션에서 어떤 노드(모델 또는 도구)가 어떤 출력을 생성했는지 확인할 수 있습니다.

#tip-box[LangChain v1은 `values`, `updates`, `messages`, `custom`, `debug` 등 5가지 스트리밍 모드를 지원합니다. 이 장에서는 가장 직관적인 `updates` 모드를 사용하며, 전체 스트리밍 모드는 5장에서 상세히 다룹니다.]

== 2.6 멀티턴 대화

지금까지의 에이전트는 매 호출이 독립적이었습니다. 즉, 이전 대화 내용을 기억하지 못합니다. 실제 어시스턴트라면 "아까 계산한 결과에 5를 곱해줘" 같은 후속 질문을 처리할 수 있어야 합니다. 이를 위해 _체크포인터_를 추가합니다.

`InMemorySaver`로 대화 상태를 유지합니다.

`InMemorySaver`는 메모리 내에서 상태를 저장하며, `thread_id`로 대화 세션을 구분합니다. 에이전트 생성 시 `checkpointer=InMemorySaver()`를 전달하고, `invoke()` 호출 시 `{"configurable": {"thread_id": "my-session"}}` 형태의 config를 함께 전달하면 됩니다. 동일한 `thread_id`를 사용하는 한, 이전 대화의 모든 메시지가 자동으로 복원됩니다.

#tip-box[LangChain v1에서는 LangGraph의 체크포인터를 사용하여 대화 히스토리를 관리합니다.]

#warning-box[`InMemorySaver`는 프로세스 메모리에 상태를 저장하므로, 서버 재시작 시 데이터가 사라집니다. 프로덕션 환경에서는 `SqliteSaver`, `PostgresSaver` 등 영구 체크포인터를 사용하세요.]

== 2.7 Tavily 검색 도구 연동 (선택)

지금까지는 산술 도구라는 단순한 예제를 사용했습니다. 이 절에서는 외부 API를 호출하는 _실전형 도구_를 연동하여, 에이전트가 실시간 정보에 접근할 수 있도록 합니다.

웹 검색 도구를 추가하여 실제 정보를 검색합니다.

Tavily는 AI 에이전트를 위해 설계된 검색 API입니다. 검색 결과를 LLM이 소비하기 좋은 형태로 반환하므로, RAG 파이프라인이나 에이전트의 검색 도구로 널리 사용됩니다.

`TAVILY_API_KEY`가 설정된 경우에만 이 셀이 실행됩니다.

== 2.8 런타임 컨텍스트 (`context_schema`)

`thread_id`가 _대화 세션_을 구분한다면, `context`는 _요청 단위 메타데이터_(사용자 ID, 권한, 테넌트 등)를 도구·미들웨어에 주입하는 통로입니다. `create_agent()`에 `context_schema=`를 등록한 뒤, `invoke()` 호출 시 `context=`로 값을 넘기면 도구의 `ToolRuntime.context`로 접근할 수 있습니다.

#code-block(`````python
from dataclasses import dataclass
from langchain.agents import create_agent

@dataclass
class Context:
    user_id: str
    tenant: str = "default"

agent = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="...",
    context_schema=Context,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    context=Context(user_id="u-1234", tenant="acme"),
)
`````)

#tip-box[`context_schema`는 4장의 `ToolRuntime`, 7장의 HITL과 짝을 이룹니다. 여기서는 "주입 통로가 있다"는 점만 기억하고, 구체적 활용은 4장과 7장에서 다룹니다.]

#chapter-summary-header()

이 장에서는 `create_agent()`의 핵심 매개변수 세 가지(`model`, `tools`, `system_prompt`)와 `checkpointer`를 사용하여 완전한 에이전트를 구축했습니다. 이 노트북에서 다룬 내용을 정리합니다:

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
  [웹 검색을 통한 실시간 정보 접근],
)

이 장에서는 `ChatOpenAI` 인스턴스를 직접 생성하여 모델을 사용했습니다. 다음 장에서는 `init_chat_model()`을 통한 프로바이더 통합 초기화, 메시지 타입의 세부 속성, 그리고 멀티모달 입력까지 --- 모델과 메시지 시스템의 전체 그림을 살펴봅니다.

