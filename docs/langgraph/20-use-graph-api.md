# LangGraph Graph API Guide

## Overview

This comprehensive guide covers LangGraph's Graph API fundamentals, including state management, graph construction patterns, and advanced control flow features.

## Key Concepts

### State Definition and Management

State in LangGraph can be defined using `TypedDict`, Pydantic models, or dataclasses. The documentation explains: "State in LangGraph can be a TypedDict, Pydantic model, or dataclass."

State schemas can include reducers to control how updates are processed. The `add_messages` reducer is built-in for handling message lists with features like updating existing messages and accepting shorthand formats.

### Graph Building Blocks

**Nodes** are Python functions that read state and return updates. As noted: "Nodes should return updates to the state directly, instead of mutating the state."

**Edges** connect nodes and define execution flow. The graph uses `START` and `END` special nodes to mark entry and exit points.

## Core Patterns

### Sequential Workflows

Graphs can chain nodes in sequence using `add_node()` and `add_edge()`. A shorthand method `add_sequence()` simplifies adding multiple nodes in order.

### Parallel Execution

Multiple nodes execute concurrently when they have no dependencies. State reducers (like `operator.add`) enable safe concurrent updates by automatically merging results.

### Branching and Routing

**Conditional edges** route execution based on state using functions that return destination node names. The `Send` API supports map-reduce patterns, dynamically dispatching work to multiple nodes.

### Loops and Termination

Graphs can loop using conditional edges that route back to previous nodes. Termination occurs when a conditional edge routes to `END` or when a recursion limit is reached.

## Advanced Features

### Runtime Configuration

Graphs accept configuration at invocation time without polluting state. This enables runtime parameter specification for items like LLM selection or system prompts.

### State Control Mechanisms

The `Overwrite` type bypasses reducers to directly replace state values. The `Command` object combines state updates with routing decisions in a single return value.

### Parallel Patterns

The `defer` parameter on nodes delays execution until pending tasks complete--useful for fan-out/fan-in workflows with unequal branch lengths.

### Caching and Retry Policies

Nodes support individualized caching policies via `CachePolicy` and retry logic through `RetryPolicy`, enabling resilience for expensive operations.

## Async Support

Graphs support async execution by using `async def` for nodes and calling `.ainvoke()` or `.astream()`. This improves performance for IO-bound operations like API calls.

## Visualization

Graphs can be rendered as Mermaid diagrams or PNG images using `draw_mermaid_png()`, aiding debugging and documentation.

## Installation

Install via: `pip install -U langgraph` or `uv add langgraph`

The guide includes extensive code examples for each pattern and emphasizes using LangSmith for debugging and monitoring LangGraph applications.
