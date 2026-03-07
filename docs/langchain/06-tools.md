# LangChain Tools

## Overview

Tools extend agent capabilities by enabling retrieval of real-time data, code execution, database queries, and world interactions. These are callable functions with defined inputs/outputs passed to chat models, which determine when invocation occurs based on conversation context.

## Creating Tools

### Basic Definition

The simplest approach uses the `@tool` decorator, where the function's docstring becomes the tool description:

```python
from langchain.tools import tool

@tool
def search_database(query: str, limit: int = 10) -> str:
    """Search the customer database for records matching the query.

    Args:
        query: Search terms to look for
        limit: Maximum number of results to return
    """
    return f"Found {limit} results for '{query}'"
```

**Key requirement:** Type hints define the input schema. Documentation should be clear and concise to guide model usage.

### Customization

**Custom naming:**

```python
@tool("web_search")
def search(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query}"
```

**Custom descriptions:**

```python
@tool("calculator", description="Performs arithmetic calculations. Use this for any math problems.")
def calc(expression: str) -> str:
    """Evaluate mathematical expressions."""
    return str(eval(expression))
```

### Advanced Schemas

Define complex inputs using Pydantic models:

```python
from pydantic import BaseModel, Field
from typing import Literal

class WeatherInput(BaseModel):
    """Input for weather queries."""
    location: str = Field(description="City name or coordinates")
    units: Literal["celsius", "fahrenheit"] = Field(
        default="celsius",
        description="Temperature unit preference"
    )

@tool(args_schema=WeatherInput)
def get_weather(location: str, units: str = "celsius") -> str:
    """Get current weather and optional forecast."""
    temp = 22 if units == "celsius" else 72
    return f"Current weather in {location}: {temp} degrees {units[0].upper()}"
```

### Reserved Parameters

The parameters `config` and `runtime` are reserved and cannot be used as tool arguments.

## Runtime Access

Tools access runtime information through the `ToolRuntime` parameter, providing access to:

- **State:** Short-term conversation memory (messages, counters, custom fields)
- **Context:** Immutable configuration (user IDs, session info)
- **Store:** Long-term persistent data across conversations
- **Stream Writer:** Real-time updates during execution
- **Tool Call ID:** Unique invocation identifier

### Accessing State

```python
from langchain.tools import tool, ToolRuntime

@tool
def get_last_user_message(runtime: ToolRuntime) -> str:
    """Get the most recent message from the user."""
    messages = runtime.state["messages"]
    for message in reversed(messages):
        if isinstance(message, HumanMessage):
            return message.content
    return "No user messages found"
```

### Updating State

```python
from langgraph.types import Command

@tool
def set_user_name(new_name: str) -> Command:
    """Set the user's name in the conversation state."""
    return Command(update={"user_name": new_name})
```

### Context Usage

```python
from dataclasses import dataclass

@dataclass
class UserContext:
    user_id: str

@tool
def get_account_info(runtime: ToolRuntime[UserContext]) -> str:
    """Get the current user's account information."""
    user_id = runtime.context.user_id
    return f"Account info for {user_id}"
```

### Long-term Memory (Store)

```python
@tool
def get_user_info(user_id: str, runtime: ToolRuntime) -> str:
    """Look up user info."""
    store = runtime.store
    user_info = store.get(("users",), user_id)
    return str(user_info.value) if user_info else "Unknown user"

@tool
def save_user_info(user_id: str, user_info: dict, runtime: ToolRuntime) -> str:
    """Save user info."""
    store = runtime.store
    store.put(("users",), user_id, user_info)
    return "Successfully saved user info."
```

### Stream Writer

```python
@tool
def get_weather(city: str, runtime: ToolRuntime) -> str:
    """Get weather for a given city."""
    writer = runtime.stream_writer
    writer(f"Looking up data for city: {city}")
    writer(f"Acquired data for city: {city}")
    return f"It's always sunny in {city}!"
```

## ToolNode

`ToolNode` is a prebuilt component executing tools in LangGraph workflows, handling parallel execution and error management automatically.

### Basic Usage

```python
from langchain.tools import tool
from langgraph.prebuilt import ToolNode
from langgraph.graph import StateGraph, MessagesState, START, END

@tool
def search(query: str) -> str:
    """Search for information."""
    return f"Results for: {query}"

tool_node = ToolNode([search])

builder = StateGraph(MessagesState)
builder.add_node("tools", tool_node)
```

### Error Handling

```python
from langgraph.prebuilt import ToolNode

# Catch all errors
tool_node = ToolNode(tools, handle_tool_errors=True)

# Custom error message
tool_node = ToolNode(tools, handle_tool_errors="Something went wrong, please try again.")

# Custom handler
def handle_error(e: ValueError) -> str:
    return f"Invalid input: {e}"

tool_node = ToolNode(tools, handle_tool_errors=handle_error)
```

### Conditional Routing

```python
from langgraph.prebuilt import tools_condition

builder.add_conditional_edges("llm", tools_condition)  # Routes to "tools" or END
builder.add_edge("tools", "llm")
```

## Prebuilt Tools & Server-side Tools

LangChain provides prebuilt tools for web search, code interpretation, and database access. Some chat models feature built-in server-side tools executed by the provider -- consult individual model integration pages for details.
