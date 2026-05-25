# LangGraph Runtime (Pregel)

> 공식 문서: <https://docs.langchain.com/oss/python/langgraph/pregel>

## Overview

LangGraph runtime은 [`Pregel`](https://reference.langchain.com/python/langgraph/pregel/main/Pregel) 컴포넌트로 구현되며, 애플리케이션 실행을 관리한다. `StateGraph` 를 컴파일하거나 `@entrypoint` 데코레이터를 사용하면 invocation 가능한 Pregel 인스턴스가 생성된다.

전체 모델은 bulk synchronous parallel(BSP) 방식이다 — "**actors** read data from channels and write data to channels."

### Execution Flow

각 step은 세 단계를 거친다.

1. **Plan**: 이번 step에서 실행할 actor 선정
2. **Execution**: 선정된 actor를 병렬 실행, 완료/실패/타임아웃까지 대기
3. **Update**: actor가 쓴 값으로 채널 갱신

남은 actor가 없거나 max step에 도달할 때까지 반복된다.

## Core Components

### Actors
`PregelNode` actor는 채널을 구독하고, 데이터를 읽고, 결과를 다시 쓴다. LangChain Runnable 인터페이스를 구현한다.

### Channels
Actor 간 통신 메커니즘. value type, update type, update function을 가진다.

| Type | Purpose |
|------|---------|
| **`LastValue`** | 가장 최근 값을 저장. 입력/출력에 적합한 기본 채널 |
| **`EphemeralValue`** | 실행 step 내부에서만 유효한 임시 값 |
| **`Topic`** | 설정 가능한 PubSub, 다중 값 + optional 중복 제거 / 누적 |
| **`BinaryOperatorAggregate`** | 현재 값과 업데이트에 binary operator 적용 (러닝 토탈 등) |
| **`DeltaChannel`** (beta, `langgraph>=1.2`) | step별 incremental delta만 저장. 자주 쓰이고 빠르게 자라는 채널(메시지 리스트 등)에 적합 |

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

## DeltaChannel (Beta, `langgraph>=1.2`)

`DeltaChannel` 은 매 step의 full 누적값이 아니라 incremental delta만 저장한다. 메시지 리스트처럼 자주 쓰이고 무한히 자라는 채널의 checkpoint 비용을 줄이는 데 쓴다. Reducer는 associative해야 하며 **write 시점이 아니라 reconstruction 시점**에 실행된다.

```python
from typing import Annotated, Sequence
from typing_extensions import TypedDict
from langgraph.channels import DeltaChannel

def list_reducer(state: list, writes: Sequence[list]) -> list:
    result = list(state)
    for write in writes:
        result.extend(write)
    return result

class State(TypedDict):
    messages: Annotated[
        list[str],
        DeltaChannel(list_reducer, snapshot_frequency=5),
    ]
```

- `snapshot_frequency` 만큼 step이 진행될 때마다 full snapshot이 한 번 기록되어 reconstruction 비용을 제한한다.
- Bulk reducer 시그니처는 `(current_state, sequence_of_writes) -> new_state` 다.

---

**Note**: Pregel이라는 이름은 그래프 기반 대규모 병렬 계산을 위한 "Google's Pregel algorithm" 에서 따왔다.
