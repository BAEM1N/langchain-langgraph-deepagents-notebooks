// Auto-generated from 04_tools_and_structured_output.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "도구와 구조화된 출력")

LangChain v1에서 `@tool` 데코레이터로 커스텀 도구를 만들고, `with_structured_output()`으로 구조화된 응답을 받는 방법을 학습합니다.

== 학습 목표
#learning-objectives([`@tool` 데코레이터로 도구를 만들고 스키마를 확인합니다], [Pydantic 모델로 복잡한 입력 스키마를 정의합니다], [`create_agent()`에 도구를 연결하여 에이전트를 구성합니다], [`ToolRuntime`으로 도구에서 런타임 컨텍스트에 접근합니다], [`with_structured_output()`으로 구조화된 출력을 설정합니다], [`ToolStrategy`와 `ProviderStrategy`의 차이를 이해합니다])

== 4.1 환경 설정

API 키를 로드하고 OpenAI 모델을 초기화합니다.

#code-block(`````python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv(override=True)

# OpenAI를 통한 모델 초기화
model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 초기화 완료:", model.model_name)
`````)

== 4.2 \@tool 데코레이터 기본

함수에 `@tool`을 붙이면 에이전트가 사용할 수 있는 도구가 됩니다.
LangChain은 함수의 이름, docstring, 타입 힌트를 자동으로 파싱하여 도구 스키마를 생성합니다.

#code-block(`````python
from langchain.tools import tool

@tool
def my_tool(param: str) -> str:
    """Tool description for the LLM."""
    return result
`````)

#code-block(`````python
from langchain.tools import tool

@tool
def get_weather(city: str) -> str:
    """도시의 현재 날씨를 조회합니다."""
    weather_data = {
        "Seoul": "맑음, 15\u00b0C",
        "Tokyo": "흐림, 12\u00b0C",
        "New York": "비, 8\u00b0C",
    }
    return weather_data.get(city, f"날씨 데이터를 사용할 수 없습니다: {city}")

# 도구의 스키마 확인
print("도구 이름:", get_weather.name)
print("도구 설명:", get_weather.description)
print("입력 스키마:", get_weather.args_schema.model_json_schema())
`````)
#output-block(`````
도구 이름: get_weather
도구 설명: 도시의 현재 날씨를 조회합니다.
입력 스키마: {'description': '도시의 현재 날씨를 조회합니다.', 'properties': {'city': {'title': 'City', 'type': 'string'}}, 'required': ['city'], 'title': 'get_weather', 'type': 'object'}
`````)

== 4.3 Pydantic 복잡한 스키마

더 복잡한 입력 구조가 필요할 때는 Pydantic `BaseModel`로 스키마를 정의합니다.
`@tool(args_schema=MySchema)` 형태로 전달하면, LLM이 파라미터 구조를 정확히 파악할 수 있습니다.

- `Field(description=...)`: 각 필드에 대한 설명을 LLM에 전달
- `Field(default=...)`: 기본값 설정

#code-block(`````python
from pydantic import BaseModel, Field

class SearchQuery(BaseModel):
    """데이터베이스 쿼리용 검색 파라미터입니다."""
    query: str = Field(description="검색 쿼리 문자열")
    max_results: int = Field(default=5, description="반환할 최대 결과 수")
    category: str = Field(default="all", description="검색 카테고리: all, tech, science, news")

@tool(args_schema=SearchQuery)
def search_database(query: str, max_results: int = 5, category: str = "all") -> str:
    """고급 필터링 옵션으로 데이터베이스를 검색합니다."""
    return f"'{category}' 카테고리에서 '{query}'에 대한 {max_results}개의 결과를 찾았습니다"

print("복합 스키마:", search_database.args_schema.model_json_schema())
`````)
#output-block(`````
복합 스키마: {'description': '데이터베이스 쿼리용 검색 파라미터입니다.', 'properties': {'query': {'description': '검색 쿼리 문자열', 'title': 'Query', 'type': 'string'}, 'max_results': {'default': 5, 'description': '반환할 최대 결과 수', 'title': 'Max Results', 'type': 'integer'}, 'category': {'default': 'all', 'description': '검색 카테고리: all, tech, science, news', 'title': 'Category', 'type': 'string'}}, 'required': ['query'], 'title': 'SearchQuery', 'type': 'object'}
`````)

== 4.4 도구를 에이전트에 연결

`create_agent()`에 도구 리스트를 전달하면, 에이전트가 상황에 맞는 도구를 자동으로 선택하여 실행합니다.

#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[tool1, tool2],
    system_prompt="...",
)
`````)

#note-box[_참고:_ LangChain v1에서는 `create_react_agent`가 제거되었습니다. 반드시 `create_agent`를 사용하세요.]

== 4.5 ToolRuntime

`ToolRuntime`을 쓰면 도구 함수 내에서 현재 대화 상태(state)에 접근할 수 있습니다.
메시지 이력, 설정값 등 런타임 컨텍스트를 활용하는 도구를 만들 때 유용합니다.

#code-block(`````python
@tool
def my_tool(runtime: ToolRuntime) -> str:
    messages = runtime.state["messages"]
    # ...
