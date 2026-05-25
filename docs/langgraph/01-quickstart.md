# LangGraph Calculator Agent Quickstart

## Overview
This documentation demonstrates building a calculator agent using LangGraph's Graph API or Functional API. Both approaches use `gpt-5.4` (initialized via `init_chat_model` with `temperature=0`) and implement tools for arithmetic operations.

### Canonical Imports (v1)

```python
from langchain.tools import tool
from langchain.chat_models import init_chat_model
from langchain.messages import AnyMessage, SystemMessage, ToolMessage, HumanMessage, ToolCall
from langchain_core.messages import BaseMessage
from langgraph.graph import StateGraph, START, END, add_messages
# Functional API
from langgraph.func import entrypoint, task
```

## Key Setup Requirement
Users must obtain a Claude API key and set the `ANTHROPIC_API_KEY` environment variable before proceeding.

## Graph API Approach

### Components
**Tools Definition**: The implementation includes three decorated functions -- multiply, add, and divide -- each with type hints and docstrings describing their parameters and operations.

**State Management**: A `MessagesState` TypedDict stores both conversation messages (`Annotated[list[AnyMessage], operator.add]` so updates append rather than replace) and an `llm_calls: int` counter.

**Nodes**:
- `llm_call(state: dict)` invokes `model_with_tools` with a `SystemMessage` system prompt prepended to `state["messages"]`, and increments `llm_calls`
- `tool_node(state: dict)` iterates over `state["messages"][-1].tool_calls`, dispatches each call through `tools_by_name`, and returns `ToolMessage(content=..., tool_call_id=...)` results

**Routing Logic**: `should_continue(state) -> Literal["tool_node", END]` inspects the last message's `tool_calls`; it returns `"tool_node"` when present and `END` otherwise. It is wired via `add_conditional_edges("llm_call", should_continue, ["tool_node", END])`.

**Compilation**: The workflow is built via `StateGraph(MessagesState)`, connecting nodes with `add_edge` / `add_conditional_edges`, then compiled with `.compile()` into an executable agent.

## Functional API Approach

### Streamlined Structure
Rather than explicitly defining nodes and edges, the functional approach uses standard Python control flow within an `@entrypoint()` decorated function.

**Task Functions**: Both `@task` decorated functions return futures when invoked — `call_llm(messages: list[BaseMessage])` and `call_tool(tool_call: ToolCall)` — and results are retrieved via `.result()`. Inside `call_tool`, the entire `tool_call` dict is passed to `tool.invoke(tool_call)` so the runtime wraps the output into a `ToolMessage` automatically.

**Agent Loop**: The `@entrypoint()` function calls the LLM, then enters a `while True` loop checking `model_response.tool_calls`. If present, it fans out `call_tool(...)` for each tool call in parallel, gathers results via `.result()`, merges them into `messages` with `add_messages(messages, [model_response, *tool_results])`, and requests another LLM response. Upon completion, it appends the final `model_response` and returns the full message history.

## Invocation
Both approaches invoke agents by passing a `HumanMessage`. The Graph API typically uses `.invoke({"messages": [...]})` returning the final state, while the Functional API accepts the message list directly and can use `.stream(messages, stream_mode="updates")` to yield incremental chunks.
