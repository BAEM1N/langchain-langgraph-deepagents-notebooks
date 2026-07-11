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
It makes it easier to build autonomous agents for complex multi-step tasks by including the following capabilities out of the box:

- _Task planning_ — break complex problems into manageable steps
- _Filesystem management_ — read, write, and search files in virtual or local environments
- _Subagent delegation_ — distribute work to specialized agents
- _Long-term memory_ — retain knowledge across conversations
- _Context management_ — manage information efficiently within the model's token budget

It is built on top of LangChain's core agent components, and it uses _LangGraph_ as its execution engine.

#tip-box[_Model setup used in this course_: These materials use the _OpenAI gpt-5.4_ model. Set the `OPENAI_API_KEY` environment variable and use `ChatOpenAI(model="gpt-5.4")`.]


=== Architecture Overview

#image("../../assets/images/deepagents_architecture.png")


#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. SDK vs CLI

Deep Agents is available in two forms:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Deep Agents SDK],
  text(weight: "bold")[Deep Agents CLI],
  [_Package_],
  [`deepagents`],
  [`deepagents-cli`],
  [_Purpose_],
  [Build agents programmatically],
  [Use a coding agent directly from the terminal],
  [_Install_],
  [`pip install deepagents`],
  [`uv tool install deepagents-cli`],
  [_Usage_],
  [Call `create_deep_agent()` from Python],
  [Run `deepagents-cli` in the terminal],
  [_Customization_],
  [Full API access (tools, backends, middleware)],
  [Config files + slash commands],
  [_Best fit_],
  [App integrations and automation pipelines],
  [Interactive coding assistance],
)

#tip-box[In this course, we focus primarily on the _SDK_.]


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Five Core Concepts

=== 3.1 Planning
The agent uses the `write_todos` tool to break complex work into a _structured task list_.
Each task moves through states such as `pending` → `in_progress` → `completed`.

=== 3.2 Context Management
Deep Agents manages large amounts of information generated during a task:
- _Offloading_: content over 20,000 tokens can be written to disk while only a pointer stays in context
- _Summarization_: conversation history can be compressed as it approaches the model limit

=== 3.3 Backends
The agent filesystem is implemented with _pluggable backends_:
- `StateBackend` — store files in the agent state (ephemeral)
- `FilesystemBackend` — access the local disk
- `StoreBackend` — cross-thread persistent storage
- `CompositeBackend` — route paths to different backends

=== 3.4 Subagents
The main agent can delegate specialized work to _subagents_. Each subagent can be given:
- Its own system prompt
- A dedicated model
- A separate context window
- A restricted toolset

=== 3.5 Memory
Deep Agents inherits LangGraph's memory model and supports both:
- _Short-term memory_ — message history within a thread
- _Long-term memory_ — reusable information across threads


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
  [Model used here],
  [_OpenAI gpt-5.4_ via `ChatOpenAI(model="gpt-5.4")`],
  [Core concepts],
  [Planning, Context Management, Backends, Subagents, Memory],
  [Built-in tools],
  [`write_todos`, `ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
)

== Next Steps
→ _#link("./02_quickstart.ipynb")[02_quickstart.ipynb]_: Build and run your first Deep Agent.
