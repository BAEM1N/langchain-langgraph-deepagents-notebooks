# Long-term Memory in LangChain

## Overview
LangChain agents leverage "LangGraph persistence to enable long-term memory," which represents an advanced capability requiring LangGraph knowledge.

## Memory Storage Architecture
The system organizes memories as JSON documents in a store using hierarchical organization. Each memory occupies a custom namespace (organizing folder) and distinct key (file identifier). Namespaces typically incorporate user or organization IDs for easier information management.

**Key Implementation:**
```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(index={"embed": embed, "dims": 2})
namespace = (user_id, application_context)
store.put(namespace, "a-memory", {"rules": [...], "my-key": "my-value"})
item = store.get(namespace, "a-memory")
items = store.search(namespace, filter={"my-key": "my-value"}, query="language preferences")
```

## Reading Long-term Memory via Tools
Agents access stored user information through tools utilizing `ToolRuntime[Context]`:

```python
@tool
def get_user_info(runtime: ToolRuntime[Context]) -> str:
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

agent = create_agent(model="claude-sonnet-4-6", tools=[get_user_info], store=store)
```

## Writing Long-term Memory from Tools
Agents can update stored information through tool parameters:

```python
@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[Context]) -> str:
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

**Production Note:** Replace `InMemoryStore` with "a DB-backed store in production use."
