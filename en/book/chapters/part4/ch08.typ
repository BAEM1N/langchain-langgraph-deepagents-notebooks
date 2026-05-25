// Auto-generated from 08_harness.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Agent Harness")

== Learning Objectives
- Understand the concept and role of AgentHarness
- Learn the harness's core capabilities: planning, filesystem access, and task delegation
- Understand context management through offloading and summarization
- Configure code execution and Human-in-the-Loop
- Connect skills and memory systems


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
== 1. AgentHarness Concept

_AgentHarness_ is a _comprehensive capability provider_ for long-running autonomous agents.
It bundles together the infrastructure needed for complex multi-step agent work.

=== Core Capabilities Provided by the Harness

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Capability],
  text(weight: "bold")[Description],
  [_Planning_],
  [Manage structured task lists with `write_todos`],
  [_Filesystem_],
  [Read, write, and search files in virtual or local environments],
  [_Task Delegation_],
  [Delegate work through subagents],
  [_Context Management_],
  [Compress context through offloading and summarization],
  [_Code Execution_],
  [Run code safely in sandboxed environments],
  [_Human-in-the-Loop_],
  [Require approval for sensitive operations],
  [_Skills & Memory_],
  [Use specialized workflows and persistent knowledge],
)

When you call `create_deep_agent()`, all of these pieces are assembled into a single agent.


#code-block(`````python
# AgentHarness concept — create_deep_agent assembles the harness
harness_config = {
    "model": "openai:gpt-5.4",
    "system_prompt": "You are a project management assistant.",
    "planning": True,
    "filesystem": True,
    "subagents": [],
    "context_management": True,
}

print("AgentHarness components:")
for key, value in harness_config.items():
    print(f"  {key}: {value}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Planning Tools

The agent uses the `write_todos` tool to break complex work into a _structured task list_.
Each task has a status:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Status],
  text(weight: "bold")[Description],
  [`pending`],
  [Not started yet],
  [`in_progress`],
  [Currently in progress],
  [`completed`],
  [Finished],
)


#code-block(`````python
# write_todos example — structured task list
todo_list = [
    {"task": "Analyze the project structure", "status": "completed"},
    {"task": "Design the API endpoints", "status": "in_progress"},
    {"task": "Write the database schema", "status": "pending"},
    {"task": "Write the tests", "status": "pending"},
    {"task": "Document the project", "status": "pending"},
]

print("=== Agent task list ===")
for i, item in enumerate(todo_list, 1):
    icon = {"completed": "[x]", "in_progress": "[-]", "pending": "[ ]"}
    print(f"  {icon[item['status']]} {i}. {item['task']}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Virtual Filesystem

The harness supports standard file operations through configurable filesystem backends.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tool],
  text(weight: "bold")[Description],
  [`ls`],
  [List directory contents with metadata],
  [`read_file`],
  [Read file contents with line numbers and multimodal returns — images (PNG, JPG, GIF, WebP, HEIC), video (MP4, MOV, AVI), audio (WAV, MP3, AAC, FLAC), documents (PDF, PPT)],
  [`write_file`],
  [Create files],
  [`edit_file`],
  [Replace strings inside files],
  [`glob`],
  [Search for files by pattern],
  [`grep`],
  [Search file contents in different output modes],
  [`execute`],
  [Run shell commands (sandbox backends only)],
)


#code-block(`````python
# Example filesystem tool calls (reference only)
fs_operations = {
    "ls": 'ls(path="/project/src")',
    "read_file": 'read_file(path="/project/src/main.py")',
    "write_file": 'write_file(path="/project/config.yaml", content="debug: true")',
    "edit_file": 'edit_file(path="/project/src/main.py", old="v1", new="v2")',
    "glob": 'glob(pattern="**/*.py")',
    "grep": 'grep(pattern="TODO", path="/project/src")',
}

print("=== Filesystem tool call examples ===")
for tool_name, call_example in fs_operations.items():
    print(f"  {tool_name:12s} -> {call_example}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Task Delegation — Subagents

The harness allows the main agent to create _temporary subagents_ for isolated multi-step work.

=== Advantages of Subagents

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Advantage],
  text(weight: "bold")[Description],
  [_Context isolation_],
  [Subagent execution does not pollute the main context],
  [_Parallel execution_],
  [Multiple subagents can run at the same time],
  [_Specialization_],
  [Each subagent can get its own tools and prompt],
  [_Token efficiency_],
  [The main agent receives a compressed result],
)


#code-block(`````python
# Example subagent delegation configuration (reference only)
subagent_config = [
    {
        "name": "researcher",
        "description": "Investigates information using web search.",
        "system_prompt": "Summarize search results concisely.",
        "tools": ["internet_search"],
    },
    {
        "name": "coder",
        "description": "Writes and tests code.",
        "system_prompt": "Write clean and testable code.",
        "tools": ["write_file", "execute"],
    },
]

