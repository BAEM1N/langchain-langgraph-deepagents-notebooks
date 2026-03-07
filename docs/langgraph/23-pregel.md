# LangGraph Runtime Documentation

## Overview

LangGraph's runtime is implemented through the [`Pregel`](https://reference.langchain.com/python/langgraph/pregel/main/Pregel) component, which manages application execution. Creating a `StateGraph` or using the `@entrypoint` decorator produces a Pregel instance ready for invocation.

The system combines "**actors** read data from channels and write data to channels" through a bulk synchronous parallel model.

### Execution Flow

Each step follows three phases:

1. **Plan**: Determine which actors execute this step
2. **Execution**: Run selected actors in parallel until completion, failure, or timeout
3. **Update**: Refresh channels with new values

Repetition continues until no actors remain or max steps are reached.

## Core Components

### Actors
`PregelNode` actors subscribe to channels, read data, and write results. They implement LangChain's Runnable interface.

### Channels
Communication mechanisms between actors with value types, update types, and update functions:

- **LastValue**: Stores the most recent value; ideal for inputs/outputs
- **Topic**: Configurable PubSub for multiple values with optional deduplication
- **BinaryOperatorAggregate**: Applies operators to current values and updates

## Implementation Approaches

### Direct Pregel API

Single node example using `NodeBuilder`:

```python
from langgraph.channels import EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder

node1 = (
    NodeBuilder().subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b")
)

app = Pregel(
    nodes={"node1": node1},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
    },
    input_channels=["a"],
    output_channels=["b"],
)

app.invoke({"a": "foo"})
# Returns: {'b': 'foofoo'}
```

### Multiple Nodes

```python
from langgraph.channels import LastValue, EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder

node1 = (
    NodeBuilder().subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b")
)

node2 = (
    NodeBuilder().subscribe_only("b")
    .do(lambda x: x + x)
    .write_to("c")
)

app = Pregel(
    nodes={"node1": node1, "node2": node2},
    channels={
        "a": EphemeralValue(str),
        "b": LastValue(str),
        "c": EphemeralValue(str),
    },
    input_channels=["a"],
    output_channels=["b", "c"],
)

app.invoke({"a": "foo"})
# Returns: {'b': 'foofoo', 'c': 'foofoofoofoo'}
```

### Topic Channel Example

```python
from langgraph.channels import EphemeralValue, Topic
from langgraph.pregel import Pregel, NodeBuilder

node1 = (
    NodeBuilder().subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b", "c")
)

node2 = (
    NodeBuilder().subscribe_to("b")
    .do(lambda x: x["b"] + x["b"])
    .write_to("c")
)

app = Pregel(
    nodes={"node1": node1, "node2": node2},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
        "c": Topic(str, accumulate=True),
    },
    input_channels=["a"],
    output_channels=["c"],
)

app.invoke({"a": "foo"})
# Returns: {'c': ['foofoo', 'foofoofoofoo']}
```

### BinaryOperatorAggregate Reducer

```python
from langgraph.channels import EphemeralValue, BinaryOperatorAggregate
from langgraph.pregel import Pregel, NodeBuilder

node1 = (
    NodeBuilder().subscribe_only("a")
    .do(lambda x: x + x)
    .write_to("b", "c")
)

node2 = (
    NodeBuilder().subscribe_only("b")
    .do(lambda x: x + x)
    .write_to("c")
)

def reducer(current, update):
    if current:
        return current + " | " + update
    else:
        return update

app = Pregel(
    nodes={"node1": node1, "node2": node2},
    channels={
        "a": EphemeralValue(str),
        "b": EphemeralValue(str),
        "c": BinaryOperatorAggregate(str, operator=reducer),
    },
    input_channels=["a"],
    output_channels=["c"],
)

app.invoke({"a": "foo"})
```

### Cycle with Skip None

```python
from langgraph.channels import EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder, ChannelWriteEntry

example_node = (
    NodeBuilder().subscribe_only("value")
    .do(lambda x: x + x if len(x) < 10 else None)
    .write_to(ChannelWriteEntry("value", skip_none=True))
)

app = Pregel(
    nodes={"example_node": example_node},
    channels={
        "value": EphemeralValue(str),
    },
    input_channels=["value"],
    output_channels=["value"],
)

app.invoke({"value": "a"})
# Returns: {'value': 'aaaaaaaaaaaaaaaa'}
```

## High-Level APIs

### StateGraph (Graph API)

The StateGraph provides higher-level abstraction for creating Pregel applications:

```python
from typing import TypedDict
from langgraph.constants import START
from langgraph.graph import StateGraph

class Essay(TypedDict):
    topic: str
    content: str | None
    score: float | None

def write_essay(essay: Essay):
    return {"content": f"Essay about {essay['topic']}"}

def score_essay(essay: Essay):
    return {"score": 10}

builder = StateGraph(Essay)
builder.add_node(write_essay)
builder.add_node(score_essay)
builder.add_edge(START, "write_essay")
builder.add_edge("write_essay", "score_essay")

graph = builder.compile()
```

Inspecting compiled graph:

```python
print(graph.nodes)
# Shows: __start__, write_essay, score_essay nodes

print(graph.channels)
# Shows: topic, content, score plus internal channels
```

### Functional API

Using the `@entrypoint` decorator:

```python
from typing import TypedDict
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.func import entrypoint

class Essay(TypedDict):
    topic: str
    content: str | None
    score: float | None

checkpointer = InMemorySaver()

@entrypoint(checkpointer=checkpointer)
def write_essay(essay: Essay):
    return {"content": f"Essay about {essay['topic']}"}

print("Nodes: ")
print(write_essay.nodes)
print("Channels: ")
print(write_essay.channels)
```

---

**Note**: The Pregel name references "Google's Pregel algorithm" for efficient large-scale parallel computation using graphs.
