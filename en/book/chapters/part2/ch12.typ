// Auto-generated from 12_frontend_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "Frontend Streaming")


== Learning Objectives

Learn how to stream LLM responses to users in real time.

This notebook covers:
- Understanding the basics of LangChain SDK streaming (`.stream()`, `.astream_events()`)
- Learning the structure and usage of the `useStream` React hook
- Understanding the `StreamEvent` protocol
- Consuming real-time streaming from the Python SDK
- Understanding real-time agent-state display patterns


== 12.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

print("Environment ready.")
`````)

== 12.2 Python SDK Streaming Basics

The `.stream()` method delivers model output token by token in real time. Users can see partial results before the full response is complete.


== 12.3 `astream_events()`

`.astream_events()` streams _all internal events_ asynchronously. This lets you trace model calls, tool execution, and chain steps in detail.

=== Main event types

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Event],
  text(weight: "bold")[Description],
  [`on_chat_model_stream`],
  [Model token streaming],
  [`on_chat_model_start`],
  [Model call started],
  [`on_chat_model_end`],
  [Model call completed],
  [`on_tool_start`],
  [Tool execution started],
  [`on_tool_end`],
  [Tool execution completed],
)


#code-block(`````python
import asyncio

async def stream_events_demo():
    """Example of event streaming with astream_events()"""
    print("Event streaming:")
    print("-" * 40)
    async for event in model.astream_events(
        "Two advantages of Python",
        version="v2",
    ):
        kind = event["event"]
        if kind == "on_chat_model_stream":
            content = event["data"]["chunk"].content
            if content:
                print(content, end="", flush=True)
        elif kind == "on_chat_model_start":
            print(f"[Model call start]")
        elif kind == "on_chat_model_end":
            print(f"\n[Model call complete]")

await stream_events_demo()
`````)

== 12.4 The `useStream` React Hook

`useStream` is a React hook from the LangGraph SDK that simplifies streaming communication with a LangGraph server.

=== Basic usage

#code-block(`````tsx
import { useStream } from "@langchain/langgraph-sdk/react";

function Chat() {
  const stream = useStream({
    assistantId: "agent",
    apiUrl: "http://localhost:2024",
  });

  const handleSubmit = (message: string) => {
    stream.submit({
      messages: [{ content: message, type: "human" }],
    });
  };

  return (
    <div>
      {stream.messages.map((message, idx) => (
        <div key={message.id ?? idx}>
          {message.type}: {message.content}
        </div>
      ))}
      {stream.isLoading && <div>Loading...</div>}
      {stream.error && <div>Error: {stream.error.message}</div>}
    </div>
  );
}
`````)

=== Main return values

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Property],
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  [`messages`],
  [`Message[]`],
  [The full message list for the current thread],
  [`isLoading`],
  [`boolean`],
  [Whether the stream is active],
  [`error`],
  [`Error \\],
  [null`],
  [Error object],
  [`interrupt`],
  [`Interrupt`],
  [An interruption request (HITL)],
  [`submit()`],
  [`function`],
  [Send a message],
  [`stop()`],
  [`function`],
  [Stop the stream],
)


== 12.5 `useStream` Configuration Options

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Required],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`assistantId`],
  [O],
  [—],
  [Agent identifier (from the deployment dashboard)],
  [`apiUrl`],
  [—],
  [`localhost:2024`],
  [Agent server URL],
  [`apiKey`],
  [—],
  [—],
  [Auth token for a deployed agent],
  [`threadId`],
  [—],
  [—],
  [Connect to an existing conversation thread],
  [`onThreadId`],
  [—],
  [—],
  [Callback when a thread is created],
  [`reconnectOnMount`],
  [—],
  [`false`],
  [Reconnect to an active stream when the component mounts],
  [`onCustomEvent`],
  [—],
  [—],
  [Custom event handler],
  [`onUpdateEvent`],
  [—],
  [—],
  [State update handler],
  [`onMetadataEvent`],
  [—],
  [—],
  [Metadata event handler],
  [`messagesKey`],
  [—],
  [`"messages"`],
  [State key that stores messages],
  [`throttle`],
  [—],
  [`true`],
  [Batch state updates],
  [`initialValues`],
  [—],
  [—],
  [Cached initial state],
)


== 12.6 Thread Management and Reconnection

=== Managing Thread IDs

By managing `threadId`, you can continue a conversation or load a previous thread.

#code-block(`````tsx
const [threadId, setThreadId] = useState<string | null>(null);

const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  threadId,
  onThreadId: setThreadId,
});

