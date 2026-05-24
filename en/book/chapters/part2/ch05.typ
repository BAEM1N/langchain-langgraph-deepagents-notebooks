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

== 5.2 Short-Term Memory: `InMemorySaver`

Short-term memory is the mechanism that remembers previous messages _within a single conversation session_.

- `InMemorySaver` acts as a checkpointer and stores agent state in memory.
- `thread_id` separates different conversation sessions.
- Reusing the same `thread_id` preserves previous conversation context.


== 5.3 Independent Conversations with Different `thread_id` Values

If you use a different `thread_id`, you create a completely _independent conversation session_. Context is not shared with the previous session.


== 5.4 Message Trimming

As a conversation grows, the token count increases and affects both cost and performance. _Message trimming_ keeps only the most relevant messages within a token budget.

- `trim_messages`: keeps only the most recent N messages or the messages that fit within the token budget
- `strategy="last"`: prioritizes the most recent messages
- `include_system=True`: always preserves the system message


== 5.5 Long-Term Memory: `InMemoryStore`

Long-term memory stores information that persists _across conversation sessions_.

- `InMemoryStore` is a key-value store for user preferences, settings, and similar data.
- Tools can access the store through the `ToolRuntime` parameter.
- The same data is available from every session, regardless of `thread_id`.

==== Per-user namespaces (`context_schema` + `runtime.context`)

In real apps you typically scope the store with the current `user_id`. Declare a `context_schema`, read `runtime.context.user_id` inside the tool, and cast Pydantic/dataclass objects with `dict(...)` before writing so the value is JSON-serializable.

#code-block(`````python
from dataclasses import dataclass
from langgraph.store.memory import InMemoryStore
from langchain.tools import tool, ToolRuntime

@dataclass
class Context:
    user_id: str

@tool
def remember_user(user_info: dict, runtime: ToolRuntime[Context]) -> str:
    """Persist the current user's profile."""
    namespace = (runtime.context.user_id, "profile")
    runtime.store.put(namespace, "info", dict(user_info))
    return "saved"

store = InMemoryStore()
agent = create_agent(
    model=model,
    tools=[remember_user],
    store=store,
    context_schema=Context,
)
agent.invoke(
    {"messages": [{"role": "user", "content": "I'm Minji"}]},
    context=Context(user_id="user_123"),
)
`````)

#tip-box[If you forget to pass `store=...` to `create_agent`, `runtime.store` is `None` and the tool cannot access the store. Always wire the store in alongside any long-term memory tool.]

#tip-box[In production, swap `InMemoryStore` for `PostgresStore` (or `AsyncPostgresStore`) from the `langgraph-checkpoint-postgres` package — same interface, persistent storage, and semantic search.]

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


=== A Note on `stream_mode="custom"`

`stream_mode="custom"` carries user-defined events. With current LangGraph, you can emit them from inside tools or middleware of a `create_agent` agent by calling `get_stream_writer()`.

#code-block(`````python
from langgraph.config import get_stream_writer
from langchain.tools import tool

@tool
def long_running_task(query: str) -> str:
    """Reports progress through the custom stream."""
    writer = get_stream_writer()
    writer({"step": 1, "status": "fetching"})
    # ... work ...
    writer({"step": 2, "status": "done"})
    return "ok"

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "search"}]},
    stream_mode="custom",
):
    print(chunk)  # whatever the writer emitted
`````)

#tip-box[Earlier docs said `stream_mode="custom"` did not work with `create_agent`. Current LangGraph supports it via `get_stream_writer()` — the same mechanism as the `writer` parameter you would receive at the `StateGraph` level.]

=== `version="v2"` Streaming and GraphOutput

`agent.stream(..., version="v2")` delivers structured events, and `agent.invoke(..., version="v2")` returns a `GraphOutput` with `value` (final state) and `interrupts` (pending interrupts).

#code-block(`````python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "hello"}]},
    config={"configurable": {"thread_id": "t1"}},
    version="v2",
):
    if chunk["type"] == "updates":
        print("update:", chunk["data"])
    elif chunk["type"] == "messages":
        print("token:", chunk["data"][0].content)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    config={"configurable": {"thread_id": "t1"}},
    version="v2",
)
print(result.value)       # final state dict
print(result.interrupts)  # [] when no interrupt is pending
`````)

=== Accumulating with `chunk_position`

When streaming with `stream_mode="messages"`, the final chunk has `chunk_position == "last"`. Accumulate text and tool calls and flush them on the last chunk.

#code-block(`````python
buffer, tool_calls = [], []
for chunk, meta in agent.stream(payload, stream_mode="messages"):
    buffer.append(chunk.content)
    if chunk.tool_calls:
        tool_calls.extend(chunk.tool_calls)
    if meta.get("chunk_position") == "last":
        print("text:", "".join(buffer))
        print("tools:", tool_calls)
`````)

=== Filtering reasoning via `content_blocks`

Models with extended thinking (e.g., Claude Sonnet 4.6) expose typed `content_blocks` so you can route reasoning to a separate UI region.

#code-block(`````python
for chunk, _ in agent.stream(payload, stream_mode="messages"):
    for block in getattr(chunk, "content_blocks", []) or []:
        if block["type"] == "reasoning":
            ui.show_reasoning(block["reasoning"])
        elif block["type"] == "text":
            ui.show_answer(block["text"])
`````)

=== Multi-mode streams and interrupts

Passing a list to `stream_mode` yields `(mode, payload)` tuples. The `"__interrupt__"` key in an `updates` payload indicates a pending HITL decision.

#code-block(`````python
for mode, payload in agent.stream(
    {"messages": [{"role": "user", "content": "send email"}]},
    config={"configurable": {"thread_id": "t1"}},
    stream_mode=["messages", "updates"],
):
    if mode == "updates" and "__interrupt__" in payload:
        interrupt = payload["__interrupt__"]
        # show approval UI, then resume with Command(resume=...)
`````)

#tip-box[Use `subgraphs=True` to receive events from nested subgraphs. To skip token streaming altogether, set `disable_streaming=True` on the call (or `streaming=False` on the model).]


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

