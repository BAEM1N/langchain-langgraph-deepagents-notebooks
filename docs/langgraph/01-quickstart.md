# LangGraph Calculator Agent Quickstart

## Overview
This documentation demonstrates building a calculator agent using LangGraph's Graph API or Functional API. Both approaches use Claude Sonnet 4.5 and implement tools for arithmetic operations.

## Key Setup Requirement
Users must obtain an Anthropic API key and set the `ANTHROPIC_API_KEY` environment variable before proceeding.

## Graph API Approach

### Components
**Tools Definition**: The implementation includes three decorated functions -- multiply, add, and divide -- each with type hints and docstrings describing their parameters and operations.

**State Management**: A `MessagesState` TypedDict stores both conversation messages (using `Annotated` with `operator.add` for list concatenation) and an LLM call counter.

**Nodes**:
- The LLM call node invokes the model with a system prompt instructing it to perform arithmetic
- The tool node executes selected functions and returns `ToolMessage` objects with results

**Routing Logic**: A conditional edge function examines whether the LLM generated tool calls, directing flow either to the tool node or to completion.

**Compilation**: The workflow is built via `StateGraph`, connecting nodes with edges, then compiled into an executable agent.

## Functional API Approach

### Streamlined Structure
Rather than explicitly defining nodes and edges, the functional approach uses standard Python control flow within an `@entrypoint()` decorated function.

**Task Functions**: Both `@task` decorated functions (call_llm and call_tool) execute asynchronously, with results retrieved via `.result()`.

**Agent Loop**: The main function calls the LLM, then enters a loop checking for tool calls. If present, it executes them concurrently, updates messages, and requests another LLM response. Upon completion, it returns the full message history.

## Invocation
Both approaches invoke agents by passing a `HumanMessage` and either calling `.invoke()` (Graph API) or `.stream()` (Functional API).
