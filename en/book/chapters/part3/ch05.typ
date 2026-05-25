// Auto-generated from 05_agents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Building agent", subtitle: "Creating ReAct agent with Graph API and Functional API")

== Learning Objectives

We implement LLM agent using tool with two APIs.

- _Graph API_: Explicitly configure ReAct loop with `StateGraph` and conditional edges
- _Functional API_: Simple implementation with `@entrypoint` + `while` loop.
- _tool Binding_: Bind tool to LLM with `@tool` decorator and `bind_tools()`.
- _Memory_: agent holding conversation state with checkpointer

== 5.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 5.2 tool Definitions — \@tool decorator and bind_tools()

The `@tool` decorator on LangChain allows you to convert a regular Python function into tool, which can be called by LLM.
`bind_tools()` binds the schema of these tools to the model, allowing LLM to select tool and generate arguments at the appropriate time.

#code-block(`````python
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, ToolMessage, AnyMessage

@tool
def add(a: int, b: int) -> int:
    """Add two numbers together."""
    return a + b

@tool
def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b

@tool
def divide(a: int, b: int) -> float:
    """Divide a by b."""
    return a / b

tools = [add, multiply, divide]
tools_by_name = {t.name: t for t in tools}
model_with_tools = model.bind_tools(tools)

print("tool bound to model:")
for t in tools:
    print(f"  - {t.name}: {t.description}")
`````)

== 5.3 Graph API agent — Implementing ReAct Loop with StateGraph

The ReAct (Reasoning + Acting) pattern consists of three elements:

- _LLM node_: Determines whether tool calling based on current message
- _Tool node_: actually executes the tool selected by LLM
- _Conditional Edge_: If `tool_calls` exists, route to `tool_node`, otherwise route to `END`
START → llm → [tool_calls?] → tools → llm → ... → END
#code-block(`````python

`````)

== 5.4 Visualizing execution flow — Observe each step with streaming

`stream_mode="updates"` allows each node to receive updates as it runs.
This allows you to observe step by step in what order agent calls tool and processes the results.

== 5.5 Functional API agent — \@entrypoint + while loop

The Functional API allows you to write agent like regular Python code, without explicitly constructing a graph.

- `@entrypoint`: Defines the entry point of agent
- `@task`: Defines individual work units
- `while` loop: repeats until there is no tool calling

== 5.6 agent with memory — Keep conversation with checkpointer

If you pass checkpointer(`InMemorySaver`) to `compile()`, agent will be able to remember previous conversations.
If you use the same `thread_id`, the previous conversation context is automatically maintained.

== 5.7 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [`\@tool`],
  [Convert Python function to LLM callable tool],
  [`bind_tools()`],
  [tool Binding schema to model],
  [_Graph API agent_],
  [`StateGraph` + Explicit implementation of ReAct loop with conditional edges],
  [_Functional API agent_],
  [Simple implementation with `\@entrypoint` + `while` loop],
  [`tool_calls`],
  [tool calling Information included in LLM response],
  [`ToolMessage`],
  [tool Message delivering execution results to LLM],
  [_checkpointer_],
  [Implement multiturn agent by saving conversation state],
)

=== Next Steps
→ _#link("./06_persistence_and_memory.ipynb")[06_persistence_and_memory.ipynb]_: Learn persistence and memory.
