// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Your First Agent")

_Getting Started with `create_agent()`_


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
    model="gpt-5.4",
)
print("✓ Model configured:", model.model_name)

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
result = agent.invoke(
    {"messages": [{"role": "user", "content": "What is 15 + 27?"}]},
    config=lf_config,
)

# Print the final response
print("Agent response:")
print(result["messages"][-1].content)

`````)

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


#code-block(`````python
print("Streaming execution:")
print("=" * 50)

for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Calculate 12 * 8, then add 5 to the result."}]},
    stream_mode="updates",
    config=lf_config,
):
    for node_name, update in chunk.items():
        print(f"\n--- {node_name} ---")
        if "messages" in update:
            for msg in update["messages"]:
                content = msg.content if hasattr(msg, 'content') else str(msg)
                if content:
                    print(f"  {content[:300]}")

`````)

== 2.6 Multi-Turn Conversation

Keep conversation state with `InMemorySaver`.

`InMemorySaver` stores state in memory and separates conversation sessions with `thread_id`.

#tip-box[In LangChain v1, conversation history is managed through LangGraph checkpointers.]


#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()

agent_with_memory = create_agent(
    model=model,
    tools=[add, multiply],
    system_prompt="You are a math assistant.",
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "math-session-1"}}

# First question
result1 = agent_with_memory.invoke(
    {"messages": [{"role": "user", "content": "What is 7 * 6?"}]},
    config={**config, **lf_config},
)
print("First response:", result1["messages"][-1].content)

# Second question that remembers the previous conversation
result2 = agent_with_memory.invoke(
    {"messages": [{"role": "user", "content": "Now add 10 to the previous result."}]},
    config={**config, **lf_config},
)
print("Second response:", result2["messages"][-1].content)

`````)

== 2.7 Adding the Tavily Search Tool (Optional)

Add a web search tool so the agent can look up real information.

Tavily is a search API designed for AI agents.

This cell only runs if `TAVILY_API_KEY` is configured.


#code-block(`````python
# Run only if the Tavily API key is available
if os.environ.get("TAVILY_API_KEY"):
    from langchain_tavily import TavilySearch

    search_tool = TavilySearch(max_results=3)

    search_agent = create_agent(
        model=model,
        tools=[search_tool],
        system_prompt="You are a research assistant. Answer questions by searching the web.",
    )

    result = search_agent.invoke(
        {"messages": [{"role": "user", "content": "What is the latest version of LangChain?"}]},
        config=lf_config,
    )
    print("Search agent response:")
    print(result["messages"][-1].content)
else:
    print("⚠ TAVILY_API_KEY is not configured. Skipping this cell.")

`````)

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
