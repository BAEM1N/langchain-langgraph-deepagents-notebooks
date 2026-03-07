# Deep Agents Quickstart

## Overview
This guide enables developers to build their first deep agent with planning, file system tools, and subagent capabilities — specifically a research agent capable of conducting research and writing reports.

## Key Requirements
- API key from a model provider (Anthropic, OpenAI, etc.)
- Model supporting tool calling functionality

## Installation
```bash
pip install deepagents tavily-python
# or
uv add deepagents tavily-python
```

## Configuration Steps

### API Keys Setup
Environment variables must be configured:
```bash
export ANTHROPIC_API_KEY="your-key"
export TAVILY_API_KEY="your-key"
```

### Search Tool Creation
Developers implement a search function leveraging Tavily's API with parameters for query customization, result limits, topic filtering, and raw content inclusion.

### Agent Creation
Using `create_deep_agent()`, developers pass custom tools and system prompts that define agent behavior — in this example, positioning the agent as "an expert researcher."

```python
from deepagents import create_deep_agent

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    tools=[internet_search],
    system_prompt="You are an expert researcher.",
)
```

## Functional Capabilities
The agent automatically:
- Plans approaches via built-in `write_todos` tool
- Conducts research through internet search
- Manages context using file system tools (`write_file`, `read_file`)
- Spawns specialized subagents for complex tasks
- Synthesizes findings into coherent reports

## Advanced Features
- Built-in streaming for real-time execution observation
- Customization options for prompts and tools
- Persistent memory capabilities
- LangGraph deployment support

## Usage Example
The agent responds to user queries like "What is langgraph?" by executing its planning, research, and synthesis pipeline.
