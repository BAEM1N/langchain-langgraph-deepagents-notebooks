# Data Analysis Agent

This tutorial walks through building a data analysis agent using the Deep Agents SDK. The agent can ingest CSV files, perform exploratory data analysis, execute code against the data, and deliver results via Slack.

## Overview

The data analysis agent leverages Deep Agents' autonomous planning capabilities to:

- Read and understand CSV file contents
- Write and execute Python analysis code
- Search the web for context using Tavily
- Send formatted results to Slack channels

## Prerequisites

```bash
pip install deep-agents tavily-python slack-sdk
```

Set the required environment variables:

```bash
export ANTHROPIC_API_KEY="your-api-key"
export TAVILY_API_KEY="your-tavily-key"
export SLACK_BOT_TOKEN="your-slack-bot-token"
```

## Compute Backends

Deep Agents supports multiple compute backends for code execution. Choose based on your infrastructure needs.

| Backend | Use Case | Setup |
|---------|----------|-------|
| `Daytona` | Cloud sandboxed environments | Requires Daytona account and API key |
| `Modal` | Serverless GPU/CPU compute | Requires Modal account |
| `Runloop` | Managed cloud execution | Requires Runloop API key |
| `LocalShell` | Local development and testing | No additional setup required |

### Configuring a Backend

```python
from deepagents.backends import Daytona, Modal, Runloop, LocalShell

# Cloud backends
backend = Daytona(api_key="your-daytona-key")
backend = Modal()
backend = Runloop(api_key="your-runloop-key")

# Local development
backend = LocalShell()
```

## Building the Agent

### Step 1: Configure the Search Tool

Use TavilyClient to give the agent web search capabilities for looking up domain-specific context during analysis.

```python
from tavily import TavilyClient

tavily_client = TavilyClient(api_key="your-tavily-key")

def tavily_search(query: str) -> str:
    """Search the web for information relevant to the analysis."""
    results = tavily_client.search(query, max_results=5)
    return "\n".join([r["content"] for r in results["results"]])
```

### Step 2: Define Custom Tools

Create domain-specific tools using the `@tool` decorator. Below is an example Slack notification tool.

```python
from deepagents import tool
from slack_sdk import WebClient

slack_client = WebClient(token="your-slack-bot-token")

@tool
def slack_send_message(channel: str, message: str) -> str:
    """Send a message to a Slack channel with analysis results.

    Args:
        channel: The Slack channel name or ID (e.g., '#data-reports').
        message: The formatted message content to send.

    Returns:
        Confirmation string with the message timestamp.
    """
    response = slack_client.chat_postMessage(channel=channel, text=message)
    return f"Message sent successfully. Timestamp: {response['ts']}"
```

### Step 3: Create the Agent

Assemble the agent using `create_deep_agent()` with your chosen model, tools, backend, and checkpointer.

```python
from deepagents import create_deep_agent
from deepagents.checkpointers import InMemorySaver

backend = LocalShell()
checkpointer = InMemorySaver()

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    tools=[tavily_search, slack_send_message],
    backend=backend,
    checkpointer=checkpointer,
)
```

### Step 4: Run the Agent

```python
result = agent.invoke(
    "Analyze the sales data in /data/sales_q4.csv. "
    "Find the top performing regions, identify trends, "
    "and send a summary to #data-reports on Slack."
)
```

## Agent Execution Flow

When invoked, the agent autonomously follows this execution flow:

1. **Planning** -- The agent calls `write_todos` to create a structured plan for the analysis task. This plan is stored and updated as the agent progresses.

2. **File Reading** -- The agent reads the specified CSV file to understand its structure, column names, data types, and row count.

3. **Code Generation and Execution** -- The agent writes Python code (using pandas, matplotlib, etc.) and executes it against the backend. The backend provides an isolated environment for safe code execution.

4. **Iterative Analysis** -- Based on initial results, the agent may refine its approach, run additional queries, or search the web for domain context using Tavily.

5. **Result Delivery** -- The agent formats findings and sends them to the specified Slack channel using the custom tool.

## Checkpointing and Resumption

The checkpointer enables the agent to save progress and resume from where it left off in case of interruption.

```python
from deepagents.checkpointers import InMemorySaver, SQLiteSaver, PostgresSaver

# In-memory (development only, lost on restart)
checkpointer = InMemorySaver()

# SQLite (persisted to disk)
checkpointer = SQLiteSaver(db_path="./agent_checkpoints.db")

# PostgreSQL (production)
checkpointer = PostgresSaver(connection_string="postgresql://...")
```

## Configuration Options

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | `str` | The model identifier (e.g., `"claude-sonnet-4-6"`) |
| `tools` | `list` | List of tool functions available to the agent |
| `backend` | `Backend` | Compute backend for code execution |
| `checkpointer` | `Checkpointer` | State persistence mechanism |

## Example: Full Data Analysis Pipeline

```python
from deepagents import create_deep_agent, tool
from deepagents.backends import LocalShell
from deepagents.checkpointers import InMemorySaver
from tavily import TavilyClient
from slack_sdk import WebClient

# Initialize clients
tavily_client = TavilyClient(api_key="your-tavily-key")
slack_client = WebClient(token="your-slack-bot-token")

# Define tools
def tavily_search(query: str) -> str:
    """Search the web for relevant context."""
    results = tavily_client.search(query, max_results=5)
    return "\n".join([r["content"] for r in results["results"]])

@tool
def slack_send_message(channel: str, message: str) -> str:
    """Send analysis results to Slack."""
    response = slack_client.chat_postMessage(channel=channel, text=message)
    return f"Message sent. Timestamp: {response['ts']}"

# Create and run agent
agent = create_deep_agent(
    model="claude-sonnet-4-6",
    tools=[tavily_search, slack_send_message],
    backend=LocalShell(),
    checkpointer=InMemorySaver(),
)

result = agent.invoke(
    "Analyze /data/quarterly_revenue.csv and send insights to #finance-reports"
)
print(result)
```
