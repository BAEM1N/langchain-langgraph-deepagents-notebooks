# LangChain Middleware

## Overview

Middleware enables granular control over agent execution. It serves several purposes:

- **Monitoring**: Tracking agent behavior with logging, analytics, and debugging
- **Transformation**: Modifying prompts, tool selection, and output formatting
- **Reliability**: Adding retry logic, fallback mechanisms, and early termination
- **Governance**: Implementing rate limiting, guardrails, and PII detection

## Implementation

Middleware is integrated via the `create_agent` function:

```python
from langchain.agents import create_agent
from langchain.agents.middleware import SummarizationMiddleware, HumanInTheLoopMiddleware

agent = create_agent(
    model="gpt-5.4",
    tools=[...],
    middleware=[
        SummarizationMiddleware(...),
        HumanInTheLoopMiddleware(...)
    ],
)
```

## LangGraph StateGraph Integration

Middleware hooks execute within the compiled LangGraph workflow returned by `create_agent`, allowing agents to function as nodes or subgraphs in larger StateGraph structures. Middleware is not a separate runtime: hooks run inside the compiled LangGraph that `create_agent` returns. The agent (with middleware) can be dropped into a larger StateGraph as a node or subgraph, and every middleware hook continues to run. This pattern enables complex topologies beyond simple loops, such as input classification, parallel work distribution, and integration with deterministic steps.

## Agent Loop Architecture

The core agent cycle involves three steps: (1) calling a model, (2) letting it choose tools to execute, and (3) finishing when it calls no more tools. Middleware provides hooks before and after each step, enabling fine-grained control over the entire workflow.

## Representative Built-in Middleware

Common provider-agnostic middleware shipped with LangChain:

- **LLM Tool Selector** (`LLMToolSelectorMiddleware`) — intelligently filters tools before model execution
- **Tool Retry** (`ToolRetryMiddleware`) — retries failed tool calls with exponential backoff
- **Model Fallback** (`ModelFallbackMiddleware`) — switches to alternative models on primary failure
- **Model Call Limit** (`ModelCallLimitMiddleware`) — caps model invocations per thread/run
- **PII Detection** (`PIIMiddleware`) — detects and redacts/masks/blocks sensitive data

## Additional Resources

The documentation links to:

- Built-in middleware implementations
- Custom middleware development guides
- Complete API references
- Agent testing with LangSmith
