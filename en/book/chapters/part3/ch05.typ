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

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Set the key in .env, or uncomment it below and enter it yourself.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: Automatically activated when LANGSMITH_TRACING=true (no code modification required)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON \u2014 project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

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

#code-block(`````python
START → llm → [tool_calls?] → tools → llm → ... → END
`````)

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict, Annotated, Literal
import operator

class AgentState(TypedDict):
    messages: Annotated[list[AnyMessage], operator.add]

SYSTEM_PROMPT = "You are a useful math assistant. Calculate using tool provided."

def llm_node(state: AgentState) -> dict:
    response = model_with_tools.invoke(
        [SystemMessage(content=SYSTEM_PROMPT)] + state["messages"],
        config=lf_config,
)
    return {"messages": [response]}

def tool_node(state: AgentState) -> dict:
    results = []
    for tc in state["messages"][-1].tool_calls:
        tool_fn = tools_by_name[tc["name"]]
        result = tool_fn.invoke(tc["args"], config=lf_config)
        results.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))
    return {"messages": results}

def should_continue(state: AgentState) -> Literal["tools", "__end__"]:
    last = state["messages"][-1]
    return "tools" if last.tool_calls else END

builder = StateGraph(AgentState)
builder.add_node("llm", llm_node)
builder.add_node("tools", tool_node)
builder.add_edge(START, "llm")
builder.add_conditional_edges("llm", should_continue, ["tools", END])
builder.add_edge("tools", "llm")

agent = builder.compile()

result = agent.invoke({"messages": [HumanMessage(content="How much is (7 * 8) + 12?")]}, config=lf_config)
print("agent Answer:", result["messages"][-1].content)
`````)

== 5.4 Visualizing execution flow — Observe each step with streaming

`stream_mode="updates"` allows each node to receive updates as it runs.
This allows you to observe step by step in what order agent calls tool and processes the results.

#code-block(`````python
print("agent Execution flow:")
print("=" * 60)
for chunk in agent.stream(
    {"messages": [HumanMessage(content="Calculate 100 / 4 and then multiply by 3 to get what?")]},
    stream_mode="updates",
    config=lf_config,
):
    for node_name, update in chunk.items():
        print(f"\n[{node_name}]")
        for msg in update.get("messages", []):
            if hasattr(msg, 'tool_calls') and msg.tool_calls:
                for tc in msg.tool_calls:
                    print(f"  Tool calls: {tc['name']}({tc['args']})")
            elif hasattr(msg, 'content') and msg.content:
                print(f"  {msg.content[:200]}")
`````)

== 5.5 Functional API agent — \@entrypoint + while loop

The Functional API allows you to write agent like regular Python code, without explicitly constructing a graph.

- `@entrypoint`: Defines the entry point of agent
- `@task`: Defines individual work units
- `while` loop: repeats until there is no tool calling

#code-block(`````python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import add_messages

@task
def call_model(messages: list) -> object:
    return model_with_tools.invoke(
        [SystemMessage(content=SYSTEM_PROMPT)] + messages,
        config=lf_config,
)

@task
def execute_tool(tool_call: dict) -> ToolMessage:
    tool_fn = tools_by_name[tool_call["name"]]
    result = tool_fn.invoke(tool_call["args"], config=lf_config)
    return ToolMessage(content=str(result), tool_call_id=tool_call["id"])

@entrypoint(checkpointer=InMemorySaver())
def functional_agent(messages: list) -> list:
    response = call_model(messages).result()

    while response.tool_calls:
        tool_results = [execute_tool(tc).result() for tc in response.tool_calls]
        messages = add_messages(messages, [response] + tool_results)
        response = call_model(messages).result()

    return add_messages(messages, response)

config = {"configurable": {"thread_id": "func-agent-1"}}
result = functional_agent.invoke(
    [HumanMessage(content="Calculate 15 * 4 and then add 20 to get what?")],
    {**config, **lf_config}
)
print("Functional agent Answer:", result[-1].content)
`````)

== 5.6 agent with memory — Keep conversation with checkpointer

If you pass checkpointer(`InMemorySaver`) to `compile()`, agent will be able to remember previous conversations.
If you use the same `thread_id`, the previous conversation context is automatically maintained.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

agent_with_memory = builder.compile(checkpointer=InMemorySaver())

config = {"configurable": {"thread_id": "math-session"}}

r1 = agent_with_memory.invoke(
    {"messages": [HumanMessage(content="How much is 6 * 7?")]},
    {**config, **lf_config}
)
print("Turn 1:", r1["messages"][-1].content)

r2 = agent_with_memory.invoke(
    {"messages": [HumanMessage(content="Now divide the result by 2.")]},
    {**config, **lf_config}
)
print("Turn 2:", r2["messages"][-1].content)
`````)

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
