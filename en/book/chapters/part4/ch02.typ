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
== 1. Project Bootstrap and API Keys

=== Bootstrap with `uv`

The recommended workflow uses `uv` for reproducible dependency management.

#code-block(`````bash
# 1) Init the project
uv init my-deepagent
cd my-deepagent

# 2) Add deepagents plus the provider package
uv add deepagents langchain-anthropic   # recommended default
# uv add deepagents langchain-openai
# uv add deepagents langchain-google-genai
uv add tavily-python python-dotenv

# 3) Sync the lockfile
uv sync
`````)

=== API keys by provider

The recommended default model is _Anthropic Claude Sonnet 4.6_ (`anthropic:claude-sonnet-4-6`). Set only the keys for the providers you actually use.

#code-block(`````bash
# Anthropic (recommended default)
ANTHROPIC_API_KEY=your-key-here

# OpenAI
OPENAI_API_KEY=your-key-here

# Google Gemini
GOOGLE_API_KEY=your-key-here

# OpenRouter (OpenAI-compatible)
OPENAI_API_KEY=your-openrouter-key
OPENAI_BASE_URL=https://openrouter.ai/api/v1

# Shared — used in the research example
TAVILY_API_KEY=your-key-here
`````)

#tip-box[The simplest setup is to copy `.env.example` to `.env` and then fill in the real values.]


#code-block(`````python
# Load environment variables
from dotenv import load_dotenv
import os

load_dotenv()

# Recommended default — Anthropic
assert os.environ.get("ANTHROPIC_API_KEY"), "ANTHROPIC_API_KEY is not set!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY is not set!"
print("API keys loaded successfully.")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Creating the Simplest Agent

`create_deep_agent()` is the core function in Deep Agents.
If you call it with no additional configuration, it automatically assembles a default model and the built-in tools.


#code-block(`````python
from deepagents import create_deep_agent

# Recommended default — Anthropic Claude Sonnet 4.6 (provider:model string)
agent = create_deep_agent(model="anthropic:claude-sonnet-4-6")

# (Alt 1) OpenAI gpt-5.4
# agent = create_deep_agent(model="openai:gpt-5.4")

# (Alt 2) Google Gemini 3.5 Flash
# agent = create_deep_agent(model="google_genai:gemini-3.5-flash")

# (Alt 3) Pass a ChatModel object for fine control
# from langchain_anthropic import ChatAnthropic
# model = ChatAnthropic(model="claude-sonnet-4-6", temperature=0)
# agent = create_deep_agent(model=model)

print(f"Agent type: {type(agent).__name__}")
print("The agent was created successfully!")

`````)

`create_deep_agent()` returns a LangGraph `CompiledStateGraph`.
That means you can use all of the normal LangGraph execution methods such as `invoke`, `stream`, and `batch`.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Running the Agent — `invoke()`

Run the agent by sending it a message.
The input format is a dictionary like `{"messages": [{"role": "user", "content": "..."}]}`.


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
    model="anthropic:claude-sonnet-4-6",
    tools=[internet_search],
    system_prompt="You are an expert researcher. Search the internet, organize the results, and write the final answer in English.",
)

print("Research agent created!")

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
  [Provider prefix preferred — `"anthropic:claude-sonnet-4-6"`, `"openai:gpt-5.4"`, `"google_genai:gemini-3.5-flash"`. ChatModel objects also accepted],
)

== Next Steps
→ _#link("./03_customization.ipynb")[03_customization.ipynb]_: learn how to customize the agent in more detail.

