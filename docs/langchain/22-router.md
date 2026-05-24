# Router Architecture Documentation

## Overview
The router pattern involves a routing step that classifies input and directs it to specialized agents. This approach works best when managing distinct knowledge domains requiring separate agent handling.

## Core Characteristics
- Query decomposition through classification
- Parallel invocation of zero or more specialized agents
- Result synthesis into coherent responses

## Use Cases
The router pattern suits scenarios with "distinct verticals (separate knowledge domains that each require their own agent)," parallel source querying, and synthesized result combining.

## Implementation Approaches

### Single Agent Routing
Using `Command` directs queries to one appropriate agent based on classification logic.

```python
from langgraph.types import Command

def route(state) -> Command:
    active_agent = classify(state["query"])
    return Command(goto=active_agent)
```

### Multiple Agent Routing (Parallel)
Using `Send` enables fan-out to multiple specialized agents simultaneously, with classifications determining which agents receive which queries.

```python
from langgraph.types import Command, Send

def route(state):
    classifications = classify(state["query"])  # [{"agent": "...", "query": "..."}, ...]
    return [Send(c["agent"], {"query": c["query"]}) for c in classifications]
```

## Architecture Modes

**Stateless**: Each request routes independently without memory between calls.

**Stateful**: Maintains conversation history across requests for multi-turn interactions.

### Stateful Implementation Options

1. **Tool Wrapper**: Wraps the stateless router as a tool within a conversational agent, keeping the router simple while the main agent manages memory.

2. **Full Persistence**: The router maintains state directly, storing message history and selectively including prior context when routing to agents.

## Router vs. Supervisor

The documentation distinguishes these patterns:

- A **router** is "a dedicated routing step (often a single LLM call or rule-based logic) that classifies the input and dispatches to agents." It is preprocessing without built-in conversation awareness.
- A **supervisor** is "a main agent dynamically deciding which subagents to call as part of an ongoing conversation," maintaining context across turns and orchestrating complex workflows.

Use a router when you have clear input categories and want deterministic or lightweight classification. Use a supervisor (the Subagents pattern) when you need flexible, conversation-aware orchestration where the LLM decides what to do next based on evolving context.
