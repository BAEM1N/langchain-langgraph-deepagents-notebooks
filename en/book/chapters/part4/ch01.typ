// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Introduction to Deep Agents")

== Learning Objectives
- Understand what Deep Agents is
- Learn the difference between the SDK and the CLI
- Understand the five core concepts: Planning, Context Management, Backends, Subagents, and Memory
- Compare Deep Agents with other frameworks
- Verify that the package is installed correctly


#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. What Is Deep Agents?

_Deep Agents_ is an _Agent Harness_ framework created by the LangChain team.
It makes it easier to build autonomous agents for complex multi-step tasks by including the following _11 core capabilities_ out of the box:

- _Task planning_ — `write_todos` breaks complex problems into a structured task list
- _Filesystem management_ — read, write, and search files (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)
- _Filesystem permissions_ — per-path ACL with `allow_read` / `allow_write` / `deny_read` etc.
- _Subagent delegation_ — distribute work via the `task` tool
- _Long-term memory + skills_ — `AGENTS.md` (`memory`) and `SKILL.md` (`skills`) with progressive disclosure
- _Context management_ — automatic offloading and summarization within the token budget
- _QuickJS interpreter_ — sandboxed JS interpreter (`use_interpreter=True`) for arbitrary computation
- _Sandbox execution_ — Modal, Daytona, Deno, and local Virtual FS backends
- _Human-in-the-loop_ — per-tool approval gates with `interrupt_on={"tool_name": True}`
- _Customization hooks_ — `before_model` / `after_model` / `wrap_model_call` middleware hooks
- _Context propagation_ — subagent-specific config via `context_schema` and namespace keys (`"agent:key"`)

It is built on top of LangChain's core agent components, and it uses _LangGraph_ as its execution engine.

#tip-box[_Model setup used in this course_: The recommended default for Deep Agents is _Anthropic Claude Sonnet 4.6_ (`anthropic:claude-sonnet-4-6`). OpenAI examples use `openai:gpt-5.4`, Google examples use `google_genai:gemini-3.5-flash`. The `provider:model` prefix form is preferred; set the matching `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GOOGLE_API_KEY`.]


=== Architecture Overview

#image("../../../../book/assets/diagrams/png/deepagents_architecture.png")


#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. SDK vs Code vs ACP

Deep Agents ships _three interfaces_ on top of the same `AgentHarness` engine:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Deep Agents SDK],
  text(weight: "bold")[Deep Agents Code],
  text(weight: "bold")[ACP server],
  [_Package_],
  [`deepagents`],
  [`deepagents-cli`],
  [`deepagents-cli` (`--acp`)],
  [_Purpose_],
  [Build agents programmatically],
  [Use a coding agent directly from the terminal],
  [Speak the Agent Client Protocol to external clients],
  [_Install_],
  [`pip install -qU deepagents langchain-{provider}`],
  [`uv tool install deepagents-cli`],
  [`uv tool install deepagents-cli`],
  [_Usage_],
  [Call `create_deep_agent()` from Python],
  [Run `deepagents` in the terminal],
  [`deepagents --acp`; clients connect over stdio],
  [_Customization_],
  [Full API access (tools, backends, middleware)],
  [`.deepagents/config.json` + slash commands],
  [Same config exposed over ACP],
  [_Best fit_],
  [App integrations, automation pipelines, custom agent services],
  [Interactive coding assistance],
  [Zed, custom IDE clients, third-party shells],
)

#tip-box[In this course we focus on the _SDK_. Deep Agents Code and the ACP server are covered later in Part 4. Choose the LangChain integration package for your provider — for example `pip install -qU deepagents langchain-anthropic` or `pip install -qU deepagents langchain-openai`.]


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Five Core Concepts (Planning · Context Management · Backends · Subagents · Memory & Skills)

=== 3.1 Planning
The agent uses the `write_todos` tool to break complex work into a _structured task list_.
Each task moves through states such as `pending` → `in_progress` → `completed`.

=== 3.2 Context Management
Deep Agents manages large amounts of information generated during a task:
- _Offloading_: content over 20,000 tokens can be written to disk while only a pointer stays in context
- _Summarization_: conversation history can be compressed as it approaches the model limit

