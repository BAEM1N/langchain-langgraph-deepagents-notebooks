// Auto-generated from 02_langchain_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "LangChain Basics", subtitle: "Your First Agent")

Build a tool-enabled agent with the core APIs of LangChain v1.


== Learning Objectives

- Define custom tools with the `@tool` decorator
- Create an agent with `create_agent()`
- Run the agent with `invoke()` and inspect the result


== 2.1 Environment Setup


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

== 2.2 Building Tools

When you add the `@tool` decorator, a regular Python function becomes an agent tool.

Important rules to remember when defining tools:
- _Type hints_: The function parameter type hints automatically define the tool's input schema. For example, `a: int` tells the model that the argument should be an integer.
- _Docstring_: The function docstring becomes the tool description. The model uses this description to decide which tool to use, so it should be clear and concise.
- _Custom name/description_: You can also set the tool name and description explicitly with `@tool("custom_name", description="...")`.
- _Complex inputs_: You can define richer input schemas with Pydantic `BaseModel` and `Field`.


#code-block(`````python
from langchain.tools import tool

@tool
def add(a: int, b: int) -> int:
    """Add two numbers."""
    return a + b

@tool
def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b

print("Tool list:")
for t in [add, multiply]:
    print(f"  - {t.name}: {t.description}")

`````)

== 2.3 Creating and Running an Agent

`create_agent()` combines a model and tools to build an agent.
The agent internally runs a _ReAct (Reasoning + Acting) loop_:

#code-block(`````python
Question → Model decides to call a tool → Tool runs → Result is observed → Repeat or produce a final answer
`````)

Core components of the agent:
- _Model_: The LLM decides which tool to call. You can pass a string such as `"openai:gpt-5"` or a model object.
- _Tools_: These are the actions the agent can take. Compared with simple tool binding, an agent can call tools in sequence, run them in parallel, and retry them.
- _System Prompt_: Instructions that guide the agent's behavior.

An agent can call tools more than once, or even use multiple tools in parallel. The loop ends when the model produces a final answer or reaches the recursion limit.


#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="You are a math assistant.",
)
print("✓ Agent created")

`````)

#code-block(`````python
result = agent.invoke(
    {"messages": [{"role": "user", "content": "What is 15 + 27?"}]},
    config=lf_config,
)
print("Agent response:", result["messages"][-1].content)

`````)

#code-block(`````python
# A compound question that requires the agent to use tools twice
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Multiply 6 and 7, then add 10."}]},
    config=lf_config,
)
print("Agent response:", result["messages"][-1].content)

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
  [`\@tool`],
  [Converts a function into an agent tool],
  [`create_agent()`],
  [Combines a model and tools to create an agent],
  [`agent.invoke()`],
  [Runs the agent and returns the result],
)

=== Next Steps
→ _#link("./03_langchain_memory.ipynb")[03_langchain_memory.ipynb]_: Learn about multi-turn conversations and memory.
