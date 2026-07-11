// Auto-generated from 05_memory_and_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Memory and Streaming")

Learn about the _memory system_ and _streaming modes_ used by LangChain v1 agents.


== Learning Objectives

- _Short-term memory:_ understand how to preserve conversation state with `InMemorySaver` and `thread_id`
- _Long-term memory:_ use `InMemoryStore` to persist memory across conversations
- _Message trimming:_ learn how to keep long conversations within a token budget
- _Streaming modes:_ understand the differences between `values`, `updates`, `messages`, and `custom`


== 5.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("Model ready:", model.model_name)
`````)

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: pass config={"callbacks": [langfuse_handler]} to invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 5.2 Short-Term Memory: `InMemorySaver`

Short-term memory is the mechanism that remembers previous messages _within a single conversation session_.

- `InMemorySaver` acts as a checkpointer and stores agent state in memory.
- `thread_id` separates different conversation sessions.
- Reusing the same `thread_id` preserves previous conversation context.


#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool
from langgraph.checkpoint.memory import InMemorySaver

@tool
def get_time() -> str:
    """Get the current time."""
    from datetime import datetime
    return datetime.now().strftime("%H:%M:%S")

checkpointer = InMemorySaver()
agent = create_agent(
    model=model,
    tools=[get_time],
    system_prompt="You are a helpful assistant. Remember the conversation context.",
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "session-1"}}

# First conversation
result1 = agent.invoke(
    {"messages": [{"role": "user", "content": "My name is Alice. What time is it right now?"}]},
    config={**config, **lf_config},
)
print("Response 1:", result1["messages"][-1].content)

# Second conversation — remembers the previous turn
result2 = agent.invoke(
    {"messages": [{"role": "user", "content": "What is my name?"}]},
    config={**config, **lf_config},
)
print("Response 2:", result2["messages"][-1].content)
`````)

== 5.3 Independent Conversations with Different `thread_id` Values

If you use a different `thread_id`, you create a completely _independent conversation session_. Context is not shared with the previous session.


#code-block(`````python
config_b = {"configurable": {"thread_id": "session-2"}}

result3 = agent.invoke(
    {"messages": [{"role": "user", "content": "Do you know my name?"}]},
    config={**config_b, **lf_config},
)
print("Different session response:", result3["messages"][-1].content)
print("→ Because this is a different thread_id, it does not know the previous conversation")
`````)

== 5.4 Message Trimming

As a conversation grows, the token count increases and affects both cost and performance. _Message trimming_ keeps only the most relevant messages within a token budget.

- `trim_messages`: keeps only the most recent N messages or the messages that fit within the token budget
- `strategy="last"`: prioritizes the most recent messages
- `include_system=True`: always preserves the system message


#code-block(`````python
from langchain.messages import trim_messages

# Configure the trimmer: keep only the most recent messages
trimmer = trim_messages(
    max_tokens=1000,
    strategy="last",
    token_counter=model,
    include_system=True,
    allow_partial=False,
)

# Example of applying trimming through middleware
from langchain.agents.middleware import before_model

@before_model
def trim_context(request):
    """Trim messages to fit within the token budget."""
    trimmed = trimmer.invoke(request.state["messages"], config=lf_config)
    return request.override(messages=trimmed)

agent_trimmed = create_agent(
    model=model,
    tools=[get_time],
    system_prompt="You are a helpful assistant.",
    middleware=[trim_context],
    checkpointer=InMemorySaver(),
)

print("Created message-trimming agent")
`````)

== 5.5 Long-Term Memory: `InMemoryStore`

Long-term memory stores information that persists _across conversation sessions_.

- `InMemoryStore` is a key-value store for user preferences, settings, and similar data.
- Tools can access the store through the `ToolRuntime` parameter.
- The same data is available from every session, regardless of `thread_id`.

Differences between short-term and long-term memory:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Short-Term Memory (Checkpointer)],
  text(weight: "bold")[Long-Term Memory (Store)],
  [Scope],
  [Inside a single `thread_id`],
  [Across all sessions],
  [What it stores],
  [Conversation message history],
  [User preferences, learned data],
  [Lifetime],
  [Until the session ends (or persists)],
  [Until explicitly deleted],
  [Access],
  [Automatic (inside the agent)],
  [Explicit (through tools)],
)


#code-block(`````python
from langgraph.store.memory import InMemoryStore
from langchain.tools import tool, ToolRuntime

store = InMemoryStore()

@tool
def save_preference(key: str, value: str, runtime: ToolRuntime) -> str:
    """Store a user preference in long-term memory."""
    runtime.store.put(("preferences",), key, {"value": value})
    return f"Preference saved: {key} = {value}"

@tool
def get_preference(key: str, runtime: ToolRuntime) -> str:
    """Look up a user preference from long-term memory."""
    result = runtime.store.get(("preferences",), key)
    if result:
        return f"Preference {key} = {result.value.get('value', 'not found')}"
    return f"{key} preference could not be found"

