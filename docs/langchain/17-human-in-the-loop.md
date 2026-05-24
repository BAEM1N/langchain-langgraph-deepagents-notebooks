# Human-in-the-Loop Documentation

## Overview

The HITL middleware enables human oversight of agent tool calls by pausing execution when actions require review -- such as file writes or SQL execution. The system saves state using LangGraph's persistence layer, allowing safe pauses and resumptions.

## Decision Types

The middleware supports four response mechanisms:

1. **Approve** - The action is approved as-is and executed without changes
2. **Edit** - Tool calls execute with modifications made by the reviewer (`{"edited_action": {"name": "...", "args": {...}}}`)
3. **Reject** - Actions are declined with explanatory feedback added to conversation (via `"message"`)
4. **Respond** - Tool execution is skipped and the human's message becomes the tool result. Used for "ask user" style tools where the human reply is returned directly to the agent.

## Configuration

Setup requires:
- Adding `HumanInTheLoopMiddleware` to the agent's middleware list
- Mapping tool names to approval policies (True/False or a dict like `{"allowed_decisions": [...]}`)
- Configuring a checkpointer (InMemorySaver for testing; AsyncPostgresSaver for production)
- Providing a thread ID when invoking the agent

Key configuration parameters include `interrupt_on` (tool-to-policy mapping) and `description_prefix` for interrupt messages.

```python
from langchain.agents.middleware import HumanInTheLoopMiddleware

middleware = HumanInTheLoopMiddleware(
    interrupt_on={
        "write_file": True,                                    # all decisions allowed
        "execute_sql": {"allowed_decisions": ["approve", "reject"]},
        "read_data": False,                                    # auto-approve
    },
    description_prefix="Tool execution pending approval",
)
```

## Invocation with `version="v2"`

`invoke` and `stream` accept an explicit `version="v2"` parameter. v2 returns a `GraphOutput` (with `.interrupts` and `.value` attributes) and is required for the `Command(resume={"decisions": [...]})` resume pattern below.

```python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={"configurable": {"thread_id": "thread_id"}},
    version="v2",
)
```

## Execution Lifecycle

The middleware runs an `after_model` hook that:

1. Inspects the model-generated tool calls.
2. Builds a `HITLRequest` object containing `action_requests` and `review_configs`.
3. Calls `interrupt` to pause execution and surface the request to the reviewer.
4. Processes the returned `HITLResponse` decisions and resumes with approved/edited/rejected/responded actions.

## Resumption Process

After an interruption occurs, resume using `Command(resume={"decisions": [...]})` with the same thread ID under `version="v2"`. Each action requires a corresponding decision in matching order.

```python
from langgraph.types import Command

agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
    version="v2",
)
```

## Streaming Support

Use `stream()` with `stream_mode=['updates', 'messages']` and `version="v2"` to monitor agent progress and handle interrupts in real-time, enabling token-by-token output alongside interrupt detection.

```python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode=["updates", "messages"],
    version="v2",
):
    ...
```

## Important Consideration

When editing tool arguments, make changes conservatively. Significant modifications to the original arguments may cause the model to re-evaluate its approach and potentially execute the tool multiple times.
