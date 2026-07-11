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
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

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
  text(weight: "bold")[Provider],
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[Best Fit],
  [_Modal_],
  [GPU support, ML workloads],
  [AI / ML tasks, data processing],
  [_Daytona_],
  [TypeScript / Python support, fast cold starts],
  [Web development, rapid iteration],
  [_Runloop_],
  [Disposable devboxes, isolated execution],
  [Code testing, one-off tasks],
)


#code-block(`````python
# Example Modal sandbox configuration (reference only)
modal_config = {
    "provider": "modal",
    "image": "python:3.12-slim",
    "gpu": "T4",
    "timeout": 300,
}

print("=== Modal sandbox configuration ===")
for key, value in modal_config.items():
    print(f"  {key}: {value}")

print()
print("Example code (reference only):")
print('  from deepagents.backends.sandbox import ModalSandbox')
print('  agent = create_deep_agent(')
print('      model="gpt-5.4",')
print('      backend=ModalSandbox(image="python:3.12-slim", gpu="T4"),')
print('  )')

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
To avoid unnecessary cost, sandboxes need _explicit shutdown_.
In chat-style applications, a common pattern is to assign one sandbox per conversation thread and configure a TTL (Time-to-Live).


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
# Example ACP server implementation (reference only)
acp_server_code = """
# pip install deepagents-acp
from deepagents import create_deep_agent
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# Create the agent
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="You are a coding assistant.",
    checkpointer=MemorySaver(),
)

# Run the ACP server (stdio mode)
server = AgentServerACP(agent)
server.run()
"""

print("=== ACP server implementation example ===")
print(acp_server_code)

print("Install: pip install deepagents-acp")
print("Run: python acp_server.py (stdio mode)")

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

=== Extra Tool: Toad
_Toad_ is a process manager for running ACP servers as local development tools.
You can install it with `uv`.


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
# Example sandbox + ACP integration (reference only)
integrated_config = """
from deepagents import create_deep_agent
from deepagents.backends.sandbox import ModalSandbox
from deepagents_acp import AgentServerACP
from langgraph.checkpoint.memory import MemorySaver

# Combine a sandbox backend with an ACP server
agent = create_deep_agent(
    model="gpt-5.4",
    system_prompt="You are a coding assistant.",
    backend=ModalSandbox(image="python:3.12-slim"),
    checkpointer=MemorySaver(),
    interrupt_on={"execute": True},
)

# Connect the agent to the editor through ACP
server = AgentServerACP(agent)
server.run()
"""

print("=== Sandbox + ACP integration example ===")
print(integrated_config)

print("What this setup gives you:")
print("  1. The editor interacts with the agent through ACP")
print("  2. Code execution runs safely inside a Modal sandbox")
print("  3. execute calls require Human-in-the-Loop approval")

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
- #link("../../docs/deepagents/11-sandboxes.md")[Sandboxes]
- #link("../../docs/deepagents/14-acp.md")[Agent Client Protocol (ACP)]
