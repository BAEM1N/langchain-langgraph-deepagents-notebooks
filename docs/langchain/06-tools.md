# LangChain Tools

## Overview

Tools extend agent capabilities by enabling retrieval of real-time data, code execution, database queries, and world interactions. These are callable functions with defined inputs/outputs passed to chat models, which determine when invocation occurs based on conversation context.

## Creating Tools

### Basic Definition

The simplest approach uses the `@tool` decorator, where the function's docstring becomes the tool description:

```python
from langchain.tools import tool

@tool
def search_database(query: str, limit: int = 10) -> str:
    """Search the customer database for records matching the query.

    Args:
        query: Search terms to look for
        limit: Maximum number of results to return
    """
    return f"Found {limit} results for '{query}'"
```

**Key requirement:** Type hints define the input schema. Documentation should be clear and concise to guide model usage.

### Customization

**Custom naming:**

```python
@tool("web_search")
def search(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query}"
```

**Custom descriptions:**

```python
@tool("calculator", description="Performs arithmetic calculations. Use this for any math problems.")
def calc(expression: str) -> str:
    """Evaluate mathematical expressions."""
    return str(eval(expression))
```

### Advanced Schemas

Define complex inputs using Pydantic models:

```python
from pydantic import BaseModel, Field
from typing import Literal

class WeatherInput(BaseModel):
    """Input for weather queries."""
    location: str = Field(description="City name or coordinates")
    units: Literal["celsius", "fahrenheit"] = Field(
        default="celsius",
        description="Temperature unit preference"
    )

@tool(args_schema=WeatherInput)
def get_weather(location: str, units: str = "celsius") -> str:
    """Get current weather and optional forecast."""
    temp = 22 if units == "celsius" else 72
    return f"Current weather in {location}: {temp} degrees {units[0].upper()}"
```

### Reserved Parameters

The parameters `config` and `runtime` are reserved and cannot be used as tool arguments.

## Runtime Access

Tools access runtime information through the `ToolRuntime` parameter, providing access to:

- **State:** Short-term conversation memory (messages, counters, custom fields)
- **Context:** Immutable configuration (user IDs, session info)
- **Store:** Long-term persistent data across conversations
- **Stream Writer:** Real-time updates during execution
- **Tool Call ID:** Unique invocation identifier

### Accessing State

```python
from langchain.tools import tool, ToolRuntime

@tool
def get_last_user_message(runtime: ToolRuntime) -> str:
    """Get the most recent message from the user."""
    messages = runtime.state["messages"]
    for message in reversed(messages):
        if isinstance(message, HumanMessage):
            return message.content
    return "No user messages found"
```

### Updating State

When a tool updates graph state with `Command`, return a paired `ToolMessage` (carrying `runtime.tool_call_id`) so the agent loop can resolve the original tool call:

```python
from langchain.messages import ToolMessage
from langchain.tools import ToolRuntime, tool
from langgraph.types import Command

@tool
def set_language(language: str, runtime: ToolRuntime) -> Command:
    """Set the preferred response language."""
    return Command(
        update={
            "preferred_language": language,
            "messages": [
                ToolMessage(
                    content=f"Language set to {language}.",
                    tool_call_id=runtime.tool_call_id,
                )
            ],
        }
    )
```

### Context Usage

```python
from dataclasses import dataclass

@dataclass
class UserContext:
    user_id: str

@tool
def get_account_info(runtime: ToolRuntime[UserContext]) -> str:
    """Get the current user's account information."""
    user_id = runtime.context.user_id
    return f"Account info for {user_id}"
```

### Long-term Memory (Store)

```python
@tool
def get_user_info(user_id: str, runtime: ToolRuntime) -> str:
    """Look up user info."""
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

@tool
def save_user_info(user_id: str, user_info: dict, runtime: ToolRuntime) -> str:
    """Save user info."""
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

### Stream Writer

```python
@tool
def get_weather(city: str, runtime: ToolRuntime) -> str:
    """Get weather for a given city."""
    writer = runtime.stream_writer
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"
```

### Execution Info

`runtime.execution_info` exposes the current thread, run, and retry attempt. Useful for correlating tool work with checkpointed state and tracing IDs.

```python
@tool
def log_execution_context(runtime: ToolRuntime) -> str:
    """Log execution identity information."""
    info = runtime.execution_info
    print(f"Thread: {info.thread_id}, Run: {info.run_id}")
    print(f"Attempt: {info.node_attempt}")
    return "done"
