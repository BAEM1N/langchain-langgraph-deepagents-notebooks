# LangGraph Graph API Guide

> 공식 문서: <https://docs.langchain.com/oss/python/langgraph/use-graph-api>

## Overview

LangGraph Graph API의 기본 개념, state 관리, 그래프 구성 패턴, 그리고 고급 제어 흐름 기능을 다룬다.

## Key Concepts

### State Definition and Management

State는 `TypedDict`, Pydantic 모델, 또는 dataclass로 정의할 수 있다. "State in LangGraph can be a TypedDict, Pydantic model, or dataclass."

State 스키마는 업데이트가 처리되는 방식을 제어하는 reducer를 포함할 수 있다. `add_messages` reducer는 메시지 리스트를 위해 내장 제공되며, 기존 메시지 갱신과 단축 입력 형식 수용 같은 기능을 지원한다.

```python
from typing import Annotated
import operator
from langgraph.graph.message import add_messages
from langgraph.graph import MessagesState

# 커스텀 reducer
class MyState(TypedDict):
    messages: Annotated[list[AnyMessage], add_messages]
    aggregate: Annotated[list, operator.add]

# 또는 prebuilt MessagesState 재사용
class ChatState(MessagesState):
    summary: str
```

### Graph Building Blocks

**Nodes**는 state를 읽고 업데이트를 반환하는 Python 함수다. "Nodes should return updates to the state directly, instead of mutating the state."

**Edges**는 노드를 연결하고 실행 흐름을 정의한다. 그래프는 진입/종료 지점 표시를 위해 `START`와 `END` 특수 노드를 사용한다.

## Core Patterns

### Sequential Workflows

`add_node()` 와 `add_edge()` 로 노드를 순차 연결한다. 여러 노드를 순서대로 추가하는 단축 메서드로 `add_sequence()` 도 있다.

### Parallel Execution

의존성이 없는 노드는 동시에 실행된다. `operator.add` 같은 state reducer가 결과를 자동 병합해 안전한 동시 업데이트를 보장한다.

### Branching and Routing

**Conditional edges** 는 state를 기반으로 라우팅하며, 도착 노드 이름을 반환하는 함수를 사용한다. `Send` API는 map-reduce 패턴을 지원해 여러 노드로 작업을 동적 분배한다.

### Loops and Termination

조건 엣지로 이전 노드로 돌아가는 루프를 만들 수 있다. 조건 엣지가 `END` 로 라우팅되거나 recursion limit에 도달하면 종료된다.

## Advanced Features

### Runtime Configuration

런타임 설정은 `context_schema` + `Runtime[ContextSchema]` 방식으로 노출된다. state를 오염시키지 않고 호출 시점에 LLM 선택, 시스템 프롬프트 같은 파라미터를 전달할 수 있다.

```python
from dataclasses import dataclass
from langgraph.runtime import Runtime

@dataclass
class ContextSchema:
    my_runtime_value: str

def node(state, runtime: Runtime[ContextSchema]):
    val = runtime.context.my_runtime_value
    ...

graph.invoke({}, context={"my_runtime_value": "a"})
```

`Runtime` 객체는 다음에 접근할 수 있다.

- `execution_info` — thread ID, run ID, checkpoint 정보, attempt 번호
- `server_info` — LangGraph Server에서 assistant ID, graph ID, 인증된 사용자 정보
- `drain_requested` — graceful shutdown 신호

### State Control Mechanisms

`Overwrite` 타입은 reducer를 우회해 state 값을 직접 교체한다. `Command` 객체는 state 업데이트와 라우팅 결정을 단일 반환값으로 결합한다. 서브그래프에서 부모 그래프 노드로 이동할 때는 `Command.PARENT` 를 사용한다.

### Parallel Patterns

노드의 `defer` 파라미터는 pending 태스크가 완료될 때까지 실행을 지연시킨다 — 분기 길이가 다른 fan-out/fan-in 워크플로에 유용하다.

### Retry, Timeout, Cache, Error Handling

`add_node()` 는 다음 파라미터를 받는다.

- **`retry_policy`** — `RetryPolicy(max_attempts=..., retry_on=...)`. 기본은 대부분 예외 재시도, 단 `ValueError`/`TypeError`/`RuntimeError` 등은 제외. HTTP 라이브러리는 5xx만 재시도.
- **`timeout`** — `TimeoutPolicy(run_timeout=..., idle_timeout=...)`. 초과 시 `NodeTimeoutError` 발생, attempt별로 독립 적용. async 노드 전용.
- **`cache_policy`** — `CachePolicy(ttl=..., key_func=...)`. 컴파일 시 `InMemoryCache` 또는 `SqliteCache` 필요.
- **`error_handler`** — `NodeError` 를 받아 복구용 `Command` 를 반환.
- **`defer`** — 다른 분기 완료 후 실행.

## Async Support

노드를 `async def` 로 정의하고 `.ainvoke()` 또는 `.astream()` 을 호출하면 비동기 실행이 활성화된다. API 호출 같은 IO bound 작업의 성능을 끌어올린다.

## Visualization

`draw_mermaid_png()` 로 그래프를 Mermaid 다이어그램 또는 PNG로 렌더링할 수 있다 — 디버깅과 문서화에 활용한다.

## Installation

```bash
pip install -U langgraph
# 또는
uv add langgraph
```

가이드 본문은 각 패턴별 코드 예제를 포함하며, LangGraph 애플리케이션 디버깅/모니터링에는 LangSmith 사용을 권장한다.

## Section Map (공식 문서 기준)

1. Use the graph API
2. Setup
3. Define and update state (define, update, reducers, `MessagesState`, `Overwrite`, input/output schemas, private state, Pydantic)
4. Add runtime configuration
5. Add retry policies / node timeouts / handle node errors
6. Access execution info / server info / drain state inside a node
7. Adjust behavior based on retry state
8. Add node caching
9. Create a sequence of steps
10. Create branches — parallel, defer node execution, conditional branching, Map-Reduce + Send
11. Create and control loops / recursion limit
12. Async
13. Combine control flow and state updates with `Command` (incl. `Command.PARENT`, use inside tools)
14. Visualize your graph (Mermaid / PNG)
