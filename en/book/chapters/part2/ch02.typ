// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Your First Agent")

*Getting Started with `create_agent()`*


== Learning Objectives

Create and run an agent with LangChain v1's `create_agent()`.

By the end of this notebook, you will be able to:

- Define custom tools with the `@tool` decorator
- Create an agent with `create_agent()`
- Run the agent with `invoke()` and inspect the result
- Receive real-time streaming responses with `stream()`
- Build a multi-turn conversation with `InMemorySaver`


== 2.1 Environment Setup

Set up the model through OpenAI. `ChatOpenAI` supports OpenAI-compatible APIs, so you can also switch providers by changing `base_url` when needed.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)
print("✓ Model configured:", model.model_name)

`````)

== 2.2 Building a Simple Tool

Define the tools that the agent can use with the `@tool` decorator.

Important details when defining a tool:
- A _docstring_ is required. The agent uses it to understand what the tool is for.
- _Type hints_ help the agent pass the correct arguments.
- The tool name is generated automatically from the function name.


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

== 2.3 Creating an Agent

Combine the model and tools with `create_agent()`.

The created agent is internally implemented as a LangGraph graph, so it provides methods such as `invoke()` and `stream()`.

#tip-box[In LangChain v1, use `create_agent()` instead of `create_react_agent()`.]


#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="You are a math assistant. Use the available tools for calculations.",
)
print("✓ Agent created")
print(f"  Type: {type(agent).__name__}")

`````)

== 2.4 Running the Agent

Run the agent with `invoke()`.

When you send messages to the agent, it runs an internal ReAct loop:
+ The model analyzes the question and decides whether to call a tool
+ The tool runs and returns a result
+ The model uses the result to generate the final response


#code-block(`````python
# Inspect the full message flow
print("Full message flow:")
print("=" * 50)
for msg in result["messages"]:
    role = msg.type if hasattr(msg, 'type') else msg.get('role', 'unknown')
    content = msg.content if hasattr(msg, 'content') else msg.get('content', '')
    print(f"[{role}] {content[:200]}")
    print("-" * 50)

`````)

== 2.5 Streaming Execution

Receive a real-time response with `stream()`.

With streaming, you can inspect each stage of the agent in real time, including model reasoning, tool calls, and the final answer. If you use `stream_mode="updates"`, you receive node updates one by one.


== 2.6 Multi-Turn Conversation

Keep conversation state with `InMemorySaver`.

`InMemorySaver` stores state in memory and separates conversation sessions with `thread_id`.

#tip-box[In LangChain v1, conversation history is managed through LangGraph checkpointers.]


== 2.7 Adding the Tavily Search Tool (Optional)

Add a web search tool so the agent can look up real information.

Tavily is a search API designed for AI agents.

This cell only runs if `TAVILY_API_KEY` is configured.


== 2.8 Summary

Here is a recap of what you covered in this notebook:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Core API],
  text(weight: "bold")[Description],
  [Tool definition],
  [`\@tool`],
  [Turn a function into an agent tool with a decorator],
  [Agent creation],
  [`create_agent()`],
  [Combine a model, tools, and a system prompt],
  [Synchronous execution],
  [`agent.invoke()`],
  [Return the full response at once],
  [Streaming execution],
  [`agent.stream()`],
  [Return real-time updates for each step],
  [Multi-turn conversation],
  [`InMemorySaver` + `thread_id`],
  [Store and restore conversation state with a checkpointer],
  [Search tool],
  [`TavilySearch`],
  [Access real-time information through web search],
)

=== Next Steps

In the next notebook, you will explore more advanced agent patterns:
- Designing custom system prompts
- Combining multiple tools in a single agent
- Error handling and fallback strategies

