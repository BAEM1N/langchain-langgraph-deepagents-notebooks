# Human-in-the-Loop Documentation

## Overview

The HITL middleware enables human oversight of agent tool calls by pausing execution when actions require review -- such as file writes or SQL execution. The system saves state using LangGraph's persistence layer, allowing safe pauses and resumptions.

## Decision Types

The middleware supports three response mechanisms:

1. **Approve** - The action is approved as-is and executed without changes
2. **Edit** - Tool calls execute with modifications made by the reviewer
3. **Reject** - Actions are declined with explanatory feedback added to conversation

## Configuration

Setup requires:
- Adding `HumanInTheLoopMiddleware` to the agent's middleware list
- Mapping tool names to approval policies (True/False or custom config)
- Configuring a checkpointer (InMemorySaver for testing; AsyncPostgresSaver for production)
- Providing a thread ID when invoking the agent

Key configuration parameters include `interrupt_on` (tool-to-policy mapping) and `description_prefix` for interrupt messages.

## Resumption Process

After interruption occurs, resume using `Command(resume={"decisions": [...]})` with the same thread ID. Each action requires a corresponding decision in matching order.

## Streaming Support

Use `stream()` with `stream_mode=['updates', 'messages']` to monitor agent progress and handle interrupts in real-time, enabling token-by-token output alongside interrupt detection.

## Important Consideration

When editing tool arguments, make changes conservatively. Significant modifications to the original arguments may cause the model to re-evaluate its approach and potentially execute the tool multiple times.
