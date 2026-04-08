// Auto-generated from 11_mcp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "MCP (Model Context Protocol)")


== Learning Objectives

Learn how to connect external tools and context to an agent through MCP (Model Context Protocol).

This notebook covers:
- Understanding the MCP concept and architecture (server / client / host)
- Connecting to MCP servers with the `langchain-mcp-adapters` package
- Integrating MCP tools with an agent through `ChatOpenAI.bind_tools(mcp_tools)`
- Understanding the difference between stdio and SSE transports
- Connecting to multiple MCP servers at once


== 11.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
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
  [`MultiServerMCPClient`],
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


== 11.3 Installing `langchain-mcp-adapters`

To use MCP from LangChain, you need the `langchain-mcp-adapters` package.


#code-block(`````python
# MCP adapter installation commands
print("MCP adapter installation:")
print("  uv add langchain-mcp-adapters mcp")
print()
print("Key components:")
print("  - MultiServerMCPClient: Client that manages multiple MCP servers")
print("  - load_mcp_tools(session): MCP Converts an MCP session into LangChain tools")
print("  - FastMCP: Utility for quickly building MCP servers")
`````)

== 11.4 Stdio Transport

_Stdio (Standard I/O)_ transport communicates with an MCP server through a local subprocess. It is a good fit for development and testing environments.


#code-block(`````python
from pathlib import Path; import json, tempfile, sys
server_path = Path(tempfile.gettempdir()) / "lc_mcp_math_server.py"
server_path.write_text('from mcp.server.fastmcp import FastMCP\nmcp = FastMCP("math")\n@mcp.tool()\ndef add(a: int, b: int) -> int:\n    return a + b\nif __name__ == "__main__":\n    mcp.run(transport="stdio")')
stdio_config = {"math": {"transport": "stdio", "command": sys.executable, "args": [str(server_path)]}}
print("Stdio Transport configuration:"); print(json.dumps(stdio_config, indent=2))
print(f"\nServer file: {server_path}")
`````)

== 11.5 SSE / HTTP Transport

_HTTP (streamable-http)_ transport uses web-based communication and is a good fit for remote MCP servers. It also supports authentication headers and custom settings.


#code-block(`````python
# Example HTTP / streamable-http transport configuration
http_config = {
    "weather_server": {"transport": "streamable_http", "url": "https://weather-mcp.example.com/mcp", "headers": {"Authorization": "Bearer YOUR_API_KEY"}}
}
import json; print("HTTP Transport configuration:"); print(json.dumps(http_config, indent=2))
print("\nUsage pattern: client = MultiServerMCPClient(http_config) -> await client.get_tools()")
`````)

== 11.6 Loading MCP Tools and Integrating Them with an Agent

This is the common pattern for binding tools fetched from an MCP server into a LangChain agent.


== 11.7 Connecting to Multiple MCP Servers

As the name suggests, `MultiServerMCPClient` can manage several MCP servers at the same time.


#code-block(`````python
# Example multi-MCP-server configuration
import json, sys
multi_server_config = {"math_server": {"transport": "stdio", "command": sys.executable, "args": [str(server_path)]}, "weather_server": {"transport": "streamable_http", "url": "https://weather-mcp.example.com/mcp"}, "database_server": {"transport": "stdio", "command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres"], "env": {"DATABASE_URL": "postgresql://..."}}}
print("Multi-MCP server configuration:"); print(json.dumps(multi_server_config, indent=2, ensure_ascii=False))
print("\nUsage pattern: client = MultiServerMCPClient(multi_server_config) -> await client.get_tools()")
print("Note: it is stateless by default — each tool call creates and then cleans up a new session")
`````)

== 11.8 Tool Interceptors

A _Tool Interceptor_ is middleware that intercepts MCP tool calls. It can access runtime context, modify requests and responses, and implement retry logic.

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


== 11.9 Writing a Custom MCP Server

With the _FastMCP_ library, you can build an MCP server quickly using decorators.


== 11.10 Summary

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
  [_SSE/HTTP transport_],
  [Web-based communication for remote servers and authentication scenarios],
  [_Agent integration_],
  [Connect with `client.get_tools()` → `create_agent(tools=mcp_tools)`],
  [_Multi-server support_],
  [Use `MultiServerMCPClient` to manage several servers at once],
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

