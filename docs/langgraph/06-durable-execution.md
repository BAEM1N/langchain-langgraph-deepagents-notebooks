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

## Code Example: Task Implementation

**Original approach (problematic):**
```python
def call_api(state: State):
    result = requests.get(state['url']).text[:100]
    return {"result": result}
```

**Improved approach with tasks:**
```python
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
