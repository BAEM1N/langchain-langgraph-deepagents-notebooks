# Custom Workflow Documentation

## Overview

The custom workflow architecture allows developers to define bespoke execution flows using LangGraph with complete control over graph structure, including sequential steps, conditional branches, loops, and parallel execution.

## Key Characteristics

- Complete control over graph structure
- Mix deterministic logic with agentic behavior
- Support for sequential steps, conditional branches, loops, and parallel execution
- Embed other patterns as nodes in your workflow

## When to Use

Custom workflows are appropriate when standard patterns don't fit requirements, you need to combine deterministic logic with agentic behavior, or your use case requires "complex routing or multi-stage processing."

Each node can be a simple function, LLM call, or entire agent with tools. You can also compose other architectures within a custom workflow—for example, embedding a multi-agent system as a single node.

## Basic Implementation

You can invoke a LangChain agent directly inside any LangGraph node:

```python
from langchain.agents import create_agent
from langgraph.graph import StateGraph, START, END

agent = create_agent(model="openai:gpt-4.1", tools=[...])

def agent_node(state: State) -> dict:
    """A LangGraph node that invokes a LangChain agent."""
    result = agent.invoke({
        "messages": [{"role": "user", "content": state["query"]}]
    })
    return {"answer": result["messages"][-1].content}

workflow = (
    StateGraph(State)
    .add_node("agent", agent_node)
    .add_edge(START, "agent")
    .add_edge("agent", END)
    .compile()
)
```

## Example: RAG Pipeline

A common use case combines retrieval with an agent. The example demonstrates a WNBA stats assistant with three node types:

- **Model node (Rewrite)**: Rewrites user queries for better retrieval using structured output
- **Deterministic node (Retrieve)**: Performs vector similarity search
- **Agent node (Agent)**: Reasons over retrieved context and fetches additional information via tools

The complete implementation includes vector store setup, tool definitions, and workflow compilation for querying WNBA information.
