// Auto-generated from 05_deep_agents_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Deep Agents Basics", subtitle: "An All-in-One Agent")

Use the Deep Agents SDK's `create_deep_agent()` to build an agent with built-in tools, memory, and backend support in one line.


== Learning Objectives

- Create an agent with `create_deep_agent()`
- Run the agent with `invoke()`
- Build an agent with an additional custom tool


== 5.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("✓ Model ready")

`````)

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: pass config={"callbacks": [langfuse_handler]} to invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 5.2 Creating an Agent

`create_deep_agent()` takes a LangChain model and returns an agent that already includes _built-in tools_ such as file reading, file writing, and search.
The return value is a LangGraph `CompiledStateGraph`, so you can call methods such as `invoke()` and `stream()` directly.

_What is Deep Agents?_

Deep Agents is a framework designed to simplify agent development. It works like an _agent harness_: internally it is built on top of LangChain agent components and uses LangGraph to manage execution.

_Core built-in capabilities:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Capability],
  text(weight: "bold")[Description],
  [_Task planning_],
  [Uses the `write_todos` tool to break down complex tasks into manageable steps],
  [_Context management_],
  [Uses file system tools such as `write_file` and `read_file` to handle larger amounts of information without overflowing the token budget],
  [_Flexible storage_],
  [Supports pluggable backends such as in-memory storage, local disk, persistent stores, and sandbox environments],
  [_Subagent delegation_],
  [Can create specialized subagents for focused sub-tasks and isolate their context],
  [_Persistent memory_],
  [Reuses LangGraph's memory infrastructure to preserve information across conversations],
)

_How agent creation works:_

Pass a model, optional tools, and an optional system prompt into `create_deep_agent()`. You need a model that supports tool calling, and you can use providers such as OpenAI or Anthropic.


#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(model=model)
print(f"✓ Agent created (type: {type(agent).__name__})")

`````)

#code-block(`````python
result = agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "Hello! What tools can you use? Please give me a short list."
            }
        ]
    },
    config=lf_config,
)

print(result["messages"][-1].content)

`````)

== 5.3 Adding a Custom Tool

If you write a Python function with a _docstring_ and _type hints_, it becomes a tool directly.

_How custom tools work:_

A custom tool is just a normal Python function, and Deep Agents automatically converts two parts of that function:

- _Docstring_ → tool description (used by the agent to understand what the tool does)
- _Type hints_ → parameter schema (used by the agent to pass the correct arguments)

If you pass a list of functions to the `tools` parameter of `create_deep_agent()`, those functions are added to the tool list alongside the built-in capabilities such as file operations and todo planning. You can also guide the agent's behavior with the `system_prompt` parameter.


#code-block(`````python
def greet(name: str) -> str:
    """Greet a person by name."""
    return f"Hello, {name}! Welcome to Deep Agents."

custom_agent = create_deep_agent(
    model=model,
    tools=[greet],
    system_prompt="You are a friendly assistant. If someone introduces themselves, use the greet tool.",
)

result = custom_agent.invoke(
    {"messages": [{"role": "user", "content": "My name is Alice."}]},
    config=lf_config,
)
print(result["messages"][-1].content)

`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Core API],
  text(weight: "bold")[Role],
  [`create_deep_agent(model)`],
  [Creates an agent with built-in tools],
  [`create_deep_agent(model, tools, system_prompt)`],
  [Adds custom tools and a system prompt],
  [`agent.invoke()`],
  [Runs the agent],
)

=== Next Steps
→ _#link("./06_comparison.ipynb")[06_comparison.ipynb]_: Compare the three frameworks and choose your next learning track.
