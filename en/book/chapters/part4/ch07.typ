// Auto-generated from 07_advanced.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Advanced Features")

== Learning Objectives
- Implement a Human-in-the-Loop workflow
- Understand streaming modes and the namespace system
- Understand sandbox integrations such as Modal, Daytona, and Runloop
- Learn how ACP (Agent Client Protocol) connects agents to editors
- Learn how to use the Deep Agents CLI


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
== 1. Human-in-the-Loop (HITL)

Human-in-the-Loop is a workflow in which the agent _requires human approval_ before calling sensitive tools. Deep Agents supports _four decision types_, all passed as dicts under `Command(resume={"decisions": [...]})` when resuming.

=== How it Works

#image("../../../../book/assets/diagrams/png/hitl_flow.png")

=== Four decision types

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Decision],
  text(weight: "bold")[Behavior],
  [`approve`],
  [Execute the tool with the proposed arguments as-is],
  [`edit`],
  [Modify arguments via `edited_action.name/args` and then execute],
  [`reject`],
  [Skip the tool call entirely],
  [`respond`],
  [Skip execution and return `message` as the tool result],
)

=== Inspecting interrupts and resuming (v2 standard)

When you call `invoke(..., version="v2")`, interrupts are exposed via `result.interrupts` — _not_ the older `result["__interrupt__"]` key. Each interrupt's `interrupt_value["action_requests"]` lists the proposed tool calls and `allowed_decisions`. Resume with `Command(resume={"decisions": [...]})` (a dict) using the same `thread_id`.

#code-block(`````python
from langgraph.types import Command

# Inspect interrupts
result = hitl_agent.invoke(inputs, config=config, version="v2")
for itr in result.interrupts:
    for req in itr.value["action_requests"]:
        print(req["action"]["name"], req["allowed_decisions"])

# Resume — one decision per interrupt, in the same order
hitl_agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config,
    version="v2",
)
`````)

=== Required Condition
- _Checkpointer_: required to preserve the agent's state between interrupt and resume


#code-block(`````python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

# Choose which tools require approval with interrupt_on
hitl_agent = create_deep_agent(
    model=model,
    system_prompt="You are a file management assistant. Respond in English.",
    checkpointer=MemorySaver(),  # required!
    interrupt_on={
        "write_file": True,
        "edit_file": True,
    },
)

print("Human-in-the-Loop agent created")
print("write_file and edit_file now require approval")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Advanced Streaming

Deep Agents runs on top of LangGraph's streaming infrastructure.

=== v2 unified format (standard)

The standard path is _one call_: `agent.stream(..., stream_mode=..., subgraphs=True, version="v2")`. The older v1 nested-tuple format is harder to branch on, and v3/projection variants are unofficial — do not use them. Every chunk shares the same 3-field shape:

#code-block(`````python
{
    "type": "updates" | "messages" | "custom",
    "ns":   tuple,            # event source (main vs subagent routing)
    "data": Any,              # payload, depends on type
}
`````)

#tip-box[Without `subgraphs=True`, subagent-internal events are invisible — set it whenever the UI needs to show subagent progress. To hide summarization tokens, filter on `metadata.get("lc_source") == "summarization"`.]

=== Stream Modes

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[Use Case],
  [`"updates"`],
  [State updates after each node finishes],
  [Progress tracking],
  [`"messages"`],
  [Token-level streaming],
  [Real-time text output],
  [`"custom"`],
  [Events emitted inside tools or nodes],
  [Custom progress reporting],
)

=== Namespace System

Events from subagents are separated by namespace:

#code-block(`````python
()                                # main agent
("tools:abc123",)                # subagent (tool call ID)
("tools:abc123", "model:def456")  # inner node inside a subagent
`````)


=== Custom progress events (`get_stream_writer` + `stream_mode="custom"`)

Tools can emit arbitrary objects for the UI — upload progress, processed counts, mid-execution status. Pin the schema (for example `{"status", "progress", "message"}`) so the UI routing does not break across tools.

#code-block(`````python
from langchain.tools import tool
from langgraph.config import get_stream_writer


@tool
def analyze_data(topic: str) -> str:
    """Analyze data for a topic and stream progress updates."""
    writer = get_stream_writer()
    writer({"status": "starting", "progress": 0, "topic": topic})
    # ... actual analysis ...
    writer({"status": "complete", "progress": 100, "topic": topic})
    return f"Analysis complete: {topic}"