print("=== Subagent configuration ===")
for sa in subagent_config:
    print(f"  [{sa['name']}] {sa['description']}")
    print(f"    tools: {', '.join(sa['tools'])}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Context Management

The biggest challenge for long-running agents is the _context window limit_.
The harness addresses it with two main techniques.

=== Input Context Assembly
The initial prompt is assembled from the system prompt, instructions, memory guidelines, skill information, and filesystem documentation.

=== Runtime Context Compression

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Technique],
  text(weight: "bold")[Behavior],
  text(weight: "bold")[Trigger],
  [_Offloading_],
  [Stores content above a configurable threshold (default 20,000 tokens) on disk and keeps only pointers in context],
  [Based on content size],
  [_Summarization_],
  [Compresses conversation history into a structured summary (session intent / artifacts / next steps). Triggered around _85%_ of `max_input_tokens`; the most recent _10%_ of messages are preserved verbatim. Falls back to a 170k-token threshold when `max_input_tokens` is not set.],
  [Triggered when the model window limit is approached],
)

The original data is preserved in filesystem storage, so information is not lost.


#code-block(`````python
# Example context-management settings (reference only)
context_config = {
    "offloading": {
        "enabled": True,
        "threshold_tokens": 20000,
        "storage": "filesystem",
    },
    "summarization": {
        "enabled": True,
        "trigger": "window_limit_approach",
        "preserve_original": True,
    },
}

print("=== Context management settings ===")
for section, settings in context_config.items():
    print(f"\n[{section}]")
    for key, value in settings.items():
        print(f"  {key}: {value}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. Code Execution

Sandbox backends expose the `execute` tool, which runs commands in an isolated environment.
That improves safety, cleanliness, and reproducibility without affecting the host system.

=== Two execution paths: sandbox `execute` (shell) vs QuickJS `CodeInterpreterMiddleware`

The harness exposes two distinct execution paths. The _sandbox backend_ contributes a shell-style `execute` tool, while the _interpreter middleware_ contributes a QuickJS eval tool. They solve different problems.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Aspect],
  text(weight: "bold")[Sandbox `execute` (shell)],
  text(weight: "bold")[QuickJS `CodeInterpreterMiddleware`],
  [Where it runs],
  [Isolated environment outside the agent (Modal / Daytona / Runloop ...)],
  [QuickJS VM inside the agent loop],
  [Language],
  [Shell commands → any language (Python, Node, ...)],
  [JavaScript (QuickJS)],
  [Network / filesystem],
  [On by default (governed by policy)],
  [Off by default — only bridged tools],
  [Package install],
  [`pip install` / `npm install` supported],
  [Not supported],
  [Best fit],
  [Installing packages, running tests, processing large data],
  [Composing tool calls, subagent fan-out, structured data transforms],
  [How to enable],
  [Swap the backend, e.g. `backend=ModalSandbox(...)`],
  [Add `middleware=[CodeInterpreterMiddleware(...)]`],
)


#code-block(`````python
# Example sandboxed execute calls (reference only)
execute_examples = [
    {"command": "python -c 'print(2+2)'", "desc": "Run a Python snippet"},
    {"command": "pip install requests", "desc": "Install a package"},
    {"command": "pytest tests/", "desc": "Run the test suite"},
]

print("=== Sandbox execute tool examples ===")
for ex in execute_examples:
    print(f"  $ {ex['command']}")
    print(f"    -> {ex['desc']}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Human-in-the-Loop

You can require human approval for selected tool calls through interrupt settings.


#code-block(`````python
# Example Human-in-the-Loop configuration (reference only)
hitl_config = {
    "interrupt_on": {
        "write_file": True,
        "edit_file": True,
        "execute": True,
    }
}

print("=== Human-in-the-Loop configuration ===")
print("Tools that require approval:")
for tool, enabled in hitl_config["interrupt_on"].items():
    status = "approval required" if enabled else "automatic"
    print(f"  {tool}: {status}")

print("\nDecision options: approve, reject, edit")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 8. Skills and Memory

=== Skills
Skills are specialized workflows that follow the _Agent Skills standard_.
They are loaded progressively when relevant, which reduces token usage.

- Each skill is defined in a `SKILL.md` file
- Skills are activated when the triggering conditions match
- They package tools, prompts, and workflows together

=== Memory
Memory uses *`AGENTS.md`*-style persistent context files.
It stores reusable guidelines, preferences, and project knowledge beyond a single conversation.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Scope],
  text(weight: "bold")[Location],
  text(weight: "bold")[Range],
  [Global memory],
  [`~/.deepagents/\<agent\>/memories/`],
  [All projects],
  [Project memory],
  [`.deepagents/AGENTS.md`],
  [Current project],
)


