// Source: docs/deepagents/15-streaming.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "Streaming", subtitle: "subgraphs=True + v2 namespaces")

This chapter covers how to surface events from both the main agent and inside subagents in real time and how to emit custom progress events. Use it when you want to show long-running agent progress to users or to build a subagent-card UI.

#learning-header()
#learning-objectives(
  [Observe the inside of subagents by combining `subgraphs=True` and `version="v2"`],
  [Route main vs subagent events using the namespace (`ns`) tuple],
  [Subscribe to `updates` · `messages` · `custom` modes simultaneously],
  [Emit custom progress events with `get_stream_writer`],
  [Map the three subagent lifecycle signals (Pending / Running / Complete) to UI cards],
)

== 14.1 Three key ideas

Deep Agents streaming rests on three ideas.

- *`subgraphs=True` + `version="v2"`* — observe events inside subagents
- *Namespace (`ns`)* — a tuple tells you which subgraph the event came from
- *Stream-mode combination* — `updates` (steps), `messages` (tokens / tools), `custom` (custom events)

The v2 format returns every chunk in a uniform `{"type", "ns", "data"}` shape. Routing is simpler than v1's nested tuples.

== 14.2 Basic usage: enabling subagent streaming

#code-block(`````python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Research quantum computing advances"}]},
    stream_mode="updates",
    subgraphs=True,
    version="v2",
):
    print(chunk)
`````)

Without `subgraphs=True`, subagent internals are only visible at the supervisor level as the result of a `task` tool call. From the UI's perspective, that is "something happened in a black box and a result came out."

== 14.3 Routing events via namespaces

Every v2 chunk carries a _tuple_ in the `ns` field, and that tuple identifies where the event was emitted.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tuple],
  text(weight: "bold")[Meaning],
  [`()`],
  [Main-agent event],
  [`("tools:abc123",)`],
  [Subagent spawned by a `task` tool call from the main agent],
  [`("tools:abc123", "model_request:def456")`],
  [The model-request node inside that subagent],
)

Detecting whether an event comes from a subagent:

#code-block(`````python
is_subagent = any(segment.startswith("tools:") for segment in chunk["ns"])
`````)

This branch is the basic split when the UI separates the main conversation panel from subagent cards.

== 14.4 Stream mode: `updates`

Emits "which step is running right now" at node granularity. The most useful mode for tracking subagent lifecycles.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="updates",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "updates":
        for node_name, data in chunk["data"].items():
            print(f"Step: {node_name}")
`````)

== 14.5 Stream mode: `messages`

Receives LLM tokens in fragments. When a tool call happens, each chunk carries `tool_call_chunks` so the _tool name and args stream in incrementally_.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="messages",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "messages":
        token, metadata = chunk["data"]
        if token.tool_call_chunks:
            for tc in token.tool_call_chunks:
                print(f"Tool: {tc['name']}, Args: {tc.get('args')}")
        else:
            print(token.content, end="")
`````)

Token-level output and tool-call assembly are handled in the same loop.

== 14.6 Custom progress events

Pull the stream writer inside a tool and emit arbitrary structures. Useful for upload progress, item counts, or intermediate states.

#code-block(`````python
from langchain.tools import tool
from langgraph.config import get_stream_writer

@tool
def analyze_data(topic: str) -> str:
    """Analyze data for the given topic."""
    writer = get_stream_writer()
    writer({"status": "starting", "progress": 0})
    # ... analysis work ...
    writer({"status": "complete", "progress": 100})
    return "done"
`````)

Subscribe with `stream_mode="custom"` on the receiving side.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="custom",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])
`````)

== 14.7 Subscribing to multiple modes at once

Pass a list and receive all three event types in one loop.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
    version="v2",
):
    t = chunk["type"]
    if t == "updates":
        # step progress
        ...
    elif t == "messages":
        # tokens / tool calls
        ...
    elif t == "custom":
        # progress / custom events
        ...
`````)

Production UIs typically subscribe to all three modes at once and fan them out to the respective panels.

== 14.8 Tracking the subagent lifecycle

From the main agent's perspective, a subagent is identified by three events.

+ *Pending* — the moment the main agent emits a `tool_call` with `name="task"`
+ *Running* — the moment the first event arrives on the `("tools:<id>",)` namespace
+ *Complete* — the moment the ToolMessage for that `task` call returns to the main `tools` node

Mapping UI card states to these three signals shows "which subagent is exploring right now" at a glance.

== 14.9 v2 unified format

Every chunk has the following three fields.

#code-block(`````python
{
    "type": "updates" | "messages" | "custom",
    "ns": tuple,
    "data": Any,
}
`````)

The old v1 nested-tuple format had different data shapes per `type`, which made branching noisy. v2 simplifies frontend routing to a single `(type, ns prefix)`.

== 14.10 Frontend integration

React / Vue / Svelte / Angular can consume this stream via `useStream` in `@langchain/react` and similar helpers. Subagent card rendering, reconnection, and history loading are all built in.

#code-block(`````tsx
import { useStream } from "@langchain/react";

const stream = useStream<typeof agent>({
  apiUrl: "https://your-deployment.langsmith.dev",
  assistantId: "agent",
  reconnectOnMount: true,
  fetchStateHistory: true,
});

stream.submit(
  { messages: [{ type: "human", content: text }] },
  {
    streamSubgraphs: true,
    config: { recursionLimit: 10000 },
  },
);
`````)

== 14.11 Caveats

- *Without `subgraphs=True`, you cannot see inside a subagent* — essential for UI progress cards
- *Specify `version="v2"` explicitly* — falling back to the legacy format changes namespace handling
- *Keep the custom event schema stable* — if every tool uses its own shape, UI routing breaks (for example, use a shared `{"status", "progress", "message"}` structure)
- *Decide whether to expose summarization tokens* (filter with `metadata.get("lc_source") == "summarization"`)
- *Retry events are streamed too* — with `ModelRetryMiddleware` attached, fail-retry flows are visible; aggregate them in the UI

== Key Takeaways

- v2 format + `subgraphs=True` is the entry point for subagent observability
- Route main vs subagent events using the `ns` tuple prefix
- Subscribing to `updates` / `messages` / `custom` as a list is the production default
- Use `get_stream_writer` to emit arbitrary progress events from tools
- Map Pending / Running / Complete to subagent UI card states
