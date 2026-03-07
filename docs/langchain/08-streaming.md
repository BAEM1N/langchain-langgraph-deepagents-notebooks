# Frontend Streaming - LangGraph React

## Overview

The `useStream` React hook enables seamless integration with LangGraph streaming, handling message streaming, state management, branching logic, and interrupts for building generative UI experiences.

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
