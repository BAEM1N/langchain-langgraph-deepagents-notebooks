# Custom Middleware Documentation

## Overview

This documentation covers building custom middleware in LangChain by implementing hooks that intercept agent execution at specific points.

## Hook Types

Two primary hook styles are available.

**Node-style hooks** execute sequentially at specific execution points and are useful for logging, validation, and state updates:
- `before_agent` — Initial execution point (once per invocation)
- `before_model` — Pre-model call (each iteration)
- `after_model` — Post-model response (each iteration)
- `after_agent` — Final execution point (once per invocation)

**Wrap-style hooks** intercept execution around model and tool calls, allowing you to control whether the handler executes zero, one, or multiple times. This enables retry logic, caching, and transformation:
- `wrap_model_call` — Around each model call
- `wrap_tool_call` — Around each tool call

### `wrap_tool_call` Signature

```python
from typing import Callable
from langchain.agents.middleware import wrap_tool_call, ToolCallRequest
from langchain_core.messages import ToolMessage
from langgraph.types import Command

@wrap_tool_call
def monitor_tool(
    request: ToolCallRequest,
    handler: Callable[[ToolCallRequest], ToolMessage | Command],
) -> ToolMessage | Command:
    print(f"Executing tool: {request.tool_call['name']}")
    return handler(request)
```

Class-based equivalent:

```python
from langchain.agents.middleware import AgentMiddleware

class ToolMonitoringMiddleware(AgentMiddleware):
    def wrap_tool_call(
        self,
        request: ToolCallRequest,
        handler: Callable[[ToolCallRequest], ToolMessage | Command],
    ) -> ToolMessage | Command:
        result = handler(request)
        return result
```

### Request and Response Types

- **`ModelRequest`** — input to `wrap_model_call`; carries `messages`, `tools`, `model`, `system_message`, `response_format`, `state`, `runtime`.
- **`ToolCallRequest`** — input to `wrap_tool_call`; carries `tool_call`, `state`, `runtime`.
- **`ModelResponse`** — return type of the inner `handler` in `wrap_model_call`.
- **`ExtendedModelResponse`** — wraps a `ModelResponse` plus a `Command` for persistent state updates emitted from the model-call layer.

### `request.override(...)`

The `ModelRequest.override(...)` method returns a modified copy used to influence the underlying call without mutating shared state:

```python
request = request.override(messages=messages)
request = request.override(tools=tools)
request = request.override(model=model)
request = request.override(system_message=new_system_message)
request = request.override(response_format=SimpleResponse)
```

### `ExtendedModelResponse` for persistent updates

Returning an `ExtendedModelResponse` from `wrap_model_call` lets a middleware inject state updates that survive the call:

```python
from langchain.agents.middleware import (
    wrap_model_call, ModelRequest, ModelResponse, ExtendedModelResponse,
)
from langgraph.types import Command

@wrap_model_call(state_schema=UsageTrackingState)
def track_usage(
    request: ModelRequest,
    handler: Callable[[ModelRequest], ModelResponse],
) -> ExtendedModelResponse:
    response = handler(request)
    return ExtendedModelResponse(
        model_response=response,
        command=Command(update={"last_model_call_tokens": 150}),
    )
```

### Async hook variants (`a` prefix)

Async middleware methods use an `a` prefix on the corresponding hook name (`abefore_model`, `aafter_model`, `awrap_model_call`, `awrap_tool_call`, …):

```python
class LoggingMiddleware(AgentMiddleware):
    async def abefore_model(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        return None

    async def aafter_model(
        self, state: AgentState, runtime: Runtime
    ) -> dict[str, Any] | None:
        print(f"Model returned: {state['messages'][-1].content}")
        return None
```

## Implementation Approaches

**Decorator-based middleware** works well for single-hook scenarios requiring minimal configuration. Multiple decorators can be imported from `langchain.agents.middleware`.

**Class-based middleware** extends `AgentMiddleware` and suits complex scenarios with multiple hooks, custom configuration, or both sync/async implementations needed for the same hook.

## Custom State Schema

Middleware can extend agent state by defining custom properties using `NotRequired` type hints. This enables tracking values across execution, sharing data between hooks, and implementing cross-cutting concerns like rate limiting or audit logging.

Pass `state_schema=CustomState` on either the decorator or the class.

**Decorator usage**:

```python
from typing import Any, NotRequired
from langchain.agents.middleware import AgentState, before_model
from langgraph.runtime import Runtime

class CustomState(AgentState):
    model_call_count: NotRequired[int]

@before_model(state_schema=CustomState, can_jump_to=["end"])
def check_call_limit(state: CustomState, runtime: Runtime) -> dict[str, Any] | None:
    count = state.get("model_call_count", 0)
    return {"jump_to": "end"} if count > 10 else None
```

**Class-based**:

```python
class CallCounterMiddleware(AgentMiddleware[CustomState]):
    state_schema = CustomState

    def before_model(self, state: CustomState, runtime) -> dict[str, Any] | None:
        # ... implementation
        ...
```

## Execution Order

When multiple middleware are registered, execution follows specific patterns:
- `before_*` hooks: First to last order
- `after_*` hooks: Last to first order (reversed)
- `wrap_*` hooks: Nested, with first middleware wrapping all others

## Agent Jumps

Early exits are possible by returning dictionaries containing `jump_to` fields targeting `'end'`, `'tools'`, or `'model'` nodes. To declare the set of legal jump targets, decorate the hook with `@hook_config(can_jump_to=[...])`:

```python
from typing import Any
from langchain.agents.middleware import after_model, hook_config, AgentState
from langchain_core.messages import AIMessage
from langgraph.runtime import Runtime

@after_model
@hook_config(can_jump_to=["end"])
def check_for_blocked(state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
    last_message = state["messages"][-1]
    if "BLOCKED" in last_message.content:
        return {
            "messages": [AIMessage("I cannot respond to that request.")],
            "jump_to": "end",
        }
    return None
```

Class-based equivalent:

```python
class BlockedContentMiddleware(AgentMiddleware):
    @hook_config(can_jump_to=["end"])
    def after_model(self, state: AgentState, runtime: Runtime) -> dict[str, Any] | None:
        # ... implementation
        return {"jump_to": "end"}
```

## Practical Examples

The documentation includes implementations for dynamic model selection, tool call monitoring, runtime tool filtering, and system message modification—including cache control support for Anthropic models.

## Best Practices

Keep middleware focused on single responsibilities, handle errors gracefully, select appropriate hook types for the use case, document custom state properties clearly, test middleware independently, and consider execution order when registering multiple middleware instances.