memory_agent = create_agent(
    model=model,
    tools=[save_preference, get_preference],
    system_prompt="You can store and retrieve user preferences with tools.",
    store=store,
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": "memory-test"}}

# Save preference
result = memory_agent.invoke(
    {"messages": [{"role": "user", "content": "Please save that my favorite color is blue and my favorite food is pizza."}]},
    config={**config, **lf_config},
)
print("Saved:", result["messages"][-1].content)

# Retrieve the preference in a new session
config2 = {"configurable": {"thread_id": "memory-test-2"}}
result2 = memory_agent.invoke(
    {"messages": [{"role": "user", "content": "What is my favorite color?"}]},
    config={**config2, **lf_config},
)
print("Retrieved:", result2["messages"][-1].content)
`````)

== 5.6 Streaming Modes

LangChain provides streaming so you can _observe agent execution in real time_. Choose the mode that best fits your use case.


=== Streaming Mode Comparison

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[Use Case],
  [`values`],
  [Full state after each step],
  [Debugging, state inspection],
  [`updates`],
  [Only the updates from each node],
  [Progress displays],
  [`messages`],
  [Message tokens],
  [Chat UI],
  [`custom`],
  [Custom user-defined events],
  [Custom progress indicators],
)


#code-block(`````python
# stream_mode="updates" — updates from each node
print('=== stream_mode="updates" ===')
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What time is it right now?"}]},
    config={**{"configurable": {"thread_id": "stream-1"}}, **lf_config},
    stream_mode="updates",
):
    for node, update in chunk.items():
        print(f"[{node}]", end=" ")
        if "messages" in update:
            for msg in update["messages"]:
                content = msg.content if hasattr(msg, 'content') else str(msg)
                if content:
                    print(content[:200])

`````)

#code-block(`````python
# stream_mode="messages" — token-level streaming
print('=== stream_mode="messages" ===')
for msg, metadata in agent.stream(
    {"messages": [{"role": "user", "content": "Tell me one short joke."}]},
    config={**{"configurable": {"thread_id": "stream-2"}}, **lf_config},
    stream_mode="messages",
):
    if hasattr(msg, 'content') and msg.content:
        print(msg.content, end="", flush=True)
print()

`````)

#code-block(`````python
# stream_mode="values" — full state snapshot at each step
print('=== stream_mode="values" ===')
for state_snapshot in agent.stream(
    {"messages": [{"role": "user", "content": "What time is it right now?"}]},
    config={**{"configurable": {"thread_id": "stream-3"}}, **lf_config},
    stream_mode="values",
):
    msgs = state_snapshot["messages"]
    last_msg = msgs[-1]
    role = getattr(last_msg, "type", "unknown")
    content = last_msg.content if hasattr(last_msg, "content") else str(last_msg)
    tool_calls = getattr(last_msg, "tool_calls", None)
    print(f"[Full state] message count: {len(msgs)} | last message role: {role}")
    if content:
        print(f"  Content: {content[:200]}")
    if tool_calls:
        print(f"  Tool calls: {[tc['name'] for tc in tool_calls]}")

`````)

=== A Note on `stream_mode="custom"`

`stream_mode="custom"` is for user-defined events. It is not directly supported by agents created with `create_agent`; instead, you must use the _lower-level LangGraph API_ (`StateGraph`) and emit custom events manually through a `StreamWriter`.

#code-block(`````python
# Example at the LangGraph StateGraph level (reference only)
from langgraph.graph import StateGraph

def my_node(state, writer):  # StreamWriter is injected
    writer("progress", {"step": 1, "status": "processing"})
    # ... work ...
    writer("progress", {"step": 2, "status": "done"})
    return state
`````)

If you are using `create_agent`, the recommended pattern for progress indicators is to combine `stream_mode="updates"` with middleware.


== 5.7 Summary

Here is a summary of what this notebook covered:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Concept],
  text(weight: "bold")[Implementation],
  text(weight: "bold")[Description],
  [_Short-term memory_],
  [`InMemorySaver` + `thread_id`],
  [Keeps context inside one conversation session],
  [_Session isolation_],
  [Different `thread_id` values],
  [Manages independent conversation sessions],
  [_Message trimming_],
  [`trim_messages` + middleware],
  [Limits messages to stay within the token budget],
  [_Long-term memory_],
  [`InMemoryStore` + `ToolRuntime`],
  [Stores user data that persists across conversations],
  [_Streaming (values)_],
  [`stream_mode="values"`],
  [Full state snapshot at each step],
  [_Streaming (updates)_],
  [`stream_mode="updates"`],
  [Node-by-node updates],
  [_Streaming (messages)_],
  [`stream_mode="messages"`],
  [Real-time token output],
  [_Streaming (custom)_],
  [`stream_mode="custom"`],
  [Only available at the LangGraph `StateGraph` level],
)

_Key points:_
- Short-term memory is isolated by `thread_id` and preserves context only within the same session.
- Long-term memory is shared across sessions through `InMemoryStore`.
- `stream_mode="values"` is useful for debugging because it returns the full state at every step.
- `stream_mode="custom"` cannot be used directly with `create_agent`; it requires LangGraph's `StateGraph` API.
- Choosing the right streaming mode can significantly improve user experience.

=== Next Steps
→ _#link("./06_middleware.ipynb")[06_middleware.ipynb]_: Learn about middleware and guardrails.
