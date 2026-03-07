# Model Context Protocol (MCP) Documentation

## Overview

The documentation explains how to use Model Context Protocol with LangChain agents. MCP is an open protocol that standardizes how applications provide tools and context to LLMs.

## Installation

To get started, install the adapter library:

```bash
pip install langchain-mcp-adapters
```

## Key Components

**MultiServerMCPClient** manages connections to MCP servers. By default it's "stateless" -- each tool invocation creates a fresh session and cleans up afterward.

### Supported Transports

- **HTTP/streamable-http**: Web-based communication with optional custom headers and authentication
- **stdio**: Local subprocess communication for development and testing

### Core Features

**Tools**: MCP servers expose executable functions that agents can invoke. Load them via `client.get_tools()` and pass to agents.

**Resources**: MCP servers can expose data (files, database records) converted to LangChain Blob objects for unified text/binary handling.

**Prompts**: Reusable prompt templates retrieved from servers and converted to messages for chat workflows.

## Advanced Capabilities

**Tool Interceptors** act as middleware, enabling you to access runtime context (user data, store information, agent state), modify requests/responses, implement retry logic, and control execution flow.

**Stateful Sessions**: For servers requiring persistent connections, use `client.session()` to maintain context across multiple tool calls.

**Progress Notifications**: Subscribe to updates for long-running operations via callbacks.

**Elicitation**: Servers can request user input interactively during tool execution rather than requiring all inputs upfront.

## Custom Server Creation

Use FastMCP library to build custom servers with decorated functions that expose tools via stdio or HTTP transports.

The documentation includes extensive code examples for each feature, authentication patterns, error handling, and composition techniques.
