// Auto-generated from 09_comparison.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Comparing External Frameworks")

== Learning Objectives
- Understand the deeper differences between Deep Agents, LangGraph, and LangChain
- Compare them with OpenCode and the Claude Agent SDK
- Analyze differences in architecture, flexibility, and ecosystem
- Learn which framework to recommend for different use cases
- Understand migration considerations


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
== 1. Comparison Overview

When choosing an AI agent framework, you need to consider several factors, including _model support_, _architecture_, _ecosystem_, and _license_.

In this notebook, you compare three major options:

- _LangChain Deep Agents_ — a model-agnostic agent harness
- _OpenCode_ — a coding agent environment centered on the terminal / desktop / IDE
- _Claude Agent SDK_ — Anthropic's SDK for Claude-based agents


#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Deep Agents vs OpenCode vs Claude Agent SDK

=== Basic Comparison

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Feature],
  text(weight: "bold")[LangChain Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_Model support_],
  [Model-agnostic (Anthropic, OpenAI, 100+ providers)],
  [75+ providers, including local models through Ollama],
  [Claude-only],
  [_License_],
  [MIT],
  [MIT],
  [MIT (SDK), proprietary (Claude Code)],
  [_SDK_],
  [Python, TypeScript + CLI],
  [Terminal, desktop, IDE integration],
  [Python, TypeScript],
  [_Sandboxing_],
  [Can be integrated as a tool],
  [Not supported],
  [Not supported],
  [_State management_],
  [Supports time travel],
  [Not supported],
  [Supports time travel],
  [_Observability_],
  [Native LangSmith support],
  [None],
  [None],
)


#code-block(`````python
# Print a framework comparison table
frameworks = {
    "LangChain Deep Agents": {
        "model_support": "100+ providers (model-agnostic)",
        "license": "MIT",
        "sdk": "Python, TypeScript, CLI",
        "sandbox": "Integrated support",
        "time_travel": "Supported",
    },
    "OpenCode": {
        "model_support": "75+ providers (including local models)",
        "license": "MIT",
        "sdk": "Terminal, desktop, IDE",
        "sandbox": "Not supported",
        "time_travel": "Not supported",
    },
    "Claude Agent SDK": {
        "model_support": "Claude only",
        "license": "MIT (SDK)",
        "sdk": "Python, TypeScript",
        "sandbox": "Not supported",
        "time_travel": "Supported",
    },
}

print("=== Framework Comparison ===")
for name, features in frameworks.items():
    print(f"\n[{name}]")
    for key, value in features.items():
        print(f"  {key}: {value}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Comparing Core Capabilities

=== Shared Capabilities
All three frameworks support the following categories:
- file operations (read, write, edit)
- shell command execution
- search features (`grep`, `glob`)
- planning support (task lists)
- Human-in-the-Loop (with different permission models)

=== Differentiating Capabilities

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Capability],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_Core tools_],
  [Files, shell, search, planning],
  [Files, shell, search, planning],
  [Files, shell, search, planning],
  [_Sandbox integration_],
  [Can be integrated as a tool],
  [No],
  [No],
  [_Pluggable backends_],
  [Storage + filesystem backends],
  [No],
  [No],
  [_Virtual filesystem_],
  [Yes, through pluggable backends],
  [No],
  [No],
  [_Native tracing_],
  [LangSmith],
  [No],
  [No],
)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3-1. Three Core Differentiators

Look past the table cells and Deep Agents diverges from the other two along _three axes_. These are design decisions, not feature checks — figure out which axis matters most for your project and the choice gets easier.

=== Execution Model — graph-based state machine vs single-pass ReAct loop

Deep Agents runs on LangGraph's `StateGraph`. It is assembled from nodes, edges, and subgraphs, with branching, looping, interrupts, and resumes all expressed in the graph itself. _Time travel_ (branching from a past checkpoint), _interrupt/resume_ (the standard HITL path), and _subgraph-scoped streaming_ fall out of that design. OpenCode and Claude Agent SDK are ReAct-loop centric, so state branching and subgraph isolation cost extra integration work.

=== Deployment & Multi-Tenancy — LangSmith Deployments integration

Deep Agents deploys directly to _LangSmith Deployments_ with built-in multi-tenancy via `assistant_id` / `thread_id` / `user_id`. Cron schedules (e.g. consolidation agents), the Store (persistent memory), and the Checkpointer are provisioned automatically at deploy time. OpenCode is a local terminal tool; Claude Agent SDK is closer to a model-calling SDK — both require you to build the surrounding infrastructure yourself.

=== Per-Model Configuration — `HarnessProfile` / `ProviderProfile`

Deep Agents 0.5+ packages provider/model defaults as _profiles_. The same codebase can switch between `openai:gpt-5.4` and `anthropic:claude-sonnet-4-6` without touching call sites. Claude Agent SDK is Claude-only with no model abstraction layer, and OpenCode supports 75+ providers but lacks a _profile_ concept that captures the differences between them.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Architecture Comparison

