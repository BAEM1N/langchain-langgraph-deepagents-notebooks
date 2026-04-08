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
model = ChatOpenAI(model="gpt-4.1")
`````)

== 6.2 checkpointer — Automatically saves state for each execution step

LangGraph provides three checkpointer:

- **`InMemorySaver`**: For development use (stored in memory, deleted when process ends)
- **`SqliteSaver`**: Local development (save to file, persist across restarts)
- **`PostgresSaver`**: Production (stored in DB, expandable)

If you pass checkpointer to `compile()`, state will be automatically saved after each node in the graph is executed.

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
