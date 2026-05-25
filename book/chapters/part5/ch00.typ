// Auto-generated from 00_migration.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "v0 → v1 마이그레이션 가이드")

LangChain/LangGraph v0에서 v1으로 전환할 때 알아야 할 브레이킹 체인지와 코드 매핑을 다룹니다. v1은 단순한 버전 업데이트가 아니라, 에이전트 개발 패러다임의 근본적인 전환입니다. 기존의 `create_react_agent`는 `create_agent`로, `AgentExecutor`는 LangGraph 네이티브로, `ConversationBufferMemory`는 `InMemorySaver` 기반 체크포인터로 대체되었습니다. 이 장에서는 각 변경점의 배경과 마이그레이션 전략을 체계적으로 살펴봅니다.

v0에서 v1으로의 전환은 크게 세 가지 축을 중심으로 이루어집니다. 첫째, _패키지 구조_가 모놀리식에서 모듈형으로 분리되었습니다. 둘째, _에이전트 생성 API_가 통합되어 `create_agent` 하나로 에이전트를 정의합니다. 셋째, _횡단 관심사(cross-cutting concerns)_ 처리가 개별 훅에서 미들웨어 시스템으로 일원화되었습니다. 이 세 축을 이해하면 마이그레이션의 큰 그림이 명확해집니다.

#learning-header()
#learning-objectives([v1 패키지 구조 변경과 import 경로를 이해한다], [`create_react_agent` → `create_agent` 마이그레이션을 수행한다], [미들웨어 기반 동적 프롬프트, 상태 관리, 컨텍스트 주입을 적용한다], [표준 콘텐츠 블록과 구조화된 출력 전략을 활용한다])

== 0.1 패키지 구조 변경

v0의 `langchain` 패키지는 Chains, Retrievers, Hub, 인덱싱 등 수십 개의 모듈을 포함하는 모놀리식 구조였습니다. 이 때문에 설치 용량이 크고 의존성 충돌이 잦았으며, 에이전트 개발에 불필요한 레거시 코드가 함께 설치되는 문제가 있었습니다. 예를 들어, 단순한 ReAct 에이전트를 만들기 위해 `langchain`을 설치하면 Retriever, Indexing, Hub 등 사용하지 않는 모듈까지 함께 설치되어 가상환경 크기가 불필요하게 커지고, 패키지 간 버전 충돌이 발생하는 경우가 빈번했습니다.

v1에서는 이를 해결하기 위해 `langchain` 네임스페이스를 에이전트 구축에 필수적인 5개 핵심 모듈로 대폭 축소하고, 나머지는 `langchain-classic`으로 분리했습니다. 이러한 분리는 _"에이전트 퍼스트"_ 철학을 반영한 것으로, LangChain이 범용 LLM 프레임워크에서 에이전트 전용 프레임워크로 방향을 전환했음을 의미합니다.

특히 메시지·도구 import 경로가 바뀐 점을 주의해야 합니다. v0에서는 `langchain_core.messages` · `langchain_core.tools`에서 가져왔지만, v1에서는 동일한 심볼을 `langchain.messages` · `langchain.tools`로 재노출합니다. 코어 모듈은 그대로 유지되지만, v1 코드 베이스에서는 단축 경로를 표준으로 사용하는 것이 권장됩니다.

#code-block(`````python
# v1 표준 import
from langchain.messages import HumanMessage, AIMessage, ToolMessage
from langchain.tools import tool, ToolRuntime, BaseTool

# v0 호환 import (`langchain_core.*`)도 계속 동작하지만 v1 코드에서는 위 경로를 선호
from langchain_core.messages import HumanMessage as _LegacyHumanMessage
`````)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v1 모듈],
  text(weight: "bold")[역할],
  text(weight: "bold")[주요 API],
  [`langchain.agents`],
  [에이전트 생성 및 상태 관리],
  [`create_agent`, `AgentState`],
  [`langchain.messages`],
  [메시지 타입과 콘텐츠 블록],
  [`HumanMessage`, `AIMessage`, `content_blocks`],
  [`langchain.tools`],
  [도구 정의],
  [`\@tool` 데코레이터, `BaseTool`],
  [`langchain.chat_models`],
  [모델 초기화],
  [`init_chat_model`],
  [`langchain.embeddings`],
  [임베딩 유틸리티],
  [임베딩 모델 래퍼],
)

=== 레거시 코드 마이그레이션 — `langchain-classic`

기존에 `langchain` 패키지에서 사용하던 Chains, Retrievers, Hub, 인덱싱 API 등은 모두 `langchain-classic`이라는 별도 패키지로 분리되었습니다. 기존 코드를 유지해야 하는 경우 `pip install langchain-classic`으로 설치 후 import 경로를 변경합니다:

#code-block(`````python
# v0 — 기존 방식
from langchain.chains import LLMChain
from langchain.retrievers import MultiQueryRetriever
from langchain import hub

