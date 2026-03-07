# LangGraph Functional API Documentation

## Overview

The Functional API enables developers to integrate LangGraph's core capabilities--persistence, memory, human-in-the-loop interactions, and streaming--into existing applications with minimal code restructuring.

### Key Components

**`@entrypoint`** decorator marks workflow starting points and manages execution flow, handling long-running operations and interrupts.

**`@task`** decorator represents discrete work units (API calls, data processing) executed asynchronously within entrypoints.

## Functional vs. Graph API

| Aspect | Functional | Graph |
|--------|-----------|-------|
| **Control Flow** | Uses standard Python constructs (if/for); less boilerplate | Requires explicit graph structure |
| **State Management** | Function-scoped; no explicit reducer setup | Requires State declaration and reducers |
| **Checkpointing** | Saves task results to existing checkpoints | Creates checkpoint after each superstep |
| **Visualization** | Runtime-generated; not visualizable | Easily visualized for debugging |

## Core Concepts

### Entrypoint Definition

An entrypoint accepts a single positional argument (use dictionaries for multiple values). Decorated functions produce a `Pregel` instance managing execution.

**Critical requirement:** Inputs and outputs must be JSON-serializable.

### Injectable Parameters

Entrypoints can request automatic parameter injection:

- **`previous`**: Accesses prior checkpoint state for continuity
- **`store`**: Enables long-term memory via `BaseStore`
- **`writer`**: Accesses `StreamWriter` for async operations
- **`config`**: Runtime configuration access

### Task Execution

Tasks return future-like objects. Results are obtained via:
- `.result()` for synchronous retrieval
- `await` for asynchronous retrieval

## Important Patterns

### Serialization Requirements

Both entrypoint inputs/outputs and task outputs require JSON serializability. Non-serializable data causes runtime errors when checkpointers are configured.

### Determinism Principle

"Any randomness should be encapsulated inside of tasks" to ensure consistent workflow resumption sequences. When execution resumes, previously computed task results are retrieved, avoiding redundant recalculation.

### Resumption Mechanics

Resume workflows using `Command(resume=value)` with the same `thread_id`. For error recovery, invoke with `None` as input while maintaining the thread identifier.

### Common Pitfalls

**Side Effects**: Place file writes, emails, and similar operations in tasks to prevent duplicate execution on resumption.

**Non-deterministic Control Flow**: Encapsulate time checks, random generation, and other variable operations in tasks to maintain execution order consistency.

## Short-Term Memory

The `previous` parameter stores the prior invocation's return value. The `entrypoint.final[return_type, save_type]` primitive decouples returned values from checkpoint-saved values.

## Execution Methods

- `invoke()`: Synchronous execution
- `ainvoke()`: Asynchronous execution
- `stream()`: Synchronous streaming
- `astream()`: Asynchronous streaming

All methods require configuration with `thread_id` for persistence.
