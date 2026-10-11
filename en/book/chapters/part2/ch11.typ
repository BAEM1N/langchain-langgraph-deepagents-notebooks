// Auto-generated from 11_mcp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "MCP (Model Context Protocol)")


== Learning Objectives

Learn how to connect external tools and context to an agent through MCP (Model Context Protocol).

This notebook covers:
- Understanding the MCP concept and architecture (server / client / host)
- Connecting to MCP servers with the beta `langchain.mcp.MCPAdapter`
- Integrating MCP tools with an agent through `create_agent(model=..., tools=await adapter.list_tools())`
- Understanding stdio and Streamable HTTP transports
- Connecting to multiple MCP servers at once


== 11.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("Environment ready.")
`````)

== 11.2 MCP Concepts

_MCP (Model Context Protocol)_ is an open protocol for providing external tools and context to an LLM in a _standardized way_.

=== Architecture components

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Component],
  text(weight: "bold")[Role],
  text(weight: "bold")[Example],
  [_MCP server_],
  [Exposes tools, resources, and prompts],
  [File system server, DB server, API wrapper],
  [_MCP client_],
  [Connects to the server and fetches tools],
  [`MCPAdapter`],
  [_Host_],
  [Manages the client and connects it to the LLM],
  [LangChain agent, IDE],
)

=== Core resource types

- _Tools_: executable functions the agent can call
- _Resources_: data such as files or database records (converted to LangChain Blob objects)
- _Prompts_: reusable prompt templates

=== Why MCP?

Before MCP, each tool needed its own custom integration code. MCP unifies this into _one standard protocol_, which means:
- Tool providers only need to implement an MCP server once
- LLM hosts can access every tool through one MCP client
- Tools can be reused across the ecosystem


== 11.3 Installing MCP support

Current LangChain exposes MCP through the beta `langchain.mcp` namespace. The older `langchain_mcp_adapters.MultiServerMCPClient` package is only a migration reference.


#code-block(`````python
# MCP adapter installation commands
print("MCP adapter installation:")
print("  uv add 'langchain[mcp]' mcp")
print()
print("Key components:")
print("  - MCPAdapter: async context manager for one or more MCP servers")
print("  - adapter.list_tools(): converts server tools into LangChain tools")
print("  - FastMCP: Utility for quickly building MCP servers")
`````)

== 11.4 Stdio Transport

_Stdio (Standard I/O)_ transport communicates with an MCP server through a local subprocess. It is a good fit for development and testing environments.


#code-block(`````python
from pathlib import Path; import json, tempfile, sys
server_path = Path(tempfile.gettempdir()) / "lc_mcp_math_server.py"
server_path.write_text('from mcp.server.fastmcp import FastMCP\nmcp = FastMCP("math")\n@mcp.tool()\ndef add(a: int, b: int) -> int:\n    return a + b\nif __name__ == "__main__":\n    mcp.run(transport="stdio")')
stdio_config = {
    "mcpServers": {
        "math": {"command": sys.executable, "args": [str(server_path)]}
    }
}
print("Stdio Transport configuration:"); print(json.dumps(stdio_config, indent=2))
print(f"\nServer file: {server_path}")
`````)

== 11.5 Streamable HTTP Transport

_HTTP (streamable-http)_ transport uses web-based communication and is a good fit for remote MCP servers. It also supports authentication headers and custom settings.


#code-block(`````python
# Example MCPConfig / Streamable HTTP configuration
http_config = {
    "mcpServers": {
        "weather": {"url": "https://weather-mcp.example.com/mcp"}
    }
}
import json; print("HTTP Transport configuration:"); print(json.dumps(http_config, indent=2))
print("\nUsage pattern: async with MCPAdapter(http_config) as adapter -> await adapter.list_tools()")
`````)

== 11.6 Loading MCP Tools and Integrating Them with an Agent

This is the common pattern for binding tools fetched from an MCP server into a LangChain agent. The core entry point is `adapter.list_tools()`. It discovers the tools exposed by the MCP server and converts each tool's name, description, and parameter schema into LangChain `Tool` objects. The converted tools can be passed directly to `create_agent(tools=mcp_tools)`.

=== Key function signatures

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Function],
  text(weight: "bold")[Description],
  [`adapter.list_tools()`],
  [Return LangChain `Tool` objects from every registered server],
  [`MCPConfig` `mcpServers`],
  [Configure multiple servers in the standard MCP config shape],
  [`fastmcp.Client`],
  [Use custom auth, transports, or handlers before passing the client to `MCPAdapter`],
  [`@wrap_tool_call`],
  [Intercept MCP tool calls from the LangChain agent side],
)

#code-block(`````python
from langchain.mcp import MCPAdapter
from langchain.agents import create_agent

async with MCPAdapter(stdio_config) as adapter:
    mcp_tools = await adapter.list_tools()
    agent = create_agent(model="gpt-5.4", tools=mcp_tools)
`````)

=== Connection lifecycle

`MCPAdapter` is an async context manager. `list_tools()` manages the underlying client lifecycle, and each returned tool opens the needed session for its call. The old `client.session(...)` stateful helper is not part of the new namespace.

#code-block(`````python
async with MCPAdapter(stdio_config) as adapter:
    tools = await adapter.list_tools()
    result = await tools[0].ainvoke({"a": 1, "b": 2})
