# Subagents

## Overview
Subagents enable deep agents to delegate work while maintaining clean context. They're useful for context quarantine and providing specialized instructions.

## Why Use Subagents?

Subagents solve the context bloat problem. When agents use tools producing large outputs (web searches, file reads, database queries), the context window fills rapidly with intermediate results. Subagents isolate detailed work — the main agent receives only final results, not the dozens of tool calls that produced them.

**When to use:**
- Multi-step tasks that would clutter main agent context
- Specialized domains needing custom instructions or tools
- Tasks requiring different model capabilities
- When keeping main agent focused on high-level coordination

**When NOT to use:**
- Simple, single-step tasks
- When intermediate context is needed
- When overhead outweighs benefits

## Configuration

### SubAgent (Dictionary-based)

| Field | Type | Description |
|-------|------|-------------|
| `name` | `str` | Required unique identifier |
| `description` | `str` | Required; what the subagent does |
| `system_prompt` | `str` | Required; custom instructions |
| `tools` | `list[Callable]` | Required; available tools |
| `model` | `str` \| `BaseChatModel` | Optional; overrides main agent model |
| `middleware` | `list[Middleware]` | Optional; custom behavior/logging |
| `interrupt_on` | `dict[str, bool]` | Optional; human-in-the-loop config |
| `skills` | `list[str]` | Optional; skill source paths |

### CompiledSubAgent

For complex workflows using pre-built LangGraph graphs:

| Field | Type | Description |
|-------|------|-------------|
| `name` | `str` | Required unique identifier |
| `description` | `str` | Required; what it does |
| `runnable` | `Runnable` | Required; compiled LangGraph graph |

## Basic SubAgent Example

```python
import os
from typing import Literal
from tavily import TavilyClient
from deepagents import create_deep_agent

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def internet_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
):
    """Run a web search"""
    return tavily_client.search(
        query, max_results=max_results,
        include_raw_content=include_raw_content, topic=topic,
    )

research_subagent = {
    "name": "research-agent",
    "description": "Used to research more in depth questions",
    "system_prompt": "You are a great researcher",
    "tools": [internet_search],
    "model": "openai:gpt-5.2",
}

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    subagents=[research_subagent]
)
```

## CompiledSubAgent Example

```python
from deepagents import create_deep_agent, CompiledSubAgent
from langchain.agents import create_agent

custom_graph = create_agent(
    model=your_model,
    tools=specialized_tools,
    prompt="You are a specialized agent for data analysis..."
)

custom_subagent = CompiledSubAgent(
    name="data-analyzer",
    description="Specialized agent for complex data analysis tasks",
    runnable=custom_graph
)

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    tools=[internet_search],
    system_prompt=research_instructions,
    subagents=[custom_subagent]
)
```

## The General-Purpose Subagent

Beyond user-defined subagents, deep agents have access to a built-in general-purpose subagent that:
- Uses the same system prompt as the main agent
- Accesses all same tools
- Uses the same model (unless overridden)
- Inherits skills from the main agent (when configured)

### Overriding the General-Purpose Subagent

```python
agent = create_deep_agent(
    model="claude-sonnet-4-6",
    tools=[internet_search],
    subagents=[
        {
            "name": "general-purpose",
            "description": "General-purpose agent for research and multi-step tasks",
            "system_prompt": "You are a general-purpose assistant.",
            "tools": [internet_search],
            "model": "openai:gpt-4o",
        },
    ],
)
```

## Context Management

Runtime context automatically propagates to all subagents:

```python
@tool
def get_user_data(query: str, config) -> str:
    """Fetch data for the current user."""
    user_id = config.get("context", {}).get("user_id")
    return f"Data for user {user_id}: {query}"

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    subagents=[research_subagent],
    context_schema={"user_id": str, "session_id": str},
)

result = await agent.invoke(
    {"messages": [HumanMessage("Look up my recent activity")]},
    {"context": {"user_id": "user-123", "session_id": "abc"}},
)
```

### Per-Subagent Context

Use namespaced keys to pass subagent-specific configuration:

```python
result = await agent.invoke(
    {"messages": [HumanMessage("Research this and verify the claims")]},
    {
        "context": {
            "user_id": "user-123",
            "researcher:max_depth": 3,
            "fact-checker:strict_mode": True,
        }
    },
)
```

## Best Practices

1. **Write Clear Descriptions**: The main agent uses descriptions to decide which subagent to call
2. **Keep System Prompts Detailed**: Include output format, constraints, and workflow steps
3. **Minimize Tool Sets**: Only give subagents the tools they need
4. **Choose Models by Task**: Use appropriate models for different subagent responsibilities
5. **Return Concise Results**: Instruct subagents to summarize, not dump raw data

## Common Patterns

### Multiple Specialized Subagents

```python
subagents = [
    {
        "name": "data-collector",
        "description": "Gathers raw data from various sources",
        "system_prompt": "Collect comprehensive data on the topic",
        "tools": [web_search, api_call, database_query],
    },
    {
        "name": "data-analyzer",
        "description": "Analyzes collected data for insights",
        "system_prompt": "Analyze data and extract key insights",
        "tools": [statistical_analysis],
    },
    {
        "name": "report-writer",
        "description": "Writes polished reports from analysis",
        "system_prompt": "Create professional reports from insights",
        "tools": [format_document],
    },
]

agent = create_deep_agent(
    model="claude-sonnet-4-6",
    system_prompt="You coordinate data analysis and reporting.",
    subagents=subagents
)
```

## Troubleshooting

- **Subagent Not Being Called**: Make descriptions more specific, instruct main agent to delegate
- **Context Still Getting Bloated**: Instruct subagent to return concise results, use filesystem for large data
- **Wrong Subagent Being Selected**: Differentiate subagents clearly in descriptions