=== 3.3 Backends
The agent filesystem is implemented with _pluggable backends_:
- `StateBackend` — store files in agent state (ephemeral, default)
- `FilesystemBackend` — local disk, with `virtual_mode=True` blocking `..` / `~` / paths outside `root_dir`
- `StoreBackend` — cross-thread persistent storage via LangGraph `BaseStore`
- `CompositeBackend` — route prefixes to different backends (for example `/memories/` → persistent)
- `ContextHubBackend` — lazy fetch + write-through remote sync (`deepagents>=0.5.2`), with `namespace=lambda rt: ...`
- Sandbox backends — _Modal_, _Daytona_, _Deno_, local _VFS_ for isolated file and code execution; the QuickJS interpreter (`use_interpreter=True`) is a complementary middleware

=== 3.4 Subagents
The main agent can delegate specialized work to _subagents_. Each subagent can be given:
- Its own system prompt
- A dedicated model
- A separate context window
- A restricted toolset

=== 3.5 Memory & Skills
Deep Agents inherits LangGraph's memory model and adds skill loading:
- _Short-term memory_ — message history within a thread
- _Long-term memory_ — `AGENTS.md` (`memory` parameter) always injected, `StoreBackend` for cross-thread state
- _Skills_ — `SKILL.md` files loaded via _progressive disclosure_ (`skills` parameter) so only frontmatter is loaded upfront, with full content fetched on demand


#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Comparison with Other Frameworks

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Capability],
  text(weight: "bold")[LangChain Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_Model support_],
  [Model-agnostic (Anthropic, OpenAI, 100+ providers)],
  [75+ providers, including Ollama],
  [Claude-only],
  [_License_],
  [MIT],
  [MIT],
  [MIT (SDK) / proprietary (Claude Code)],
  [_SDK_],
  [Python, TypeScript + CLI],
  [Terminal, desktop, IDE],
  [Python, TypeScript],
  [_Sandboxing_],
  [Integrated as a tool (Modal, Daytona, etc.)],
  [Not supported],
  [Not supported],
  [_Pluggable backends_],
  [O (State, FS, Store, Composite)],
  [X],
  [X],
  [_Time travel_],
  [O (via LangGraph)],
  [X],
  [O],
  [_Observability_],
  [Native LangSmith support],
  [X],
  [X],
  [_Built-in file tools_],
  [O],
  [O],
  [O],
  [_Human-in-the-loop_],
  [O],
  [X],
  [O],
)

Deep Agents is especially strong when you want to build agents that need _planning + files + memory + subagents_ in one integrated stack.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Installation Check

Install `deepagents` together with the LangChain integration package for your chosen provider:

#code-block(`````bash
# Recommended default — Anthropic
pip install -qU deepagents langchain-anthropic

# OpenAI
pip install -qU deepagents langchain-openai

# Google Gemini
pip install -qU deepagents langchain-google-genai

# OpenRouter (OpenAI-compatible)
pip install -qU deepagents langchain-openai  # just change base_url
`````)

Run the cells below to verify that the `deepagents` package is installed correctly.


#code-block(`````python
# Check the deepagents package version
import deepagents
print(f"deepagents version: {deepagents.__version__}")

`````)

#code-block(`````python
# Verify imports of the main modules
from deepagents import create_deep_agent, SubAgent, CompiledSubAgent
from deepagents import FilesystemMiddleware, MemoryMiddleware, SubAgentMiddleware
from deepagents.backends import StateBackend, FilesystemBackend, StoreBackend, CompositeBackend
from deepagents.backends.protocol import BackendProtocol

print("Successfully imported all main modules!")

`````)

#code-block(`````python
# Check dependency package versions
import importlib.metadata

print(f"langchain version: {importlib.metadata.version('langchain')}")
print(f"langgraph version: {importlib.metadata.version('langgraph')}")

`````)

#code-block(`````python
# Inspect the create_deep_agent function signature
import inspect

sig = inspect.signature(create_deep_agent)
print("create_deep_agent() parameters:")
for name, param in sig.parameters.items():
    default = param.default if param.default is not inspect.Parameter.empty else "(required)"
    print(f"  - {name}: {default}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [Deep Agents],
  [A LangChain-based agent harness framework],
  [Core function],
  [`create_deep_agent()`],
  [Execution engine],
  [LangGraph (`CompiledStateGraph`)],
  [Recommended model],
  [_Anthropic Claude Sonnet 4.6_ via `"anthropic:claude-sonnet-4-6"` (OpenAI: `"openai:gpt-5.4"`)],
  [Core concepts],
  [Planning, Context Management, Backends, Subagents, Memory & Skills],
  [Built-in tools],
  [`write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
)

== Next Steps
→ _#link("./02_quickstart.ipynb")[02_quickstart.ipynb]_: Build and run your first Deep Agent.

