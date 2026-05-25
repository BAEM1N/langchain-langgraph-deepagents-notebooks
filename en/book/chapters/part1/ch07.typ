// Auto-generated from 07_mini_project.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Mini Project", subtitle: "A Search + Summarization Agent")

Combine what you learned in the beginner track to build a research agent with Tavily web search.


== Learning Objectives

- Define a Tavily search tool directly
- Build a research agent with Deep Agents
- Observe the agent's execution process in real time with streaming
- Solve the same task with a LangChain agent and compare the two approaches


== 7.1 Environment Setup

This notebook requires `TAVILY_API_KEY`. You can get a free key at https://tavily.com.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is required!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY is required!"

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
print("✓ Environment ready")

`````)

== 7.2 Defining the Search Tool

Wrap the Tavily client in a search function.
The _docstring_ and _type hints_ tell the agent what schema the tool should use.

_Rules for writing a tool function:_

Here you define a search function that will be passed to the `tools` parameter of `create_deep_agent()`. Deep Agents automatically converts the function docstring into a tool description and the type hints into a parameter schema. In practice, that means:

- _Docstring_: Gives the agent evidence for deciding _when_ to use the tool. Be specific and clear.
- _Type hints_: Help the agent pass arguments of the correct type. `Literal` is useful when you want to restrict the allowed values.
- _Args section_: Explaining each parameter makes it easier for the agent to choose the right arguments.


#code-block(`````python
from typing import Literal
from tavily import TavilyClient

tavily = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])

def internet_search(
    query: str,
    max_results: int = 3,
    topic: Literal["general", "news"] = "general",
) -> dict:
    """Search the internet for information.

    Args:
        query: Search query
        max_results: Maximum number of results
        topic: Search topic category
    """
    return tavily.search(query, max_results=max_results, topic=topic)

print("✓ Search tool ready")

`````)

== 7.3 A Deep Agents Research Agent

Pass the search tool and a system prompt into `create_deep_agent()`.

_The agent's automatic workflow:_

When the agent receives a request, it can automatically go through the following steps:

+ _Planning_: Breaks the task into steps with the built-in `write_todos` tool
+ _Research_: Collects information from the web with the provided `internet_search` tool
+ _Context management_: Uses filesystem tools such as `write_file` and `read_file` to store intermediate results when needed and manage the token budget
+ _Synthesis_: Analyzes the gathered information and turns it into a consistent final report

For more complex tasks, the agent can also create specialized subagents and isolate their context for focused sub-work.


#code-block(`````python
from deepagents import create_deep_agent

research_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="You are an expert researcher. Search the web and summarize the results in English.",
)
print("✓ Research agent created")

`````)

== 7.4 Observing the Process with Streaming

With `stream(mode="updates")`, you can watch the agent's steps in real time.

_LangGraph's streaming system:_

LangGraph provides a flexible streaming system that improves responsiveness by showing progress before the final response is complete.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Stream Mode],
  text(weight: "bold")[Use Case],
  [`values`],
  [Streams the _full state_ after each graph step],
  [`updates`],
  [Streams only the _state changes_ after each step],
  [`messages`],
  [Streams LLM tokens together with metadata],
  [`custom`],
  [Streams custom data emitted from nodes],
  [`debug`],
  [Streams comprehensive execution details],
)

You can access streaming with `stream()` (sync) or `astream()` (async), and you can combine multiple modes at once by passing a list. In the example below, we use `updates` so that each stage of the agent, such as tool calls and the final response, appears as it happens.


== 7.5 Comparing It with a LangChain Agent

Try the same search tool with a LangChain `create_agent()`.

_How it differs from a LangChain agent:_

LangChain's `create_agent()` builds a simple ReAct agent from a model and a list of tools. Compared with Deep Agents:

- _LangChain_: A lightweight baseline for tool-calling agents. It is excellent for fast prototyping, but advanced capabilities such as task planning or filesystem management must be added manually.
- _Deep Agents_: Includes planning (`write_todos`), file management, and subagent delegation by default, so it is a better fit for complex multi-step tasks.

If you add the `@tool` decorator, you can convert a function into LangChain's tool interface. The general pattern of passing a system prompt and a list of tools into `create_agent()` is similar to Deep Agents.


== Summary

Technologies used in this mini project:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Technique],
  text(weight: "bold")[Source],
  [`ChatOpenAI` + `load_dotenv`],
  [00_setup],
  [Message roles, streaming],
  [01_llm_basics],
  [`\@tool`, `create_agent()`],
  [02_langchain_basics],
  [`InMemorySaver`, `thread_id`],
  [03_langchain_memory],
  [`StateGraph`, `compile()`],
  [04_langgraph_basics],
  [`create_deep_agent()`],
  [05_deep_agents_basics],
)

=== Next Steps
→ Continue to the intermediate tracks. Use _#link("./06_comparison_en.ipynb")[06_comparison_en.ipynb]_ as your roadmap.

