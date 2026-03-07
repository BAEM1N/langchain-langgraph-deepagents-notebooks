# LangChain Overview

## Documentation Index
The complete documentation index is available at: https://docs.langchain.com/llms.txt

## What is LangChain?

LangChain serves as "an open source framework with a pre-built agent architecture and integrations for any model or tool." You can connect to multiple LLM providers (OpenAI, Anthropic, Google, and others) in under 10 lines of code.

## Framework Comparison

The documentation recommends starting with Deep Agents for "batteries-included" features including automatic conversation compression, virtual filesystem capabilities, and subagent spawning. For basic needs, LangChain agents provide a simpler entry point. LangGraph is recommended when you need "advanced needs that require a combination of deterministic and agentic workflows and heavy customization."

## Quick Start Example

```python
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

agent.invoke(
    {"messages": [{"role": "user", "content": "what is the weather in sf"}]}
)
```

## Core Benefits

**Standard Model Interface** - LangChain standardizes interactions across different LLM providers to prevent vendor lock-in.

**Flexible Agent Design** - Build simple agents quickly or employ advanced context engineering techniques.

**LangGraph Foundation** - Leverages durable execution, human-in-the-loop support, and persistence capabilities.

**LangSmith Integration** - Use tracing, debugging, and evaluation tools by setting `LANGSMITH_TRACING=true`.
