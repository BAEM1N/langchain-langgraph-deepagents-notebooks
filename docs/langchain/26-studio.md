# LangSmith Studio Documentation

## Overview

"LangSmith Studio is a free visual interface for developing and testing your LangChain agents from your local machine." This tool enables developers to visualize agent operations, interact with them in real-time, and debug issues locally without requiring deployment.

## Key Features

Studio provides visibility into:
- Each step the agent executes
- Prompts sent to models
- Tool calls and their results
- Final outputs
- Intermediate states for inspection
- Token and latency metrics

### Studio Key Features

<CardGroup cols={2}>
  <Card title="Hot-reloading">
    Make changes to prompts or tool signatures in your code, and Studio reflects them immediately without restarting the dev server.
  </Card>
  <Card title="Full execution trace inspection">
    Inspect every step the agent executes — prompts sent to models, tool calls, intermediate states, and final outputs.
  </Card>
  <Card title="Thread replay">
    Re-run conversation threads from any step to test modifications iteratively without starting over.
  </Card>
  <Card title="Exception capture">
    When the agent throws, Studio captures the exception alongside the surrounding state for post-mortem debugging.
  </Card>
</CardGroup>

## Setup Requirements

Before starting, you'll need:
- A free LangSmith account at smith.langchain.com
- An API key from LangSmith
- Optional: Set `LANGSMITH_TRACING=false` to keep data local

## Installation Steps

**1. Install LangGraph CLI:**
```shell
pip install --upgrade "langgraph-cli[inmem]"
```
(Requires Python 3.11+)

**2. Create Agent File** (`agent.py`):
```python
from langchain.agents import create_agent

def send_email(to: str, subject: str, body: str):
    """Send an email"""
    email = {"to": to, "subject": subject, "body": body}
    return f"Email sent to {to}"

agent = create_agent(
    "gpt-5.4",
    tools=[send_email],
    system_prompt="You are an email assistant."
)
```

**3. Create `.env` File:**
```bash
LANGSMITH_API_KEY=lsv2...
```
⚠️ Don't commit this to version control.

**4. Create `langgraph.json`:**
```json
{
  "dependencies": ["."],
  "graphs": {"agent": "./src/agent.py:agent"},
  "env": ".env"
}
```

**5. Install Dependencies:**
```shell
pip install langchain langchain-openai
```

**6. Start Development Server:**
```shell
langgraph dev
```

Access the UI at: `https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024`

The dev server itself listens at `http://127.0.0.1:2024` for raw API access; the Studio UI is the hosted front-end that points to that base URL.

⚠️ Safari users: Use `--tunnel` flag for localhost compatibility.

## Additional Resources

The documentation references guides for managing assistants, threads, prompt iteration, and trace debugging available in the LangSmith docs.
