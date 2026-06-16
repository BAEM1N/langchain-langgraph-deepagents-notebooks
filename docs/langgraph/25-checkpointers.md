# LangGraph Checkpointers

## Overview

Checkpointer는 graph state snapshot을 각 super-step마다 저장한다. 저장 단위는 **thread**이며, `thread_id`가 같은 실행은 같은 checkpoint history를 공유한다. 이 계층은 human-in-the-loop, time travel, fault tolerance, conversational memory를 가능하게 한다.

Store와 구분해야 한다. Checkpointer는 **한 thread 안의 실행 상태**를 저장하고, Store는 **thread를 넘어 공유되는 장기 기억**을 저장한다.

## Core Concepts

| 개념 | 설명 |
|------|------|
| Thread | checkpoint 묶음의 식별자. `config={"configurable": {"thread_id": "..."}}`로 지정 |
| Checkpoint | 특정 super-step 이후의 state snapshot |
| Pending writes | 같은 super-step에서 성공한 node write를 별도로 저장해 실패 node만 재실행 가능 |
| Checkpoint namespace | subgraph/parent graph checkpoint scope 구분 |

## Basic Usage

```python
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph

checkpointer = InMemorySaver()
graph = builder.compile(checkpointer=checkpointer)

config = {"configurable": {"thread_id": "user-1"}}
result = graph.invoke({"messages": [...]}, config=config)
```

상태 조회:

```python
graph.get_state(config)
list(graph.get_state_history(config))
```

과거 checkpoint 재실행:

```python
config = {"configurable": {"thread_id": "user-1", "checkpoint_id": "..."}}
graph.invoke(None, config=config)
```

## Checkpointer Libraries

| 구현체 | 패키지 | 용도 |
|--------|--------|------|
| `InMemorySaver` | `langgraph-checkpoint` | 개발·테스트 |
| `SqliteSaver` / `AsyncSqliteSaver` | `langgraph-checkpoint-sqlite` | 로컬 영속성 |
| `PostgresSaver` / `AsyncPostgresSaver` | `langgraph-checkpoint-postgres` | 프로덕션 |
| `CosmosDBSaver` | `langchain-azure-cosmosdb` | Azure Cosmos DB |

프로덕션 DB 계열은 최초 1회 `setup()`으로 schema를 생성한다.

## Durability Modes

| Mode | 동작 | 적합한 경우 |
|------|------|-------------|
| `"exit"` | 완료/오류/interrupt 시 저장 | 최고 성능, 중간 복구 불필요 |
| `"async"` | 다음 step과 비동기 저장 | 기본 균형점 |
| `"sync"` | 다음 step 전 동기 저장 | 강한 내구성 필요 |

```python
graph.invoke(inputs, config=config, durability="sync")
```

## Optimize Checkpoint Storage

Append-heavy channel은 snapshot이 계속 커질 수 있다. LangGraph 1.2+의 `DeltaChannel`은 전체 누적값 대신 delta를 저장하고, `snapshot_frequency`마다 전체 snapshot을 남겨 읽기 지연을 제한한다.

```python
from typing_extensions import Annotated, TypedDict
from langgraph.channels.delta import DeltaChannel


def append(state: list[str], writes: list[list[str]]) -> list[str]:
    return state + [item for batch in writes for item in batch]


class State(TypedDict):
    items: Annotated[list[str], DeltaChannel(reducer=append, snapshot_frequency=50)]
```

`DeltaChannel`은 beta API다. 저장량 절감과 복구 지연 사이의 trade-off를 측정한 뒤 적용한다.

## Related

- `05-persistence.md` — persistence 전체 개념
- `06-durable-execution.md` — timeout, error handler, graceful shutdown
- `26-stores.md` — thread를 넘어 공유되는 장기 기억
