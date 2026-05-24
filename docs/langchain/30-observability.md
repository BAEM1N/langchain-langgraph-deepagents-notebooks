# LangSmith Observability Documentation

## Overview

LangChain agents automatically support tracing through LangSmith, enabling visibility into agent behavior. As stated in the documentation: "Traces record every step of your agent's execution, from the initial user input to the final response, including all tool calls, model interactions, and decision points."

## Prerequisites

Users need:
- A LangSmith account (free signup available at smith.langchain.com)
- An API key obtained through the account setup process

## Enabling Tracing

Two environment variables activate automatic tracing:

```bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
```

## Basic Usage

The documentation emphasizes that "no extra code is needed to log a trace to LangSmith." Agents created with `create_agent` automatically capture execution data when environment variables are configured.

## Selective Tracing

Users can control which operations get traced using the `tracing_context` context manager from the langsmith module, enabling granular control over what data LangSmith captures.

```python
import langsmith as ls

# This WILL be traced
with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "Send a test email to alice@example.com"}]})

# This will NOT be traced (if LANGSMITH_TRACING is not set)
agent.invoke({"messages": [{"role": "user", "content": "Send another email"}]})
```

## Project Management

By default, traces are logged to the project named `default`.

Projects can be configured either:
- **Statically**: Via the `LANGSMITH_PROJECT` environment variable
  ```bash
  export LANGSMITH_PROJECT=my-project
  ```
- **Dynamically**: Programmatically through `tracing_context` with the `project_name` parameter

## Metadata Annotation

Traces can be enriched with custom tags and metadata through the `config` parameter or within `tracing_context`, supporting production monitoring and debugging workflows.

```python
agent.invoke(
    {"messages": [{"role": "user", "content": "Send a welcome email"}]},
    config={
        "tags": ["production", "v1.0"],
        "metadata": {"user_id": "123", "session_id": "456"},
    },
)
```
