# Streaming

This page covers two layers:

1. **Backend streaming** — the Python `agent.stream(...)` / `agent.ainvoke(...)` API exposed by `create_agent`. Use this when you are writing the agent itself or any Python service that wraps it.
2. **Frontend streaming** — the `useStream` React hook from `@langchain/langgraph-sdk/react`. Use this when you are building a browser UI on top of a LangGraph deployment.

The two layers interoperate: the backend emits stream chunks (updates / messages / custom / interrupt), and the frontend hook subscribes to the same event types.

---

## Backend Streaming (LangGraph ≥ 1.1, `version="v2"`)

LangChain agents run on top of LangGraph, so `agent.stream(...)` returns a stream of chunks describing what is happening inside the graph. Passing `version="v2"` switches to the unified chunk shape, where every chunk is a dict with `type`, `ns`, and `data` keys (no more tuple unpacking).

### Stream modes

| `stream_mode` | Emits |
|---|---|
| `"updates"` | State updates after each agent step (each node's output) |
| `"messages"` | `(token, metadata)` tuples from any node where an LLM is invoked |
| `"custom"` | Custom payloads emitted from inside nodes via the stream writer |

You can pass multiple modes as a list: `stream_mode=["updates", "custom"]`.

### `invoke(..., version="v2")` return type

When you call `agent.invoke(...)` with `version="v2"`, the return value is a `GraphOutput` object exposing:

- `.value` — the final graph state
- `.interrupts` — a tuple of `Interrupt` objects raised during the run

```python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Hello"}]},
    version="v2",
)
print(result.value)
print(result.interrupts)
```

### `stream_mode="updates"`

```python
from langchain.agents import create_agent
from langchain_core.utils.uuid import uuid7
from langgraph.checkpoint.memory import InMemorySaver

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[get_weather],
    checkpointer=InMemorySaver(),
)

config = {"configurable": {"thread_id": str(uuid7())}}
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    config=config,
    stream_mode="updates",
    version="v2",
):
    if chunk["type"] == "updates":
        for step, data in chunk["data"].items():
            print(f"step: {step}")
            print(f"content: {data['messages'][-1].content_blocks}")
```

### `stream_mode="messages"` + reasoning blocks + tool-call aggregation

```python
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="gpt-5-nano",
    tools=[get_weather],
)

full_message = None
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="messages",
    version="v2",
):
    if chunk["type"] != "messages":
        continue

    token, metadata = chunk["data"]

    # Filter reasoning content via the normalized content_blocks property
    reasoning = [b for b in token.content_blocks if b["type"] == "reasoning"]
    if reasoning:
        print(f"[thinking] {reasoning[0]['reasoning']}")

    # Aggregate partial chunks into a complete message; tool_calls are only
    # finalized on the last chunk of a given message
    full_message = token if full_message is None else full_message + token
    if token.chunk_position == "last" and full_message.tool_calls:
        print(f"Tool calls: {full_message.tool_calls}")
        full_message = None
```

The normalized `content_blocks` property exposes reasoning consistently across providers (Anthropic `thinking`, OpenAI `reasoning`, etc.). `chunk_position == "last"` marks the final partial of a streamed message — useful to know when the assembled `tool_calls` are ready.

### `stream_mode="custom"` with `get_stream_writer()`

Emit arbitrary payloads from inside tools or nodes using `get_stream_writer()` from `langgraph.config`:

```python
from langchain.agents import create_agent
from langgraph.config import get_stream_writer

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    writer = get_stream_writer()
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[get_weather],
)

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in SF?"}]},
    stream_mode="custom",
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])
```

### Human-in-the-loop: capturing `"__interrupt__"` and resuming

Interrupts surface inside `stream_mode="updates"` chunks under the special source key `"__interrupt__"`. Resume with a `Command(resume=...)` payload.

```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langchain.messages import AIMessage, AIMessageChunk, AnyMessage, ToolMessage
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, Interrupt

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

checkpointer = InMemorySaver()
agent = create_agent(
    "openai:gpt-5.4",
    tools=[get_weather],
    middleware=[HumanInTheLoopMiddleware(interrupt_on={"get_weather": True})],
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "some_id"}}
interrupts: list[Interrupt] = []

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Look up the weather in Boston and SF."}]},
    config=config,
    stream_mode=["messages", "updates"],
    version="v2",
):
    if chunk["type"] == "updates":
        for source, update in chunk["data"].items():
            if source == "__interrupt__":
                interrupts.extend(update)

# Build a decisions dict keyed by interrupt id and resume
decisions = {
    interrupt.id: {
        "decisions": [
            {"type": "approve"} for _ in interrupt.value["action_requests"]
        ],
    }
    for interrupt in interrupts
}

for chunk in agent.stream(
    Command(resume=decisions),
    config=config,
    stream_mode=["messages", "updates"],
    version="v2",
):
    ...
```

### Sub-agents: `name=...` + `subgraphs=True`

Set a `name` on each sub-agent so streamed chunks carry an `lc_agent_name` in metadata, and pass `subgraphs=True` to stream events from nested graphs:

```python
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model

def get_weather(city: str) -> str:
    return f"It's always sunny in {city}!"

weather_agent = create_agent(
    model=init_chat_model("openai:gpt-5.4"),
    tools=[get_weather],
    name="weather_agent",
)

def call_weather_agent(query: str) -> str:
    """Query the weather agent."""
    result = weather_agent.invoke({"messages": [{"role": "user", "content": query}]})
    return result["messages"][-1].text

agent = create_agent(
    model=init_chat_model("openai:gpt-5.4"),
    tools=[call_weather_agent],
    name="supervisor",
)

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "What is the weather in Boston?"}]},
    stream_mode=["messages", "updates"],
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "messages":
        token, metadata = chunk["data"]
        agent_name = metadata.get("lc_agent_name")
        # … render with per-agent labels
```

### Disabling streaming

To skip token-level streaming for a specific model, pass `streaming=False` to the chat model constructor, or `disable_streaming=True` (available on all chat models):

```python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4", streaming=False)
# or
model = ChatOpenAI(model="gpt-5.4", disable_streaming=True)
```

---

# Frontend Streaming — LangGraph React

## Overview

The `useStream` React hook enables seamless integration with LangGraph streaming, handling message streaming, state management, branching logic, and interrupts for building generative UI experiences.


## Event Streaming v3 (LangChain 1.3+)

LangChain agent는 LangGraph 위에서 실행되므로 `stream_events(..., version="v3")`를 통해 **메시지, 도구 호출, 상태, 커스텀 이벤트**를 projection 단위로 소비할 수 있다. 기존 `.stream()`은 토큰 또는 상태 chunk를 직접 순회하는 저수준 API이고, v3 event streaming은 프런트엔드/서비스 코드에서 파싱 부담을 줄이는 고수준 API다.

```python
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """도시 날씨를 조회한다."""
    return f"{city}: 맑음"

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[get_weather],
)

stream = agent.stream_events(
    {"messages": [{"role": "user", "content": "서울 날씨 알려줘"}]},
    version="v3",
)

for message in stream.messages:
    for token in message.text:
        print(token, end="", flush=True)

final_state = stream.output
```

### 언제 v3를 쓰나

| 필요 | 권장 API | 이유 |
|------|----------|------|
| 간단한 모델 토큰 출력 | `.stream()` | 최소 코드 |
| Agent 메시지·도구 호출·상태를 UI에 분리 표시 | `stream_events(..., version="v3")` | projection(`messages`, `tool_calls`, `values`, `output`) 제공 |
| raw 이벤트 프로토콜 디버깅 | run stream 직접 순회 | `event["method"]`, `event["params"]` 확인 |
| LangGraph 서버/React UI | `useStream` 또는 Agent Server streaming | 재연결·thread·interrupt 처리 포함 |

주의: v3 event streaming은 LangChain 1.3+ 기준이다. 오래된 런타임에서는 기존 `.stream()` / `.astream_events(version="v2")` 예제를 유지한다.

## Key Features

- **Messages streaming**: Process message chunks into complete messages
- **Automatic state management**: Handles messages, interrupts, loading states, and errors
- **Conversation branching**: Create alternate conversation paths from any chat history point
- **UI-agnostic design**: Use custom components and styling

## Installation

Install the LangGraph SDK to access the `useStream` hook in React applications.

## Basic Usage Example

```tsx
import { useStream } from "@langchain/langgraph-sdk/react";

function Chat() {
  const stream = useStream({
    assistantId: "agent",
    apiUrl: "http://localhost:2024", // Local development
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
```

## Configuration Parameters

**Required:**

- `assistantId` (string): Agent identifier matching deployment dashboard

**Optional:**

- `apiUrl`: Agent Server URL (defaults to localhost:2024)
- `apiKey`: Authentication token for deployed agents
- `threadId`: Connect to existing conversation thread
- `onThreadId`: Callback when thread is created
- `reconnectOnMount`: Resume ongoing runs on component mount
- `onCreated`: Callback when run starts
- `onError`: Error handling callback
- `onFinish`: Completion callback with final state
- `onCustomEvent`: Handle custom events from agent
- `onUpdateEvent`: Handle state updates after graph steps
- `onMetadataEvent`: Receive run and thread metadata
- `messagesKey`: State key containing messages (default: "messages")
- `throttle`: Batch state updates (default: true)
- `initialValues`: Initial state for cached display

## Return Values

- `messages`: All messages in current thread
- `values`: Current graph state
- `isLoading`: Stream in progress indicator
- `error`: Error object or null
- `interrupt`: Current interrupt requiring user input
- `toolCalls`: All tool calls with results and states
- `submit()`: Submit input to agent
- `stop()`: Stop current stream
- `joinStream()`: Resume stream by run ID
- `setBranch()`: Switch conversation branch
- `getToolCalls()`: Extract tool calls from message
- `getMessagesMetadata()`: Get message metadata including checkpoint info
- `experimental_branchTree`: Advanced branching control

## Thread Management

Track conversations and enable resumption:

```tsx
const [threadId, setThreadId] = useState<string | null>(null);

const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  threadId,
  onThreadId: setThreadId,
});
```

Store `threadId` in URL parameters or localStorage for persistence.

## Resume After Page Refresh

Enable automatic resumption using `reconnectOnMount`:

```tsx
const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  reconnectOnMount: true, // Uses sessionStorage
});
```

Or with custom storage:

```tsx
const stream = useStream({
  reconnectOnMount: () => window.localStorage,
});
```

## Optimistic Updates

Update client state before network requests for immediate feedback:

```tsx
stream.submit(
  { messages: [newMessage] },
  {
    optimisticValues(prev) {
      return {
        ...prev,
        messages: [...(prev.messages ?? []), newMessage],
      };
    },
  }
);
```

## Optimistic Thread Creation

Use predetermined thread IDs for UI patterns requiring thread ID before creation:

```tsx
const optimisticThreadId = crypto.randomUUID();
stream.submit(
  { messages: [{ type: "human", content: text }] },
  { threadId: optimisticThreadId }
);
```

## Cached Thread Display

Display cached data immediately while loading server history:

```tsx
const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  threadId,
  initialValues: cachedData?.values,
});
```

## Branching Implementation

Enable editing and regenerating responses:

```tsx
{stream.messages.map((message) => {
  const meta = stream.getMessagesMetadata(message);
  const parentCheckpoint = meta?.firstSeenState?.parent_checkpoint;

  return (
    <div key={message.id}>
      {message.type === "human" && (
        <button
          onClick={() => {
            const newContent = prompt("Edit:", message.content);
            if (newContent) {
              stream.submit(
                { messages: [{ type: "human", content: newContent }] },
                { checkpoint: parentCheckpoint }
              );
            }
          }}
        >
          Edit
        </button>
      )}
      {message.type === "ai" && (
        <button
          onClick={() =>
            stream.submit(undefined, { checkpoint: parentCheckpoint })
          }
        >
          Regenerate
        </button>
      )}
    </div>
  );
})}
```

## Type-Safe Streaming

### With createAgent

Define tool call types matching your Python agent:

```typescript
export type GetWeatherToolCall = {
  name: "get_weather";
  args: { location: string };
  id?: string;
};

export interface AgentState {
  messages: Message<GetWeatherToolCall>[];
}
```

### With StateGraph

Define state matching your graph's TypedDict:

```typescript
export interface GraphState {
  messages: Message[];
}
```

## Rendering Tool Calls

Extract and display tool calls from messages:

```tsx
const toolCalls = stream.getToolCalls(message);

{toolCalls.map((toolCall) => (
  <ToolCallCard key={toolCall.id} toolCall={toolCall} />
))}
```

Access tool call details with type safety:

```typescript
export type ToolCallWithResult<T> = {
  call: T;
  result?: ToolMessage;
  state: "pending" | "completed" | "error";
};
```

## Custom Streaming Events

Stream custom data from agents using the `writer`:

```python
@tool
async def analyze_data(data_source: str, *, config: ToolRuntime) -> str:
    if config.writer:
        config.writer({
            "type": "progress",
            "id": f"analysis-{int(time.time() * 1000)}",
            "message": "Processing...",
            "progress": 75,
        })
    return '{"result": "Complete"}'
```

Handle custom events in UI:

```tsx
const handleCustomEvent = (data: unknown) => {
  if (isProgressData(data)) {
    setProgressData((prev) => {
      const updated = new Map(prev);
      updated.set(data.id, data);
      return updated;
    });
  }
};

const stream = useStream<AgentState>({
  assistantId: "custom-streaming",
  apiUrl: "http://localhost:2024",
  onCustomEvent: handleCustomEvent,
});
```

## Event Handling

Available callbacks for different streaming events:

| Callback | Purpose | Stream mode |
|----------|---------|------------|
| `onUpdateEvent` | State updates after graph steps | `updates` |
| `onCustomEvent` | Custom events from graph | `custom` |
| `onMetadataEvent` | Run and thread metadata | `metadata` |
| `onError` | Error handling | - |
| `onFinish` | Stream completion | - |

## Multi-Agent Streaming

Identify message sources using metadata for distinct styling:

```tsx
const metadata = stream.getMessagesMetadata?.(message);
const nodeName = metadata?.streamMetadata?.langgraph_node;

const config = NODE_CONFIG[nodeName];
if (config) {
  return (
    <div className={`bg-${config.color}-950/30`}>
      <div className={`text-${config.color}-400`}>
        {config.label}
      </div>
      {message.content}
    </div>
  );
}
```

## Human-in-the-Loop Workflows

Handle interrupts requiring human approval:

```tsx
const stream = useStream<AgentState, { InterruptType: HITLRequest }>({
  assistantId: "human-in-the-loop",
  apiUrl: "http://localhost:2024",
});

const hitlRequest = stream.interrupt?.value as HITLRequest | undefined;

const handleApprove = async () => {
  if (!hitlRequest) return;

  const decisions = hitlRequest.actionRequests.map(() => ({
    type: "approve",
  }));

  await stream.submit(null, {
    command: { resume: { decisions } },
  });
};
```

## Reasoning Models Support

Extract reasoning/thinking content from models with extended reasoning:

```typescript
export function getReasoningFromMessage(message: Message): string | undefined {
  const msg = message as MessageWithExtras;

  // Check OpenAI reasoning
  if (msg.additional_kwargs?.reasoning?.summary) {
    return msg.additional_kwargs.reasoning.summary
      .filter((item) => item.type === "summary_text")
      .map((item) => item.text)
      .join("");
  }

  // Check Anthropic thinking
  if (msg.contentBlocks?.length) {
    return msg.contentBlocks
      .filter((b) => b.type === "thinking" && b.thinking)
      .map((b) => b.thinking)
      .join("\n");
  }

  return undefined;
}
```

Display reasoning separately:

```tsx
{reasoning && (
  <div className="bg-amber-950/50 border border-amber-500/20 rounded-2xl">
    <div className="text-sm text-amber-100/90">
      {reasoning}
    </div>
  </div>
)}
```

## Custom Transport

Connect to custom API endpoints using `FetchStreamTransport`:

```tsx
const stream = useStream({
  transport: new FetchStreamTransport({
    url: "https://custom-endpoint.com",
  }),
});
```

## Related Resources

- Streaming overview documentation
- useStream API Reference
- Agent Chat UI component
- Human-in-the-loop configuration guide
- Multi-agent systems patterns
