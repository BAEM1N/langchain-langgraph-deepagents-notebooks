// Auto-generated from 02_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Building Your First Agent")

== Learning Objectives
- Learn how to load API keys from a `.env` file
- Create a basic agent with `create_deep_agent()`
- Run the agent with `agent.invoke()` and `agent.stream()`
- Build a research agent with a Tavily search tool
- Understand the built-in tools and what they are for


#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. API Key Setup

Add the following keys to your `.env` file:

#code-block(`````python
OPENAI_API_KEY=your-key-here
TAVILY_API_KEY=your-key-here
`````)

#tip-box[The simplest setup is to copy `.env.example` to `.env` and then fill in the real values.]


#code-block(`````python
# Load environment variables
from dotenv import load_dotenv
import os

load_dotenv()

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY is not set!"
print("API keys loaded successfully.")

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

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Creating the Simplest Agent

`create_deep_agent()` is the core function in Deep Agents.
If you call it with no additional configuration, it automatically assembles a default model and the built-in tools.


#code-block(`````python
from deepagents import create_deep_agent
from langchain_openai import ChatOpenAI

# Configure the OpenAI gpt-5.4 model
model = ChatOpenAI(model="gpt-5.4")

# Create the basic agent
agent = create_deep_agent(model=model)

print(f"Agent type: {type(agent).__name__}")
print("The agent was created successfully!")

`````)

`create_deep_agent()` returns a LangGraph `CompiledStateGraph`.
That means you can use all of the normal LangGraph execution methods such as `invoke`, `stream`, and `batch`.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Running the Agent — `invoke()`

Run the agent by sending it a message.
The input format is a dictionary like `{"messages": [{"role": "user", "content": "..."}]}`.


#code-block(`````python
# Ask the agent a simple question
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Hello! What tools can you use? Please give me a short list."}]},
    config=lf_config,
)

# Print the last message (the AI response)
print(result["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Connecting Tavily Search — A Research Agent

You can extend the agent by adding custom tools.
In this example, you connect the _Tavily_ web search tool.

=== How tool definitions work
A Python function's _docstring_ becomes the tool description, and its _type hints_ become the parameter schema.


#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])


def internet_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
) -> dict:
    """Search the internet for information.

    Args:
        query: The question or keyword to search for
        max_results: Maximum number of results to return
        topic: Search topic category
        include_raw_content: Whether to include the raw source content
    """
    return tavily_client.search(
        query,
        max_results=max_results,
        include_raw_content=include_raw_content,
        topic=topic,
    )


print(f"Tool name: {internet_search.__name__}")
print(f"Tool description: {internet_search.__doc__.strip().splitlines()[0]}")

`````)

#code-block(`````python
# Create a research agent — search tool + custom system prompt
research_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="You are an expert researcher. Search the internet, organize the results, and write the final answer in English.",
)

print("Research agent created!")

`````)

#code-block(`````python
# Run the research agent
result = research_agent.invoke(
    {"messages": [{"role": "user", "content": "Search for what LangGraph is and summarize it briefly."}]},
    config=lf_config,
)

print(result["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Checking the Built-In Tools

These are the built-in tools that `create_deep_agent()` adds automatically:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tool],
  text(weight: "bold")[Description],
  [`write_todos`],
  [Manage a structured task list (`pending` → `in_progress` → `completed`)],
  [`ls`],
  [List directory contents with metadata],
  [`read_file`],
  [Read a file (with line numbers and image support)],
  [`write_file`],
  [Create a new file],
  [`edit_file`],
  [Replace text inside a file (`old_string` → `new_string`)],
  [`glob`],
  [Pattern-based file search (for example `**/*.py`)],
  [`grep`],
  [Search file contents (with regex support)],
  [`task`],
  [Call a subagent (added automatically when subagents are configured)],
)

#tip-box[All of these tools work through the _backend_. The default is `StateBackend`, which stores files inside agent state.]


#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. Streaming Output — `stream()`

With `agent.stream()`, you can observe the agent's execution process in real time.
You can choose different levels of detail through `stream_mode`:

- `"updates"` — state updates after each completed step
- `"messages"` — token-level streaming
- `"custom"` — custom events emitted from tools or nodes


#code-block(`````python
# Stream in updates mode — watch progress step by step
print("=== Streaming execution (updates mode) ===")
print()

for chunk in research_agent.stream(
    {"messages": [{"role": "user", "content": "Search for the major changes in Python 3.13 and summarize them in three lines."}]},
    stream_mode="updates",
    config=lf_config,
):
    # Print each node's result
    for node_name, node_data in chunk.items():
        if not node_data:
            continue
        msgs = node_data.get("messages", [])
        # LangGraph may wrap state updates in Overwrite objects
        if hasattr(msgs, "value"):
            msgs = msgs.value
        if not msgs:
            continue
        last_msg = msgs[-1]
        # Show tool calls
        if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
            for tc in last_msg.tool_calls:
                print(f"[Tool call] {tc['name']}({tc['args'].get('query', '')[:50]}...)")
        # Show final AI message content
        elif hasattr(last_msg, "content") and last_msg.content and not hasattr(last_msg, "tool_call_id"):
            content = last_msg.content if isinstance(last_msg.content, str) else str(last_msg.content)
            if content.strip():
                print(f"\n[Final response]\n{content[:500]}")

`````)

#code-block(`````python
# Stream in messages mode — token-level output
print("=== Streaming execution (messages mode) ===")
print()

for msg, metadata in research_agent.stream(
    {"messages": [{"role": "user", "content": "Write Python code that prints 'Hello World'."}]},
    stream_mode="messages",
    config=lf_config,
):
    # Print only text chunks from the model node
    if hasattr(msg, "content") and msg.content and metadata and metadata.get("langgraph_node") == "model":
        print(msg.content, end="", flush=True)

print()

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
  [Agent creation],
  [`create_deep_agent(model, tools, system_prompt)`],
  [Synchronous execution],
  [`agent.invoke({"messages": [...]})`],
  [Streaming execution],
  [`agent.stream({"messages": [...]}, stream_mode="updates")`],
  [Custom tools],
  [Python function + docstring + type hints],
  [Model format],
  [`ChatOpenAI(model="gpt-5.4")` or `"provider:model-name"`],
)

== Next Steps
→ _#link("./03_customization.ipynb")[03_customization.ipynb]_: learn how to customize the agent in more detail.
