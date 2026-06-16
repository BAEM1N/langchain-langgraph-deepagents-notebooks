// Auto-generated from 07_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "streaming", subtitle: "Observe agent execution in real time")

== Learning Objectives

Understand and utilize the various streaming modes of LangGraph.

- Understand the differences between `values`, `updates`, `messages`, `custom`, `debug` modes
- Identify appropriate use cases for each streaming mode
- Learn how to use multiple streaming modes simultaneously

== 7.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv()
from langchain_openai import ChatOpenAI
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, ToolMessage, AnyMessage
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver
from typing import TypedDict, Annotated, Literal
import operator

model = ChatOpenAI(model="gpt-4.1")

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Search result for '{query}': LangGraph is a framework for building stateful agents."

tools = [search]
tools_by_name = {t.name: t for t in tools}
model_with_tools = model.bind_tools(tools)

class AgentState(TypedDict):
    messages: Annotated[list[AnyMessage], operator.add]

def llm_node(state: AgentState) -> dict:
    return {"messages": [model_with_tools.invoke(
        [SystemMessage(content="You are a useful assistant.")] + state["messages"],
        config=lf_config,
)]}

def tool_node(state: AgentState) -> dict:
    results = []
    for tc in state["messages"][-1].tool_calls:
        result = tools_by_name[tc["name"]].invoke(tc["args"], config=lf_config)
        results.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))
    return {"messages": results}

def should_continue(state: AgentState) -> Literal["tools", "__end__"]:
    return "tools" if state["messages"][-1].tool_calls else END

builder = StateGraph(AgentState)
builder.add_node("llm", llm_node)
builder.add_node("tools", tool_node)
builder.add_edge(START, "llm")
builder.add_conditional_edges("llm", should_continue, ["tools", END])
builder.add_edge("tools", "llm")
agent = builder.compile(checkpointer=InMemorySaver())

print("streaming agent ready for demo")
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
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 7.2 streaming Mode Comparison

LangGraph provides various streaming modes. Each mode conveys a different level of information in real time.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[Use],
  [`values`],
  [Total state of each step],
  [Debugging, tracing state],
  [`updates`],
  [Only updates returned by each node],
  [Show progress],
  [`messages`],
  [Message Token Unit],
  [Chat UI],
  [`custom`],
  [custom event],
  [Custom Progress],
  [`debug`],
  [Full debug information],
  [Debugging during development],
)

== 7.3 stream_mode="values" — Full state snapshot

`values` mode returns _full state_ after each node execution. This is useful for tracking the overall flow of how the graph progresses.

#code-block(`````python
config = {"configurable": {"thread_id": "stream-values"}}
print("=== stream_mode='values' ===")
for state in agent.stream(
    {"messages": [HumanMessage(content="LangGraph Please search for information")]},
    {**config, **lf_config}, stream_mode="values",
):
    msg = state["messages"][-1]
    print(f"  [{type(msg).__name__}] {str(msg.content)[:100]}")
`````)

== 7.4 stream_mode="updates" — Node-specific updates

`updates` mode only passes the update value returned by each node. You can see exactly which nodes made which changes.

#code-block(`````python
config = {"configurable": {"thread_id": "stream-updates"}}
print("=== stream_mode='updates' ===")
for chunk in agent.stream(
    {"messages": [HumanMessage(content="LangGraph Please search for information")]},
    {**config, **lf_config}, stream_mode="updates",
):
    for node_name, update in chunk.items():
        print(f"\n  [{node_name}]")
        for msg in update.get("messages", []):
            if hasattr(msg, 'tool_calls') and msg.tool_calls:
                for tc in msg.tool_calls:
                    print(f"    Tool: {tc['name']}({tc['args']})")
            elif msg.content:
                print(f"    {msg.content[:150]}")
`````)

== 7.5 stream_mode="messages" — Per-token streaming

The `messages` mode delivers _tokens generated by LLM in real time_. Best suited for implementing typing effects in chat UI.

#code-block(`````python
config = {"configurable": {"thread_id": "stream-messages"}}
print("=== stream_mode='messages' ===")
print("response:", end="")
for msg, metadata in agent.stream(
    {"messages": [HumanMessage(content="What is LangGraph? Please answer briefly.")]},
    {**config, **lf_config}, stream_mode="messages",
):
    if msg.content and metadata.get("langgraph_node") == "llm":
        print(msg.content, end="", flush=True)
