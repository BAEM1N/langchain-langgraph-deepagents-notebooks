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
model = ChatOpenAI(model="gpt-5.4")
`````)

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Set the key in .env, or uncomment it below and enter it yourself.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: Automatically activated when LANGSMITH_TRACING=true (no code modification required)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON \u2014 project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 6.2 checkpointer — Automatically saves state for each execution step

LangGraph provides three checkpointer:

- _`InMemorySaver`_: For development use (stored in memory, deleted when process ends)
- _`SqliteSaver`_: Local development (save to file, persist across restarts)
- _`PostgresSaver`_: Production (stored in DB, expandable)

If you pass checkpointer to `compile()`, state will be automatically saved after each node in the graph is executed.

#code-block(`````python
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.checkpoint.memory import InMemorySaver
from langchain.messages import HumanMessage

def chatbot(state: MessagesState) -> dict:
    response = model.invoke(state["messages"], config=lf_config)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

# Compile with checkpointer
checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)

config = {"configurable": {"thread_id": "session-1"}}

# conversation 1
r1 = graph.invoke({"messages": [HumanMessage(content="My name is Alice.")]}, {**config, **lf_config})
print("Turn 1:", r1["messages"][-1].content)

# Conversation 2 — Remember previous conversation
r2 = graph.invoke({"messages": [HumanMessage(content="What was my name?")]}, {**config, **lf_config})
print("Turn 2:", r2["messages"][-1].content)
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

#code-block(`````python
from langchain.messages import AIMessage

# Add message directly to state
graph.update_state(config, {
    "messages": [AIMessage(content="(System Note: User prefers Korean response.)")]
})

# Continue conversation with modified state
r3 = graph.invoke({"messages": [HumanMessage(content="Please tell us a fun fact.")]}, {**config, **lf_config})
print("After update:", r3["messages"][-1].content[:200])
`````)

== 6.6 Thread Independence — Different thread_ids are completely independent state

Each `thread_id` has a completely independent conversation state.
Conversations in different threads do not affect each other.

#code-block(`````python
config_b = {"configurable": {"thread_id": "session-2"}}
r = graph.invoke({"messages": [HumanMessage(content="Do you know my name?")]}, {**config_b, **lf_config})
print("Other threads:", r["messages"][-1].content)
print("-> Different thread_id so previous conversation is unknown")
`````)

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

#code-block(`````python
import uuid
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.store.memory import InMemoryStore
from langgraph.store.base import BaseStore
from langchain_core.runnables import RunnableConfig
from langchain.messages import HumanMessage

# --- Store and checkpointer ---
memory_store = InMemoryStore()
memory_checkpointer = InMemorySaver()

# --- Node that reads/writes long-term memory via the store parameter ---
def chatbot_with_memory(state: MessagesState, config: RunnableConfig, *, store: BaseStore):
    """This is a node that reads and writes long-term memory through the store parameter."""
    user_id = config["configurable"].get("user_id", "anonymous")
    namespace = ("memories", user_id)

    # Query existing memory for this user
    existing = store.search(namespace)
    memory_text = "\n".join(f"- {item.value['data']}" for item in existing)

    # Configure system context in memory
    system_msg = "You are a useful assistant."
    if memory_text:
        system_msg += f"\n\nUser memory:\n{memory_text}"

    messages = [{"role": "system", "content": system_msg}] + state["messages"]
    response = model.invoke(messages, config=lf_config)

    # Save new facts that users say about themselves
    user_msg = state["messages"][-1].content.lower()
    if any(kw in user_msg for kw in ["good", "love", "The name is", "preference", "preferably"]):
        store.put(namespace, str(uuid.uuid4()), {"data": state["messages"][-1].content})

    return {"messages": [response]}

# --- Build graph ---
builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_with_memory)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

graph_with_store = builder.compile(
    checkpointer=memory_checkpointer,
    store=memory_store,  # <-- Connect store to graph
)

# --- Thread 1: user shares preferences ---
config_1 = {"configurable": {"thread_id": "store-thread-1", "user_id": "user-alice"}}
r1 = graph_with_store.invoke(
    {"messages": [HumanMessage(content="I like hiking and taking pictures.")]},
    {**config_1, **lf_config},
)
print("Thread 1:", r1["messages"][-1].content[:150])

# --- Thread 2 (different thread, same user): memories persist ---
config_2 = {"configurable": {"thread_id": "store-thread-2", "user_id": "user-alice"}}
r2 = graph_with_store.invoke(
    {"messages": [HumanMessage(content="What is my hobby?")]},
    {**config_2, **lf_config},
)
print("Thread 2 (new thread, same user):", r2["messages"][-1].content[:150])

# --- Verify stored memories ---
stored = memory_store.search(("memories", "user-alice"))
print(f"\nStored memory for user-alice ({len(stored)} entries):")
for item in stored:
    print(f"  {item.key[:8]}...: {item.value}")
`````)

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

#code-block(`````python
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.checkpoint.memory import InMemorySaver
from langchain_core.messages.utils import trim_messages, count_tokens_approximately
from langchain.messages import HumanMessage, AIMessage, RemoveMessage

# ============================================================
# Part 1: trim_messages — Trim messages before calling LLM
# ============================================================

def chatbot_with_trim(state: MessagesState) -> dict:
    """After truncating the message to fit the token budget, LLM is called."""
    trimmed = trim_messages(
        state["messages"],
        strategy="last",
        token_counter=count_tokens_approximately,
        max_tokens=80,
        start_on="human",
        end_on=("human", "tool"),
    )
    print(f"  Original messages: {len(state['messages'])}, after trimming: {len(trimmed)}")
    response = model.invoke(trimmed, config=lf_config)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_with_trim)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

