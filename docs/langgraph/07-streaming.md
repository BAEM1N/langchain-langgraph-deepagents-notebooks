# LangGraph Streaming Documentation

## Overview
LangGraph provides a comprehensive streaming system to deliver real-time updates, enhancing application responsiveness by displaying outputs progressively before complete responses are ready.

## Key Streaming Capabilities

The framework supports several streaming features:

- **Graph state streaming** -- access state updates via `updates` and `values` modes
- **Subgraph outputs** -- capture outputs from parent and nested subgraphs
- **LLM tokens** -- stream token-by-token output from language models
- **Custom data** -- emit user-defined updates directly from nodes or tools
- **Multiple modes** -- combine `values`, `updates`, `messages`, `custom`, or `debug` modes

## Supported Stream Modes

| Mode | Purpose |
|------|---------|
| `values` | Streams complete state after each graph step |
| `updates` | Streams state changes after each step |
| `custom` | Streams user-defined data from nodes |
| `messages` | Streams LLM token tuples with metadata |
| `debug` | Streams comprehensive execution information |

## Basic Usage

Access streaming through `stream()` (synchronous) or `astream()` (asynchronous) methods:

```python
for chunk in graph.stream(inputs, stream_mode="updates"):
    print(chunk)
```

## Type-safe streaming (`version="v2"`) — LangGraph 1.1+

Opt-in으로 `version="v2"`를 전달하면 모든 청크가 **통일된 `StreamPart` dict** 형태로 반환된다. v1 동작은 그대로 유지되며, v2는 후방 호환성 손실 없이 점진 도입 가능하다.

### StreamPart 구조

```python
{
    "type": "values" | "updates" | "messages" | "custom" | "checkpoints" | "tasks" | "debug",
    "ns":   (),    # 서브그래프 namespace 튜플
    "data": ...,   # 모드별 payload
}
```

### 모드별 TypedDict

`langgraph.types`에서 import 가능하다. 편집기/타입체커에서 `data` 타입을 자동 내로잉할 수 있다.

| Mode | TypedDict |
|------|-----------|
| `values` | `ValuesStreamPart` |
| `updates` | `UpdatesStreamPart` |
| `messages` | `MessagesStreamPart` |
| `custom` | `CustomStreamPart` |
| `checkpoints` | `CheckpointStreamPart` |
| `tasks` | `TasksStreamPart` |
| `debug` | `DebugStreamPart` |

### 사용 예시

```python
from langgraph.types import UpdatesStreamPart, CustomStreamPart  # 타입 힌트용

for chunk in graph.stream(
    {"topic": "ice cream"},
    stream_mode=["updates", "custom"],
    version="v2",
):
    if chunk["type"] == "updates":
        for node_name, state in chunk["data"].items():
            print(f"[{node_name}] {state}")
    elif chunk["type"] == "custom":
        print(f"status: {chunk['data']}")
```

### v1 vs v2 비교

| 측면 | v1 (기본) | v2 (opt-in) |
|------|-----------|-------------|
| 반환 형태 | 모드/subgraph 조합에 따라 dict/tuple 혼재 | 항상 `StreamPart` dict |
| 모드 식별 | 튜플 첫 원소(다중모드) / 암묵적 | `chunk["type"]` 명시 필드 |
| namespace | `subgraphs=True` 시에만 tuple | 항상 `chunk["ns"]` |
| 타입 추론 | 추론 제한 | TypedDict로 자동 내로잉 |

### values 모드 + Pydantic/dataclass 강제

v2에서 `stream_mode="values"`는 그래프 state의 Pydantic 모델 / dataclass 타입으로 자동 강제된다. (invoke와 동일한 강제 규칙)

## State Streaming

**Updates mode** -- receive only state modifications:
```python
for chunk in graph.stream({"topic": "ice cream"}, stream_mode="updates"):
    print(chunk)
```

**Values mode** -- receive full state snapshots:
```python
for chunk in graph.stream({"topic": "ice cream"}, stream_mode="values"):
    print(chunk)
```

## Subgraph Streaming

Enable subgraph output streaming with:
```python
for chunk in graph.stream({"foo": "foo"}, subgraphs=True, stream_mode="updates"):
    print(chunk)
```

Outputs appear as tuples: `(namespace, data)` with namespace indicating the subgraph path.

## LLM Token Streaming

Use `messages` mode to stream tokens with metadata:

```python
for message_chunk, metadata in graph.stream(
    {"topic": "ice cream"},
    stream_mode="messages"
):
    if message_chunk.content:
        print(message_chunk.content, end="|", flush=True)
```

### Filtering by Tags

Associate tags with LLM invocations for selective streaming:

```python
model = init_chat_model(model="gpt-4.1-mini", tags=['joke'])

async for msg, metadata in graph.astream(
    {"topic": "cats"},
    stream_mode="messages"
):
    if metadata["tags"] == ["joke"]:
        print(msg.content, end="|", flush=True)
```

### Filtering by Node

Stream tokens from specific nodes using `langgraph_node` metadata:

```python
for msg, metadata in graph.stream(inputs, stream_mode="messages"):
    if msg.content and metadata["langgraph_node"] == "target_node":
        print(msg.content)
```

## Custom Data Streaming

Use `get_stream_writer()` to emit custom data from nodes or tools:

```python
from langgraph.config import get_stream_writer

def node(state: State):
    writer = get_stream_writer()
    writer({"custom_key": "Custom data"})
    return {"answer": "result"}

for chunk in graph.stream(inputs, stream_mode="custom"):
    print(chunk)
```

## Integration with Non-LangChain LLMs

Stream output from any LLM using custom mode:

```python
def call_arbitrary_model(state):
    writer = get_stream_writer()
    for chunk in your_custom_streaming_client(state["topic"]):
        writer({"custom_llm_chunk": chunk})
    return {"result": "completed"}
```

## Multiple Stream Modes

Combine modes by passing a list:

```python
for mode, chunk in graph.stream(inputs, stream_mode=["updates", "custom"]):
    print(chunk)
```

Outputs appear as `(mode, chunk)` tuples.

## Disabling Streaming

For models that don't support streaming:

```python
model = init_chat_model("claude-sonnet-4-6", streaming=False)
# Or use: disable_streaming=True
```

## Async Considerations (Python < 3.11)

In Python versions before 3.11, context propagation requires manual intervention:

1. **Pass RunnableConfig explicitly** to async LLM calls:
```python
async def call_model(state, config):
    response = await model.ainvoke(messages, config)
    return {"result": response.content}
```

2. **For custom streaming**, accept `writer` parameter directly:
```python
async def generate_joke(state: State, writer: StreamWriter):
    writer({"custom_key": "data"})
    return {"joke": "result"}
```

## Debug Mode

Enable comprehensive execution tracing:

```python
for chunk in graph.stream({"topic": "ice cream"}, stream_mode="debug"):
    print(chunk)
```
