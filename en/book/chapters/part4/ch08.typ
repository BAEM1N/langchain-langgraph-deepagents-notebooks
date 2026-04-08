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

model = ChatOpenAI(model="gpt-4.1")

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
    "model": "gpt-4.1",
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
  [Read file contents with line numbers (and image support)],
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
  [Stores content larger than 20,000 tokens on disk and keeps only pointers in context],
  [Based on content size],
  [_Summarization_],
  [Compresses conversation history into a structured summary],
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

