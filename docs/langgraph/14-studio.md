# LangSmith Studio Documentation

## Overview

LangSmith Studio is a complimentary visual development environment designed for creating and testing LangChain agents locally. It enables developers to observe agent operations in real-time, including prompt delivery to models, tool invocations with results, and final outputs.

## Key Features

1. **Real-time Visualization** — every step the agent takes (prompts, tool calls, results, final output) is rendered live.
2. **Interactive Testing** — drive different inputs and inspect intermediate states directly in the UI.
3. **Hot-reloading** — edits to prompts or tool signatures are reflected immediately without restarting the server.
4. **Trace Inspection** — execution traces include prompts, tool arguments, return values, token counts, and latency.
5. **Exception Capture** — exceptions are captured together with surrounding state for debugging context.
6. **Thread Replay** — re-run conversation threads from any step to validate changes without restarting.
7. **Optional Tracing** — set `LANGSMITH_TRACING=false` to keep run data on the local machine.

## Key Prerequisites

Before setup, users need:
- A LangSmith account (free signup available at smith.langchain.com)
- An API key generated from LangSmith
- Optional: `LANGSMITH_TRACING=false` in `.env` to prevent data transmission to external servers

## Setup Steps

### 1. Install LangGraph CLI
The tool requires Python 3.11+:
```
pip install --upgrade "langgraph-cli[inmem]"
```

### 2. Agent Preparation
Users can employ existing LangChain agents directly. A sample email agent demonstrates the pattern with the `create_agent` function:

```python
from langchain.agents import create_agent

def send_email(to: str, subject: str, body: str):
    """Send an email"""
    email = {
        "to": to,
        "subject": subject,
        "body": body,
    }
    return f"Email sent to {to}"

agent = create_agent(
    "gpt-5.4",
    tools=[send_email],
    system_prompt="You are an email assistant. Always use the send_email tool.",
)
```

### 3. Environment Configuration
Add your API credentials to a `.env` file:
```
LANGSMITH_API_KEY=lsv2...
```

### 4. LangGraph Configuration
Create `langgraph.json` specifying agent location and dependencies:
```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./src/agent.py:agent"
  },
  "env": ".env"
}
```

### 5. Dependency Installation
Install required packages via pip or uv package manager:

```bash
pip install langchain langchain-openai
```

### 6. Launch Development Server
Execute `langgraph dev` to start the local server. The agent becomes accessible via API at `http://127.0.0.1:2024` and through Studio at:

```
https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
```

Safari users should append the `--tunnel` flag (`langgraph dev --tunnel`) because Safari blocks plain-localhost connections from a remote origin.

## Notable Features

The development environment supports hot-reloading, allowing immediate reflection of code modifications. Execution traces capture detailed metrics including prompts, tool arguments, and performance data. The interface facilitates iterative testing from any execution step.

## Additional Resources

Documentation references include guides for running applications, managing assistants and threads, optimizing prompts, and debugging traces within LangSmith.