// Persist threadId in a URL parameter or localStorage
`````)

=== Reconnecting After a Page Refresh

If you enable `reconnectOnMount`, the hook automatically reconnects to a stream that was already in progress after a page refresh.

#code-block(`````tsx
const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  reconnectOnMount: true, // use sessionStorage
});

// Use custom storage
const stream = useStream({
  reconnectOnMount: () => window.localStorage,
});
`````)


== 12.7 Branching and Message Editing

With branching, you can create an _alternate path_ from a specific point in the conversation history. This is useful when you want to edit a user message or regenerate an AI response.

#code-block(`````tsx
{stream.messages.map((message) => {
  const meta = stream.getMessagesMetadata(message);
  const parentCheckpoint = meta?.firstSeenState?.parent_checkpoint;

  return (
    <div key={message.id}>
      {message.content}

      {/* Edit a user message */}
      {message.type === "human" && (
        <button onClick={() => {
          const newContent = prompt("Edit:", message.content);
          if (newContent) {
            stream.submit(
              { messages: [{ type: "human", content: newContent }] },
              { checkpoint: parentCheckpoint }
            );
          }
        }}>
          Edit
        </button>
      )}

      {/* Regenerate an AI response */}
      {message.type === "ai" && (
        <button onClick={() =>
          stream.submit(undefined, { checkpoint: parentCheckpoint })
        }>
          Regenerate
        </button>
      )}
    </div>
  );
})}
`````)

Key idea: use the `checkpoint` parameter to jump back to a specific state and generate a new branch.


== 12.8 Custom Streaming Events

You can stream _custom data_ from the agent to the client. This is useful for progress updates, intermediate results, and other real-time signals.


#code-block(`````python
# Custom streaming events — Python writer pattern
print("Custom streaming event pattern (Python server side):")
print("=" * 50)
print("""
from langchain.tools import tool
from langchain.agents.types import ToolRuntime

@tool
async def analyze_data(
    data_source: str, *, config: ToolRuntime
) -> str:
    \"\"\"Analyzes the data.\"\"\"
    if config.writer:
        # Stream progress updates to the client
        config.writer({
            "type": "progress",
            "message": "Loading data...",
            "progress": 25,
        })
        # ... processing ...
        config.writer({
            "type": "progress",
            "message": "Analysis complete!",
            "progress": 100,
        })
    return '{"result": "Analysis complete"}'
""")
print("Client side (React): receive it via the onCustomEvent callback")
print('  onCustomEvent: (data) => setProgress(data.progress)')
`````)

== 12.9 Multi-Agent Streaming

When several agents collaborate, their messages should be _displayed separately_. Use the `langgraph_node` metadata field to identify which agent produced each message.

=== Event callback summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Callback],
  text(weight: "bold")[Use Case],
  text(weight: "bold")[Stream Mode],
  [`onUpdateEvent`],
  [State update after a graph step],
  [`updates`],
  [`onCustomEvent`],
  [Agent-defined custom event],
  [`custom`],
  [`onMetadataEvent`],
  [Execution and thread metadata],
  [`metadata`],
  [`onError`],
  [Error handling],
  [—],
  [`onFinish`],
  [Stream completion],
  [—],
)


== 12.10 Summary

This notebook covered:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Idea],
  [_SDK streaming_],
  [Use `.stream()` for real-time token output],
  [`astream_events`],
  [Trace model and tool calls through asynchronous event streaming],
  [`useStream`],
  [Simplify LangGraph server streaming in React],
  [_Thread management_],
  [Keep conversations alive with `threadId` and `reconnectOnMount`],
  [_Branching_],
  [Create alternate conversation paths from a `checkpoint`],
  [_Custom events_],
  [Stream progress and other custom data with a writer pattern],
  [_Multi-agent_],
  [Use `langgraph_node` metadata to distinguish messages by agent],
)

=== Next Steps
→ Continue to _#link("./13_guardrails.ipynb")[13_guardrails.ipynb]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langchain/08-streaming.md")[Streaming]
- #link("../docs/langchain/28-ui.md")[UI (Agent Chat UI & useStream)]

