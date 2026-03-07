# Subgraphs Guide - Complete Documentation

## Overview

A subgraph is a graph that functions as a node within another graph. They enable building multi-agent systems, reusing node sets across graphs, and distributing development across teams while maintaining interface contracts.

## Setup

Install LangGraph using either pip or uv:

```bash
pip install -U langgraph
```

or

```bash
uv add langgraph
```

## Subgraph Communication Patterns

Two primary patterns exist for parent-subgraph interaction:

### Pattern 1: Call Subgraph Inside a Node

**Use when:** Parent and subgraph have different state schemas with no overlapping keys, or state transformation is needed.

**Mechanism:** A wrapper function transforms parent state to subgraph input and converts results back.

```python
from typing_extensions import TypedDict
from langgraph.graph.state import StateGraph, START

class SubgraphState(TypedDict):
    bar: str

def subgraph_node_1(state: SubgraphState):
    return {"bar": "hi! " + state["bar"]}

subgraph_builder = StateGraph(SubgraphState)
subgraph_builder.add_node(subgraph_node_1)
subgraph_builder.add_edge(START, "subgraph_node_1")
subgraph = subgraph_builder.compile()

class State(TypedDict):
    foo: str

def call_subgraph(state: State):
    subgraph_output = subgraph.invoke({"bar": state["foo"]})
    return {"foo": subgraph_output["bar"]}

builder = StateGraph(State)
builder.add_node("node_1", call_subgraph)
builder.add_edge(START, "node_1")
graph = builder.compile()
```

### Pattern 2: Add Subgraph as Node

**Use when:** Parent and subgraph share state keys -- subgraph reads from and writes to parent's channels.

**Mechanism:** Pass the compiled subgraph directly to `add_node()` without a wrapper.

```python
from typing_extensions import TypedDict
from langgraph.graph.state import StateGraph, START

class State(TypedDict):
    foo: str

def subgraph_node_1(state: State):
    return {"foo": "hi! " + state["foo"]}

subgraph_builder = StateGraph(State)
subgraph_builder.add_node(subgraph_node_1)
subgraph_builder.add_edge(START, "subgraph_node_1")
subgraph = subgraph_builder.compile()

builder = StateGraph(State)
builder.add_node("node_1", subgraph)
builder.add_edge(START, "node_1")
graph = builder.compile()
```

## Subgraph Persistence

Control whether subgraphs retain memory across invocations using the `checkpointer` parameter:

### Stateless Subgraphs (Default)

Each invocation starts fresh. Two options:

**With Interrupts (Recommended):**
- Supports pause/resume via `interrupt()`
- Enables durable execution
- Default behavior: omit `checkpointer` or set to `None`
- Ideal for multi-agent systems with tool-wrapped subagents

**Without Interrupts:**
- Minimal overhead, function-call semantics
- Compile with `checkpointer=False`
- No recovery on process crash during execution

### Stateful Subgraphs

Subagent retains context across calls on the same thread -- conversation history accumulates.

Compile with `checkpointer=True`:

```python
fruit_agent = create_agent(
    model="gpt-4.1-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=True,
)
```

**Important Limitation:** Stateful subgraphs don't support parallel tool calls. Use `ToolCallLimitMiddleware` to prevent multiple simultaneous invocations of the same stateful subgraph.

## Namespace Isolation for Multiple Stateful Subgraphs

When calling multiple different stateful subgraphs within a single node, wrap each in its own `StateGraph` with a unique node name to avoid checkpoint conflicts:

```python
from langgraph.graph import MessagesState, StateGraph

def create_sub_agent(model, *, name, **kwargs):
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)
        .add_edge("__start__", name)
        .compile()
    )
```

## Checkpointer Reference

| Feature | Without Interrupts | With Interrupts | Stateful |
|---------|-------------------|-----------------|----------|
| `checkpointer=` | `False` | `None` | `True` |
| Interrupts (HITL) | No | Yes | Yes |
| Multi-turn memory | No | No | Yes |
| State inspection | No | Current invocation only | Yes |
| Multiple different subgraphs | Yes | Yes | Namespace conflicts possible |
| Same subgraph multiple times | Yes | Yes | No |

## Viewing Subgraph State

Inspect subgraph state using `get_state()` with the `subgraphs=True` option:

```python
subgraph_state = graph.get_state(config, subgraphs=True).tasks[0].state
```

Requires:
- Parent graph compiled with a checkpointer
- Subgraph is directly added as a node or called inside a node
- Does not work for subgraphs invoked within tool functions

## Streaming Subgraph Outputs

Include subgraph outputs in streamed results:

```python
for chunk in graph.stream(
    {"foo": "foo"},
    subgraphs=True,
    stream_mode="updates",
):
    print(chunk)
```

## Prerequisites for Persistence Features

The parent graph must be compiled with a checkpointer to enable:
- Interrupts
- State inspection
- Stateful memory

See the persistence documentation for details.
