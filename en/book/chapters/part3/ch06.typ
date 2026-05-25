// Auto-generated from 06_persistence_and_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Persistence and memory", subtitle: "checkpointer and memory store")

== Learning Objectives

Store state with checkpointer and implement long-term memory with store.

- _checkpointer_: Automatically save and restore state of each execution step.
- _state lookup_: Check state saved as `get_state()` and `get_state_history()`
- _state Modification_: Change state externally with `update_state()`.
- _Thread Independence_: Different `thread_id` are completely independent state
- _InMemoryStore_: long-term memory shared between threads (standalone and graph integration)
- _Conversation length management_: Message management with `trim_messages` and `RemoveMessage`
- _Durable Execution_: resume at last checkpoint in case of failure

== 6.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 6.2 checkpointer — Automatically saves state for each execution step

LangGraph offers multiple checkpointer implementations. The seven commonly used options are summarized below.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Checkpointer],
  text(weight: "bold")[Package],
  text(weight: "bold")[Use],
  [`InMemorySaver`],
  [`langgraph-checkpoint` (built-in)],
  [Development/testing. State lost on process exit],
  [`SqliteSaver`],
  [`langgraph-checkpoint-sqlite`],
  [Local development. Single-file persistence, async variant],
  [`PostgresSaver`],
  [`langgraph-checkpoint-postgres`],
  [Production default. `AsyncPostgresSaver` for async graphs],
  [`MongoDBSaver`],
  [`langgraph-checkpoint-mongodb`],
  [Document DB. JSON-friendly storage backend],
  [`RedisSaver`],
  [`langgraph-checkpoint-redis`],
  [In-memory persistence. Low latency, async variant],
  [`OracleSaver`],
  [`langgraph-checkpoint-oracle`],
  [Enterprise Oracle DB. Vector search included],
  [`CosmosDBSaver`],
  [`langchain-azure-cosmosdb`],
  [Azure Cosmos DB. Microsoft Entra ID authentication],
)

If you pass checkpointer to `compile()`, state will be automatically saved after each node in the graph is executed.

DB-backed checkpointers are initialized with the context-manager + `setup()` pattern. Use async variants (e.g. `AsyncPostgresSaver`) for async graphs.

#code-block(`````python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()  # first time only — create schema
    graph = builder.compile(checkpointer=checkpointer)

# Async graphs
from langgraph.checkpoint.postgres import AsyncPostgresSaver

checkpointer = AsyncPostgresSaver.from_conn_string(DB_URI)
await checkpointer.setup()
graph = builder.compile(checkpointer=checkpointer)
`````)

== 6.3 get_state() — Retrieve currently stored state lookup

`get_state()` returns the latest checkpoint state for the specified thread.
You can check information such as number of messages, checkpoint ID, and next node to run.

#code-block(`````python
state = graph.get_state(config)
print(f"Thread: {config['configurable']['thread_id']}")
print(f"Message count: {len(state.values['messages'])}")
print(f"Checkpoint ID: {state.config['configurable']['checkpoint_id']}")
print(f"Next node: {state.next}")
`````)

== 6.4 get_state_history() — View entire execution history

`get_state_history()` returns all checkpoints for that thread, sorted by most recent.
This allows you to trace the entire history of graph execution.

#code-block(`````python
print("state History (most recent):")
for i, snapshot in enumerate(graph.get_state_history(config)):
    msg_count = len(snapshot.values.get("messages", []))
    print(f"  [{i}] checkpoint={snapshot.config['configurable']['checkpoint_id'][:20]}... messages={msg_count}")
    if i >= 4:
        print("... (omitted)")
        break
`````)

== 6.5 update_state() — Modify stored state externally

`update_state()` allows you to programmatically modify state stored in a checkpoint.
For example, you can add system Note, reflect user preferences, and more.

== 6.6 Thread Independence — Different thread_ids are completely independent state

Each `thread_id` has a completely independent conversation state.
Conversations in different threads do not affect each other.

== 6.7 InMemoryStore — Cross-thread sharing long-term memory

`InMemoryStore` is a key-value store shared between threads.
Used to store information that needs to be maintained across threads, such as user profiles and preferences.

- `put()`: Store data with namespace and key
- `get()`: Search for a specific item
- `search()`: Search within namespace

#code-block(`````python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# data storage
store.put(("users",), "alice", {"favorite_color": "blue", "city": "Seoul"})
store.put(("users",), "bob", {"favorite_color": "red", "city": "Tokyo"})

# Data inquiry
alice = store.get(("users",), "alice")
print(f"Alice: {alice.value}")

# search
results = store.search(("users",))
print(f"\nTotal users ({len(results)}):")
for item in results:
    print(f"  {item.key}: {item.value}")
