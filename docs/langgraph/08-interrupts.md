# LangGraph Interrupts Documentation

## Overview

Interrupts enable pausing graph execution at specific points to await external input, facilitating human-in-the-loop workflows. When triggered, LangGraph persists the graph state and waits indefinitely until execution resumes.

## Core Concepts

**Key Features:**
- "Checkpointing keeps your place: the checkpointer writes the exact graph state"
- Thread IDs function as persistent cursors for resuming checkpoints
- Interrupt payloads surface in the `__interrupt__` field of results

## Implementation Basics

### Using the `interrupt()` Function

The interrupt function pauses execution and returns a value to the caller. Required components:
1. A checkpointer for state persistence
2. A thread ID in configuration
3. JSON-serializable interrupt payload

```python
from langgraph.types import interrupt

def approval_node(state: State):
    approved = interrupt("Do you approve this action?")
    return {"approved": approved}
```

### Resuming Execution

Resume using `Command(resume=...)` with the same thread ID:

```python
config = {"configurable": {"thread_id": "thread-1"}}
result = graph.invoke({"input": "data"}, config=config)
print(result["__interrupt__"])

graph.invoke(Command(resume=True), config=config)
```

## Common Patterns

### Approval Workflows
Pause before critical actions like API calls or database changes, routing based on approval decisions.

### Review and Edit
Allow humans to review and modify LLM outputs before proceeding.

### Tool Interrupts
Place interrupts within tool functions to pause before execution, enabling approval and editing of tool calls.

### Input Validation
Use multiple interrupt calls in loops to validate human input, re-prompting with clearer messages for invalid data.

### Multiple Interrupts
Map each interrupt ID to resume values when parallel branches interrupt simultaneously.

## Critical Rules

**Do Not:**
- Wrap interrupt calls in bare try/except blocks (catches the interrupt exception)
- Reorder or conditionally skip interrupt calls within nodes
- Pass non-serializable objects (functions, class instances)
- Perform non-idempotent operations before interrupts

**Do:**
- Separate interrupt logic from error-prone code
- Keep interrupt call order consistent across executions
- Use simple, JSON-serializable types
- Place side effects after interrupts or in separate nodes

## Debugging

Static interrupts serve as breakpoints for testing. Set them at compile time or runtime:

```python
graph = builder.compile(
    interrupt_before=["node_a"],
    interrupt_after=["node_b"],
    checkpointer=checkpointer
)
```

LangSmith Studio provides UI-based interrupt configuration and state inspection.
