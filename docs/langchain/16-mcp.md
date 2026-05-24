# Model Context Protocol (MCP) Documentation

## Overview

The documentation explains how to use Model Context Protocol with LangChain agents. MCP is an open protocol that standardizes how applications provide tools and context to LLMs.

## Installation

Install the adapter library using either pip or uv:

```bash
pip install langchain-mcp-adapters
# or
uv add langchain-mcp-adapters
```

## Key Components

**MultiServerMCPClient** manages connections to MCP servers. By default it's "stateless" — each tool invocation creates a fresh session and cleans up afterward.

> **Note on stdio transport:** stdio connections are inherently stateful (the subprocess persists across calls), but the client still wraps each tool invocation in a fresh session unless you explicitly hold one open via `client.session(...)`.

### Supported Transports

- **HTTP/streamable-http**: Web-based communication with optional custom headers and authentication
- **stdio**: Local subprocess communication for development and testing

### Core Features

**Tools**: MCP servers expose executable functions that agents can invoke. Load them via `client.get_tools()` and pass to agents. For session-scoped loading, use `load_mcp_tools(session)`.

**Resources**: MCP servers can expose data (files, database records) converted to LangChain Blob objects for unified text/binary handling. Use `client.get_resources(server_name)` or `load_mcp_resources(session, uris=[...])` for direct session-based loading.

**Prompts**: Reusable prompt templates retrieved from servers and converted to messages for chat workflows. Fetch them with `client.get_prompt(server_name, prompt_name, arguments={...})`.

## Quickstart Example

```python
import asyncio
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_agent

async def main():
    client = MultiServerMCPClient(
        {
            "math": {
                "transport": "stdio",
                "command": "python",
                "args": ["/path/to/math_server.py"],
            },
            "weather": {
                "transport": "http",
                "url": "http://localhost:8000/mcp",
            },
        }
    )

    tools = await client.get_tools()
    agent = create_agent("claude-sonnet-4-6", tools)

    response = await agent.ainvoke(
        {"messages": [{"role": "user", "content": "what's (3 + 5) x 12?"}]}
    )
    print(response)

if __name__ == "__main__":
    asyncio.run(main())
```

## Authentication

HTTP transports support two approaches:

1. **Custom headers**: pass a `headers` field directly in the connection config.
2. **`httpx.Auth` interface**: implement custom authentication mechanisms. The library also leverages the official MCP Python SDK, which ships a built-in OAuth2 flow via `mcp.client.auth.oauth2`.

## Advanced Capabilities

**Tool Interceptors** act as middleware, allowing you to access runtime context (user data, store information, agent state), modify requests/responses, implement retry logic, and control execution flow. Interceptors can return a `Command` object to update agent state or redirect graph execution:

```python
from langchain_mcp_adapters.interceptors import MCPToolCallRequest
from langchain.messages import ToolMessage
from langgraph.types import Command

async def handle_task_completion(request: MCPToolCallRequest, handler):
    """Route execution based on tool result."""
    result = await handler(request)
    if request.name == "submit_order":
        return Command(
            update={
                "messages": [result] if isinstance(result, ToolMessage) else [],
                "task_status": "completed",
            },
            goto="summary_agent",
        )
    return result

client = MultiServerMCPClient({...}, tool_interceptors=[handle_task_completion])
```

**Stateful Sessions**: For servers requiring persistent connections, use `async with client.session("server_name") as session:` and then call `load_mcp_tools(session)` to keep context across multiple tool calls.

**Progress Notifications**: Subscribe to updates for long-running operations via callbacks.

**Elicitation**: Servers can request user input interactively during tool execution rather than requiring all inputs upfront. The handler responds with an `ElicitResult` whose `action` is one of:

- `accept` — user provided valid input (return data via the `content` field)
- `decline` — user chose not to provide information
- `cancel` — user aborted the operation entirely

```python
from langchain_mcp_adapters.callbacks import Callbacks, CallbackContext
from mcp.shared.context import RequestContext
from mcp.types import ElicitRequestParams, ElicitResult

async def on_elicitation(
    mcp_context: RequestContext,
    params: ElicitRequestParams,
    context: CallbackContext,
) -> ElicitResult:
    return ElicitResult(
        action="accept",
        content={"email": "user@example.com", "age": 25},
    )

client = MultiServerMCPClient(
    {"profile": {"url": "http://localhost:8000/mcp", "transport": "http"}},
    callbacks=Callbacks(on_elicitation=on_elicitation),
)
```

## Custom Server Creation

Use FastMCP library to build custom servers with decorated functions that expose tools via stdio or HTTP transports.

The documentation includes extensive code examples for each feature, authentication patterns, error handling, and composition techniques.
