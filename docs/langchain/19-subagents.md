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

**Asynchronous**: Main agent continues while subagent works backgrounded -- use for independent tasks with a job ID/status/result pattern.

## Tool Patterns

**Tool per agent**: Fine-grained control with separate wrapped subagents.

**Single dispatch tool**: One parameterized tool invoking registered subagents by name -- better for distributed teams and scalability.

## Context Engineering

Control information flow through subagent specifications (names/descriptions), customized inputs (pulling from agent state), and formatted outputs (using Commands for additional state).
