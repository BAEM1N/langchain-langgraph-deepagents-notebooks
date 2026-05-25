// Auto-generated from 10_sandboxes_and_acp.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Sandboxes and ACP")

== Learning Objectives
- Understand the concept of sandbox isolation and its security principles
- Compare sandbox providers such as E2B, Modal, and Docker-style environments
- Understand the overview and purpose of ACP (Agent Client Protocol)
- Understand editor-agent integration patterns
- Design an architecture that combines sandboxes and ACP


#code-block(`````python
# Environment setup
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
print("Environment setup complete")

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

print(f"Model configured: {model.model_name}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Sandbox Concepts

A _sandbox_ is an _isolated execution environment_ where an AI agent can run code, manage files, and execute shell commands.

=== Why Isolation Matters

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Risk],
  text(weight: "bold")[Without isolation],
  text(weight: "bold")[With a sandbox],
  [Filesystem access],
  [The host filesystem can be changed or deleted],
  [Only the isolated filesystem is exposed],
  [Network access],
  [Unlimited external communication],
  [Restricted network access],
  [Credentials],
  [Environment variables can leak],
  [Secrets remain isolated],
  [System impact],
  [Can affect the host OS],
  [Host system stays protected],
)

In Deep Agents, a sandbox functions as a _backend_ and exposes the filesystem tools (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`) together with the `execute` tool.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Architecture Patterns

There are two major patterns for sandbox integration.

=== Agent-in-Sandbox
The agent itself runs _inside_ the sandbox and communicates with the outside world over a network protocol.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Advantages],
  text(weight: "bold")[Drawbacks],
  [Similar to a normal development environment],
  [Higher risk of credential exposure],
  [Simple setup],
  [More infrastructure complexity],
)

=== Sandbox-as-Tool (Recommended)
The agent runs _outside_ the sandbox and calls sandbox APIs to execute code.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Advantages],
  text(weight: "bold")[Drawbacks],
  [Clean separation between agent state and execution environment],
  [Network latency],
  [Keeps secrets outside the sandbox],
  [],
  [Makes parallel task execution easier],
  [],
)


#code-block(`````python
# Compare the two architecture patterns (reference only)
print("=== Pattern 1: Agent-in-Sandbox ===")
print("  [Sandbox]")
print("    |-- agent (running inside)")
print("    |-- filesystem")
print("    |-- code execution")
print("    <---> network protocol <---> external systems")

print()
print("=== Pattern 2: Sandbox-as-Tool (recommended) ===")
print("  [Host]")
print("    |-- agent (running outside)")
print("    |-- credential management")
print("    |-- API call --> [Sandbox]")
print("                       |-- filesystem")
print("                       |-- code execution")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Comparing Sandbox Providers

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Package / Provider],
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[Best Fit],
  [`langchain-modal` / Modal],
  [GPU support, ML workloads],
  [AI / ML tasks, data processing],
  [`langchain-daytona` / Daytona],
  [TypeScript / Python support, fast cold starts],
  [Web development, rapid iteration],
  [`langchain-runloop` / Runloop],
  [Disposable devboxes, isolated execution],
  [Code testing, one-off tasks],
  [`langsmith[sandbox]` / LangSmith],
  [LangSmith Deployments integration (private beta)],
  [Operations on top of LangSmith],
  [`langchain-agentcore-codeinterpreter` / AgentCore],
  [AWS Bedrock-backed code interpreter],
  [AWS-native deployments],
)


#code-block(`````python
# Modal sandbox — canonical pattern via langchain-modal
# pip install langchain-modal deepagents
import modal
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_modal import ModalSandbox

app = modal.App.lookup("your-app")
modal_sandbox = modal.Sandbox.create(app=app)
backend = ModalSandbox(sandbox=modal_sandbox)

agent = create_deep_agent(
    model=ChatAnthropic(model="claude-sonnet-4-6"),
    system_prompt="You are a Python coding assistant with sandbox access.",
    backend=backend,
)

try:
    result = agent.invoke({
        "messages": [{"role": "user", "content": "Create a small Python package and run pytest"}],
    })
finally:
    modal_sandbox.terminate()   # required: free resources
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Security Guidelines

=== Never Put Secrets Inside the Sandbox

If credentials are stored in environment variables or mounted files inside the sandbox, an agent can read and leak them.

=== Safe Practices

+ _Manage credentials only through external tools_
+ _Use Human-in-the-Loop_ for sensitive operations
+ _Block unnecessary network access_
+ _Monitor outbound activity_
+ _Review sandbox outputs_ before applying them back to the main application


#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. File Transfer and Lifecycle Management

=== Ways to Access Files

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Method],
  text(weight: "bold")[Description],
  [Agent filesystem tools],
  [Direct file operations through `execute()` and the backend],
  [File transfer APIs],
  [Manage seed files and artifacts through `uploadFiles()` / `downloadFiles()`],
)

=== Lifecycle Management

To avoid unnecessary cost, sandboxes need _explicit shutdown_. There are two operational modes.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Lifetime],
  text(weight: "bold")[Best fit],
  [_Thread-scoped (default)_],
  [One sandbox per conversation thread. Created on the first run, reused on subsequent turns of the same thread, and cleaned up via an idle TTL.],
  [Chat-style agents and conversational sessions],
  [_Assistant-scoped_],
  [All threads of the same assistant share one sandbox. Files, packages, and repositories accumulate across conversations. Always set a TTL or periodic snapshot policy.],
  [Long-running coding sessions, accumulated workspaces],
)

