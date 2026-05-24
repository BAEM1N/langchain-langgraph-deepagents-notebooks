# Handoffs Architecture Documentation

## Overview

The handoffs pattern enables dynamic behavior changes in multi-agent systems by using tools to update state variables that persist across conversation turns. This approach supports both agent transitions and dynamic configuration adjustments.

## Core Concept

Behavior changes based on a state variable (e.g., `current_step` or `active_agent`) with tools managing state updates to move between workflow stages.

## Key Characteristics

- **State-driven behavior**: Configuration adjusts based on tracked state variables
- **Tool-based transitions**: Tools return `Command` objects updating state
- **Direct user interaction**: Each state handles messages independently
- **Persistent state**: State survives across conversation turns

## Implementation Approaches

### Single Agent with Middleware

A single agent dynamically adjusts behavior through middleware that intercepts model calls. Middleware applies different system prompts and tool sets based on the current state variable. This approach is recommended for most scenarios due to its simplicity.

Use the `@wrap_model_call` decorator and `request.override(...)` to swap the system prompt and tool set per state:

```python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def dynamic_behavior(request, handler):
    step = request.state.get("current_step", "intake")
    if step == "intake":
        request = request.override(
            system_prompt="You are collecting customer info.",
            tools=[ask_name, ask_issue],
        )
    elif step == "resolve":
        request = request.override(
            system_prompt="You are resolving the customer's issue.",
            tools=[lookup_account, refund],
        )
    return handler(request)
```

Handoff tools receive `ToolRuntime[None, SupportState]` as a parameter, giving access to `runtime.tool_call_id`. That id must be echoed back in the returned `ToolMessage`:

```python
from langchain.tools import tool, ToolRuntime
from langgraph.types import Command
from langchain_core.messages import ToolMessage

@tool
def transfer_to_resolve(runtime: ToolRuntime[None, SupportState]) -> Command:
    return Command(update={
        "current_step": "resolve",
        "messages": [ToolMessage(
            content="Transferred to resolve step",
            tool_call_id=runtime.tool_call_id,
        )],
    })
```

### Multiple Agent Subgraphs

Distinct agents operate as separate graph nodes. Handoff tools use `Command.PARENT` to navigate between agents. This requires careful "context engineering" to ensure valid conversation history flows between agents.

When handing off between subgraph agents, the receiving agent must see a valid conversation. Flow exactly two messages across the handoff:

1. The `AIMessage` from the source agent that contains the original tool call.
2. A `ToolMessage` acknowledging the handoff (with matching `tool_call_id`).

Anything more or less leaves the receiving agent with malformed history that the LLM will reject.

## Critical Implementation Detail

When tools update messages via `Command`, include a `ToolMessage` with matching `tool_call_id`. This requirement ensures the conversation history becomes valid rather than malformed, as LLMs expect paired tool calls and responses.

## When to Choose Subgraphs

Prefer the single-agent-with-middleware approach for most handoff use cases — it is simpler. Reserve multiple agent subgraphs for cases where each node is a bespoke, complex graph in its own right (for example, an agent with built-in reflection or retrieval steps as internal nodes).

## When to Use

This pattern suits scenarios requiring sequential constraints, direct user conversation across states, or multi-stage flows -- particularly customer support workflows needing information collected in specific sequences.
