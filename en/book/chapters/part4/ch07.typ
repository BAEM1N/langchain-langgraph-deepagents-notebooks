// Auto-generated from 07_advanced.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Advanced Features")

== Learning Objectives
- Implement a Human-in-the-Loop workflow
- Understand streaming modes and the namespace system
- Understand sandbox integrations such as Modal, Daytona, and Runloop
- Understand `CodeInterpreterMiddleware`, QuickJS, and programmatic subagent gates
- Use `RubricMiddleware` as a selective runtime quality gate
- Learn how ACP (Agent Client Protocol) connects agents to editors
- Learn how to use Deep Agents Code (`dcode`)


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

model = ChatOpenAI(model="gpt-4.1")

print(f"Model configured: {model.model_name}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Human-in-the-Loop (HITL)

Human-in-the-Loop is a workflow in which the agent _requires human approval_ before calling sensitive tools.

=== How it Works

#image("../../assets/images/hitl_flow.png")

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

#code-block(`````python
# Run the agent — it will pause before write_file
config = {"configurable": {"thread_id": "hitl-demo"}}

result = hitl_agent.invoke(
    {"messages": [{"role": "user", "content": "Create a file named config.yaml and write 'debug: true'."}]},
    config={**config, **lf_config},
)

# Inspect interrupts
if "__interrupt__" in result:
    interrupt_info = result["__interrupt__"]
    print("The agent was interrupted")
    print(f"Pending approvals: {len(interrupt_info)}")
    for item in interrupt_info:
        val = item.value if hasattr(item, 'value') else item
        print(f"  - Interrupt payload: {val}")
else:
    print("Completed without interruption:")
    print(result["messages"][-1].content)

`````)

#code-block(`````python
from langgraph.types import Command

# Resume with approval
if "__interrupt__" in result:
    resumed = hitl_agent.invoke(
        Command(
            resume={
                "decisions": [
                    {"type": "approve"}
                    # {"type": "reject"}
                    # {"type": "edit", "args": {"content": "debug: false"}}
                ]
            }
        ),
        config={**config, **lf_config},
    )

    print("✅ Resumed after approval:")
    print(resumed["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Advanced Streaming

Deep Agents runs on top of LangGraph's streaming infrastructure.

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


#code-block(`````python
from typing import Literal

LOCAL_DOC_SNIPPETS = {
    "langgraph": "LangGraph supports persistence, interrupts, subgraphs, streaming, and fault tolerance.",
    "python 3.13": "Python 3.13 improves the REPL, error messages, and standard-library behavior.",
}


def internet_search(query: str, max_results: int = 3, topic: Literal["general", "news"] = "general") -> dict:
    """Search local course snippets. The live harness does not need an external search key."""
    matches = [v for k, v in LOCAL_DOC_SNIPPETS.items() if k in query.lower()]
    return {"query": query, "topic": topic, "results": matches[:max_results] or list(LOCAL_DOC_SNIPPETS.values())[:max_results]}


stream_agent = create_deep_agent(
    model=model,
    system_prompt="You are a research coordinator. Respond in English.",
    subagents=[
        {
            "name": "researcher",
            "description": "Uses local course snippets to investigate topics.",
            "system_prompt": "Use only the search tool results, then summarize the requested information concisely.",
            "tools": [internet_search],
        }
    ],
)

print("Streaming demo agent created")

`````)

#code-block(`````python
# Stream events with subgraphs — use namespaces to distinguish sources
print("=== Subagent event streaming ===")
print()

for namespace, chunk in stream_agent.stream(
    {"messages": [{"role": "user", "content": "Research the latest LangGraph features."}]},
    stream_mode="updates",
    subgraphs=True,
    config=lf_config,
):
    source = "[main]" if not namespace else f"[subagent: {namespace}]"

    for node_name, node_data in chunk.items():
        if not node_data:
            continue
        msgs = node_data.get("messages", [])
        if hasattr(msgs, "value"):
            msgs = msgs.value
        if msgs:
            last_msg = msgs[-1]
            if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
                for tc in last_msg.tool_calls:
                    print(f"{source} 🔧 tool call: {tc['name']}")
            elif hasattr(last_msg, "content") and last_msg.content:
                content = last_msg.content if isinstance(last_msg.content, str) else str(last_msg.content)
                if content.strip() and not hasattr(last_msg, "tool_call_id"):
                    preview = content[:100].replace("\n", " ")
                    print(f"{source} 💬 {preview}...")

`````)

#code-block(`````python
# Use multiple stream modes together
print("=== Multiple stream modes ===")
print()

for event in stream_agent.stream(
    {"messages": [{"role": "user", "content": "Explain one new feature in Python 3.13 in a single sentence."}]},
    stream_mode=["updates", "messages"],
    subgraphs=True,
    config=lf_config,
):
    *namespace_parts, mode, data = event
    if mode == "updates":
        for node_name in data:
            print(f"  [updates] node '{node_name}' completed")
    elif mode == "messages":
        msg, metadata = data
        if hasattr(msg, "content") and msg.content and metadata and metadata.get("langgraph_node") == "model":
            print(msg.content, end="", flush=True)

print()

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

#image("../../assets/images/sandbox_architecture.png")

=== ⚠️ Security Guidelines
- _Never put secrets inside the sandbox_ — the agent may leak them
- Manage credentials only through external tools
- Use Human-in-the-Loop approval for sensitive operations
- Block unnecessary network access


#code-block(`````python
# Sandbox integration example (reference only — requires provider-specific setup)

sandbox_example_code = """
# pip install deepagents-modal
from deepagents.backends.sandbox import ModalSandbox

agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    backend=ModalSandbox(
        image="python:3.12-slim",
        gpu="T4",  # GPU support
    ),
)
"""

print("Sandbox integration example (reference only):")
print(sandbox_example_code)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Interpreters — CodeInterpreterMiddleware

Deep Agents can use a QuickJS-based interpreter as an internal workspace for tool composition, intermediate variables, structured data transforms, and programmatic subagent fan-out/fan-in.

=== Installation

#code-block(`````bash
pip install -U "deepagents[quickjs]"
# or
uv add "deepagents[quickjs]"
`````)

=== Programmatic Tool Calling vs programmatic subagents

Programmatic Tool Calling exposes allowlisted tools as `tools.*` functions inside QuickJS. Programmatic subagents are separate: the interpreter exposes a top-level `task(...)` function when `CodeInterpreterMiddleware(subagents=True)` is enabled.

#code-block(`````javascript
const topics = ["retrieval", "memory", "evaluation"];
const reports = await Promise.all(
  topics.map((topic) => task({
    description: `Research ${topic}`,
    subagent_type: "general-purpose",
  })),
);
`````)

Use a least-privilege PTC allowlist for sensitive tools. Do not assume parent-level approvals automatically cover every interpreter dispatch.

#code-block(`````python
# Interpreter configuration example — requires the deepagents[quickjs] extra
interpreter_example = r'''
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=MemorySaver(),
    middleware=[CodeInterpreterMiddleware(ptc=["web_search"], subagents=True, mode="thread")],
)

# Inside QuickJS, use task(...) separately from tools.webSearch(...).
'''
print(interpreter_example)

`````)

=== Compatibility gate in the current course environment

The official Programmatic Subagents pattern relies on the QuickJS interpreter and top-level `task(...)`. The current course venv has Deep Agents installed, but the `langchain_quickjs` extra may not be present. Therefore the default notebook path detects availability and falls back to ordinary `SubAgent` orchestration.

#code-block(`````python
from importlib.metadata import PackageNotFoundError, version
from importlib.util import find_spec

try:
    deepagents_version = version("deepagents")
except PackageNotFoundError:
    deepagents_version = "not installed"
quickjs_available = find_spec("langchain_quickjs") is not None
fallback_pattern = "Programmatic task(...) demo" if quickjs_available else "ordinary SubAgent fan-out/fan-in fallback"
print("deepagents:", deepagents_version)
print("langchain_quickjs available:", quickjs_available)
print("recommended path:", fallback_pattern)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. RubricMiddleware — runtime LLM-as-a-judge

`RubricMiddleware` evaluates an agent response against a rubric during the same invocation. Use it as a selective runtime quality gate for high-risk outputs, final deliverables, or external-send steps. Keep offline regression checks in LangSmith/AgentEvals, and use runtime rubrics only where the extra latency and cost are justified.

#code-block(`````python
# RubricMiddleware configuration example — reference only
rubric_example = r'''
from deepagents import RubricMiddleware, create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=MemorySaver(),
    middleware=[RubricMiddleware(
        model="openai:gpt-5.4-mini",
        system_prompt="Judge accuracy, grounding, and safety from 1 to 5; request revision if weak.",
        max_iterations=3,
    )],
)
'''
print(rubric_example)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. ACP (Agent Client Protocol)

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
# ACP server implementation example (reference only)
acp_example_code = """
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

print("ACP server implementation example (reference only):")
print(acp_example_code)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Deep Agents Code (`dcode`)

Deep Agents Code is a _terminal coding agent_ built on top of the SDK. Current CLI material uses the `deepagents-code` package and the `dcode` command.

=== Installation and Execution
#code-block(`````bash
# Install script
curl -LsSf https://langch.in/dcode | bash

# Check help without installing
uvx --from deepagents-code dcode --help

# Run
dcode
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
  [`-M/--model MODEL`],
  [Choose the model],
  [`-n/--non-interactive`],
  [Non-interactive mode for a single task],
  [`-S/--shell-allow-list`],
  [Specify allowed shell commands],
  [`--interpreter`],
  [Enable the interpreter],
  [`--interpreter-tools`],
  [Specify tools available to the interpreter],
  [`--stdin`],
  [Read the prompt from standard input],
  [`--json`],
  [Emit JSON output],
  [`--acp`],
  [Run as an ACP server over stdio],
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

=== Configuration and Memory
- _Global config_: `~/.deepagents/config.toml`
- _Project instructions_: `AGENTS.md`
- _Skills_: progressive disclosure through `SKILL.md`
- _Subagents_: configured through files or project instructions


#code-block(`````python
# Deep Agents Code examples (run in the shell)
cli_examples = """
# Check help without installing
uvx --from deepagents-code dcode --help

# Non-interactive execution with a specific model
uvx --from deepagents-code dcode -M gpt-5.4 -n "Write the README.md file for this project"

# Enable interpreter support
uvx --from deepagents-code dcode --interpreter "Inspect this repository and summarize risks"
"""

print("dcode usage examples (run in the terminal):")
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
  [`interrupt_on`, streaming, `CodeInterpreterMiddleware`, `RubricMiddleware`, Sandbox, ACP, `dcode`],
)

=== Next Steps
→ Continue to _#link("./08_harness.ipynb")[08_harness.ipynb]_
→ Or jump to the _advanced track_ at _#link("../05_advanced/00_migration.ipynb")[../05_advanced/00_migration.ipynb]_
