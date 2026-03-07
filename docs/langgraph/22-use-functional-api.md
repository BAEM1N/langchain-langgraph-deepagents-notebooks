# LangGraph Functional API Documentation

## Overview

The Functional API enables developers to incorporate key LangGraph capabilities--persistence, memory, human-in-the-loop interactions, and streaming--into applications with "minimal changes to your existing code."

## Core Concepts

### Creating Workflows

Entrypoints accept a single dictionary argument for multiple inputs:

```python
@entrypoint(checkpointer=checkpointer)
def my_workflow(inputs: dict) -> int:
    value = inputs["value"]
    another_value = inputs["another_value"]
    ...
```

### Parallel Execution

Tasks can run concurrently by invoking multiple tasks and collecting results:

```python
@task
def add_one(number: int) -> int:
    return number + 1

@entrypoint(checkpointer=checkpointer)
def graph(numbers: list[int]) -> list[str]:
    futures = [add_one(i) for i in numbers]
    return [f.result() for f in futures]
```

## Advanced Features

### Streaming

The Functional API uses identical streaming mechanisms as the Graph API. Import `get_stream_writer` from `langgraph.config` to emit custom data during execution.

### Retry Policy

Tasks support `RetryPolicy` configuration to handle failures automatically. The default policy targets network errors; customize with `retry_on` parameter for specific exceptions.

### Task Caching

Cache task results using `CachePolicy` with TTL (time-to-live) specifications:

```python
@task(cache_policy=CachePolicy(ttl=120))
def slow_add(x: int) -> int:
    time.sleep(1)
    return x * 2
```

### Human-in-the-Loop

The `interrupt()` function pauses execution for human review. Resume using `Command` primitive with necessary data.

## Memory Management

**Short-term memory** persists information within the same thread ID across invocations. View state using `get_state()` and access history with `get_state_history()`.

**Long-term memory** stores information across different thread IDs, useful for cross-conversation learning.

### Decoupling Return and Saved Values

Use `entrypoint.final()` to separate returned results from persisted checkpoint data--helpful for returning summaries while saving detailed state.

## Interoperability

The Functional API and Graph API can be used together. Compiled graphs from Graph API integrate seamlessly within functional workflows through standard `.invoke()` calls.
