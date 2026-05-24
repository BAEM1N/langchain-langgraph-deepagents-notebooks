# LangChain Agents

## Overview

Agents merge language models with tools to build systems capable of reasoning about tasks, deciding which tools to suit the situation, and iteratively working toward solutions. The `create_agent` function provides a production-ready implementation.

## Core Architecture

Agents follow a loop pattern: input flows to the model, which decides on actions, calls appropriate tools, receives observations, and repeats until reaching a stop condition (final output or iteration limit).

## Key Components

### Model Configuration

**Static Models:** Set once at creation and remain constant throughout execution.

```python
from langchain.agents import create_agent
agent = create_agent("openai:gpt-5.4", tools=tools)
```

For granular control, instantiate model objects directly:

```python
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4", temperature=0.1, max_tokens=1000)
agent = create_agent(model, tools=tools)
```

**Dynamic Models:** Selected at runtime based on state and context using the `@wrap_model_call` decorator for sophisticated routing and cost optimization.

### Tools

Tools enable agent actions. Unlike simple binding, agents facilitate multiple sequential calls, parallel execution, dynamic selection, retry logic, and state persistence.

**Static Tools:** Defined at creation using the `@tool` decorator:

```python
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Results for: {query}"

agent = create_agent(model, tools=[search])
```

**Dynamic Tools:** Modified at runtime through two approaches -- filtering pre-registered tools or registering tools discovered at runtime (from MCP servers or external registries).

### System Prompt

Shape agent behavior by providing guidance:

```python
agent = create_agent(
    model,
    tools,
    system_prompt="You are a helpful assistant. Be concise and accurate."
)
```

**`SystemMessage` 직접 주입 (langchain 1.1+)**: 문자열 대신 `SystemMessage` 인스턴스를 그대로 넘길 수 있다. Anthropic 프롬프트 캐싱 블록, 이미지 포함 시스템 메시지, content blocks 등 고급 기능이 필요할 때 사용한다.

```python
from langchain_core.messages import SystemMessage

system_message = SystemMessage(
    content=[
        {"type": "text", "text": "You are a senior data analyst."},
        {
            "type": "text",
            "text": LONG_PLAYBOOK,
            # Anthropic 프롬프트 캐싱
            "cache_control": {"type": "ephemeral"},
        },
    ],
)

agent = create_agent(
    model,
    tools,
    system_prompt=system_message,
)
```

**Dynamic Prompts:** Generate system prompts based on runtime context using the `@dynamic_prompt` decorator.

### Agent Name

Set optional identifiers for multi-agent systems. Names should use **snake_case** (alphanumeric characters, underscores, and hyphens only) for compatibility across LLM providers:

```python
agent = create_agent(model, tools, name="research_assistant")
```

## Invocation

Pass messages to invoke agents:

```python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather in San Francisco?"}]}
)
```

For persistent conversations and typed runtime context, pass `config={"configurable": {"thread_id": ...}}` together with `context=` (paired with `context_schema=` on `create_agent`):

```python
from dataclasses import dataclass
from langchain_core.utils.uuid import uuid7
from langgraph.checkpoint.memory import InMemorySaver

@dataclass
class Context:
    user_id: str

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[],
    checkpointer=InMemorySaver(),
    context_schema=Context,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather?"}]},
    config={"configurable": {"thread_id": str(uuid7())}},
    context=Context(user_id="user-123"),
)
```

### Custom State Schema

Custom state schemas passed via `state_schema=` **must be `TypedDict` subclasses** (typically extending `AgentState`):

```python
from langchain.agents import AgentState

class CustomState(AgentState):
    user_preferences: dict

agent = create_agent(model, tools=tools, state_schema=CustomState)
```

### Tool Error Handling

Use the `@wrap_tool_call` middleware decorator to convert tool exceptions into model-visible `ToolMessage`s:

```python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"Tool error: {e}",
            tool_call_id=request.tool_call["id"],
        )

agent = create_agent(model, tools=tools, middleware=[handle_tool_errors])
```

## Advanced Features

### Structured Output

Return outputs in specific formats using `ToolStrategy` (artificial tool calling) or `ProviderStrategy` (native provider support).

### Memory

Agents maintain conversation history automatically. Extend conversation tracking using custom state schemas that inherit from `AgentState`.

### Streaming

Stream intermediate steps for long-running agents:

```python
for chunk in agent.stream({"messages": [...]}, stream_mode="values"):
    print(chunk["messages"][-1])
```

### Middleware

Customize execution at different stages -- process state before model calls, validate responses, handle errors, implement dynamic selection, and add monitoring.

---

**Key Documentation Links:** [Tools](/oss/python/langchain/tools), [Messages](/oss/python/langchain/messages), [Middleware](/oss/python/langchain/middleware), [LangSmith](/langsmith/home)