=== LangChain Deep Agents
- _Pluggable storage backends_ — state, filesystem, and store layers can be configured independently
- _Virtual filesystem_ — can switch between local, in-memory, or sandboxed backends
- _LangGraph-based runtime_ — supports complex workflows through graph execution
- _Middleware system_ — fine-grained control over agent behavior

=== OpenCode
- _Terminal-native_ — lightweight and fast to start
- _75+ model providers_ — includes local models through Ollama
- _LSP integration_ — optimized for code editing workflows

=== Claude Agent SDK
- _Claude-optimized_ — tailored for Claude model capabilities
- _Time travel_ — supports branching and state exploration
- _Concise API_ — useful for fast prototyping


#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Recommendations by Use Case

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Use Case],
  text(weight: "bold")[Recommended Framework],
  text(weight: "bold")[Why],
  [Production agent app],
  [_Deep Agents_],
  [Pluggable backends, observability, sandbox support],
  [Multi-model agent],
  [_Deep Agents_],
  [100+ provider support],
  [Terminal coding assistant],
  [_OpenCode_],
  [Lightweight startup, strong local-model story],
  [Claude-only app],
  [_Claude Agent SDK_],
  [Optimized for Claude, simple API],
  [Rapid prototyping],
  [_Claude Agent SDK_],
  [Minimal API, fast setup],
  [Complex multi-agent system],
  [_Deep Agents_],
  [Subagents and strong context management],
  [Local model usage],
  [_OpenCode_],
  [Native Ollama support],
)


#code-block(`````python
# Helper to recommend a framework by use case
def recommend_framework(use_case: str) -> str:
    """Recommend a framework for a given use case."""
    recommendations = {
        "production": ("Deep Agents", "pluggable backends, observability, sandbox support"),
        "multi-model": ("Deep Agents", "100+ provider support"),
        "terminal": ("OpenCode", "fast startup and strong support for local models"),
        "claude-only": ("Claude Agent SDK", "Claude optimization and a concise API"),
        "prototyping": ("Claude Agent SDK", "simple API and fast setup"),
        "multi-agent": ("Deep Agents", "subagents and context management"),
        "local-model": ("OpenCode", "native Ollama support"),
    }
    if use_case in recommendations:
        fw, reason = recommendations[use_case]
        return f"{fw} — {reason}"
    return "No recommendation found for that use case."

# Demo
for case in ["production", "terminal", "claude-only", "multi-agent"]:
    print(f"{case}: {recommend_framework(case)}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. Ecosystem Comparison

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Deep Agents],
  text(weight: "bold")[OpenCode],
  text(weight: "bold")[Claude Agent SDK],
  [_Community_],
  [LangChain ecosystem (large)],
  [GitHub community],
  [Anthropic community],
  [_Documentation_],
  [Official docs + LangSmith integration],
  [GitHub README],
  [Anthropic official docs],
  [_Integrations_],
  [LangChain, LangGraph, LangSmith],
  [LSP, terminal tooling],
  [Claude API],
  [_Package management_],
  [pip / uv],
  [go install / brew],
  [pip / npm],
  [_Editor integration_],
  [ACP (Zed, JetBrains, VS Code, Neovim)],
  [Own editor workflows],
  [None],
)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Migration Considerations

Important questions when migrating between frameworks:

=== Shared Considerations
+ _Model compatibility_ — verify that the target framework supports the models you use
+ _Tool compatibility_ — check how your custom tool interfaces need to be adapted
+ _State management_ — plan how checkpoints and memory should be migrated
+ _Observability_ — decide how tracing and logging should be replaced or preserved

=== Advantages of Migrating to Deep Agents
- _LangChain tool reuse_ — existing LangChain tools can often be reused directly
- _LangGraph compatibility_ — integrates well with LangGraph-based workflows
- _Incremental migration_ — supports gradual adoption rather than all-at-once rewrites

=== Caveats
- Claude Agent SDK features that are Claude-specific may need alternative implementations
- Terminal UI logic from OpenCode may need to be separated from the core agent logic


#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Core Idea],
  text(weight: "bold")[Key API / Tool],
  [Three-way comparison],
  [Deep Agents, OpenCode, Claude Agent SDK],
  [model support, license, SDK],
  [Core capabilities],
  [Shared tools + differentiators],
  [sandboxing, pluggable backends],
  [Architecture],
  [Pluggable vs terminal-native vs model-optimized],
  [LangGraph, LSP, Claude API],
  [Use-case guidance],
  [Production, terminal, prototyping, etc.],
  [`recommend_framework()`],
  [Ecosystem],
  [Community, docs, integrations, editor support],
  [LangSmith, ACP],
  [Migration],
  [Model / tool / state compatibility],
  [gradual adoption],
)

=== Next Steps
→ _#link("./10_sandboxes_and_acp.ipynb")[10_sandboxes_and_acp.ipynb]_


#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/deepagents/04-comparison.md")[Comparison with OpenCode and Claude Agent SDK]

