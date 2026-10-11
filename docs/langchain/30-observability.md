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

## Programmatic Run Queries

For current LangSmith SDKs, use SmithDB-backed `client.runs.query(...)` rather than `client.list_runs(...)` in new teaching code. The migration changes query shape:

- resolve project names to UUIDs first,
- pass `project_ids=[...]`,
- set explicit `min_start_time` and `max_start_time`,
- iterate async results and handle pagination/page size separately,
- pass `selects=[...]` for every field the consumer reads; the new query returns only `ID` by default,
- keep exception handling scoped to the API being migrated instead of replacing prompt, dataset, or evaluation helpers globally.

Field projection is explicit. Use SCREAMING_SNAKE_CASE names, not old lower-case attribute names:

```python
project = await client.aread_project(project_name="default")

async for run in client.runs.query(
    project_ids=[str(project.id)],
    min_start_time=start,
    max_start_time=end,
    page_size=100,
    selects=[
        "ID",
        "NAME",
        "RUN_TYPE",
        "STATUS",
        "START_TIME",
        "END_TIME",
        "INPUTS",
        "OUTPUTS",
        "TRACE_ID",
        "METADATA",
        "FEEDBACK_STATS",
        "LS_USER_ID",
    ],
):
    print(run.id, run.name, run.inputs, run.outputs, run.trace_id)
```

If a helper reads `run.name`, `run.inputs`, `run.outputs`, `run.start_time`, or `run.end_time`, include `NAME`, `INPUTS`, `OUTPUTS`, `START_TIME`, and `END_TIME`. For trace consumers and feedback summaries, add `TRACE_ID`, `METADATA`, `FEEDBACK_STATS`, and `LS_USER_ID` as needed. The Korean and English LangSmith notebooks already show the async UUID/time-window pattern for the updated cells; use those as the local code reference and check their `selects` list against the fields the cell reads.
