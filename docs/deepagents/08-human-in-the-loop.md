# Human-in-the-Loop

## Overview
Human-in-the-loop enables approval workflows that pause agent execution when sensitive tool operations require verification before proceeding.

## Key Configuration

The `interrupt_on` parameter maps tool names to interrupt settings with three options:

```python
interrupt_on = {
    "tool_name": True,                                       # Default: all decisions allowed
    "tool_name": False,                                      # No interrupts
    "tool_name": {"allowed_decisions": ["approve", "reject"]}  # Custom subset
}
```

## Decision Types

Four human approval decisions are supported when reviewing pending tool calls:

1. **`approve`** – Execute the tool with the original arguments as proposed by the agent
2. **`edit`** – Modify the tool arguments before execution
3. **`reject`** – Skip executing this tool call entirely
4. **`respond`** – Return the human's message as a successful synthetic tool result for an "ask user" style tool

Use `reject` to deny side effects. Use `respond` only when the human intentionally acts as the tool, such as answering an `ask_user` prompt; otherwise the agent can mistake a denial message for a successful operation.

## Implementation Requirements

A checkpointer is **REQUIRED** for human-in-the-loop workflows. The `MemorySaver` or equivalent persists agent state between interrupt and resume cycles.

```python
from langgraph.checkpoint.memory import MemorySaver
checkpointer = MemorySaver()
```

All invoke calls require `version="v2"` for interrupt support.

## Handling Interrupts

When triggered, the result exposes pending actions via `result.interrupts`. Each entry's `interrupt_value["action_requests"]` lists the proposed tool calls along with their `allowed_decisions`. Developers then:

1. Extract action details and allowed decisions from `interrupt_value["action_requests"]`
2. Collect user input for each action
3. Resume using `Command(resume={"decisions": [...]})` with the same thread ID

### Resume Formats by Decision Type

```python
# Approve as-is
Command(resume={"decisions": [{"type": "approve"}]})

# Edit before execution
Command(resume={"decisions": [{
    "type": "edit",
    "edited_action": {
        "name": "tool_name",
        "args": {"param": "new_value"},
    },
}]})

# Reject the call
Command(resume={"decisions": [{"type": "reject"}]})

# Answer an ask_user tool with a synthetic result
Command(resume={"decisions": [{"type": "respond", "message": "Blue."}]})
```

The same `config` (identical `thread_id`) must be reused for both the initial invocation and the resume call.

## Multiple Tool Calls

If an agent proposes multiple tools requiring approval, all interrupts batch together. Developers must provide one decision per action in matching order.

## Subagent Support

Each subagent can override the parent agent's `interrupt_on` settings. Subagents can also call `interrupt()` directly within tool implementations to request mid-execution approvals.

## Best Practices

- Always use a checkpointer for state persistence
- Maintain consistent thread IDs across interrupt and resume calls
- Align decision lists with action request order
- Configure interrupts based on operational risk levels
- Reject denied side effects; reserve respond for human-as-tool answers
