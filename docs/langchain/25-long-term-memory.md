# Long-term Memory in LangChain

## Overview
LangChain agents leverage "LangGraph persistence to enable long-term memory," which represents an advanced capability requiring LangGraph knowledge.

## Store Options

| Store | Install | Use case |
|---|---|---|
| `InMemoryStore` | included with `langgraph` | development, tests, ephemeral demos |
| `PostgresStore` | `pip install langgraph-checkpoint-postgres` | production, durable cross-process storage |

`InMemoryStore` keeps data in a Python dict and is wiped on process exit. The PostgreSQL store persists data across processes and supports concurrent agents, vector similarity search, and operational tooling.

> **Required wiring:** the store instance must be passed to `create_agent(store=store, ...)`. If it is not, tools that call `runtime.store` will not have access to long-term memory.

## Memory Storage Architecture
The system organizes memories as JSON documents in a store using hierarchical organization. Each memory occupies a custom namespace (organizing folder) and distinct key (file identifier). Namespaces typically incorporate user or organization IDs — passed via a **context schema** — for easier information management. Stores also support **vector similarity** and content-based search via `store.search(...)` when an embedding index is configured.

**Key Implementation:**
```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": embed, "dims": 2})
namespace = (user_id, application_context)
store.put(namespace, "a-memory", {"rules": [...], "my-key": "my-value"})
item = store.get(namespace, "a-memory")
items = store.search(namespace, filter={"my-key": "my-value"}, query="language preferences")
```

## End-to-end Example: Read + Write with Context Schema

```python
from dataclasses import dataclass
from langchain.agents import create_agent
from langchain.tools import ToolRuntime, tool
from langchain_core.runnables import Runnable
from langgraph.store.memory import InMemoryStore
from typing_extensions import TypedDict

store = InMemoryStore()

@dataclass
class Context:
    user_id: str

class UserInfo(TypedDict):
    name: str
    language: str

@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[Context]) -> str:
    """Save user info."""
    assert runtime.store is not None
    runtime.store.put(("users",), runtime.context.user_id, dict(user_info))
    return "Successfully saved user info."

@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    """Look up user info."""
    assert runtime.store is not None
    user_info = runtime.store.get(("users",), runtime.context.user_id)
    return str(user_info.value) if user_info else "Unknown user"

agent: Runnable = create_agent(
    model="anthropic:claude-sonnet-4-6",
    tools=[save_user_info, get_user_info],
    store=store,
    context_schema=Context,
)

agent.invoke(
    {"messages": [{"role": "user", "content": "My name is Alice and I speak French"}]},
    context=Context(user_id="user_456"),
)
```

The user/organization identifier travels through the `context_schema` rather than through tool arguments, which keeps the LLM-visible tool signatures clean and lets the agent author centrally control multi-tenant isolation.

## Reading Long-term Memory via Tools
Agents access stored user information through tools utilizing `ToolRuntime[Context]`:

```python
@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    user_info = runtime.store.get(("users",), runtime.context.user_id)
    return str(user_info.value) if user_info else "Unknown user"

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[get_user_info],
    store=store,
    context_schema=Context,
)
```

## Writing Long-term Memory from Tools
Agents can update stored information through tool parameters. Cast typed inputs (`TypedDict`, dataclass) to `dict` before passing to `store.put(...)`:

```python
@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[Context]) -> str:
    runtime.store.put(("users",), runtime.context.user_id, dict(user_info))
    return "Successfully saved user info."
```

**Production Note:** Replace `InMemoryStore` with a DB-backed store such as `PostgresStore` (`pip install langgraph-checkpoint-postgres`) for production deployments.
