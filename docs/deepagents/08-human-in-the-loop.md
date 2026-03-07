# Human-in-the-Loop

## Overview
Human-in-the-loop enables approval workflows that pause agent execution when sensitive tool operations require verification before proceeding.

## Key Configuration

The `interrupt_on` parameter controls which tools need approval:

- **`True`**: Enable interrupts with default options (approve, edit, reject)
- **`False`**: Disable interrupts
- **Custom dict**: Specify allowed decision types

## Decision Types

Users can take three actions when reviewing pending tool calls:

1. **Approve** – Execute with original arguments
2. **Edit** – Modify arguments before execution
3. **Reject** – Skip the tool call entirely

## Implementation Requirements

A checkpointer is **REQUIRED** for human-in-the-loop workflows. The `MemorySaver` or equivalent persists agent state between interrupt and resume cycles.

## Handling Interrupts

When triggered, agents return `result["__interrupt__"]` containing pending actions. Developers then:

1. Extract action details and allowed decisions
2. Collect user input for each action
3. Resume using `Command(resume={"decisions": [...]})` with the same thread ID

## Multiple Tool Calls

If an agent proposes multiple tools requiring approval, all interrupts batch together. Developers must provide one decision per action in matching order.

## Subagent Support

Each subagent can override the parent agent's `interrupt_on` settings. Subagents can also call `interrupt()` directly within tool implementations to request mid-execution approvals.

## Best Practices

- Always use a checkpointer for state persistence
- Maintain consistent thread IDs across interrupt and resume calls
- Align decision lists with action request order
- Configure interrupts based on operational risk levels