#code-block(`````python
# Example skill and memory configuration (reference only)
skills_config = [
    {"name": "code-review", "trigger": "when the user asks for a code review"},
    {"name": "test-writer", "trigger": "when the user asks for tests"},
    {"name": "doc-generator", "trigger": "when the user asks for documentation"},
]

memory_config = {
    "global": "~/.deepagents/my-agent/memories/",
    "project": ".deepagents/AGENTS.md",
}

print("=== Skill configuration ===")
for skill in skills_config:
    print(f"  [{skill['name']}] trigger: {skill['trigger']}")

print("\n=== Memory configuration ===")
for scope, path in memory_config.items():
    print(f"  {scope}: {path}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 9. Harness Profiles

`HarnessProfile` packages provider/model-specific harness defaults without touching the `create_deep_agent()` call site. System prompt suffixes, tool description overrides, excluded tools and middleware, general-purpose subagent options, and extra middleware can all be registered as a profile.

=== `HarnessProfile` (7 fields)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Meaning],
  [`base_system_prompt`],
  [Replace the base system prompt itself],
  [`system_prompt_suffix`],
  [Append text to the assembled base prompt],
  [`tool_description_overrides`],
  [Per-tool description overrides (mapping)],
  [`excluded_tools`],
  [Tools to remove by name after injection (set)],
  [`excluded_middleware`],
  [Middleware classes to remove (set)],
  [`extra_middleware`],
  [Additional middleware instances to attach],
  [`general_purpose_subagent`],
  [Enable, disable, or customize the general-purpose subagent via `GeneralPurposeSubagentProfile`],
)

=== Merge semantics

When multiple profiles match:

- A later profile overrides earlier _scalar_ fields (for example `base_system_prompt`).
- _Mapping_-style fields such as `tool_description_overrides` merge key by key.
- _Set_-style fields (`excluded_tools`, `excluded_middleware`) take the union.

=== `ProviderProfile` (3 fields)

`ProviderProfile` does not change harness behavior; it bundles initialization arguments for `init_chat_model()` — credential checks, provider default temperature, runtime headers, and so on.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Meaning],
  [`init_kwargs`],
  [Default kwargs passed to `init_chat_model()` (for example `temperature`)],
  [`credentials_check`],
  [Callable run before model initialization to verify credentials],
  [`runtime_headers`],
  [HTTP header mapping attached to every request],
)

=== YAML / JSON workflow — `HarnessProfileConfig.from_dict`

`HarnessProfileConfig` provides `from_dict()`, `to_dict()`, and `from_harness_profile()` class methods, so profiles can be managed as YAML and applied per environment without code changes.

#code-block(`````yaml
# profile.yaml
base_system_prompt: You are helpful.
system_prompt_suffix: Respond briefly.
excluded_tools:
  - execute
excluded_middleware:
  - SummarizationMiddleware
general_purpose_subagent:
  enabled: false
`````)

#code-block(`````python
import yaml
from deepagents import HarnessProfileConfig, register_harness_profile

with open("profile.yaml") as f:
    register_harness_profile(
        "openai:gpt-5.4",
        HarnessProfileConfig.from_dict(yaml.safe_load(f)),
    )
`````)

=== Entry-point plugins

Profiles can ship as packages via `pyproject.toml` entry points. The load order is _built-ins → entry-point plugins → user code's direct `register_*_profile` calls_.

#code-block(`````toml
[project.entry-points."deepagents.harness_profiles"]
"anthropic:claude-sonnet-4-6" = "my_pkg.profiles:claude_profile"

[project.entry-points."deepagents.provider_profiles"]
"openai" = "my_pkg.profiles:openai_provider"
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
  [Harness concept],
  [Comprehensive capability provider for long-running agents],
  [`create_deep_agent()`],
  [Planning tools],
  [Structured task list management],
  [`write_todos`],
  [Filesystem],
  [Virtual and local file operations],
  [`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`, `execute`],
  [Subagents],
  [Isolated task delegation, parallel execution],
  [`subagents`, `task`],
  [Context management],
  [Offloading (20K tokens), summarization],
  [automatic],
  [Code execution],
  [Safe command execution in sandboxes],
  [`execute`],
  [HITL],
  [Human approval for sensitive tool calls],
  [`interrupt_on`],
  [Skills / Memory],
  [Specialized workflows + persistent context],
  [`SKILL.md`, `AGENTS.md`],
)

=== Next Steps
→ Continue to _#link("./09_comparison.ipynb")[09_comparison.ipynb]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/deepagents/05-harness.md")[Deep Agents Harness]