`````)

=== 4.5.1 `runtime.execution_info`

`ToolRuntime`은 단순 state 접근을 넘어, 현재 실행의 메타 정보를 들고 있습니다. 도구가 어떤 thread/run/node에서 호출됐는지 알 수 있어 로깅·디버깅·재시도 추적에 유용합니다.

#tip-box[일부 필드는 `deepagents>=0.5.0` 또는 `langgraph>=1.1.5`에서 노출됩니다.]

=== 4.5.2 `runtime.server_info`

LangGraph Platform·LangSmith 같은 호스팅 환경에서는 어시스턴트 ID, 사용자 식별자가 자동으로 채워집니다. 도구 안에서 이 정보를 꺼내 권한 분기·감사 로그에 씁니다.

=== 4.5.3 `\@wrap_tool_call` — 도구 호출 가로채기

`@wrap_tool_call` 데코레이터는 모든 도구 호출 전·후에 끼어들어 재시도·관측·에러 처리를 한 곳에서 처리할 수 있게 해 줍니다. `ToolCallRequest`로 도구 이름과 인자를 확인하고, 실패 시 fallback `ToolMessage`를 반환합니다.

#code-block(`````python
from langchain.messages import ToolMessage

try:
    from langchain.tools import wrap_tool_call, ToolCallRequest
except ImportError:
    # 일부 빌드에서는 langchain.agents 하위로 노출됩니다.
    from langchain.agents.tool_executor import wrap_tool_call, ToolCallRequest  # type: ignore


@wrap_tool_call
def safe_executor(request: ToolCallRequest, handler):
    """도구 호출 전후로 로그를 남기고, 예외는 ToolMessage로 흡수합니다."""
    print(f"[tool_call] {request.tool_call['name']} args={request.tool_call.get('args')}")
    try:
        result = handler(request)
        print("[tool_call] ok")
        return result
    except Exception as exc:  # noqa: BLE001
        print(f"[tool_call] failed: {exc}")
        return ToolMessage(
            content=f"도구 호출이 실패했습니다: {exc}. 다른 방식으로 답하세요.",
            tool_call_id=request.tool_call["id"],
        )


# 사용 예 — middleware/agent 옵션에 따라 전달 위치가 달라질 수 있습니다.
# wrapped_agent = create_agent(
#     model=model,
#     tools=[get_weather],
#     middleware=[safe_executor],
# )
print("safe_executor 정의 완료 — agent 생성 시 middleware로 등록하세요.")
`````)

=== 4.5.4 `Command` 업데이트 + `ToolMessage` 동반 반환

도구가 단순 문자열이 아니라 _상태 업데이트_를 함께 반환해야 할 때는 `Command`를 씁니다. 핵심은 `Command.update["messages"]`에 `ToolMessage(tool_call_id=runtime.tool_call_id)`를 같이 실어야 한다는 점입니다. 이 짝이 빠지면 모델이 도구 응답을 못 받았다고 판단해 같은 도구를 무한 반복할 수 있습니다.

#tip-box[`runtime.tool_call_id`·`Command` API는 `deepagents>=0.5.0` 또는 `langgraph>=1.1.5`에서 안정화됐습니다.]

== 4.6 구조화된 출력

`with_structured_output()`을 쓰면 모델의 응답을 Pydantic 모델이나 dataclass 형태로 직접 받을 수 있습니다.
에이전트 없이 모델에서 직접 사용하는 방식입니다.

#code-block(`````python
structured_model = model.with_structured_output(MySchema)
result = structured_model.invoke("...")
# result는 MySchema 인스턴스
`````)

== 4.7 ToolStrategy vs ProviderStrategy

에이전트에서 구조화된 출력을 사용하는 두 가지 전략이 있습니다:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[전략],
  text(weight: "bold")[설명],
  text(weight: "bold")[장점],
  [`ToolStrategy`],
  [도구 호출 메커니즘을 활용하여 구조화된 출력 생성],
  [모든 모델에서 동작, 안정적],
  [`ProviderStrategy`],
  [프로바이더의 네이티브 구조화 출력 기능 사용],
  [더 빠르고 정확 (지원 모델 한정)],
)

`response_format` 파라미터에 전략을 지정하여 에이전트의 최종 응답을 구조화할 수 있습니다.

#note-box[_버전 메모._ `ProviderStrategy(..., strict=True)` 같은 엄격 검증 옵션은 `langchain>=1.2`에서 안정화됐습니다. 그 이전 버전에서는 `ToolStrategy`로 대체하거나 패키지를 업그레이드하세요.]

#note-box[_Gemini는 비공식 지원._ Google Gemini 계열은 구조화 출력 동작이 빠르게 바뀌고 있어, 노트북 예시는 OpenAI 기준으로 제공합니다. Gemini로 옮길 때는 응답 검증 코드를 별도로 두는 편이 안전합니다.]

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [`\@tool` 데코레이터],
  [함수를 에이전트용 도구로 변환],
  [`args_schema`],
  [Pydantic 모델로 복잡한 입력 스키마 정의],
  [`create_agent()`],
  [모델과 도구를 연결하여 에이전트 생성],
  [`ToolRuntime`],
  [도구 내에서 런타임 상태(대화 이력 등) 접근],
  [`runtime.execution_info`],
  [`thread_id`·`run_id`·`node_attempt` 등 실행 메타],
  [`runtime.server_info`],
  [호스팅 환경의 `assistant_id`·`user` 정보],
  [`\@wrap_tool_call`],
  [모든 도구 호출에 공통 로깅·에러 핸들링 주입],
  [`Command` + `ToolMessage`],
  [상태 업데이트와 도구 응답을 한 번에 반환],
  [`with_structured_output()`],
  [모델 응답을 Pydantic/dataclass로 구조화],
  [`ToolStrategy`],
  [도구 호출 방식의 구조화된 에이전트 출력],
  [`ProviderStrategy`],
  [프로바이더 네이티브 구조화 출력 (`strict`는 `langchain\>=1.2`)],
)
