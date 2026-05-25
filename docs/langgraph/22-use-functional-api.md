# Use the Functional API

> 공식 문서: <https://docs.langchain.com/oss/python/langgraph/use-functional-api>

## Overview

Functional API는 persistence, memory, human-in-the-loop, streaming을 "minimal changes to your existing code"로 도입할 수 있게 한다.

```python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langchain.chat_models import init_chat_model
```

## Core Concepts

### Creating a Simple Workflow

Entrypoint는 단일 dict 인자로 여러 입력을 받는 것이 관례다.

```python
@entrypoint(checkpointer=InMemorySaver())
def my_workflow(inputs: dict) -> int:
    value = inputs["value"]
    another_value = inputs["another_value"]
    ...
```

### Parallel Execution

여러 task를 호출해 future를 모았다가 결과를 수집하면 동시 실행이 된다.

```python
@task
def add_one(number: int) -> int:
    return number + 1

@entrypoint(checkpointer=InMemorySaver())
def graph(numbers: list[int]) -> list[int]:
    futures = [add_one(i) for i in numbers]
    return [f.result() for f in futures]
```

### Calling Graphs / Call Other Entrypoints

Graph API로 컴파일된 graph나 다른 entrypoint를 `.invoke()` 로 호출해 함수형 워크플로 안에서 그대로 합성할 수 있다.

## Advanced Features

### Streaming

Functional API의 스트리밍은 Graph API와 동일한 메커니즘을 사용한다. 커스텀 데이터를 emit하려면 `langgraph.config` 에서 `get_stream_writer` 를 가져온다.

```python
from langgraph.config import get_stream_writer

@task
def step():
    writer = get_stream_writer()
    writer("Started processing")
    ...
```

Python < 3.11 의 async 코드에서는 `StreamWriter` 를 직접 주입받는다.

```python
from langgraph.types import StreamWriter

@entrypoint(checkpointer=checkpointer)
async def main(inputs: dict, writer: StreamWriter) -> int:
    ...
```

### Retry Policy

`RetryPolicy` 로 실패 시 자동 재시도를 설정한다. 기본 정책은 일반적인 네트워크 에러 대상이며, `retry_on` 으로 대상 예외를 좁힌다.

```python
from langgraph.types import RetryPolicy

retry_policy = RetryPolicy(retry_on=ValueError)

@task(retry_policy=retry_policy)
def get_info():
    ...
```

### Set Task and Entrypoint Timeouts

`@entrypoint(timeout=5.0)` / `@task(timeout=1.0)` 로 타임아웃을 지정한다. 초과 시 `NodeTimeoutError` 가 발생하고, retry policy와 결합할 수 있다.

```python
from langgraph.errors import NodeTimeoutError

@task(timeout=1.0, retry_policy=RetryPolicy(retry_on=NodeTimeoutError))
async def call_api(url: str) -> str:
    ...
```

### Caching Tasks

`CachePolicy` 로 task 결과를 캐싱한다. `ttl` 은 캐시 유효 시간(초)을 의미한다.

```python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import CachePolicy

@entrypoint(cache=InMemoryCache())
def main(inputs: dict) -> dict[str, int]:
    ...

@task(cache_policy=CachePolicy(ttl=120))
def slow_add(x: int) -> int:
    time.sleep(1)
    return x * 2
```

### Resuming After an Error

같은 `thread_id` 로 입력에 `None` 을 전달하면 직전 실패 지점부터 재시도한다. 이미 성공한 task의 결과는 checkpoint에서 재사용된다.

### Human-in-the-Loop

`interrupt()` 함수가 실행을 일시 중단하고 사람의 검토를 기다린다. 재개는 `Command(resume=...)` 로 한다.

```python
from langgraph.types import Command, interrupt

@task
def review(input_query: str):
    feedback = interrupt(f"Please provide feedback: {input_query}")
    return feedback

# 또는 구조화된 인터럽트
human_review = interrupt({
    "question": "Is this correct?",
    "tool_call": tool_call,
})
```

## Memory Management

### Short-term memory

같은 `thread_id` 의 invocation 간에 정보를 유지한다.

```python
config = {"configurable": {"thread_id": "1"}}
graph.get_state(config)
list(graph.get_state_history(config))
```

### Long-term memory

서로 다른 thread id 사이에서도 정보를 공유한다 — 한 대화에서 학습한 정보를 다른 대화에서 활용하는 데 적합하다.

### Decoupling Return and Saved Values

`entrypoint.final()` 로 반환값과 checkpoint에 저장될 값을 분리한다 — 요약은 반환하고 detailed state는 별도 저장하는 식의 패턴에 유용하다.

```python
return entrypoint.final(value=model_response, save=messages)
```

## Interoperability

Functional API와 Graph API는 함께 쓸 수 있다. Graph API로 컴파일된 graph는 `.invoke()` 한 번으로 함수형 워크플로에 매끄럽게 합성된다.

## Reference

- 모델 예시: `gpt-3.5-turbo`, `claude-sonnet-4-6` (공식 가이드 사용 모델)
- 핵심 import 경로
  - `from langgraph.func import entrypoint, task`
  - `from langgraph.checkpoint.memory import InMemorySaver`
  - `from langgraph.config import get_stream_writer`
  - `from langgraph.types import RetryPolicy, CachePolicy, Command, interrupt, StreamWriter`
  - `from langgraph.cache.memory import InMemoryCache`
  - `from langgraph.errors import NodeTimeoutError`
  - `from langgraph.graph.message import add_messages`
