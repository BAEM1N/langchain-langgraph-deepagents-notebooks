# Agent Client Protocol (ACP)

## Overview
The Agent Client Protocol standardizes communication between coding agents and development environments. ACP is designed for agent-editor integrations and enables integration with code editors and IDEs.

## Installation

```bash
pip install deepagents-acp
# or
uv add deepagents-acp
```

## Basic Implementation

Create an ACP server that runs in stdio mode. Initialize a Deep Agent with a custom system prompt and memory checkpointer, then expose it through the `AgentServerACP` class.

## Supported Clients

- **Zed** — Native integration available
- **JetBrains IDEs** — Built-in support
- **Visual Studio Code** — Via vscode-acp plugin
- **Neovim** — Through ACP-compatible plugins

## Zed Configuration

Setup requires:
1. Cloning the repository and installing dependencies
2. Configuring the ANTHROPIC_API_KEY in an .env file
3. Adding the agent server command to Zed's settings.json

## Additional Tools

**Toad** offers process management for running ACP servers as local development tools, installable via uv.

## Key Distinction

ACP is designed for agent-editor integrations, distinguishing it from the Model Context Protocol (MCP), which handles external tool integration.
