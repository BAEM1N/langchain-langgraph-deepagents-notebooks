# Runtime Documentation

## Overview

LangChain's `create_agent` utilizes LangGraph's runtime under the hood. The Runtime object provides three key components: context for static information, a BaseStore instance for long-term memory, and a stream writer for custom streaming.

**Key Benefit**: Runtime context provides dependency injection for your tools and middleware, enabling flexible tool design without hardcoding values or relying on global state.

## Access Configuration

When creating an agent, specify a `context_schema` to define the runtime context structure. Pass the `context` argument during invocation:

```python
from dataclasses import dataclass
from langchain.agents import create_agent

@dataclass
class Context:
    user_name: str

agent = create_agent(
    model="gpt-5-nano",
    tools=[...],
    context_schema=Context
)

agent.invoke(
    {"messages": [{"role": "user", "content": "What's my name?"}]},
    context=Context(user_name="John Smith")
)
```

## Inside Tools

Access runtime information using the `ToolRuntime` parameter to retrieve context, access long-term memory, or write custom stream updates:

```python
from langchain.tools import tool, ToolRuntime

@tool
def fetch_user_email_preferences(runtime: ToolRuntime[Context]) -> str:
    user_id = runtime.context.user_id
    preferences = "The user prefers you to write a brief and polite email."
    if runtime.store and (memory := runtime.store.get(("users",), user_id)):
        preferences = memory.value["preferences"]
    return preferences
```

## Inside Middleware

The `Runtime` parameter is available in node-style hooks; wrap-style hooks access it through `ModelRequest`. This enables dynamic prompts based on user context:

```python
from langchain.agents.middleware import dynamic_prompt, ModelRequest, before_model, after_model

@dynamic_prompt
def dynamic_system_prompt(request: ModelRequest) -> str:
    user_name = request.runtime.context.user_name
    return f"You are a helpful assistant. Address the user as {user_name}."

@before_model
def log_before_model(state: AgentState, runtime: Runtime[Context]) -> dict | None:
    print(f"Processing request for user: {runtime.context.user_name}")
    return None
```