Operational checklist: for one-off scripts, use `try/finally` and terminate immediately. For chat / long sessions, use a per-thread sandbox with TTL-based cleanup. On LangSmith Deployments, wire termination into the session-end hook.


#code-block(`````python
# Example lifecycle and file-transfer settings (reference only)
lifecycle_config = {
    "ttl_seconds": 1800,
    "auto_shutdown": True,
    "thread_isolation": True,
}

file_operations = [
    "uploadFiles(['/local/data.csv'], '/sandbox/data/')",
    "downloadFiles(['/sandbox/output/result.json'], '/local/results/')",
]

print("=== Lifecycle configuration ===")
for key, value in lifecycle_config.items():
    print(f"  {key}: {value}")

print("\n=== File transfer examples ===")
for op in file_operations:
    print(f"  {op}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. ACP Overview

_ACP (Agent Client Protocol)_ standardizes communication between coding agents and development environments such as editors and IDEs.

=== MCP vs ACP

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Protocol],
  text(weight: "bold")[Purpose],
  text(weight: "bold")[Target],
  [_MCP_ (Model Context Protocol)],
  [External tool integration],
  [agent ↔ external service],
  [_ACP_ (Agent Client Protocol)],
  [Editor-agent integration],
  [agent ↔ editor / IDE],
)

ACP allows agents to interact with editors directly for code editing, file navigation, and terminal operations.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. ACP Server Implementation


#code-block(`````python
# ACP server — canonical pattern (asyncio + acp.run_agent)
# pip install deepagents-acp
import asyncio

from acp import run_agent
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    agent = create_deep_agent(
        model="anthropic:claude-sonnet-4-6",
        system_prompt="You are a helpful coding assistant",
        checkpointer=MemorySaver(),
    )
    server = AgentServerACP(agent)
    await run_agent(server)


if __name__ == "__main__":
    asyncio.run(main())
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 8. Editors That Support ACP

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Editor],
  text(weight: "bold")[Integration Style],
  [_Zed_],
  [Native integration],
  [_JetBrains IDEs_],
  [Built-in support],
  [_Visual Studio Code_],
  [`vscode-acp` plugin],
  [_Neovim_],
  [ACP-compatible plugin],
)

=== Example Zed Configuration

#code-block(`````json
// Zed settings.json
{
  "agent_servers": [
    {
      "command": "python",
      "args": ["acp_server.py"],
      "env": {
        "ANTHROPIC_API_KEY": "sk-..."
      }
    }
  ]
}
`````)

=== Toad CLI

_Toad_ is a process manager for running ACP servers as local development tools. It handles start, stop, and restart automatically so you do not have to manage processes by hand.

#code-block(`````bash
# Install
uv tool install -U batrachian-toad

# Run — pass the ACP server command and the working directory
toad acp "python path/to/your_server.py" .
`````)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 9. Combining Sandboxes and ACP

If you combine sandboxes with ACP, you get a _complete architecture_ in which the editor controls the agent while code execution happens in an isolated environment.

=== Integrated Architecture

#code-block(`````text
[Editor / IDE] <-- ACP --> [Agent] <-- API --> [Sandbox]
    |                      |                     |
  code editing         task management       code execution
  file browsing        context management    file isolation
  terminal UI          tool calls            secure runtime
`````)

=== Advantages
- interact with the agent directly from the editor
- run code safely in a sandbox
- keep secrets only on the host side


#code-block(`````python
# Sandbox + ACP integration — canonical pattern
import asyncio

import modal
from acp import run_agent
from deepagents import create_deep_agent
from langchain_anthropic import ChatAnthropic
from langchain_modal import ModalSandbox
from langgraph.checkpoint.memory import MemorySaver

from deepagents_acp.server import AgentServerACP


async def main() -> None:
    app = modal.App.lookup("your-app")
    modal_sandbox = modal.Sandbox.create(app=app)
    try:
        agent = create_deep_agent(
            model=ChatAnthropic(model="claude-sonnet-4-6"),
            system_prompt="You are a coding assistant.",
            backend=ModalSandbox(sandbox=modal_sandbox),
            checkpointer=MemorySaver(),
            interrupt_on={"execute": True},   # HITL approval before code execution
        )
        server = AgentServerACP(agent)
        await run_agent(server)
    finally:
        modal_sandbox.terminate()


if __name__ == "__main__":
    asyncio.run(main())
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Core Concept],
  text(weight: "bold")[Key API / Tool],
  [Sandbox concept],
  [Isolated execution that protects the host system],
  [`execute`, filesystem tools],
  [Architecture patterns],
  [Agent-in-Sandbox vs Sandbox-as-Tool],
  [Sandbox-as-Tool recommended],
  [Providers],
  [Modal (GPU), Daytona (fast startup), Runloop (disposable)],
  [`ModalSandbox`],
  [Security],
  [External secret management, HITL, network controls],
  [`interrupt_on`],
  [ACP overview],
  [Standardized editor-agent communication],
  [`AgentServerACP`],
  [ACP server],
  [Expose the agent in stdio mode],
  [`deepagents-acp`],
  [Editor integration],
  [Zed, JetBrains, VS Code, Neovim],
  [ACP protocol],
  [Integrated pattern],
  [editor ↔ agent ↔ sandbox],
  [ACP + sandbox],
)

=== Next Steps
→ Continue to the _advanced track_ at _#link("../05_advanced/00_migration.ipynb")[../05_advanced/00_migration.ipynb]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/deepagents/11-sandboxes.md")[Sandboxes]
- #link("../docs/deepagents/14-acp.md")[Agent Client Protocol (ACP)]

