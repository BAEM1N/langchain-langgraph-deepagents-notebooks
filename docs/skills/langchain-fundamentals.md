# LangChain Fundamentals

`create_agent()`, `@tool` 데코레이터, 미들웨어 패턴, 구조화된 출력.

## create_agent()

에이전트를 만드는 권장 방법:

```python
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent

model = init_chat_model("openai:gpt-5.4")
agent = create_agent(model, tools=[...], system_prompt="...")
result = agent.invoke(
    {"messages": [{"role": "user", "content": "질문"}]},
    config={"configurable": {"thread_id": "1"}},
)
print(result["messages"][-1].content)
```

문자열 단축 표기도 지원한다.

```python
agent = create_agent("openai:gpt-5.4", tools=[...])
```

## @tool 데코레이터

```python
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Search the web for information."""
    return tavily.search(query)
```

도구 설명(docstring)이 에이전트의 도구 선택에 직접적 영향을 미친다. 명확하고 구체적으로 작성.

도구·메시지·미들웨어 import 경로는 `langchain.tools`, `langchain.messages`, `langchain.agents.middleware` 로 통일한다 (`langchain_core.*` 가 아닌 v1 공식 경로).

## 구조화된 출력

`with_structured_output()` 외에도 `create_agent(response_format=...)` 가 권장 진입점이다. 스키마 타입을 그대로 넘기면 LangChain 이 모델 프로파일을 보고 `ProviderStrategy` (OpenAI/Anthropic/xAI 네이티브) 와 `ToolStrategy` (도구 호출 기반) 를 자동 선택한다.

```python
from pydantic import BaseModel
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy, ProviderStrategy

class Answer(BaseModel):
    reasoning: str
    answer: str

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[...],
    response_format=Answer,  # 자동 전략 선택
)
# 또는 명시적으로
agent = create_agent(model, tools, response_format=ToolStrategy(Answer))
```

결과는 `result["structured_response"]` 키로 반환된다.

## Runtime Context & Naming

런타임 정보를 주입할 때는 `context_schema=` 와 호출 시 `context=` 를 함께 쓴다 (legacy `config={"configurable": {...}}` 대신).

```python
from dataclasses import dataclass
from langchain.agents import create_agent

@dataclass
class Context:
    user_id: str

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[],
    context_schema=Context,
    name="research_assistant",  # snake_case 권장
)

agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={"configurable": {"thread_id": "1"}},
    context=Context(user_id="user-123"),
)
```

에이전트 이름은 멀티 에이전트 시스템 호환을 위해 **snake_case** 로 작성한다.

## 표준 콘텐츠 블록 (`output_version="v1"`)

LangChain v1 의 표준화된 content block 직렬화를 켜려면 모델 초기화 시 `output_version="v1"` 을 지정하거나 환경변수 `LC_OUTPUT_VERSION=v1` 을 설정한다.

```python
model = init_chat_model("openai:gpt-5.4", output_version="v1")
```

## 흔한 실수

| 실수 | 올바른 방법 |
|------|------------|
| 체크포인터 누락 | `create_agent(..., checkpointer=InMemorySaver())` |
| thread_id 누락 | `config={"configurable": {"thread_id": "1"}}` |
| 모호한 도구 설명 | 구체적 docstring 작성 |
| `result.content` 접근 | `result["messages"][-1].content` |
| recursion_limit 미설정 | `config={"recursion_limit": 25}` |
| `langchain_core.tools` import | `from langchain.tools import tool` |
| 카멜케이스 에이전트 이름 | snake_case (`research_assistant`) |
