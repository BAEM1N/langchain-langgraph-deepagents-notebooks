# LangGraph Time-Travel Documentation

## Overview

LangGraph enables developers to examine decision-making processes in non-deterministic systems by allowing execution resumption from prior checkpoints. This capability supports three key use cases:

- **Understanding reasoning**: Analyzing successful decision paths
- **Debugging mistakes**: Identifying error sources
- **Exploring alternatives**: Testing different execution routes

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

## Summary

The time-travel feature enables developers to systematically explore execution paths, debug issues, and optimize LLM-based system performance through checkpoint-based execution control.
