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
    model="gpt-4.1",
    tools=[...],
    middleware=[
        SummarizationMiddleware(...),
        HumanInTheLoopMiddleware(...)
    ],
)
```

## Agent Loop Architecture

The core agent cycle involves: model invocation, tool selection, execution, and termination check. Middleware provides hooks before and after each step, enabling fine-grained control over the entire workflow.

## Additional Resources

The documentation links to:

- Built-in middleware implementations
- Custom middleware development guides
- Complete API references
- Agent testing with LangSmith