# v1 — langchain-classic으로 이전
from langchain_classic.chains import LLMChain
from langchain_classic.retrievers import MultiQueryRetriever
from langchain_classic import hub
`````)

이 분리를 통해 v1의 `langchain` 패키지는 에이전트 빌딩에만 집중하는 경량 구조가 되었으며, 레거시 기능은 독립적으로 유지보수됩니다. `langchain-classic`은 기존 프로젝트의 호환성을 보장하면서도, 새 프로젝트에서는 최소한의 의존성으로 시작할 수 있게 합니다.

#tip-box[마이그레이션 시 기존 import 경로를 일괄 치환하려면 `sed` 또는 IDE의 전체 검색/치환 기능을 활용하세요. `from langchain.chains` → `from langchain_classic.chains`처럼 패턴이 일정합니다.]

#warning-box[`langchain`과 `langchain-classic`을 동시에 설치할 수 있지만, 두 패키지의 내부 모듈이 이름 충돌을 일으킬 수 있습니다. 가상환경을 분리하거나, 점진적으로 `langchain-classic` 의존을 제거하는 것을 권장합니다.]

패키지 구조가 정리되었으니, 이제 가장 중요한 변경점인 에이전트 생성 API를 살펴보겠습니다.

== 0.2 에이전트 생성 API 변경

v0에서 에이전트를 만들려면 `langgraph.prebuilt`에서 `create_react_agent`를 import하고, 별도의 `AgentExecutor`를 감싸는 이중 구조가 필요했습니다. 이 구조는 에이전트 정의와 실행이 분리되어 있어 코드가 장황해지고, 미들웨어나 상태 관리를 추가할 때 복잡도가 급격히 증가했습니다.

v1에서는 이를 `langchain.agents.create_agent` 단일 함수로 통합하여, 에이전트 생성부터 실행까지 하나의 API로 처리합니다. 파라미터명도 직관적으로 변경되었습니다. `prompt`는 `system_prompt`로, 훅 시스템은 통합 `middleware`로 일원화되었습니다. 이 통합 덕분에 에이전트 정의가 선언적(declarative)이 되어 코드 가독성이 크게 향상됩니다.

다음 코드는 v1에서 에이전트를 생성하는 기본 패턴을 보여줍니다. v0 대비 import 경로, 함수명, 파라미터명이 어떻게 변경되었는지 주석으로 비교합니다.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
from langchain.tools import tool
from langchain.agents import create_agent

model = ChatOpenAI(model="gpt-5.4")

@tool
def add(a: int, b: int) -> int:
    """두 수를 더합니다."""
    return a + b

# v0: from langgraph.prebuilt import create_react_agent
# v1: from langchain.agents import create_agent
agent = create_agent(
    model=model,
    tools=[add],
    system_prompt="당신은 수학 어시스턴트입니다.",  # v0: prompt=
)
print("\u2713 v1 에이전트 생성 완료")
`````)
#output-block(`````
✓ v1 에이전트 생성 완료
`````)

위 코드에서 주목할 점은 `create_agent`가 에이전트를 즉시 실행 가능한 상태로 반환한다는 것입니다. v0처럼 `AgentExecutor`로 감쌀 필요가 없으므로, `agent.invoke(...)` 또는 `agent.stream(...)`을 바로 호출할 수 있습니다.

=== 주요 변경점

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  text(weight: "bold")[비고],
  [`from langgraph.prebuilt import create_react_agent`],
  [`from langchain.agents import create_agent`],
  [import 경로 + 함수명],
  [`prompt=`],
  [`system_prompt=`],
  [파라미터명],
  [`ToolNode` 지원],
  [미지원],
  [함수/BaseTool/dict만],
  [`pre_hooks`, `post_hooks`],
  [`middleware=[]`],
  [통합 미들웨어],
  [Pydantic/dataclass 상태],
  [`TypedDict` only],
  [상태 스키마],
)

에이전트 생성 API가 단순해졌으므로, 이제 에이전트의 상태를 어떻게 정의하는지 살펴보겠습니다. 상태 스키마는 에이전트가 실행 중에 추적하는 데이터의 구조를 결정하는 중요한 요소입니다.

== 0.3 상태 스키마 — TypedDict only

v1에서 커스텀 상태는 반드시 `TypedDict` 기반 `AgentState`를 상속해야 합니다. v0에서는 Pydantic `BaseModel`이나 `@dataclass`로도 상태를 정의할 수 있었지만, v1은 직렬화 일관성과 LangGraph 그래프 엔진과의 호환성을 위해 `TypedDict`로 단일화했습니다. `TypedDict`는 런타임 오버헤드가 없는 순수한 타입 힌팅 메커니즘이므로, 그래프 엔진이 상태를 직렬화/역직렬화할 때 예측 가능한 동작을 보장합니다.

기존에 Pydantic 상태를 사용하던 코드는 `TypedDict`로 전환해야 하며, 검증 로직이 필요한 경우 미들웨어의 `before_model` 훅에서 수동으로 처리할 수 있습니다.

#warning-box[`TypedDict`는 런타임 검증을 제공하지 않으므로, 상태 필드의 타입 안전성은 개발자 책임입니다. `mypy`나 `pyright` 같은 정적 분석 도구를 병행 사용하는 것을 권장합니다.]

상태 스키마가 단순해진 대신, v1은 런타임 컨텍스트라는 새로운 개념을 도입하여 실행 시점의 데이터를 체계적으로 관리합니다.

== 0.4 런타임 컨텍스트 주입 (신규)

v1에서는 `context_schema`와 `context` 파라미터를 통해 _불변 런타임 데이터_를 에이전트에 전달할 수 있습니다. 이는 사용자 ID, 역할, 세션 정보 등 요청마다 달라지지만 실행 중에는 변하지 않는 데이터를 에이전트와 도구에 안전하게 전달하는 패턴입니다.

_작동 방식:_
+ `@dataclass`로 컨텍스트 스키마를 정의합니다.
+ `create_agent(context_schema=...)`로 스키마를 등록합니다.
+ `agent.invoke(..., context=ContextInstance(...))`로 런타임에 값을 전달합니다.
+ 도구에서는 `ToolRuntime[ContextType]` 파라미터로 컨텍스트에 접근합니다.

컨텍스트는 에이전트 상태(`AgentState`)와 달리 도구 호출 간에 _변경되지 않는 읽기 전용 데이터_입니다. 상태는 에이전트 루프 중 업데이트되지만, 컨텍스트는 `invoke` 호출 시 고정됩니다.

#tip-box[`context_schema`는 멀티테넌트 에이전트에서 특히 유용합니다. 사용자 ID, 조직 정보, 권한 수준 등을 컨텍스트로 전달하면, 도구가 사용자별 맞춤 동작을 수행할 수 있습니다.]

런타임 컨텍스트가 정적 데이터를 다룬다면, 동적 프롬프트는 실행 시점의 조건에 따라 에이전트의 지시사항을 변경하는 메커니즘입니다.

== 0.5 동적 프롬프트 — 미들웨어 방식 (신규)

v0에서는 `system_prompt`가 에이전트 생성 시점에 고정되어, 런타임 조건에 따라 프롬프트를 변경할 수 없었습니다. 이 제약 때문에 개발자들은 프롬프트 내에 조건 분기 텍스트를 미리 넣어두거나, 에이전트를 여러 개 만들어 상황별로 전환하는 우회 방법을 사용해야 했습니다.

v1의 `@dynamic_prompt` 미들웨어는 매 모델 호출 직전에 상태와 컨텍스트를 분석하여 시스템 프롬프트를 동적으로 생성합니다. 이를 통해 사용자 역할, 시간대, 이전 도구 호출 결과 등에 따라 에이전트의 행동 지침을 실시간으로 조정할 수 있습니다. 예를 들어, 관리자 사용자에게는 삭제 권한에 대한 지침을 추가하고, 일반 사용자에게는 읽기 전용 지침만 포함하는 식입니다.

미들웨어는 에이전트 실행 루프의 6개 지점에 훅을 노출합니다. `before_agent`(루프 시작), `before_model`(매 모델 호출 직전), `wrap_model_call`(모델 호출 감싸기), `after_model`(매 모델 응답 직후), `wrap_tool_call`(도구 호출 감싸기), `after_agent`(루프 종료) 순으로 실행되며, 6개 훅 모두 동기/비동기(`a` 프리픽스) 두 형태로 작성할 수 있습니다. 자세한 동작은 Chapter 1에서 다룹니다.

#tip-box[동적 프롬프트 미들웨어는 Chapter 1에서 상세히 다룹니다. 여기서는 v0에서 고정 프롬프트를 사용하던 코드가 v1에서 어떻게 유연해졌는지만 이해하면 충분합니다.]

동적 프롬프트와 마찬가지로, 도구 에러 처리도 v1에서는 미들웨어 패턴으로 통합되었습니다.

== 0.6 도구 에러 처리 — `\@wrap_tool_call` (신규)

v0에서는 `handle_tool_errors=True` 파라미터로 도구 에러를 자동 처리했지만, 에러 메시지 형식이나 재시도 로직을 커스터마이즈하기 어려웠습니다. 에러가 발생하면 기본 에러 메시지가 그대로 LLM에 전달되어, LLM이 에러의 맥락을 파악하지 못하는 경우가 많았습니다.

v1은 `@wrap_tool_call` 미들웨어로 도구 호출 전체를 감싸서, 에러 포맷팅, 조건부 재시도, 폴백 로직 등을 자유롭게 구현할 수 있습니다. `wrap_tool_call`은 도구 호출의 요청(request)과 핸들러(handler)를 받아, 핸들러 실행 전후로 임의의 로직을 삽입합니다. 핸들러를 호출하지 않으면 도구 실행 자체를 차단할 수도 있고, 여러 번 호출하여 재시도를 구현할 수도 있습니다.

다음 코드는 도구 실행 중 발생하는 모든 예외를 포착하여, LLM이 이해할 수 있는 형식의 `ToolMessage`로 변환하는 에러 핸들링 미들웨어 예시입니다.

#code-block(`````python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"도구 오류: {e}",
            tool_call_id=request.tool_call["id"],
        )

