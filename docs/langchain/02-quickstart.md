# LangChain Quickstart

## Overview

This guide demonstrates building AI agents from basic setup to production-ready implementations using LangChain with Claude.

## Prerequisites

- Install LangChain package
- Set up Anthropic account with API key
- Configure `ANTHROPIC_API_KEY` environment variable

### Installation

Using uv:

```bash
uv add langchain deepagents
```

Using pip:

```bash
pip install -U langchain deepagents
```

## Basic Agent Example

The documentation shows creating a simple agent using `create_agent()` with Claude Sonnet 4.5, a weather tool function, and system instructions.

```python
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather in San Francisco?"}]}
)
```

## Research Agent: Literary Analysis

The official quickstart also walks through a research-style example that compares a plain LangChain agent and a Deep Agent on a literary analysis task (e.g. computing exact line counts inside The Great Gatsby).

### Tool

```python
import urllib.error
import urllib.request
from langchain.tools import tool

@tool
def fetch_text_from_url(url: str) -> str:
    """Fetch the document from a URL."""
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (compatible; quickstart-research/1.0)"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read()
    except urllib.error.URLError as e:
        return f"Fetch failed: {e}"
    return raw.decode("utf-8", errors="replace")
```

### Model & memory

```python
from langchain.chat_models import init_chat_model
from langgraph.checkpoint.memory import InMemorySaver

model = init_chat_model(
    "claude-sonnet-4-6",
    temperature=0.5,
    timeout=600,
    max_tokens=25000,
    streaming=True,
)
checkpointer = InMemorySaver()
```

### Agent vs Deep Agent

```python
from langchain.agents import create_agent
from deepagents import create_deep_agent

agent = create_agent(
    model=model,
    tools=[fetch_text_from_url],
    system_prompt=SYSTEM_PROMPT,
    checkpointer=checkpointer,
)

deep_agent = create_deep_agent(
    model=model,
    tools=[fetch_text_from_url],
    system_prompt=SYSTEM_PROMPT,
    checkpointer=checkpointer,
)

agent_result = agent.invoke(
    {"messages": [{"role": "user", "content": content}]},
    config={"configurable": {"thread_id": "great-gatsby-lc"}},
)

deep_agent_result = deep_agent.invoke(
    {"messages": [{"role": "user", "content": content}]},
    config={"configurable": {"thread_id": "great-gatsby-da"}},
)
```

### LangChain Agent vs Deep Agent

| Aspect       | LangChain Agent          | Deep Agent                       |
|--------------|--------------------------|----------------------------------|
| Control      | Fine-grained             | Built-in capabilities            |
| Planning     | Manual                   | Integrated                       |
| File tools   | Custom-built             | Built-in (`grep`, `read_file`)   |
| Subagents    | Manual implementation    | Automatic spawning               |
| Setup        | More code                | Minimal                          |

On grounded research tasks (line counts, first-occurrence lookup, multi-step file inspection) Deep Agents typically deliver more reliable answers out of the box, while a plain LangChain agent gives you a smaller, fully-controllable loop.

## Production Agent Components

### 1. System Prompt

A detailed prompt defines agent behavior. The example uses: "You are an expert weather forecaster, who speaks in puns" with specific tool access instructions.

### 2. Tools Definition

Tools enable external system interaction through decorated functions. The guide demonstrates:
- `@tool` decorator for function conversion
- Runtime context injection via `ToolRuntime`
- Tool documentation requirements

### 3. Model Configuration

Initialize language models with parameters like temperature, timeout, and max_tokens using `init_chat_model()`.

### 4. Structured Response Format

Optional dataclass definitions ensure consistent output schemas matching specific requirements.

### 5. Memory Management

`InMemorySaver()` provides conversation state persistence. Production deployments require persistent checkpointers for database storage.

### 6. Agent Assembly and Execution

Components combine into a functional agent using `create_agent()`, executed with unique thread identifiers for conversation tracking.

## Key Capabilities

The resulting agent can:
- Understand context
- Utilize multiple tools
- Provide structured responses
- Handle user-specific data
- Maintain conversation history

## Additional Resources

Documentation references LangSmith for tracing and MCP server integration for IDE assistants.
