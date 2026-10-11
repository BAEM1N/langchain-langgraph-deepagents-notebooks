# Model Context Protocol (MCP) Documentation

## Overview

LangChain 1.4 introduced the beta `langchain.mcp` namespace. The current teaching surface should use `MCPAdapter`, which is built on FastMCP and adapts MCP server tools into LangChain tools for `create_agent`.

The older `langchain_mcp_adapters.MultiServerMCPClient` API remains useful only as migration context. Do not write new examples that depend on it unless the section is explicitly labeled historical.

## Installation

Use the `mcp` extra on LangChain:

```bash
uv add "langchain[mcp]"
```

Migration from the standalone adapter package is:

```bash
uv remove langchain-mcp-adapters
uv add "langchain[mcp]"
```

`langchain.mcp` is beta and emits `LangChainBetaWarning` when imported.

## Core API

`MCPAdapter` is an async context manager. It infers the transport from the target and exposes `list_tools()`.

```python
from langchain.agents import create_agent
from langchain.mcp import MCPAdapter

config = {
    "mcpServers": {
        "math": {"command": "python", "args": ["/path/to/math_server.py"]},
        "weather": {"url": "https://example.com/mcp"},
    }
}

async with MCPAdapter(config) as adapter:
    tools = await adapter.list_tools()
    agent = create_agent("openai:gpt-5.4", tools)
```

Targets can be:

- an `http` or `https` URL,
- a `Path` to a local script launched over stdio,
- an in-process FastMCP server,
- an `MCPConfig` dict with `mcpServers`,
- a prebuilt `fastmcp.Client` or `ClientGroup`.

For `str` targets, use URLs. Local scripts should be passed as `Path` objects to avoid ambiguous execution.

## Migration Map

| Previous `langchain-mcp-adapters` | Current `langchain.mcp` |
|---|---|
| `MultiServerMCPClient(...)` | `MCPAdapter(target)` |
| `client.get_tools()` | `await adapter.list_tools()` |
| per-server `transport` fields | standard `MCPConfig` shape; transport inferred |
| `tool_interceptors` | LangChain `@wrap_tool_call` middleware |
| `callbacks=Callbacks(...)` | FastMCP `Client(..., progress_handler=..., log_handler=...)`; elicitation handled by interrupt |
| `auth` / `headers` on adapter config | prebuilt FastMCP client/transport with auth or headers |
| `convert_mcp_tool_to_langchain_tool` | `await as_langchain_tool(tool, client)` |
| `MCPToolArtifact` | still exported from `langchain.mcp` |

Unsupported or not directly wrapped after migration:

- `get_prompt`
- `get_resources`
- direct `session(...)` management
- WebSocket transport
- client-side sampling/roots
- converting LangChain tools to FastMCP tools with `to_fastmcp`

If existing code relies on one of those surfaces, document the gap instead of inventing a replacement.

## Connection Lifecycle

`MCPAdapter` opens the configured client inside `async with`. `list_tools()` discovers tools; the returned tools retain enough client context to be used by the agent after the context exits. Session-scoped prompt/resource APIs from `MultiServerMCPClient` do not have a direct `langchain.mcp` wrapper.

Multi-server configs automatically prefix tools where needed, usually as `{server}_{tool}`.

## Authentication

Authentication lives on FastMCP clients or transports:

```python
from fastmcp.client import Client
from langchain.mcp import MCPAdapter

client = Client("https://example.com/mcp", auth="oauth")

async with MCPAdapter(client) as adapter:
    tools = await adapter.list_tools()
```

Common patterns:

- `Client(url, auth=token)` for simple bearer-token authentication,
- `Client(url, auth="oauth")` for FastMCP's built-in OAuth 2.1 flow,
- a prebuilt FastMCP auth object when you need persisted tokens or provider-specific behavior,
- `ClientGroup` for per-server credentials,
- graph factory/runtime identity for per-user credentials.

Custom auth belongs on the FastMCP client or transport. In FastMCP 4.1 the `Client` annotation is `httpx2.Auth | Literal["oauth"] | str | None`, so examples that pass a custom auth class should be verified against the installed FastMCP/httpx2 type rather than copied from an older plain-`httpx.Auth` snippet. Headers belong on the underlying FastMCP transport, not as a legacy adapter connection field.

## Elicitation

Elicitation is now handled through LangGraph interrupts and is enabled by the adapter. When a modern MCP server returns an `InputRequiredResult`, the run pauses and resumes with a `Command` that carries the answer:

```python
from langgraph.types import Command

resume = Command(
    resume={
        "responses": {
            request_key: {"action": "accept", "content": form_values}
        }
    }
)
```

Each response action is `accept`, `decline`, or `cancel`; accepted structured input goes in `content` and must match the server's requested schema. A server that only pushes elicitation over a legacy handshake session cannot be answered through this interrupt/resume path. A prebuilt FastMCP client with its own elicitation handler is honored. Sampling and roots are not answered by `langchain.mcp`; a tool that requires them raises `NotImplementedError`.

## Tool Wrappers

The old MCP-specific interceptor API is gone. Wrap tool execution at the LangChain agent layer:

```python
from collections.abc import Callable

from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage
from langchain.tools.tool_node import ToolCallRequest


@wrap_tool_call
def log_mcp_calls(
    request: ToolCallRequest,
    handler: Callable[[ToolCallRequest], ToolMessage],
) -> ToolMessage:
    metadata = request.tool.metadata or {}
    if "mcp" in metadata:
        print(f"calling MCP tool {request.tool_call['name']}")
    return handler(request)
```

MCP provenance is stored under `request.tool.metadata["mcp"]`.

## Local Teaching Guidance

- Use `MCPAdapter` for new examples.
- Keep `MultiServerMCPClient` snippets only in migration comparisons.
- Update notebooks together with HITL/runtime material because MCP elicitation now uses interrupts.
- Treat MCP as an integration topic: external servers, auth, and protocol gaps usually belong in `08_integration/` or an explicitly gated notebook.

## Local Reference Notes

- Canonical slug note: [`mcp.md`](mcp.md)
- Migration research: [`../verification/2026-10-11-update-research.md`](../verification/2026-10-11-update-research.md)
- Matrix item: `L01` in [`../verification/2026-10-11-update-research-matrix.csv`](../verification/2026-10-11-update-research-matrix.csv)