for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "..."}]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])
`````)

#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ.get("TAVILY_API_KEY", ""))


def internet_search(
    query: str,
    max_results: int = 3,
    topic: Literal["general", "news"] = "general",
) -> dict:
    """Search the internet for information."""
    return tavily_client.search(query, max_results=max_results, topic=topic)


stream_agent = create_deep_agent(
    model=model,
    system_prompt="You are a research coordinator. Respond in English.",
    subagents=[
        {
            "name": "researcher",
            "description": "Uses internet search to investigate topics.",
            "system_prompt": "Search the internet, collect the requested information, and summarize it concisely.",
            "tools": [internet_search],
        }
    ],
)

print("Streaming demo agent created")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Sandboxes

A sandbox lets the agent run code in an _isolated environment_.
That prevents it from accessing the host machine's files, network, or credentials directly.

=== Supported Providers

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
  [AI / ML tasks],
  [_Daytona_],
  [TypeScript / Python, fast cold starts],
  [Web development],
  [_Runloop_],
  [Disposable devboxes, isolated execution],
  [Code testing],
)

=== Architecture Pattern

_Use the sandbox as a tool_ (recommended)

#image("../../../../book/assets/diagrams/png/sandbox_architecture.png")

=== ⚠️ Security Guidelines
- _Never put secrets inside the sandbox_ — the agent may leak them
- Manage credentials only through external tools
- Use Human-in-the-Loop approval for sensitive operations
- Block unnecessary network access


#code-block(`````python
# Modal sandbox integration — uses the langchain-modal package
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
    modal_sandbox.terminate()    # required: free resources
`````)

#tip-box[Each provider ships as a separate package (`langchain-modal`, `langchain-daytona`, ...). Always pair sandbox creation with `try/finally` and call `terminate()` (or `stop()` / `shutdown()`) so resources are released.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3-1. Interpreters — `CodeInterpreterMiddleware`

Deep Agents 0.6 lets you attach a _QuickJS-based interpreter_ through `CodeInterpreterMiddleware`. A sandbox runs code in an isolated _outside_ environment; an interpreter runs small programs _inside_ the agent loop. It is useful for composing tool calls, fan-out/fan-in across subagents, and shaping structured data.

=== Install

#code-block(`````bash
pip install -U "deepagents[quickjs]"
# or
uv add "deepagents[quickjs]"
`````)

=== Programmatic Tool Calling (PTC)

Set `ptc=["task"]` (an allowlist) to expose tools as async functions under the `tools.*` namespace, with names converted to camelCase (for example `web_search` → `tools.webSearch`). Inside the interpreter you can fan out with `Promise.all`.

#code-block(`````python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[
        CodeInterpreterMiddleware(
            ptc=["task"],
            snapshot_between_turns=True,
            timeout=5.0,
            max_ptc_calls=256,
        ),
    ],
)
`````)

=== Middleware options (10)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Purpose],
  [`memory_limit`], [`64*1024*1024`], [QuickJS heap memory limit (bytes)],
  [`timeout`], [`5.0`], [Per-eval timeout (seconds)],
  [`max_ptc_calls`], [`256`], [Max `tools.*` calls per eval],
  [`tool_name`], [`"eval"`], [Interpreter tool name],
  [`max_result_chars`], [`4000`], [Max characters returned],
  [`capture_console`], [`True`], [Capture `console.log` output],
  [`ptc`], [`None`], [PTC allowlist],
  [`skills_backend`], [`None`], [Backend for interpreter skill modules],
  [`snapshot_between_turns`], [`True`], [Preserve state across turns],
  [`max_snapshot_bytes`], [`None`], [Max snapshot size],
)

#warning-box[PTC does not go through the regular tool-calling path, so per-tool `interrupt_on` policies are _not_ guaranteed to apply. Do not expose tools with side effects (cost, data mutation, network) without an explicit approval wrapper.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. ACP (Agent Client Protocol)

ACP standardizes communication _between coding agents and editors / IDEs_.

=== Supported Editors
- _Zed_ — native integration
- _JetBrains IDEs_ — built-in support
- _VS Code_ — `vscode-acp` plugin
- _Neovim_ — ACP-compatible plugins

=== MCP vs ACP
#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Protocol],
  text(weight: "bold")[Purpose],
  [MCP (Model Context Protocol)],
  [External tool integration],
  [ACP (Agent Client Protocol)],
  [Editor ↔ agent integration],
)


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

#tip-box[The Toad CLI runs ACP servers as managed local processes. Install with `uv tool install -U batrachian-toad`, then `toad acp "python path/to/your_server.py" .` to launch with automatic start/stop/restart.]

=== Context Engineering — `@dynamic_prompt`

Inject request-time data into the system prompt with the `@dynamic_prompt` middleware. It can read `request.runtime.context` and `request.runtime.store`, so any field declared in `context_schema` (such as `user_id` / `org_id`) propagates to every subagent and tool automatically. Tools receive `ToolRuntime[Context]` and read runtime values from `runtime.context.user_id`.

#code-block(`````python
from deepagents.middleware import dynamic_prompt