`````)


== 11.7 Connecting to Multiple MCP Servers

An `MCPConfig` with `mcpServers` can manage several MCP servers at the same time. Tool names are prefixed automatically when needed.


#code-block(`````python
# Example multi-MCP-server configuration
import json, sys
multi_server_config = {
    "mcpServers": {
        "math": {"command": sys.executable, "args": [str(server_path)]},
        "weather": {"url": "https://weather-mcp.example.com/mcp"},
        "database": {"command": "pnpm", "args": ["dlx", "@modelcontextprotocol/server-postgres"], "env": {"DATABASE_URL": "postgresql://..."}},
    }
}
print("Multi-MCP server configuration:"); print(json.dumps(multi_server_config, indent=2, ensure_ascii=False))
print("\nUsage pattern: async with MCPAdapter(multi_server_config) as adapter -> await adapter.list_tools()")
`````)

== 11.8 MCP Authentication

Remote MCP servers authenticate through the underlying FastMCP client. Static config is fine for unauthenticated examples; bearer tokens, OAuth, and custom `httpx.Auth` belong on a `fastmcp.Client` that you pass to `MCPAdapter`.

=== Track A — Static headers

The simplest approach: pass the token through a header. Good for CI/CD with pre-issued keys.

#code-block(`````python
from fastmcp import Client
from langchain.mcp import MCPAdapter

client = Client("https://weather-mcp.example.com/mcp", auth="Bearer YOUR_API_KEY")
async with MCPAdapter(client) as adapter:
    tools = await adapter.list_tools()
`````)

=== Track B — `httpx2.Auth` interface

For dynamic auth such as token refresh or request signing, pass an `httpx2.Auth` implementation, matching FastMCP's current client dependency.

#code-block(`````python
import httpx2
from fastmcp import Client

class BearerAuth(httpx2.Auth):
    def __init__(self, token: str):
        self.token = token

    def auth_flow(self, request):
        request.headers["Authorization"] = f"Bearer {self.token}"
        yield request

client = Client("https://weather-mcp.example.com/mcp", auth=BearerAuth(token="..."))
`````)

=== Track C — FastMCP OAuth

For an OAuth-protected remote MCP server, let FastMCP run its OAuth flow by passing `auth="oauth"`. If your deployment needs custom storage or token refresh policy, build that into a FastMCP-compatible auth object before giving the client to `MCPAdapter`.

#code-block(`````python
from fastmcp import Client
from langchain.mcp import MCPAdapter

client = Client("https://secure-mcp.example.com/mcp", auth="oauth")
async with MCPAdapter(client) as adapter:
    tools = await adapter.list_tools()
`````)

== 11.9 Elicitation — Server-requested user input

Elicitation lets an MCP server request _additional input_ from the client (host) during a tool call. In `langchain.mcp`, this is handled as a LangGraph interrupt rather than a client callback.

#code-block(`````python
from langgraph.types import Command

# When the tool pauses for elicitation, collect user input in your UI.
# Resume with one answer per request key. Accepted form answers carry `content`.
resume = Command(resume={
    "responses": {
        "city_form": {
            "action": "accept",
            "content": {"city": "Seoul", "unit": "celsius"},
        }
    }
})
result = await graph.ainvoke(resume, config=config)
`````)

#tip-box[`MCPAdapter` arms elicitation automatically for clients it creates. This interrupt loop requires a modern MCP server that returns `InputRequiredResult`; a legacy server-initiated elicitation callback still needs a pre-built client with its own handler. Sampling and roots are not implemented by the LangChain adapter; a server request for those capabilities raises `NotImplementedError`.]

== 11.10 Tool Interceptors

MCP-specific `tool_interceptors` are replaced by LangChain `@wrap_tool_call` middleware. It wraps every tool call made by the agent; branch on MCP metadata when the logic should apply only to MCP tools.

=== Tool interceptor use cases

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Use Case],
  text(weight: "bold")[Description],
  [Auth injection],
  [Pass user-specific tokens at runtime],
  [Request transformation],
  [Rewrite tool call parameters],
  [Response filtering],
  [Remove sensitive information],
  [Retry logic],
  [Retry automatically after failures],
  [Logging],
  [Trace tool calls],
)

=== Agent-side wrapper

The wrapper can log, retry, filter, or short-circuit a tool call. For MCP-specific logic, check the tool metadata before applying the policy.

#code-block(`````python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
async def logging_interceptor(request, handler):
    """Log MCP tool calls while appending to a state trace."""
    if request.tool.metadata.get("mcp"):
        print(f"[mcp] tool={request.tool_call['name']}")
    return await handler(request)
`````)

This pattern is useful for auth, logging, retries, and response filtering. If the middleware needs to update custom state, define the agent state schema for that field and return a LangGraph `Command` from the wrapper.


== 11.11 Writing a Custom MCP Server

With the _FastMCP_ library, you can build an MCP server quickly using decorators.


== 11.12 Summary

This notebook covered:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Idea],
  [_MCP concepts_],
  [An open protocol that provides external tools and context to an LLM in a standardized way],
  [_Stdio transport_],
  [Local subprocess communication, good for development and testing],
  [_Streamable HTTP transport_],
  [Web-based communication for remote servers and authentication scenarios],
  [_Agent integration_],
  [Connect with `MCPAdapter` → `await adapter.list_tools()` → `create_agent(tools=mcp_tools)`],
  [_Multi-server support_],
  [Use an `MCPConfig` `mcpServers` target to manage several servers at once],
  [_Interceptors_],
  [Apply middleware for auth, logging, and request/response modification],
  [_Custom servers_],
  [Build an MCP server quickly with FastMCP decorators],
)

=== Next Steps
→ Continue to _#link("./12_frontend_streaming.ipynb")[12_frontend_streaming.ipynb]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langchain/16-mcp.md")[MCP (Model Context Protocol)]

