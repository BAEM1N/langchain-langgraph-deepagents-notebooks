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

공식 문서는 세 가지 모드를 다음과 같이 분류합니다.

| Mode | `checkpointer=` | Behavior |
|------|-----------------|----------|
| Per-invocation (default) | `None` | Each call starts fresh and inherits the parent's checkpointer for interrupts within a single invocation |
| Per-thread (stateful) | `True` | State accumulates across calls on the same thread |
| Stateless | `False` | No checkpointing — runs like a plain function call, no interrupt support |

### Per-Invocation (Default)

Each invocation starts fresh while still inheriting the parent's checkpointer for interrupts and durable execution within that single run. Omit `checkpointer` or set to `None`. Ideal for multi-agent systems with tool-wrapped subagents.

```python
from langchain.agents import create_agent
from langchain.tools import tool
from langgraph.checkpoint.memory import MemorySaver

@tool
def fruit_info(fruit_name: str) -> str:
    """Look up fruit info."""
    return f"Info about {fruit_name}"

# Subagent — no checkpointer (inherits parent)
fruit_agent = create_agent(
    model="gpt-5.4-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert. Use the fruit_info tool.",
)

@tool
def ask_fruit_expert(question: str) -> str:
    """Ask the fruit expert."""
    response = fruit_agent.invoke(
        {"messages": [{"role": "user", "content": question}]},
    )
    return response["messages"][-1].content

agent = create_agent(
    model="gpt-5.4-mini",
    tools=[ask_fruit_expert],
    checkpointer=MemorySaver(),
)
```

### Stateless

Minimal overhead with function-call semantics. Compile with `checkpointer=False`. No recovery on process crash during execution; no interrupt support.

### Per-Thread (Stateful)

Subagent retains context across calls on the same thread — conversation history accumulates. Compile with `checkpointer=True`:

```python
fruit_agent = create_agent(
    model="gpt-5.4-mini",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=True,
)
```

**Important Limitation:** Per-thread subgraphs do not support parallel tool calls. When an LLM has access to a per-thread subagent as a tool, it may try to call that tool multiple times in parallel, causing checkpoint conflicts because both calls write to the same namespace. Use `ToolCallLimitMiddleware` to restrict simultaneous invocations:

```python
from langchain.agents import create_agent
from langchain.agents.middleware import ToolCallLimitMiddleware
from langgraph.checkpoint.memory import MemorySaver

agent = create_agent(
    model="gpt-5.4-mini",
    tools=[ask_fruit_expert],
    middleware=[
        ToolCallLimitMiddleware(tool_name="ask_fruit_expert", run_limit=1),
    ],
    checkpointer=MemorySaver(),
)
```

## Namespace Isolation for Multiple Per-Thread Subgraphs

When multiple different per-thread (stateful) subgraphs exist, each needs unique namespace isolation to prevent state conflicts. Wrap each in its own `StateGraph` with a distinct node name:

```python
from langgraph.graph import MessagesState, StateGraph
from langchain.agents import create_agent

def create_sub_agent(model, *, name, **kwargs):
    """Wrap an agent with a unique node name for namespace isolation."""
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)  # unique name -> stable namespace
        .add_edge("__start__", name)
        .compile()
    )

fruit_agent = create_sub_agent(
    "gpt-5.4-mini",
    name="fruit_agent",
    tools=[fruit_info],
    prompt="You are a fruit expert.",
    checkpointer=True,
)

veggie_agent = create_sub_agent(
    "gpt-5.4-mini",
    name="veggie_agent",
    tools=[veggie_info],
    prompt="You are a veggie expert.",
    checkpointer=True,
)
```

## Checkpointer Reference

| Feature | Stateless | Per-Invocation | Per-Thread |
|---------|-----------|----------------|------------|
| `checkpointer=` | `False` | `None` | `True` |
| Interrupts (HITL) | No | Yes | Yes |
| Multi-turn memory | No | No | Yes |
| State inspection | No | Current invocation only | Yes |
| Multiple different subgraphs | Yes | Yes | Namespace conflicts possible |
| Same subgraph multiple times in parallel | Yes | Yes | No |

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

Include subgraph outputs in streamed results — set `subgraphs=True` (use `version="v2"` for the namespaced chunk format):

```python
for chunk in graph.stream(
    {"foo": "foo"},
    subgraphs=True,
    stream_mode="updates",
    version="v2",
):
    print(chunk["type"])  # "updates"
    print(chunk["ns"])    # () for root, ("node_2:<id>",) for subgraph
    print(chunk["data"])  # {"node_name": {"key": "value"}}
```

## Prerequisites for Persistence Features

The parent graph must be compiled with a checkpointer to enable:
- Interrupts
- State inspection
- Stateful memory

See the persistence documentation for details.
