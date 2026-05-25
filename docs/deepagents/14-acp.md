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

```python
import asyncio

from acp import run_agent
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    agent = create_deep_agent(
        model="google_genai:gemini-3.5-flash",
        # You can customize your deep agent here: set a custom prompt,
        # add your own tools, attach middleware, or compose subagents.
        system_prompt="You are a helpful coding assistant",
        checkpointer=MemorySaver(),
    )
    server = AgentServerACP(agent)
    await run_agent(server)


if __name__ == "__main__":
    asyncio.run(main())
```

이 스크립트가 stdio 모드로 떠 있으면 ACP-호환 클라이언트가 같은 프로세스에 붙어 메시지를 주고받는다.

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

```bash
uv tool install -U batrachian-toad

toad acp "python path/to/your_server.py" .
# or
toad acp "uv run python path/to/your_server.py" .
```

## Key Distinction

ACP is designed for agent-editor integrations, distinguishing it from the Model Context Protocol (MCP), which handles external tool integration.
