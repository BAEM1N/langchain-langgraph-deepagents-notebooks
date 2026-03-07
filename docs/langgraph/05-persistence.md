# LangGraph Persistence Documentation

## Overview

LangGraph implements persistence through **checkpointers**, which save graph state snapshots at each super-step. These checkpoints are stored in **threads** (identified by unique IDs), enabling powerful capabilities like human-in-the-loop workflows, conversation memory, time travel debugging, and fault tolerance.

## Core Concepts

### Threads
A thread is a unique identifier that groups related checkpoint executions. When invoking a graph with persistence, you must specify a `thread_id` in the config's configurable section:

```python
{"configurable": {"thread_id": "1"}}
```

Threads store the accumulated state across multiple runs, allowing state retrieval and resumption after interruptions.

### Checkpoints
A checkpoint represents a graph state snapshot at a specific moment, captured as a `StateSnapshot` object containing:

- **config**: Associated configuration details
- **metadata**: Checkpoint metadata
- **values**: Current state channel values
- **next**: Node names to execute next
- **tasks**: Upcoming `PregelTask` objects with execution information

## Key Operations

### Getting State

**Latest state retrieval:**
```python
config = {"configurable": {"thread_id": "1"}}
graph.get_state(config)
```

**Specific checkpoint retrieval:**
```python
config = {"configurable": {"thread_id": "1", "checkpoint_id": "..."}}
graph.get_state(config)
```

### State History

Access complete execution history for a thread:
```python
config = {"configurable": {"thread_id": "1"}}
list(graph.get_state_history(config))
```

Returns `StateSnapshot` objects ordered chronologically, with most recent first.

### Replay Mechanism

Replay prior executions by specifying both `thread_id` and `checkpoint_id`:

```python
config = {"configurable": {"thread_id": "1", "checkpoint_id": "..."}}
graph.invoke(None, config=config)
```

"LangGraph knows whether a particular step has been executed previously. If it has, LangGraph simply *re-plays* that particular step in the graph and does not re-execute."

### Updating State

Modify graph state using `update_state()`:

```python
graph.update_state(config, {"foo": 2, "bar": ["b"]})
```

**Important**: Channels with reducers merge values; channels without reducers are overwritten. You can optionally specify `as_node` to control which node executes next.

## Memory Store

The `Store` interface enables information sharing **across threads**, complementing checkpointers which are thread-specific.

### Basic Usage

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
user_id = "1"
namespace = (user_id, "memories")

# Save memory
memory_id = str(uuid.uuid4())
store.put(namespace, memory_id, {"food_preference": "I like pizza"})

# Retrieve memories
memories = store.search(namespace)
```

Each stored item has `value`, `key`, `namespace`, `created_at`, and `updated_at` attributes.

### Semantic Search

Enable meaning-based memory retrieval with embeddings:

```python
from langchain.embeddings import init_embeddings

store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["food_preference", "$"]
    }
)

memories = store.search(namespace, query="What does the user like to eat?", limit=3)
```

### Using Store in LangGraph

Compile graphs with both checkpointer and store:

```python
builder = StateGraph(MessagesState, context_schema=Context)
graph = builder.compile(checkpointer=checkpointer, store=store)
```

Access the store in nodes via injected `Runtime`:

```python
from langgraph.runtime import Runtime

async def update_memory(state: MessagesState, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    namespace = (user_id, "memories")
    await runtime.store.aput(namespace, memory_id, {"memory": memory})
```

## Checkpointer Libraries

LangGraph provides multiple checkpointer implementations:

- **langgraph-checkpoint**: Base interface and `InMemorySaver` (included by default)
- **langgraph-checkpoint-sqlite**: `SqliteSaver` and `AsyncSqliteSaver` for local development
- **langgraph-checkpoint-postgres**: Production-grade `PostgresSaver` implementations
- **langgraph-checkpoint-cosmosdb**: Azure Cosmos DB support with sync/async variants

### Interface Methods

All checkpointers implement `BaseCheckpointSaver` with methods:
- `.put`: Store checkpoints
- `.put_writes`: Store intermediate writes (pending writes)
- `.get_tuple`: Fetch checkpoint by configuration
- `.list`: List matching checkpoints

Async versions (`.aput`, `.aput_writes`, `.aget_tuple`, `.alist`) are available for asynchronous execution.

### Serialization

The default `JsonPlusSerializer` handles most types. For unsupported objects (e.g., Pandas dataframes):

```python
from langgraph.checkpoint.serde.jsonplus import JsonPlusSerializer

checkpointer = InMemorySaver(serde=JsonPlusSerializer(pickle_fallback=True))
```

### Encryption

Enable state encryption using `EncryptedSerializer`:

```python
from langgraph.checkpoint.serde.encrypted import EncryptedSerializer

serde = EncryptedSerializer.from_pycryptodome_aes()  # reads LANGGRAPH_AES_KEY
checkpointer = SqliteSaver(connection, serde=serde)
```

## Capabilities Enabled by Persistence

**Human-in-the-loop**: Inspect, interrupt, and approve graph steps with state access at any point.

**Conversation memory**: Retain context across multiple interactions within threads while sharing user-level data via stores.

**Time travel**: Replay executions, review specific steps, fork state at arbitrary checkpoints for alternative trajectories.

**Fault tolerance**: "When a graph node fails mid-execution at a given superstep, LangGraph stores pending checkpoint writes from any other nodes that completed successfully" for recovery without re-running successful nodes.
