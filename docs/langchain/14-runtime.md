# Runtime Documentation

## Overview

LangChain's `create_agent` utilizes LangGraph's runtime under the hood. The Runtime object exposes five components:

1. **Context** — Static information like user IDs, database connections, and dependencies.
2. **Store** — A `BaseStore` instance for long-term memory.
3. **Stream writer** — Enables streaming via the `"custom"` stream mode.
4. **Execution info** — Identity and retry data (`thread_id`, `run_id`, `attempt`).
5. **Server info** — Server-specific metadata on LangGraph Server (`assistant_id`, `graph_id`, authenticated user).

**Key Benefit**: Runtime context provides dependency injection for your tools and middleware, enabling flexible tool design without hardcoding values or relying on global state.

**Version requirements**: `runtime.execution_info` and `runtime.server_info` require `deepagents>=0.5.0` (or `langgraph>=1.1.5`). This minimum applies to both tool and middleware implementations.

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

## Execution Info

`runtime.execution_info` exposes identity and retry data for the current run:

- `thread_id` — Conversation thread identifier (persists across runs in a thread).
- `run_id` — Identifier for the current invocation.
- `attempt` — Retry attempt number (incremented on retried runs).

```python
from langchain.tools import tool, ToolRuntime

@tool
def log_identity(runtime: ToolRuntime) -> str:
    info = runtime.execution_info
    return f"Thread: {info.thread_id}, Run: {info.run_id}, Attempt: {info.attempt}"
```

## Server Info (LangGraph Server only)

`runtime.server_info` exposes metadata that is only populated when the agent runs on LangGraph Server. It returns `None` during local development.

- `assistant_id` — Deployed assistant identifier.
- `graph_id` — Compiled graph identifier.
- `user` — Authenticated user object (may itself be `None`); when present, `user.identity` carries the principal.

```python
@tool
def whoami(runtime: ToolRuntime) -> str:
    server = runtime.server_info
    if server is None:
        return "local development"
    parts = [f"assistant={server.assistant_id}", f"graph={server.graph_id}"]
    if server.user is not None:
        parts.append(f"user={server.user.identity}")
    return ", ".join(parts)
```
