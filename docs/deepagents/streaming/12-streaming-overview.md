# Streaming Overview

## Overview
Real-time streaming capabilities for deep agents built on LangGraph's infrastructure. Enables monitoring of subagent execution, including progress tracking, token streaming, tool calls, and custom updates.

## Core Streaming Features

1. **Subagent Progress** — Track each subagent's execution steps as they run in parallel
2. **LLM Tokens** — Stream tokens from main agent and each subagent individually
3. **Tool Calls** — Monitor tool invocations and results from within subagent execution
4. **Custom Updates** — Emit user-defined signals from inside subagent nodes

## Enabling Subgraph Streaming

Set `stream_subgraphs=True` when calling the stream method:

```python
for namespace, chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Research quantum computing advances"}]},
    stream_mode="updates",
    subgraphs=True,
):
    if namespace:
        print(f"[subagent: {namespace}]")
    else:
        print("[main agent]")
    print(chunk)
```

## Namespace System

Streaming events include a namespace identifying the event source:

- `()` (empty) = Main agent
- `("tools:abc123",)` = Subagent spawned by tool call
- `("tools:abc123", "model_request:def456")` = Model request node inside subagent

## Stream Modes

- **Updates Mode**: Shows completion of each step for progress tracking
- **Messages Mode**: Streams individual tokens with metadata identifying the source agent
- **Tool Calls**: Appears in messages stream mode; displays tool invocations and results
- **Custom Mode**: Uses `get_stream_writer()` to emit progress events from within tool implementations

## Multiple Stream Modes

```python
for namespace, chunk in agent.stream(
    {"messages": [{"role": "user", "content": "..."}]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
):
    mode, data = chunk
    # Handle each mode differently
```

## Lifecycle Tracking Pattern

Monitor subagent state transitions through three phases:

1. **Pending** — Detected when main agent's model_request contains task tool calls
2. **Running** — Triggered by events from `tools:UUID` namespaces
3. **Complete** — Identified when main agent's tools node returns results
