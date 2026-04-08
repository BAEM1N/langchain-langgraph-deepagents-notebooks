// Auto-generated from 01_introduction.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "Introduction to LangGraph", subtitle: "state based agent orchestration framework")

== Learning Objectives

Understand the core concepts of LangGraph and two APIs (Graph API, Functional API).

== 1.1 What is LangGraph?

LangGraph is a _low-level orchestration framework_ for the LangChain ecosystem.

=== LangChain 3-tier structure

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[tier],
  text(weight: "bold")[Role],
  text(weight: "bold")[Description],
  [Deep Agents],
  [high standard],
  [Pre-built agent system],
  [LangChain],
  [agent],
  [Building LLM agent tool],
  [_LangGraph_],
  [_workflow_],
  [_state-based orchestration_],
)

=== Key Features

- _state Management_: TypedDict-based state definition and reducer
- _Persistence_: Auto-save state via checkpointer
- _streaming_: Real-time token unit output
- _Human-in-the-loop_: interrupt/resume for human intervention
- _durable execution_: Automatic recovery in case of failure

== 1.2 Core concepts

LangGraph defines workflow based on _graph structure_.

=== Component

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [_Node_],
  [Processing unit — defined as a Python function],
  [_Edge_],
  [Connection between nodes, conditional branching possible],
  [_state(State)_],
  [Defined as TypedDict, shared data between nodes],
  [_checkpointer(Checkpointer)_],
  [Auto-save each step state],
)

=== Graph structure diagram

#image("../../assets/images/stategraph_structure.png")

== 1.3 Two APIs

LangGraph provides an API that allows the same functionality to be implemented in two different styles.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[Graph API],
  text(weight: "bold")[Functional API],
  [approach],
  [declarative (node+edge)],
  [imperative (Python control flow)],
  [state Management],
  [Explicit State + Reducer],
  [No need for function scope or reducer],
  [Visualization],
  [Graph visualization support],
  [Not supported],
  [checkpointing],
  [New checkpoint every superstep],
  [By `\@task`, save to existing checkpoint],
  [suitable situation],
  [Complex workflow, Team Development],
  [Migrate existing code, simple flow],
)

== 1.4 Environment Setup and check installation

Verify that the required packages are installed correctly.

#code-block(`````python
import importlib

packages = {
    "langgraph": "langgraph",
    "langchain": "langchain",
    "langchain_openai": "langchain-openai",
}

print("=" * 50)
print("LangGraph Check environment")
print("=" * 50)

for module_name, package_name in packages.items():
    try:
        mod = importlib.import_module(module_name)
        version = getattr(mod, "__version__", "installed")
        print(f"  OK  {package_name}: {version}")
    except ImportError:
        print(f"  ERR {package_name}: not installed")
`````)

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

required = ["OPENAI_API_KEY"]
optional = ["TAVILY_API_KEY", "LANGSMITH_API_KEY"]

print("API key state:")
for key in required:
    print(f"  {'OK' if os.environ.get(key) else 'MISSING'} {key} (required)")
for key in optional:
    print(f"  {'OK' if os.environ.get(key) else '--'} {key} (optional)")
`````)

#code-block(`````python
# Core import verification
from langgraph.graph import StateGraph, START, END
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.types import Command, interrupt
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, AIMessage
from langchain_openai import ChatOpenAI

print("All core imports completed")
`````)

== 1.5 A taste of the Graph API

The Graph API defines workflow in a _declarative_ manner.

+ Create a graph builder with `StateGraph(State)` — `state_schema`
+ `add_node()` — Node (function) registration
+ `add_edge()` — Connections between nodes
+ `compile()` — Create an executable graph
+ `invoke()` — Graph execution

== 1.6 A taste of the Functional API

The Functional API defines workflow in an _imperative_ manner.

- `@task` — Unit operation definition (checkpointing unit)
- `@entrypoint` — workflow Entry point definition
- Use regular Python control flow (`if`, `for`, `while`, etc.)

== 1.7 Next Steps

In the next Note book, we will learn Graph API in earnest.

- _02_graph_api.ipynb_ — StateGraph, node, edge, conditional branch, state reducer

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [LangGraph],
  [state Based on agent Orchestration Framework],
  [Graph API],
  [Explicit state flow definition with `StateGraph`],
  [Functional API],
  [`\@entrypoint` + `\@task` Functional workflow],
  [Key concepts],
  [State (state), Node, Edge],
  [checkpointer],
  [state Persistence, multi-turn dialogue, time travel support],
)

=== Next Steps
→ _#link("./02_graph_api.ipynb")[02_graph_api.ipynb]_: Learn the core concepts of Graph API.
