# LangSmith Observability Documentation

## Overview
LangSmith provides visualization capabilities for application execution traces. A trace represents the journey from input to output through individual steps called runs.

## Key Capabilities
According to the documentation, LangSmith enables users to:
- "Debug a locally running application"
- Evaluate application performance through assessments
- Monitor applications via dashboards

## Getting Started Requirements
Users need two things: a free LangSmith account at smith.langchain.com and an API key obtained through their account settings.

## Enabling Tracing
To activate tracing, set these environment variables:
```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
export LANGSMITH_PROJECT=my-agent-project
```

`LANGSMITH_TRACING` and `LANGSMITH_API_KEY` are required. `LANGSMITH_PROJECT` is optional and defaults to `default` if unset.

## Selective Tracing
The `tracing_context` context manager toggles tracing for specific operations:

```python
import langsmith as ls

# This WILL be traced
with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "Send a test email to alice@example.com"}]})

# This will NOT be traced (if LANGSMITH_TRACING is not set)
agent.invoke({"messages": [{"role": "user", "content": "Send another email"}]})
```

Dynamic project selection works the same way:

```python
with ls.tracing_context(project_name="email-agent-test", enabled=True):
    response = agent.invoke({
        "messages": [{"role": "user", "content": "Send a welcome email"}]
    })
```

## Metadata and Tagging
Annotate traces with tags and metadata via the `config` argument of `invoke()`:

```python
response = agent.invoke(
    {"messages": [{"role": "user", "content": "Send a welcome email"}]},
    config={
        "tags": ["production", "email-assistant", "v1.0"],
        "metadata": {
            "user_id": "user_123",
            "session_id": "session_456",
            "environment": "production",
        },
    },
)
```

Or attach them through `tracing_context`:

```python
with ls.tracing_context(
    project_name="email-agent-test",
    enabled=True,
    tags=["production", "email-assistant", "v1.0"],
    metadata={"user_id": "user_123", "session_id": "session_456", "environment": "production"},
):
    response = agent.invoke(
        {"messages": [{"role": "user", "content": "Send a welcome email"}]}
    )
```

## Data Privacy
LangSmith supports anonymizers that mask sensitive information patterns before logging. Wire the anonymized `Client` into a `LangChainTracer` and attach it to the compiled graph via `.with_config({"callbacks": [...]})`:

```python
from langchain_core.tracers.langchain import LangChainTracer
from langgraph.graph import StateGraph, MessagesState
from langsmith import Client
from langsmith.anonymizer import create_anonymizer

anonymizer = create_anonymizer([
    {"pattern": r"\b\d{3}-?\d{2}-?\d{4}\b", "replace": "<ssn>"},
])

tracer_client = Client(anonymizer=anonymizer)
tracer = LangChainTracer(client=tracer_client)
graph = (
    StateGraph(MessagesState)
    ...
    .compile()
    .with_config({"callbacks": [tracer]})
)
```
