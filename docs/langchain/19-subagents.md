# Subagents Architecture Documentation

## Overview

The subagents pattern features a central supervisor agent that coordinates specialized worker agents by invoking them as tools. This architecture maintains conversation memory centrally while keeping subagents stateless, providing context isolation: each subagent invocation works in a clean context window, preventing context bloat.

## Key Characteristics

- **Centralized control**: All routing flows through the main agent
- **No direct user interaction**: Subagents return results to the supervisor (though interrupts enable mid-task user interaction)
- **Tool-based invocation**: Subagents function as callable tools
- **Parallel execution**: Multiple subagents can be invoked in a single turn

## When to Use This Pattern

Implement subagents when managing multiple distinct domains (calendar, email, CRM), subagents don't require direct user conversation, or you need centralized workflow management. For simpler scenarios with few tools, a single agent suffices.

## Basic Implementation

```python
from langchain.tools import tool
from langchain.agents import create_agent

subagent = create_agent(model="anthropic:claude-sonnet-4-20250514", tools=[...])

@tool("research", description="Research a topic and return findings")
def call_research_agent(query: str):
    result = subagent.invoke({"messages": [{"role": "user", "content": query}]})
    return result["messages"][-1].content

main_agent = create_agent(model="anthropic:claude-sonnet-4-20250514", tools=[call_research_agent])
```

## Design Decisions

Key choices include:
- **Sync vs. async execution**: Blocking vs. background processing
- **Tool patterns**: Individual tool per agent or single dispatch tool
- **Subagent specifications**: System prompts, enum constraints, or tool-based discovery
- **Input/output strategies**: Query-only vs. full context; result vs. full history

## Execution Modes

**Synchronous**: Main agent waits for completion before continuing -- use when results inform next actions.

**Asynchronous**: Main agent continues while subagent works backgrounded. Implement as a three-tool workflow:

1. **Start job** — launches the task and returns a job ID.
2. **Check status** — reports progress (`pending` / `running` / `completed` / `failed`).
3. **Get result** — retrieves the completed output once the job is done.

This keeps the supervisor responsive while subagents work independently.

## State Management

Subagents support two checkpointing modes:

- **Inherited (default)**: Each invocation runs in a fresh state, sharing the parent's checkpointer transparently. Supports interrupts and is safe for parallel execution.
- **Persistent (`checkpointer=True`)**: The subagent maintains its own conversation history across multiple calls. Use when a subagent needs to remember prior turns independently of the supervisor.

```python
subagent = create_agent(
    model="anthropic:claude-sonnet-4-20250514",
    tools=[...],
    checkpointer=True,   # opt in to subagent-local history
)
```

Note: `get_state` on subgraphs will not return nested agent state due to static discovery; inspect state from node functions during interrupts instead.

## Tool Patterns

**Tool per agent**: Fine-grained control with separate wrapped subagents.

**Single dispatch tool**: One parameterized tool invoking registered subagents by name -- better for distributed teams and scalability. Three approaches expose the available subagents to the dispatcher:

| Approach | Scope | Trade-off |
|---|---|---|
| **System prompt enumeration** | Under 10 agents, static registry | Simple; requires manual prompt updates |
| **Enum / `Literal` constraint** | Under 10 agents, type-safe | Schema-level validation without prompt bloat |
| **Tool-based discovery** | Large / dynamic registries | Progressive disclosure; more wiring complexity |

## Context Engineering

Control information flow through subagent specifications (names/descriptions), customized inputs (pulling from agent state), and formatted outputs.

### Injecting state with `ToolRuntime`

Use `ToolRuntime` to pull message history or other state keys into the subagent's input:

```python
from langchain.tools import tool, ToolRuntime

@tool
def call_subagent(query: str, runtime: ToolRuntime[None, CustomState]):
    # runtime.state exposes the parent agent's state
    messages = runtime.state["messages"]
    ...
```

### Returning `Command` for output formatting

Subagent tools can return a `Command` object to update parent state alongside the tool message — useful for surfacing intermediate artifacts or merging results back into shared state.
