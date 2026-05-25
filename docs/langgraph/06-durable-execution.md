# Durable Execution in LangGraph - Complete Documentation

## Overview

"Durable execution is a technique in which a process or workflow saves its progress at key points, allowing it to pause and later resume exactly where it left off."

This approach proves valuable for human-in-the-loop scenarios and extended operations susceptible to interruptions or errors.

## Core Requirements

To implement durable execution, you need three elements:

1. **Persistence Layer**: Enable persistence through a checkpointer that records workflow progress
2. **Thread Identifier**: Specify a thread ID to track execution history for workflow instances
3. **Task Wrapping**: Encapsulate non-deterministic and side-effect operations inside tasks to prevent re-execution during resumption

## Determinism and Replay Strategy

When resuming workflows, execution doesn't restart from the exact stopping point. Instead, the system identifies an appropriate starting point and replays steps until reaching the previous stopping location. This necessitates wrapping operations with side effects (API calls, file writes) and non-deterministic operations (random generation) in tasks or nodes.

### Best Practices:

- Separate side-effect operations into individual tasks
- Encapsulate non-deterministic code within tasks
- Implement idempotent operations to safely handle retries
- Avoid unintended data duplication using idempotency keys

## Durability Modes

LangGraph offers three modes balancing performance and consistency:

| Mode | Behavior | Trade-off |
|------|----------|-----------|
| `"exit"` | Persists only at completion/error/interrupt | Best performance, no mid-execution recovery |
| `"async"` | Asynchronous persistence during next step | Good balance, minor crash risk |
| `"sync"` | Synchronous persistence before next step | Maximum durability, performance cost |

Pass via `durability=` on `invoke` / `stream`:

```python
graph.stream({"input": "test"}, durability="sync")
```

## Code Example: Task Implementation

**Original approach (problematic):**
```python
def call_api(state: State):
    result = requests.get(state['url']).text[:100]
    return {"result": result}
```

**Improved approach with tasks:**
```python
from langgraph.func import task

@task
def _make_request(url: str):
    return requests.get(url).text[:100]

def call_api(state: State):
    requests = [_make_request(url) for url in state['urls']]
    results = [request.result() for request in requests]
    return {"results": results}
```

## Resumption Scenarios

- **Pausing/Resuming**: Use interrupt functions and Command primitives for human-in-the-loop workflows
- **Failure Recovery**: Automatically resume from the last checkpoint using the same thread identifier

## Starting Points for Resumption

- **StateGraph**: Beginning of the node where execution halted
- **Subgraph Calls**: Parent node, then specific halted node within subgraph
- **Functional API**: The entrypoint where execution stopped


## LangGraph 1.2 Fault Tolerance

내구성 실행은 checkpoint로 **어디까지 진행했는지**를 보존한다. LangGraph 1.2의 fault tolerance 기능은 노드 시도 단위에서 **언제 포기하고, 어떻게 보정할지**를 제어한다.

### Per-node timeout

`add_node(..., timeout=TimeoutPolicy(...))`로 단일 노드 시도에 시간 제한을 둔다. 제한이 초과되면 `NodeTimeoutError`가 발생하고, retry policy가 있으면 다음 시도로 넘어간다. timeout이 발생한 시도의 partial write는 지워진다.

```python
from langgraph.types import RetryPolicy, TimeoutPolicy

builder.add_node(
    "call_model",
    call_model,
    timeout=TimeoutPolicy(idle_timeout=30),
    retry_policy=RetryPolicy(max_attempts=3),
)
```

장기 작업 노드는 `Runtime.heartbeat()`와 `refresh_on="heartbeat"`를 결합해 idle timeout을 갱신할 수 있다.

```python
from langgraph.runtime import Runtime
from langgraph.types import TimeoutPolicy

async def long_running_node(state: State, runtime: Runtime) -> dict:
    for batch in fetch_batches():
        process(batch)
        runtime.heartbeat()
    return {"result": "done"}

builder.add_node(
    "long_running_node",
    long_running_node,
    timeout=TimeoutPolicy(idle_timeout=30, refresh_on="heartbeat"),
)
```

### Node-level error handler

`error_handler=`는 retry가 모두 소진된 뒤 실행되는 보정 함수다. handler는 `NodeError`로 실패 컨텍스트를 받고, `Command`로 상태를 업데이트하거나 다른 노드로 라우팅할 수 있다.

```python
from langgraph.errors import NodeError
from langgraph.types import Command, RetryPolicy

def payment_error_handler(state: State, error: NodeError) -> Command:
    return Command(
        update={"status": f"compensated: {error.error}"},
        goto="finalize",
    )

builder.add_node(
    "charge_payment",
    charge_payment,
    retry_policy=RetryPolicy(max_attempts=3, retry_on=ConnectionError),
    error_handler=payment_error_handler,
)
```

### Graceful shutdown

장기 실행 그래프를 즉시 강제 종료하지 않고, 현재 superstep을 끝낸 뒤 checkpoint를 남기려면 `RunControl.request_drain()`을 사용한다. drain이 요청되면 런은 `GraphDrained`로 멈추고 같은 config로 나중에 재개할 수 있다.

```python
from langgraph.runtime import RunControl
from langgraph.errors import GraphDrained

control = RunControl()
control.request_drain("sigterm")

try:
    result = graph.invoke(inputs, config, control=control)
except GraphDrained as e:
    print(f"Drained: {e.reason}")

# 같은 config로 재개
graph.invoke(None, config)
```

노드 안에서는 `Runtime.drain_requested`로 drain 신호를 직접 확인할 수 있다.

```python
from langgraph.runtime import Runtime

async def my_node(state: State, runtime: Runtime) -> State:
    if runtime.drain_requested:
        return {"status": "skipped"}
    # ... 일반 처리
```

### DeltaChannel beta

기본 checkpoint는 매 superstep마다 채널 값을 전체 저장한다. 메시지 목록처럼 계속 커지는 채널은 checkpoint 비용이 커질 수 있다. `DeltaChannel`은 누적 전체값 대신 delta를 저장해 장기 thread의 저장량을 줄인다. `snapshot_frequency`로 일정 간격마다 전체 snapshot을 남겨 읽기 지연을 제한한다.

```python
from typing_extensions import Annotated, TypedDict
from langgraph.channels.delta import DeltaChannel

def append(state: list[str], writes: list[list[str]]) -> list[str]:
    return state + [item for batch in writes for item in batch]

class State(TypedDict):
    items: Annotated[
        list[str],
        DeltaChannel(reducer=append, snapshot_frequency=50),
    ]
```

`reducer`는 `(state, list[writes]) -> new_state` 형태의 pure function이어야 하며, batch 순서가 바뀌어도 같은 결과를 내는 결합 규칙을 지켜야 한다. `DeltaChannel`은 LangGraph 1.2+ beta 기능이므로, 프로덕션 적용 전 저장량·복구 지연·마이그레이션 비용을 함께 측정한다.
