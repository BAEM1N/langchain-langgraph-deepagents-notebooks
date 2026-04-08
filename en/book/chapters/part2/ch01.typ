// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Introduction to LangChain")

_An Overview of the LangChain v1 Framework_


== Learning Objectives

Understand the structure and core components of the LangChain framework.

By the end of this notebook, you will understand:

- The three-layer structure of the LangChain v1 framework
- How the ReAct agent pattern works
- The core components and main APIs
- How to set up and verify the development environment


== 1.1 LangChain Framework Overview

LangChain v1 is an integrated framework for building LLM-based agents. It is organized into three layers, and each layer provides a different level of abstraction.

=== Three-Layer Structure

#image("../../assets/images/langchain_3layer.png")

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Layer],
  text(weight: "bold")[Role],
  text(weight: "bold")[Target User],
  [_LangChain_],
  [Core APIs for agent creation (`create_agent`, `tool`, `ChatOpenAI`)],
  [All developers],
  [_LangGraph_],
  [Building complex workflows (state graphs, checkpointers, streaming)],
  [Intermediate and advanced developers],
  [_Deep Agents_],
  [Prebuilt agents (coding, research, and more)],
  [Fast prototyping],
)

=== Major Changes in LangChain v1

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Previous (v0.x)],
  text(weight: "bold")[Current (v1)],
  [Agent creation],
  [`create_react_agent()`],
  [`create_agent()`],
  [Agent import],
  [`from langchain.agents import ...` (various forms)],
  [`from langchain.agents import create_agent`],
  [Model initialization],
  [Direct use of `ChatOpenAI(...)`],
  [`init_chat_model()` or `ChatOpenAI(...)`],
  [Memory],
  [`ConversationBufferMemory` and similar classes],
  [`InMemorySaver` (LangGraph checkpointer)],
  [Execution engine],
  [AgentExecutor],
  [_LangGraph graph_ (internally)],
)

=== Core Design Philosophy

The central design idea in LangChain v1 is that _every agent runs as a LangGraph graph_. An agent created with `create_agent()` is implemented internally as a LangGraph `StateGraph`, which enables:

- _Streaming_: Real-time responses with the `stream()` method
- _State management_: Conversation history through a checkpointer
- _Extensibility_: Adding custom nodes and edges when needed


== 1.2 The ReAct Agent Pattern

The ReAct (Reasoning + Acting) pattern is the default operating model for LangChain v1 agents. The agent repeatedly runs the following loop:

#image("../../assets/images/react_loop.png")

=== Key Characteristics

- _Autonomous decisions_: The agent decides for itself whether it should use a tool
- _Multi-step reasoning_: The agent breaks complex tasks into multiple steps
- _Observation-based updates_: The agent observes tool results and chooses its next action


== 1.3 Overview of the Main Components

The table below summarizes the core components of LangChain v1:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Component],
  text(weight: "bold")[Description],
  text(weight: "bold")[Main APIs],
  [_Model_],
  [An LLM or chat model. Acts as the agent's “brain.”],
  [`ChatOpenAI`, `init_chat_model()`],
  [_Tools_],
  [Functions the agent can use, such as search, calculation, or API calls],
  [`\@tool` decorator, `TavilySearch`],
  [_Agent_],
  [The execution unit that combines the model and tools. Internally, it is a LangGraph graph],
  [`create_agent()`],
  [_Memory_],
  [A checkpointer that stores and manages conversation history],
  [`InMemorySaver`, `SqliteSaver`],
  [_Middleware_],
  [Logic inserted into the request/response processing pipeline],
  [`prompt`, `before_tool`, `after_model`],
  [_State_],
  [The state managed while the agent runs, such as messages and context],
  [`AgentState`, `messages`],
  [_Streaming_],
  [Support for real-time response streaming],
  [`stream()`, `stream_mode="updates"`],
)


== 1.4 Environment Setup and Installation Check

Check the packages and API keys required for LangChain v1 development.


#code-block(`````python
# Environment check
import importlib

packages = {
    "langchain": "langchain",
    "langchain_openai": "langchain-openai",
    "langchain_community": "langchain-community",
    "langgraph": "langgraph",
}

print("=" * 50)
print("LangChain v1 environment check")
print("=" * 50)

for module_name, package_name in packages.items():
    try:
        mod = importlib.import_module(module_name)
        version = getattr(mod, "__version__", "installed")
        print(f"✓ {package_name}: {version}")
    except ImportError:
        print(f"✗ {package_name}: not installed → pip install {package_name}")

`````)

#code-block(`````python
# API key check
from dotenv import load_dotenv
import os

load_dotenv(override=True)

required_keys = ["OPENAI_API_KEY"]
optional_keys = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]

print("Required API keys:")
for key in required_keys:
    status = "✓ configured" if os.environ.get(key) else "✗ missing"
    print(f"  {key}: {status}")

print("\nOptional API keys:")
for key in optional_keys:
    status = "✓ configured" if os.environ.get(key) else "- not configured (optional)"
    print(f"  {key}: {status}")

`````)

#code-block(`````python
# Verify the core LangChain v1 imports
from langchain.agents import create_agent
from langchain.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.checkpoint.memory import InMemorySaver

print("✓ Successfully imported all core modules")
print("  - create_agent: create a LangChain v1 agent")
print("  - tool: tool decorator")
print("  - ChatOpenAI: OpenAI-compatible chat model")
print("  - InMemorySaver: memory checkpointer")

`````)

== 1.5 Next Steps

In this notebook, you explored the overall structure and core components of the LangChain v1 framework.

In the next notebook (`02_quickstart.ipynb`), you will create and run an actual agent:

- Define a custom tool with the `@tool` decorator
- Create an agent with `create_agent()`
- Run the agent with `invoke()` and `stream()`
- Build a multi-turn conversation with `InMemorySaver`


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [LangChain v1],
  [An agent-centered framework built around the `create_agent()` API],
  [Three-layer structure],
  [LangChain → LangGraph → Deep Agents],
  [ReAct pattern],
  [Repeated loop of reasoning → action → observation],
  [Core APIs],
  [`create_agent()`, `\@tool`, `invoke()`, `stream()`],
)

=== Next Steps
→ _#link("./02_quickstart.ipynb")[02_quickstart.ipynb]_: Build your first LangChain agent.