trim_checkpointer = InMemorySaver()
trim_graph = builder.compile(checkpointer=trim_checkpointer)
trim_config = {"configurable": {"thread_id": "trim-demo"}}

# Build up a long conversation
for i, msg in enumerate(["Hello, my name is Alice.", "I live in Seoul.", "I work as an engineer.", "Please summarize my introduction."]):
    print(f"Turn {i+1}: {msg}")
    r = trim_graph.invoke({"messages": [HumanMessage(content=msg)]}, {**trim_config, **lf_config})
    print(f"  AI: {r['messages'][-1].content[:120]}\n")

# Verify full history is preserved in checkpoint despite trimming
full_state = trim_graph.get_state(trim_config)
print(f"Total message count in the checkpoint: {len(full_state.values['messages'])}")
print("-> trim_messages is trimmed only when LLM is called, and the entire history is preserved at checkpoints.")
`````)

#code-block(`````python
# ============================================================
# Part 2: RemoveMessage — Permanently delete a message from a checkpoint
# ============================================================
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.checkpoint.memory import InMemorySaver
from langchain.messages import HumanMessage, RemoveMessage

def chatbot_node(state: MessagesState) -> dict:
    response = model.invoke(state["messages"], config=lf_config)
    return {"messages": [response]}

def delete_old_messages(state: MessagesState) -> dict:
    """Keep only the most recent two messages and discard the rest from the checkpoint."""
    messages = state["messages"]
    if len(messages) > 2:
        to_delete = messages[:-2]
        print(f"  Deleting {len(to_delete)} old messages from the checkpoint")
        return {"messages": [RemoveMessage(id=m.id) for m in to_delete]}
    return {"messages": []}

builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot_node)
builder.add_node("cleanup", delete_old_messages)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", "cleanup")
builder.add_edge("cleanup", END)

rm_checkpointer = InMemorySaver()
rm_graph = builder.compile(checkpointer=rm_checkpointer)
rm_config = {"configurable": {"thread_id": "remove-demo"}}

# Run several turns
for msg_text in ["hello! My name is Bob.", "I love cooking.", "What was my name?"]:
    r = rm_graph.invoke({"messages": [HumanMessage(content=msg_text)]}, {**rm_config, **lf_config})
    state = rm_graph.get_state(rm_config)
    print(f"User: {msg_text}")
    print(f"  AI: {r['messages'][-1].content[:120]}")
    print(f"  Message count in the checkpoint: {len(state.values['messages'])}\n")

print("-> Save storage space by permanently deleting old messages from checkpoints with RemoveMessage")
`````)

== 6.8 Durable Execution — resume at last checkpoint on failure

_Durable Execution_ is possible using checkpointer.
Even if an error occurs during graph execution, you can resumeat the last successful checkpoint.
Nodes that have already been completed are not rerun, saving money and time.

The example below configures a three-stage pipeline:
+ _step_1_: Collect data (always succeeds)
+ _step_2_: Data analysis (always successful)
+ _step_3_: External API call (failure on first run, success on retry)

With `attempt_count`, step_3 fails on the first run, and when calling `invoke()` the second time, step_1 and step_2 are skipped and only resume occurs in step_3.

#code-block(`````python
import operator
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

# --- State ---
class PipelineState(TypedDict):
    data: str
    log: Annotated[list[str], operator.add]

# Track how many times step_3 has been called across invocations
attempt_count = {"step_3": 0}

# --- Nodes ---
def step_1(state: PipelineState) -> dict:
    """Step 1: Data Collection — Always Successful"""
    print(">> step_1 executed (data collection)")
    return {
        "data": "Raw data collected",
        "log": ["step_1: Data collection completed"],
    }

def step_2(state: PipelineState) -> dict:
    """Step 2: Data Analysis — Always Successful"""
    print(">> step_2 executed (analysis)")
    return {
        "data": state["data"] + "-> Analysis completed",
        "log": ["step_2: Complete data analysis"],
    }

def step_3(state: PipelineState) -> dict:
    """Step 3: Call external API — fails on first attempt, succeeds on retry."""
    attempt_count["step_3"] += 1
    print(f"  >> step_3 executed (API call, attempt {attempt_count['step_3']})")
    if attempt_count["step_3"] == 1:
        raise ConnectionError("Simulated API error!")
    return {
        "data": state["data"] + "-> Receive API results",
        "log": ["step_3: API call successful"],
    }

# --- Build graph ---
builder = StateGraph(PipelineState)
builder.add_node("step_1", step_1)
builder.add_node("step_2", step_2)
builder.add_node("step_3", step_3)
builder.add_edge(START, "step_1")
builder.add_edge("step_1", "step_2")
builder.add_edge("step_2", "step_3")
builder.add_edge("step_3", END)

durable_checkpointer = InMemorySaver()
durable_graph = builder.compile(checkpointer=durable_checkpointer)

config = {"configurable": {"thread_id": "durable-1"}}

# --- First invocation: step_3 will fail ---
print("=== 1st call: expected failure at step_3 ===")
try:
    durable_graph.invoke({"data": "", "log": []}, {**config, **lf_config})
except ConnectionError as e:
    print(f"  !! Error occurred: {e}")

# Check checkpoint state after failure
state_after_fail = durable_graph.get_state(config)
print(f"\nCheckpoint after failure:")
print(f"  Next node to run: {state_after_fail.next}")
print(f"  Log so far: {state_after_fail.values.get('log', [])}")

# --- Second invocation: resumes from step_3 only ---
print("=== 2nd call: at last checkpoint resume ===")
result = durable_graph.invoke(None, {**config, **lf_config})
print(f"\nFinal result:")
print(f"  Data: {result['data']}")
print(f"  Log: {result['log']}")
print("-> step_1 and step_2 were not re-executed, but only step_3 was re-executed (durable execution)")
`````)

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
