# LangGraph Time-Travel Documentation

## Overview

LangGraph enables developers to examine decision-making processes in non-deterministic systems by allowing execution resumption from prior checkpoints. This capability supports three key use cases:

- **Understanding reasoning**: Analyzing successful decision paths
- **Debugging mistakes**: Identifying error sources
- **Exploring alternatives**: Testing different execution routes

## Two Mechanisms: Replay vs Fork

LangGraph의 time travel은 두 가지 동작으로 나뉜다.

- **Replay** — 이전 checkpoint에서 그대로 다시 실행한다. 체크포인트 이전 노드는 결과가 캐시되어 건너뛰고, 이후 노드는 다시 실행된다.
- **Fork** — 이전 checkpoint에서 state를 수정한 새 branch를 만들어 대체 경로를 탐색한다.

> Replay는 노드를 캐시에서 읽기만 하는 게 아니라 **다시 실행**한다. LLM 호출 / API 호출 / interrupt가 다시 발생하며 결과가 달라질 수 있다.

## Implementation Steps

The time-travel workflow involves four phases:

1. **Execute the graph** using `invoke()` or `stream()` methods
2. **Locate a checkpoint** via `get_state_history()` to access execution history
3. **Modify state (optional)** using `update_state()` to explore alternatives
4. **Resume execution** with `invoke()` from the selected checkpoint

## Practical Example

The documentation provides a complete workflow example that generates joke topics and writes jokes using Claude.

### Setup Requirements

```bash
pip install langchain_core langchain-anthropic langgraph
```

Initialize the model:
```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(model="claude-sonnet-4-6")
```

### Workflow Structure

The example implements a two-node graph:
- **generate_topic**: LLM call creating a joke subject
- **write_joke**: LLM call composing a joke based on the topic

The workflow uses `InMemorySaver` for checkpointing and requires a `thread_id` for tracking execution history.

### Key Methods

- `get_state_history()`: "retrieve all the states and select the one where you want to resume execution"
- `update_state()`: Creates new checkpoints with modified state values
- Resuming calls `invoke(None, config)` where config contains the target checkpoint ID

## Replay Implementation

`get_state_history()`로 원하는 시점의 checkpoint를 찾고, 그 checkpoint의 config로 `invoke(None, ...)`를 호출하면 해당 시점부터 다시 실행된다.

```python
history = list(graph.get_state_history(config))
before_joke = next(s for s in history if s.next == ("write_joke",))
replay_result = graph.invoke(None, before_joke.config)
```

`next`로 표시된 노드부터 재실행되며, 그 이전 노드 결과는 캐시에서 재사용된다.

## Fork Implementation

`update_state()`로 지정 checkpoint에 수정된 state를 적용한 새 branch를 만든다.

```python
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
)
fork_result = graph.invoke(None, fork_config)
```

> `update_state`는 thread를 **롤백하지 않는다**. 원본 실행은 그대로 두고, 지정 지점에서 갈라지는 새 checkpoint를 생성한다.

### `as_node`로 노드 지정

`as_node` 파라미터로 update를 "발생시킨 것으로 간주할" 노드를 명시한다. 다음 상황에서 사용한다.

- 병렬 branch 때문에 어느 노드가 update를 만들었는지 모호할 때
- 새 thread에 초기 state를 주입하는 테스트 시나리오
- 의도적으로 특정 노드를 건너뛰고 싶을 때

```python
fork_config = graph.update_state(
    before_joke.config,
    values={"topic": "chickens"},
    as_node="generate_topic",
)
```

지정한 노드의 후속 노드부터 실행이 재개된다.

## Interrupt 처리

time travel 중 interrupt는 항상 다시 발생한다. interrupt를 포함한 노드는 재실행되어 새로운 `Command(resume=...)`을 기다린다.

여러 interrupt가 있는 그래프에서 **나중 interrupt만** 수정하고 싶다면, 두 interrupt 사이의 checkpoint에서 fork한다. 앞선 interrupt 응답은 보존되고, 뒤의 interrupt만 다시 묻는다.

```python
between = [s for s in history if s.next == ("ask_age",)][-1]
fork_config = graph.update_state(between.config, {"value": ["modified"]})
result = graph.invoke(None, fork_config)
```

## Subgraph 고려사항

- **기본 (부모 checkpointer 상속)** — subgraph는 하나의 super-step으로 다뤄진다. subgraph 진입 직전에서 time travel하면 subgraph 전체가 다시 실행되며, 내부 중간 노드로 점프할 수 없다.
- **독립 checkpointer** — subgraph에 `checkpointer=True`를 지정하면 내부에서도 granular checkpoint가 남는다. `graph.get_state(config, subgraphs=True)`로 접근하고, 내부 checkpoint에서 fork할 수 있다.

## Use Cases

1. **Debugging** — 문제 노드 직전으로 replay해 fix를 검증
2. **Exploration** — decision 지점에서 fork해 대체 경로를 비교
3. **Human-in-the-loop** — 뒤쪽 interrupt 응답만 바꿔 결과 재생성
4. **Testing** — 새 thread에 `as_node`로 초기 state를 주입

## Summary

The time-travel feature enables developers to systematically explore execution paths, debug issues, and optimize LLM-based system performance through checkpoint-based execution control.
