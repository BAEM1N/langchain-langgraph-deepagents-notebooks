# LangChain v1 Migration Guide - Complete Content

## Overview
This guide details major changes between LangChain v1 and previous versions, focusing on simplified packages, agent creation updates, and breaking changes.

## Simplified Package Structure

The `langchain` namespace has been significantly reduced in v1 to focus on essential agent-building components:

**Core Modules Available:**
- `langchain.agents` — `create_agent`, `AgentState`
- `langchain.messages` — Message types and content blocks
- `langchain.tools` — `@tool` decorator, `BaseTool`
- `langchain.chat_models` — `init_chat_model`
- `langchain.embeddings` — `init_embeddings`

### Legacy Code Migration to `langchain-classic`

Users relying on older functionality must install `langchain-classic`:

```python
# Updated imports for v1
from langchain_classic.chains import LLMChain
from langchain_classic.retrievers import MultiQueryRetriever
from langchain_classic import hub
```

"If you were using any of the following from the `langchain` package, you'll need to install [`langchain-classic`](https://pypi.org/project/langchain-classic/)" including legacy chains, retrievers, indexing APIs, and hub modules.

Install via: `pip install langchain-classic`

## Agent Creation Changes

### Import Path Updates

"The import path for the agent prebuilt has changed from `langgraph.prebuilt` to `langchain.agents`" and the function renamed from `create_react_agent` to `create_agent`:

```python
# New approach
from langchain.agents import create_agent

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[check_weather],
    system_prompt="You are a helpful assistant"
)
```

### Prompt Parameter Changes

The `prompt` parameter is now `system_prompt`. "If using [`SystemMessage`](reference...) objects in the system prompt, extract the string content."

### Dynamic Prompts via Middleware

Dynamic prompts now use the `@dynamic_prompt` decorator with middleware integration:

```python
from langchain.agents.middleware import dynamic_prompt, ModelRequest

@dynamic_prompt
def dynamic_prompt(request: ModelRequest) -> str:
    user_role = request.runtime.context.user_role
    return f"Base prompt. Expert mode: {user_role == 'expert'}"

agent = create_agent(
    model="gpt-5.4",
    tools=tools,
    middleware=[dynamic_prompt]
)
```

### Pre/Post-Model Hooks as Middleware

"Pre-model hooks are now implemented as middleware with the `before_model` method" for extensibility. Similarly, post-model hooks use `after_model`.

Middleware now exposes six lifecycle hooks: `before_agent`, `before_model`, `wrap_model_call`, `wrap_tool_call`, `after_model`, and `after_agent`. The `before_agent` / `after_agent` hooks (new in v1) run once at agent initialization and completion respectively — useful for memory loading, input validation, result persistence, and cleanup.

Built-in middleware options include `PIIMiddleware` (redaction), `SummarizationMiddleware`, and `HumanInTheLoopMiddleware`.

## State Management

### Custom State via `state_schema`

State must now use `TypedDict` only (no Pydantic models or dataclasses):

```python
from langchain.agents import AgentState, create_agent

class CustomAgentState(AgentState):
    user_id: str

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=tools,
    state_schema=CustomAgentState
)
```

### State via Middleware

Middleware can define custom state using the `state_schema` attribute for better conceptual scoping.

## Model Selection

"Dynamic model selection allows you to choose different models based on runtime context" through the `wrap_model_call` middleware method.

**Important:** "Pre-bound models with tools or configuration are no longer supported" in `create_agent`.

## Tool Handling

Tools accept:
- LangChain `BaseTool` instances
- Callable functions with type hints
- Dictionary representations of built-in provider tools

"The argument will no longer accept [`ToolNode`](reference...) instances."

### Tool Error Handling

Use `@wrap_tool_call` middleware decorator for error management:

```python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_tool_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"Tool error: {str(e)}",
            tool_call_id=request.tool_call["id"]
        )
```

## Structured Output

Structured output is now integrated into the main agent loop (no separate LLM call required), reducing cost and latency. Two strategies are available via `response_format`:
- `ToolStrategy` - Uses artificial tool calling
- `ProviderStrategy` - Uses provider-native generation

```python
from langchain.agents import create_agent
from langchain.agents.structured_output import ToolStrategy
from pydantic import BaseModel

class Weather(BaseModel):
    temperature: float
    condition: str

agent = create_agent(
    "gpt-5.4-mini",
    tools=[weather_tool],
    response_format=ToolStrategy(Weather),
)
```

"Prompted output is no longer supported via the `response_format` argument."

## Streaming Changes

"The node name has changed from `"agent"` to `"model"`" when streaming events.

## Runtime Context

Runtime context now passes via the `context` parameter (replacing the older `config["configurable"]` pathway). The schema is declared with `context_schema`:

```python
from dataclasses import dataclass

@dataclass
class Context:
    user_id: str

agent = create_agent(
    model=model,
    tools=tools,
    context_schema=Context
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Hello"}]},
    context=Context(user_id="123")
)
```

## Standard Content Blocks

Messages now support provider-agnostic content blocks via `message.content_blocks`:

```python
response = model.invoke("Explain AI")

for block in response.content_blocks:
    if block["type"] == "text":
        print(block.get("text"))
```

Create multimodal messages:

```python
from langchain.messages import HumanMessage

message = HumanMessage(content_blocks=[
    {"type": "text", "text": "Describe this image."},
    {"type": "image", "url": "https://example.com/image.jpg"},
])
```

## Breaking Changes

### Python Version
"All LangChain packages now require **Python 3.10 or higher**."

### Chat Model Return Types
"The return type signature for chat model invocation has been fixed from [`BaseMessage`](reference...) to [`AIMessage`](reference...)"

### Content Block Serialization (`output_version`)
Messages now expose provider-agnostic blocks via `message.content_blocks`. To serialize standard blocks back into the `content` attribute, opt in with `output_version="v1"` on the model or set the `LC_OUTPUT_VERSION=v1` environment variable. Provider-native format remains the default for `content` to preserve backward compatibility.

### Anthropic `max_tokens`
"The `max_tokens` parameter in `langchain-anthropic` now defaults to higher values based on the model chosen, rather than the previous default of `1024`."

### Message `.text` Property
".text" now operates as a property rather than method. The `.text()` method call syntax is deprecated.

### Removed `AIMessage.example`
"The `example` parameter has been removed from [`AIMessage`](reference...) objects" in favor of `additional_kwargs`.

## Minor Updates

- `AIMessageChunk` includes `chunk_position` attribute ('last' for final chunks)
- `LanguageModelOutputVar` typed to `AIMessage` instead of `BaseMessage`
- Improved message chunk merging logic with prioritized ID selection
- Files now open with UTF-8 encoding by default
- Standard tests use multimodal content blocks

## Reference Materials

- [v0.3 docs archived on GitHub](https://github.com/langchain-ai/langchain/tree/v0.3/docs/docs)
- [v0.3 API reference](https://reference.langchain.com/v0.3/python/)
