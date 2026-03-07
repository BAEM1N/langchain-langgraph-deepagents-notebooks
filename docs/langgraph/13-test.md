# LangGraph Testing Guide - Complete Documentation

## Overview
This documentation covers testing patterns for LangGraph agents after prototyping. It's specifically designed for graphs with custom structures, distinct from basic LangChain agent testing.

## Prerequisites
Install pytest using:
```bash
pip install -U pytest
```

## Basic Testing Pattern

The recommended approach involves creating your graph before each test and compiling it with a fresh checkpointer instance. Here's a simple linear graph example:

```python
import pytest

from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver

def create_graph() -> StateGraph:
    class MyState(TypedDict):
        my_key: str

    graph = StateGraph(MyState)
    graph.add_node("node1", lambda state: {"my_key": "hello from node1"})
    graph.add_node("node2", lambda state: {"my_key": "hello from node2"})
    graph.add_edge(START, "node1")
    graph.add_edge("node1", "node2")
    graph.add_edge("node2", END)
    return graph

def test_basic_agent_execution() -> None:
    checkpointer = MemorySaver()
    graph = create_graph()
    compiled_graph = graph.compile(checkpointer=checkpointer)
    result = compiled_graph.invoke(
        {"my_key": "initial_value"},
        config={"configurable": {"thread_id": "1"}}
    )
    assert result["my_key"] == "hello from node2"
```

## Testing Individual Nodes

Access individual nodes through the compiled graph's `nodes` attribute:

```python
def test_individual_node_execution() -> None:
    checkpointer = MemorySaver()
    graph = create_graph()
    compiled_graph = graph.compile(checkpointer=checkpointer)
    result = compiled_graph.nodes["node1"].invoke(
        {"my_key": "initial_value"},
    )
    assert result["my_key"] == "hello from node1"
```

## Partial Execution Testing

Test specific sections of larger graphs without executing the entire flow. Use these steps:

1. Compile with a checkpointer (MemorySaver works for tests)
2. Call `update_state` with `as_node` parameter referencing the node before your test section
3. Invoke with `interrupt_after` to stop at your desired endpoint

Example executing nodes 2-3 only:

```python
def test_partial_execution_from_node2_to_node3() -> None:
    checkpointer = MemorySaver()
    graph = create_graph()
    compiled_graph = graph.compile(checkpointer=checkpointer)
    compiled_graph.update_state(
        config={
          "configurable": {
            "thread_id": "1"
          }
        },
        values={"my_key": "initial_value"},
        as_node="node1",
    )
    result = compiled_graph.invoke(
        None,
        config={"configurable": {"thread_id": "1"}},
        interrupt_after="node3",
    )
    assert result["my_key"] == "hello from node3"
```

This approach allows "simulating a state where your agent is paused right before the beginning of the desired section."