```

**Requirements:** `deepagents>=0.5.0` or `langgraph>=1.1.5`.

### Server Info

When the agent runs on LangGraph Server, `runtime.server_info` carries assistant, graph, and authenticated-user metadata (otherwise it is `None`):

```python
@tool
def get_assistant_scoped_data(runtime: ToolRuntime) -> str:
    """Fetch data scoped to the current assistant."""
    server = runtime.server_info
    if server is not None:
        print(f"Assistant: {server.assistant_id}, Graph: {server.graph_id}")
        if server.user is not None:
            print(f"User: {server.user.identity}")
    return "done"
```

**Requirements:** `deepagents>=0.5.0` or `langgraph>=1.1.5`.

## Return Values

Tools can return three kinds of values, each suited to different downstream behavior:

**String** — plain text result for model interpretation:

```python
@tool
def get_weather(city: str) -> str:
    """Get weather for a city."""
    return f"It is currently sunny in {city}."
```

**Object (dict)** — structured data the model can reason over:

```python
@tool
def get_weather_data(city: str) -> dict:
    """Get structured weather data for a city."""
    return {"city": city, "temperature_c": 22, "conditions": "sunny"}
```

**`Command`** — updates graph state with optional model visibility (see Updating State above for the pattern that also returns a `ToolMessage`).

## Error Handling with `@wrap_tool_call`

For agent-level error handling, the `@wrap_tool_call` middleware decorator wraps every tool invocation and converts exceptions into model-visible `ToolMessage`s:

```python
from collections.abc import Callable
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage
from langchain.tools.tool_node import ToolCallRequest

@wrap_tool_call
def handle_tool_errors(
    request: ToolCallRequest,
    handler: Callable[[ToolCallRequest], ToolMessage],
) -> ToolMessage:
    """Convert tool exceptions into ToolMessages the model can handle."""
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"Tool error: Please check your input and try again. ({e})",
            tool_call_id=request.tool_call["id"],
        )

# Attach via create_agent(middleware=[handle_tool_errors])
```

## ToolNode

`ToolNode` is a prebuilt component executing tools in LangGraph workflows, handling parallel execution and error management automatically.

### Basic Usage

```python
from langchain.tools import tool
from langgraph.prebuilt import ToolNode
from langgraph.graph import StateGraph, MessagesState, START, END

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Results for: {query}"

tool_node = ToolNode([search])

builder = StateGraph(MessagesState)
builder.add_node("tools", tool_node)
```

### Error Handling

```python
from langgraph.prebuilt import ToolNode

# Catch all errors
tool_node = ToolNode(tools, handle_tool_errors=True)

# Custom error message
tool_node = ToolNode(tools, handle_tool_errors="Something went wrong, please try again.")

# Custom handler
def handle_error(e: ValueError) -> str:
    return f"Invalid input: {e}"

tool_node = ToolNode(tools, handle_tool_errors=handle_error)
```

### Conditional Routing

```python
from langgraph.prebuilt import tools_condition

builder.add_conditional_edges("llm", tools_condition)  # Routes to "tools" or END
builder.add_edge("tools", "llm")
```

## Provider-specific `extras` (langchain 1.2+)

일부 공급자는 도구에 **공급자 전용 파라미터**가 필요한 기능을 제공한다. 1.2부터 `@tool(extras=...)`에 dict를 전달하면 `create_agent()` / `bind_tools()`가 공급자에 해당 메타데이터를 그대로 전달한다.

### Anthropic programmatic tool calling

Claude가 **서버측 빌트인 도구(`code_execution_20250825` 등)에서 사용자 도구를 호출**할 수 있도록 허용한다.

```python
from langchain.tools import tool

@tool(extras={"allowed_callers": ["code_execution_20250825"]})
def fetch_row(row_id: int) -> dict:
    """Fetch a single row from the analytics table."""
    return lookup(row_id)

# create_agent에 Anthropic 빌트인 code_execution 도구를 함께 붙이면
# Claude가 code_execution 환경 안에서 fetch_row를 프로그램적으로 호출 가능
```

### Fine-grained (eager) input streaming

도구 호출 인자가 모델 쪽에서 **토큰 단위로 스트리밍**되도록 한다. 긴 JSON 인자를 조기에 UI에 보여줘야 할 때 유용하다.

```python
@tool(extras={"eager_input_streaming": True})
def draft_email(to: str, subject: str, body: str) -> str:
    """Draft an email."""
    return send(to, subject, body)
```

### 주의

- `extras`는 **공급자가 이해하는 키만 적용**된다. 다른 공급자는 무시한다.
- 지원 키는 공급자 통합 페이지 참고 (langchain-anthropic, langchain-openai 등).
- 1.2 미만에서는 적용되지 않는다.

## Prebuilt Tools & Server-side Tools

LangChain provides prebuilt tools for web search, code interpretation, and database access. Some chat models feature built-in server-side tools executed by the provider -- consult individual model integration pages for details.
