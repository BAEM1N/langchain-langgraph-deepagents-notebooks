# Short-term Memory

## Overview

Short-term memory enables AI applications to retain information from previous interactions within a single conversation thread. This capability is essential for agents handling complex tasks with numerous user interactions.

**Key concept:** "Memory is a system that remembers information about previous interactions."

The primary challenge involves managing conversation history within LLM context windows, as lengthy conversations can exceed token limits or degrade performance.

## Implementation

### Basic Setup

To add short-term memory to an agent, specify a `checkpointer` during agent creation:

```python
from langchain.agents import create_agent
from langgraph.checkpoint.memory import InMemorySaver

agent = create_agent(
    "gpt-5",
    tools=[get_user_info],
    checkpointer=InMemorySaver(),
)

agent.invoke(
    {"messages": [{"role": "user", "content": "Hi! My name is Bob."}]},
    {"configurable": {"thread_id": "1"}},
)
```

### Production Deployment

For production environments, use database-backed checkpointers:

```python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()
    agent = create_agent(
        "gpt-5",
        tools=[get_user_info],
        checkpointer=checkpointer,
    )
```

## Custom State Management

Extend `AgentState` to track additional information beyond conversation history:

```python
from langchain.agents import create_agent, AgentState

class CustomAgentState(AgentState):
    user_id: str
    preferences: dict

agent = create_agent(
    "gpt-5",
    tools=[get_user_info],
    state_schema=CustomAgentState,
    checkpointer=InMemorySaver(),
)
```

## Message Management Strategies

### Trim Messages

Reduce context by keeping only recent messages:

```python
from langchain.agents.middleware import before_model

@before_model
def trim_messages(state: AgentState, runtime: Runtime):
    messages = state["messages"]
    if len(messages) <= 3:
        return None
    # Keep first and last messages
    return {"messages": [messages[0]] + messages[-3:]}
```

### Delete Messages

Permanently remove messages from state:

```python
from langchain.messages import RemoveMessage

def delete_messages(state):
    messages = state["messages"]
    if len(messages) > 2:
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}
```

### Summarize Messages

Replace older messages with condensed summaries:

```python
from langchain.agents.middleware import SummarizationMiddleware

agent = create_agent(
    model="gpt-4.1",
    tools=[],
    middleware=[
        SummarizationMiddleware(
            model="gpt-4.1-mini",
            trigger=("tokens", 4000),
            keep=("messages", 20)
        )
    ],
    checkpointer=InMemorySaver(),
)
```

## Accessing Memory

### Within Tools

Access state through the `runtime` parameter:

```python
from langchain.tools import tool, ToolRuntime

@tool
def get_user_info(runtime: ToolRuntime) -> str:
    user_id = runtime.state["user_id"]
    return "User is John Smith" if user_id == "user_123" else "Unknown user"
```

### Dynamic Prompts

Reference state in middleware for context-aware system messages:

```python
from langchain.agents.middleware import dynamic_prompt

@dynamic_prompt
def dynamic_system_prompt(request: ModelRequest) -> str:
    user_name = request.runtime.context["user_name"]
    return f"You are helpful. Address user as {user_name}."
```

### Middleware Hooks

Process memory at specific execution points:

- **`@before_model`**: Modify messages before LLM calls
- **`@after_model`**: Filter or validate responses

---

**Important note:** Ensure resulting message histories remain valid for your LLM provider's requirements when deleting messages.