@dynamic_prompt
def inject_user(request):
    user_id = request.runtime.context.user_id
    pref = request.runtime.store.get(("prefs", user_id), "lang")
    return f"\n\nUser: {user_id} / Preferred language: {pref}"
`````)

=== Permissions (`deepagents>=0.5.2`)

`FilesystemPermission` controls read/write access on built-in FS tools using _first-match-wins_ semantics; if nothing matches, the default is `allow`. Custom tools, MCP, and the sandbox `execute` bypass these rules and need separate guards. A subagent's `permissions` _fully replaces_ parent rules (no partial override).

#code-block(`````python
from deepagents.permissions import FilesystemPermission

permissions = [
    FilesystemPermission(operations=["write"], paths=["/policies/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
]
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Deep Agents CLI

The Deep Agents CLI is a _terminal coding agent_ built on top of the SDK.

=== Installation and Execution
#code-block(`````bash
# Install
uv tool install deepagents-cli

# Run
deepagents-cli

# Run directly without installing
uvx deepagents-cli
`````)

=== Main Options

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Option],
  text(weight: "bold")[Description],
  [`-a/--agent AGENT`],
  [Specify the agent name],
  [`-M/--model MODEL`],
  [Choose the model],
  [`-n/--non-interactive`],
  [Non-interactive mode (single task execution)],
  [`--auto-approve`],
  [Skip human confirmation],
  [`--sandbox {none,modal,daytona,runloop}`],
  [Select a sandbox backend],
)

=== Interactive Commands

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Command],
  text(weight: "bold")[Description],
  [`/model`],
  [Change the model],
  [`/remember`],
  [Store information in memory],
  [`/tokens`],
  [Inspect token usage],
  [`!command`],
  [Run a shell command],
)

=== Memory System
- _Global_: `~/.deepagents/<agent_name>/memories/`
- _Project_: `.deepagents/AGENTS.md` (project root)


#code-block(`````python
# CLI non-interactive examples (run in the shell)
cli_examples = """
# Basic usage
deepagents-cli

# Non-interactive execution with a specific model
deepagents-cli -M claude-sonnet-4-6 -n "Write the README.md file for this project"

# Run inside a sandbox
deepagents-cli --sandbox modal "Run the test suite"

# Skill management
deepagents-cli skills list
deepagents-cli skills create my-skill
"""

print("CLI usage examples (run in the terminal):")
print(cli_examples)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== Full Track Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Notebook],
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key APIs],
  [_01_],
  [Introduction],
  [`deepagents.__version__`],
  [_02_],
  [Quickstart],
  [`create_deep_agent()`, `invoke()`, `stream()`],
  [_03_],
  [Customization],
  [`model`, `system_prompt`, `tools`, `response_format`],
  [_04_],
  [Backends],
  [`StateBackend`, `FilesystemBackend`, `StoreBackend`, `CompositeBackend`],
  [_05_],
  [Subagents],
  [`SubAgent`, `CompiledSubAgent`, `subagents`],
  [_06_],
  [Memory & Skills],
  [`memory`, `skills`, `AGENTS.md`, `SKILL.md`],
  [_07_],
  [Advanced Features],
  [`interrupt_on`, `stream_mode`, Sandbox, ACP, CLI],
)

=== Next Steps
→ Continue to _#link("./08_harness.ipynb")[08_harness.ipynb]_
→ Or jump to the _advanced track_ at _#link("../05_advanced/00_migration.ipynb")[../05_advanced/00_migration.ipynb]_