`````)

=== 6.7.5 Using InMemoryStore with graphs

If you pass `InMemoryStore` to the graph as `compile(store=store)`, you can directly access store through the `store` parameter in each node function.
This pattern allows you to store and retrieve user information within a node, maintaining long-term memory across threads.

- `compile(store=store)`: connect store to the graph.
- Add `store` parameter to node function: LangGraph automatically injects store instance
- Separate namespace for each user with `config["configurable"]["user_id"]`

=== Context and Runtime — accessing user_id and store from nodes

To partition long-term memory _per user_, the node function needs the current user's ID. LangGraph solves this with a `@dataclass` `Context` registered via `StateGraph(..., context_schema=Context)`, plus a `runtime: Runtime[Context]` parameter on the node. Pass `context=Context(user_id=...)` to `graph.invoke(...)`, then access `runtime.context.user_id` and `runtime.store` inside the node.

#code-block(`````python
import uuid
from dataclasses import dataclass
from langgraph.runtime import Runtime
from langgraph.graph import StateGraph, MessagesState, START

@dataclass
class Context:
    user_id: str

async def call_model(state: MessagesState, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    namespace = (user_id, "memories")  # recommended pattern

    memories = await runtime.store.asearch(
        namespace, query=state["messages"][-1].content, limit=3
    )
    await runtime.store.aput(
        namespace, str(uuid.uuid4()), {"data": "User prefers dark mode"}
    )
    return {"messages": [await model.ainvoke(state["messages"])]}

builder = StateGraph(MessagesState, context_schema=Context)
builder.add_node(call_model)
builder.add_edge(START, "call_model")
graph = builder.compile(checkpointer=checkpointer, store=store)

graph.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    {"configurable": {"thread_id": "1"}},
    context=Context(user_id="alice"),
)
`````)

#tip-box[Any tuple shape works as a namespace, but the official docs recommend `(user_id, "memories")`. First-level partitioning by user, second-level by memory kind (`"memories"`, `"preferences"`, etc.) makes category-scoped `search()` straightforward.]

Production stores follow the same context-manager pattern as checkpointers:

#code-block(`````python
from langgraph.store.postgres import PostgresStore

with PostgresStore.from_conn_string(DB_URI) as store:
    store.setup()
    graph = builder.compile(checkpointer=checkpointer, store=store)

# Redis / Oracle follow the same pattern
from langgraph.store.redis import RedisStore
from langgraph.store.oracle import OracleStore  # vector search built-in
`````)

=== Semantic search with `index`

Enable embedding-based search by passing `index={"embed": ..., "dims": ..., "fields": [...]}`:

#code-block(`````python
from langchain.embeddings import init_embeddings
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["food_preference", "$"],
    }
)

store.put(("alice", "memories"), "1", {"food_preference": "I love pizza"})
items = store.search(("alice", "memories"), query="I'm hungry", limit=1)
`````)

Use `index=False` on `put()` to skip embedding for a specific item; pass a list of keys to limit which fields get embedded.

== 6.7.6 Managing conversation length — trim_messages and RemoveMessage

Long conversations can exceed LLM's context window. LangGraph manages messages in two ways:

=== `trim_messages`
- Automatically trims old messages based on number of tokens
- `strategy="last"`: Keep only recent messages
- `start_on="human"`: Ensure truncated results always start with the user message.
- Returns a list of truncated messages, without modifying the original state (full history is maintained in checkpoints)

=== `RemoveMessage`
- Permanently delete specific messages from checkpoints
- The reducer of `MessagesState` detects `RemoveMessage` and removes that message.
- Useful for saving storage space by organizing old messages

== 6.8 Durable Execution — resume at last checkpoint on failure

_Durable Execution_ is possible using checkpointer.
Even if an error occurs during graph execution, you can resumeat the last successful checkpoint.
Nodes that have already been completed are not rerun, saving money and time.

The example below configures a three-stage pipeline:
+ _step_1_: Collect data (always succeeds)
+ _step_2_: Data analysis (always successful)
+ _step_3_: External API call (failure on first run, success on retry)

With `attempt_count`, step_3 fails on the first run, and when calling `invoke()` the second time, step_1 and step_2 are skipped and only resume occurs in step_3.

== 6.9 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [_checkpointer_],
  [Automatically save state after each node execution (`InMemorySaver`, `SqliteSaver`, `PostgresSaver`)],
  [`get_state()`],
  [View the latest checkpoint state of the current thread],
  [`get_state_history()`],
  [View the entire checkpoint history of a thread (most recent)],
  [`update_state()`],
  [Programmatically modifying stored state],
  [_Thread independence_],
  [Different `thread_id` are completely independent state],
  [`InMemoryStore`],
  [Key-value shared across threads long-term memory storage],
  [`compile(store=store)`],
  [Access long-term memory with `store` parameter from graph node],
  [`trim_messages`],
  [Cut out old messages based on number of tokens and pass them to LLM (maintain checkpoints)],
  [`RemoveMessage`],
  [Permanently delete specific messages from checkpoint],
  [_Durable Execution_],
  [On failure, at the last successful checkpoint resume],
)

=== Next Steps
→ _#link("./07_streaming.ipynb")[07_streaming.ipynb]_: Learn streaming.