agent = create_agent(
    model=model,
    tools=[add],
    middleware=[handle_errors],
)
print("\u2713 에러 핸들링 미들웨어 적용")
`````)
#output-block(`````
✓ 에러 핸들링 미들웨어 적용
`````)

에러 처리 미들웨어를 통해 도구 실행의 안정성을 확보했습니다. 이제 에이전트가 생성하는 응답의 _형식_에 대한 변경점을 살펴보겠습니다.

== 0.7 표준 콘텐츠 블록 & 구조화된 출력 (신규)

v1에서 메시지는 프로바이더 무관한 `content_blocks`를 지원합니다. 이전에는 OpenAI와 Anthropic의 응답 형식이 달라서 프로바이더 전환 시 파싱 로직을 수정해야 했지만, `content_blocks`는 텍스트, 이미지, 도구 호출 등을 표준화된 블록으로 표현하여 프로바이더 간 이식성을 보장합니다. 이는 멀티 프로바이더 전략(예: OpenAI를 주 모델로, Anthropic을 폴백으로 사용)을 채택할 때 특히 중요합니다.

구조화된 출력은 `ToolStrategy`(도구 호출 기반)와 `ProviderStrategy`(네이티브) 두 가지로 분리되었습니다. `ToolStrategy`는 모든 모델에서 동작하는 범용 방식이고, `ProviderStrategy`는 OpenAI의 JSON mode나 Anthropic의 tool_use 같은 네이티브 기능을 활용하여 더 높은 정확도를 제공합니다.

#code-block(`````python
from pydantic import BaseModel
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class Weather(BaseModel):
    location: str
    temperature_c: float

