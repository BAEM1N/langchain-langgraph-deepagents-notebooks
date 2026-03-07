# Memory in LangGraph - Complete Documentation

## Overview

AI applications require memory to maintain context across interactions. LangGraph supports two memory types:

1. **Short-term memory**: Thread-level persistence for multi-turn conversations
2. **Long-term memory**: User/application-specific data persisting across sessions

---

## Short-Term Memory

### Basic Implementation

Short-term memory enables agents to track multi-turn conversations using checkpointers.

**In-memory example:**
```python
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph

checkpointer = InMemorySaver()
builder = StateGraph(...)
graph = builder.compile(checkpointer=checkpointer)

graph.invoke(
    {"messages": [{"role": "user", "content": "hi! i am Bob"}]},
    {"configurable": {"thread_id": "1"}},
)
```

### Production Implementations

#### PostgreSQL
```python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    builder = StateGraph(...)
    graph = builder.compile(checkpointer=checkpointer)
```

**Setup requirement:** Call `checkpointer.setup()` on first use.

#### MongoDB
```python
from langgraph.checkpoint.mongodb import MongoDBSaver

DB_URI = "localhost:27017"
with MongoDBSaver.from_conn_string(DB_URI) as checkpointer:
    builder = StateGraph(...)
    graph = builder.compile(checkpointer=checkpointer)
```

#### Redis
```python
from langgraph.checkpoint.redis import RedisSaver

DB_URI = "redis://localhost:6379"
with RedisSaver.from_conn_string(DB_URI) as checkpointer:
    builder = StateGraph(...)
    graph = builder.compile(checkpointer=checkpointer)
```

### Subgraph Persistence

Provide checkpointer only to parent graphs; LangGraph automatically propagates to subgraphs:

```python
checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)
```

Configure subgraph-specific behavior:
```python
subgraph = subgraph_builder.compile(checkpointer=True)
```

---

## Long-Term Memory

Long-term memory stores persistent user-specific or application-level data.

### Basic Setup

```python
from langgraph.store.memory import InMemoryStore
from langgraph.graph import StateGraph

store = InMemoryStore()
builder = StateGraph(...)
graph = builder.compile(store=store)
```

### Accessing Store in Nodes

Access the store via the `Runtime` object:

```python
from dataclasses import dataclass
from langgraph.runtime import Runtime
from langgraph.graph import StateGraph, MessagesState, START
import uuid

@dataclass
class Context:
    user_id: str

async def call_model(state: MessagesState, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    namespace = (user_id, "memories")

    # Search memories
    memories = await runtime.store.asearch(
        namespace, query=state["messages"][-1].content, limit=3
    )
    info = "\n".join([d.value["data"] for d in memories])

    # Store new memory
    await runtime.store.aput(
        namespace, str(uuid.uuid4()), {"data": "User prefers dark mode"}
    )

builder = StateGraph(MessagesState, context_schema=Context)
builder.add_node(call_model)
graph = builder.compile(store=store)

graph.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    {"configurable": {"thread_id": "1"}},
    context=Context(user_id="1"),
)
```

### Production Implementations

#### PostgreSQL Store
```python
from langgraph.store.postgres import PostgresStore

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresStore.from_conn_string(DB_URI) as store:
    builder = StateGraph(...)
    graph = builder.compile(store=store)
```

#### Redis Store
```python
from langgraph.store.redis import RedisStore

DB_URI = "redis://localhost:6379"
with RedisStore.from_conn_string(DB_URI) as store:
    graph = builder.compile(store=store)
```

### Semantic Search

Enable semantic search for memory retrieval:

```python
from langchain.embeddings import init_embeddings
from langgraph.store.memory import InMemoryStore

embeddings = init_embeddings("openai:text-embedding-3-small")
store = InMemoryStore(
    index={
        "embed": embeddings,
        "dims": 1536,
    }
)

store.put(("user_123", "memories"), "1", {"text": "I love pizza"})
store.put(("user_123", "memories"), "2", {"text": "I am a plumber"})

items = store.search(
    ("user_123", "memories"), query="I'm hungry", limit=1
)
```

---

## Managing Short-Term Memory

Long conversations can exceed LLM context limits. Solutions include:

### Trim Messages

Use `trim_messages` to remove excess messages based on token count:

```python
from langchain_core.messages.utils import trim_messages, count_tokens_approximately

def call_model(state: MessagesState):
    messages = trim_messages(
        state["messages"],
        strategy="last",
        token_counter=count_tokens_approximately,
        max_tokens=128,
        start_on="human",
        end_on=("human", "tool"),
    )
    response = model.invoke(messages)
    return {"messages": [response]}
```

### Delete Messages

Remove specific messages using `RemoveMessage`:

```python
from langchain.messages import RemoveMessage

def delete_messages(state):
    messages = state["messages"]
    if len(messages) > 2:
        return {"messages": [RemoveMessage(id=m.id) for m in messages[:2]]}
```

Remove all messages:
```python
from langgraph.graph.message import REMOVE_ALL_MESSAGES

def delete_messages(state):
    return {"messages": [RemoveMessage(id=REMOVE_ALL_MESSAGES)]}
```

### Summarize Messages

Summarize conversation history to preserve information:

```python
class State(MessagesState):
    summary: str

def summarize_conversation(state: State):
    summary = state.get("summary", "")

    if summary:
        summary_message = f"Summary: {summary}\n\nExtend the summary:"
    else:
        summary_message = "Create a summary:"

    messages = state["messages"] + [HumanMessage(content=summary_message)]
    response = model.invoke(messages)

    delete_messages = [RemoveMessage(id=m.id) for m in state["messages"][:-2]]
    return {"summary": response.content, "messages": delete_messages}
```

---

## Managing Checkpoints

### View Thread State

```python
config = {"configurable": {"thread_id": "1"}}
graph.get_state(config)
```

### View Thread History

```python
config = {"configurable": {"thread_id": "1"}}
list(graph.get_state_history(config))
```

### Delete Thread Checkpoints

```python
thread_id = "1"
checkpointer.delete_thread(thread_id)
```

---

## Database Management

Database-backed implementations require schema migrations. Most use a `setup()` method:

```python
checkpointer.setup()
store.setup()
```

Run migrations as dedicated deployment steps or during server startup.