print()
`````)

== 7.6 Simultaneous use of multiple streaming modes

You can use multiple modes _simultaneously_ by passing a list to `stream_mode`. The returned event is in the form of a `(mode, data)` tuple.

#code-block(`````python
config = {"configurable": {"thread_id": "stream-multi"}}
print("=== Simultaneous use of multiple streaming modes ===")
for event in agent.stream(
    {"messages": [HumanMessage(content="Please search Python")]},
    {**config, **lf_config}, stream_mode=["updates", "messages"],
):
    kind = event[0] if isinstance(event, tuple) else "unknown"
    print(f"  [{kind}] received")
`````)

== 7.7 stream_mode="custom" — custom streaming

`custom` mode lets you _stream arbitrary data_ directly inside a node.

If you call `get_stream_writer()` of `langgraph.config`, you can get the `writer` function. If you pass data such as a dictionary to this function, it will be sent to the client in real time while the graph is running.

_Use Case:_
- _Progress_ reporting of long tasks
- _Chunk-wise streaming_ in external LLM without using LangChain
- Immediate delivery of _intermediate results_ inside the node

#tip-box[If you run a graph with `stream_mode="custom"`, the client receives only the data sent with `writer()`.]

#code-block(`````python
from langgraph.config import get_stream_writer

# --- Simple graph definition using custom streaming ---
class CustomState(TypedDict):
    topic: str
    result: str

def research_node(state: CustomState) -> dict:
    """research_node: streaming intermediate progress with get_stream_writer()."""
    writer = get_stream_writer()

    # Step 1: Notification that search begins
    writer({"step": 1, "status": "Searching", "detail": f"Searching for '{state['topic']}' ..."})

    # Step 2: Notification during analysis
    writer({"step": 2, "status": "Analyzing", "detail": "Analyzing search results..."})

    # Step 3: Notification of completion
    writer({"step": 3, "status": "complete", "detail": "Investigation completed."})

    return {"result": f"Research on '{state['topic']}' is complete."}

custom_builder = StateGraph(CustomState)
custom_builder.add_node("research", research_node)
custom_builder.add_edge(START, "research")
custom_builder.add_edge("research", END)
custom_graph = custom_builder.compile()

# --- Run with stream_mode="custom" ---
print("=== stream_mode='custom' ===")
for chunk in custom_graph.stream(
    {"topic": "LangGraph streaming"},
    stream_mode="custom",
    config=lf_config,
):
    print(f"  Custom event: {chunk}")

print("--- Simultaneous use of updates + custom ---")
for mode, chunk in custom_graph.stream(
    {"topic": "LangGraph streaming"},
    stream_mode=["updates", "custom"],
    config=lf_config,
):
    if mode == "custom":
        print(f"  [custom]  {chunk}")
    else:
        print(f"  [updates] {chunk}")
`````)

== 7.8 Event Streaming v3 — projection-based app streams

LangGraph `stream_events(..., version="v3")` adds projection handles on top of raw `stream_mode`. Raw stream modes are useful when you want to parse runtime chunks directly. v3 event streaming is better when app code wants purpose-specific handles such as `stream.messages`, `stream.values`, `stream.subgraphs`, `stream.output`, `stream.interrupts`, and `stream.extensions`.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Need],
  text(weight: "bold")[Recommended API],
  [Inspect raw node updates],
  [`graph.stream(..., stream_mode="updates")`],
  [Handle custom events directly],
  [`graph.stream(..., stream_mode="custom")`],
  [Split messages, state, and subgraphs for UI],
  [`graph.stream_events(..., version="v3")`],
  [Show resume-after-interrupt state],
  [`stream.interrupted`, `stream.interrupts`],
  [Add typed custom projections],
  [`StreamTransformer`, `StreamChannel`],
)

#code-block(`````python
# Event Streaming v3 — consume values/output projections from custom_graph.
stream = custom_graph.stream_events(
    {"topic": "LangGraph Event Streaming v3"},
    version="v3",
)
print("values projection:")
for snapshot in stream.values:
    print(snapshot)
print("final output:", stream.output)
print("interrupted:", stream.interrupted)
`````)

== 7.9 Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[streaming mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[Use],
  [`values`],
  [Return full state after each step],
  [Debugging, tracing state],
  [`updates`],
  [Return only the part changed by the node],
  [Monitor progress],
  [`messages`],
  [LLM token real-time streaming],
  [Chat UI implementation],
  [`custom`],
  [Send data from `get_stream_writer()`],
  [Progress reporting],
  [`stream_events(..., version="v3")`],
  [Projection handles for messages, values, subgraphs, output, interrupts, extensions],
  [App/UI integration],
)

=== Next Steps
→ _#link("./08_interrupts_and_time_travel.ipynb")[08_interrupts_and_time_travel.ipynb]_: Learn interrupts and time travel.