# 1) 도구 호출 기반 — 모든 모델에서 동작
agent_tool = create_agent(
    model=model,
    tools=[add],
    response_format=ToolStrategy(schema=Weather),
)

# 2) 프로바이더 네이티브 — OpenAI JSON mode, Anthropic tool_use 등 활용
agent_provider = create_agent(
    model=model,
    tools=[add],
    response_format=ProviderStrategy(schema=Weather),
)
`````)

기존 OpenAI Responses API 동작이 필요하면 `output_version="v0"`으로 명시적으로 옵트아웃합니다. v1 신규 모델은 기본값이 `output_version="v1"`로, 표준 콘텐츠 블록과 `content_blocks` 프로퍼티가 자동 활성화됩니다.

#code-block(`````python
from langchain_openai import ChatOpenAI

# 표준 블록 형식 (v1 기본값) — content_blocks / .text 프로퍼티 활성화
model_v1 = ChatOpenAI(model="gpt-5.4", output_version="v1")

# 레거시 호환 — v0 동작 복구
model_v0 = ChatOpenAI(model="gpt-5.4", output_version="v0")
`````)

#warning-box[`content_blocks`를 사용할 때, 기존에 `message.content`를 문자열로 가정하던 코드는 수정이 필요합니다. v1에서 `content`는 문자열 또는 블록 리스트일 수 있으므로, `.text` 프로퍼티를 사용하여 텍스트를 추출하는 것이 안전합니다.]

에이전트 응답 형식이 변경되었으므로, 스트리밍 처리 방식도 함께 달라졌습니다.

== 0.8 스트리밍 변경

v1에서 스트리밍 API의 두 가지 핵심 변경점이 있습니다. 에이전트 노드명이 `"agent"`에서 `"model"`로 변경되었고, 텍스트 접근 방식이 메서드 호출에서 프로퍼티 접근으로 바뀌었습니다. 이 두 변경은 상호 의존적이므로, 반드시 함께 적용해야 합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  [에이전트 노드명],
  [`"agent"`],
  [`"model"`],
  [`.text`],
  [메서드 `.text()`],
  [프로퍼티 `.text`],
)

스트리밍 변경 외에도, v1에는 여러 세부적인 브레이킹 체인지가 포함되어 있습니다. 각 항목은 개별적으로는 작지만, 놓치면 런타임 에러의 원인이 되므로 체계적으로 확인해야 합니다.

== 0.9 기타 브레이킹 체인지

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[변경],
  text(weight: "bold")[설명],
  [_Python 3.10+_],
  [모든 LangChain 패키지가 Python 3.10 이상을 요구합니다. 3.9 이하는 미지원됩니다.],
  [_반환 타입_],
  [채팅 모델의 반환 타입이 `BaseMessage`에서 `AIMessage`로 고정되었습니다.],
  [_OpenAI Responses API_],
  [메시지 콘텐츠가 기본적으로 표준 블록 형식입니다. `output_version="v0"`으로 이전 동작을 복구할 수 있습니다.],
  [_Anthropic max_tokens_],
  [기본값이 1024에서 모델별 자동 설정으로 변경되었습니다.],
  [_AIMessage.example_],
  [`example` 파라미터가 제거되었습니다. `additional_kwargs`를 사용하세요.],
  [_AIMessageChunk_],
  [`chunk_position` 속성이 추가되었습니다 (마지막 청크에 `'last'` 값).],
  [*`.text` 프로퍼티*],
  [`.text()` 메서드가 `.text` 프로퍼티로 변경되었습니다.],
  [_파일 인코딩_],
  [파일이 기본적으로 UTF-8 인코딩으로 열립니다.],
)

#tip-box[스트리밍 코드를 마이그레이션할 때는 노드명(`"agent"` → `"model"`)과 `.text` 접근 방식(메서드 → 프로퍼티)을 동시에 변경해야 합니다. 둘 중 하나만 변경하면 런타임 에러가 발생합니다.]

지금까지 살펴본 모든 변경점을 체크리스트로 정리합니다. 마이그레이션을 진행할 때 이 목록을 순서대로 확인하면서 작업하면 누락을 방지할 수 있습니다.

== 요약 — 마이그레이션 체크리스트

- [ ] Python 3.10+ 확인
- [ ] `create_react_agent` → `create_agent` 변경
- [ ] `prompt=` → `system_prompt=` 변경
- [ ] 상태 스키마를 `TypedDict` 기반 `AgentState`로 전환
- [ ] `pre_hooks`/`post_hooks` → `middleware=[]`
- [ ] `ToolNode` → 함수/BaseTool로 교체
- [ ] `.text()` → `.text` 프로퍼티
- [ ] 스트리밍 노드명 `"agent"` → `"model"` 확인
- [ ] 레거시 import를 `langchain-classic`으로 이전

v1 마이그레이션의 핵심은 _에이전트 중심 아키텍처로의 전환_입니다. Chains와 Retrievers 중심의 v0 패러다임에서, 미들웨어와 상태 관리 중심의 v1 패러다임으로 사고방식을 바꾸는 것이 중요합니다. 다음 장에서는 v1의 가장 강력한 신기능인 미들웨어 시스템을 심층적으로 다룹니다.

