// Auto-generated from 05_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Subagents and Task Delegation")

== Learning Objectives
- Understand the problem subagents solve: context bloat
- Define subagents with `SubAgent` dictionaries and `CompiledSubAgent`
- Understand and override the built-in general-purpose subagent
- Use context propagation and namespace keys
- Implement a multi-subagent pipeline pattern


#code-block(`````python
# Environment setup
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
assert os.environ.get("TAVILY_API_KEY"), "TAVILY_API_KEY is not set!"
print("Environment setup complete")

`````)

#code-block(`````python
# Recommended default — Anthropic Claude Sonnet 4.6
model = "anthropic:claude-sonnet-4-6"

print(f"Model configured: {model}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Why Subagents Are Useful

=== The Context Bloat Problem

Every time an agent uses a tool, the _inputs and outputs accumulate inside the context window_:
- web search results (thousands of tokens)
- file contents (hundreds or thousands of lines)
- database query results

When too much intermediate data builds up in the main context, the agent can lose track of the most important information.

=== How Subagents Help

#image("../../../../book/assets/diagrams/png/subagent_context.png")

The main agent receives only a _short summary_, so its context stays compact and focused.


=== `SubAgentMiddleware` is auto-attached

Subagent support is implemented by _`SubAgentMiddleware`_. `create_deep_agent()` always attaches this middleware regardless of whether you pass `subagents`, and it _cannot be removed_ via `excluded_middleware`. If you do not declare any subagents, a built-in `general-purpose` subagent registers automatically so the `task` tool is always available.

=== TodoList + `task` dispatch pattern

The canonical loop looks like this:

+ The main agent calls `write_todos` to break the work into a _structured list_, for example `[research, analyze, write]`
+ For each TODO the main agent calls the _`task` tool_ to dispatch the item to the right subagent
+ The subagent runs in an _isolated context_ and returns only a _compressed result_
+ The main agent moves to the next TODO or composes the final answer

This _`write_todos` → `task` → compressed result_ pattern is the core delegation cycle in Deep Agents. The main context only accumulates the todo list and the compressed results, which keeps token usage efficient.

=== When to Use a Subagent

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Situation],
  text(weight: "bold")[Use a subagent?],
  [Multi-step work with lots of intermediate results],
  [✅ Yes],
  [A domain that needs specialized knowledge or tools],
  [✅ Yes],
  [A task that is better handled by a different model],
  [✅ Yes],
  [A simple one-shot task],
  [❌ Usually unnecessary],
  [The main agent needs every intermediate detail],
  [❌ Usually unnecessary],
)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Defining a `SubAgent` (Dictionary Form)

A `SubAgent` is defined as a dictionary.

=== Required Fields
#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  [`name`],
  [`str`],
  [Unique identifier],
  [`description`],
  [`str`],
  [Role description used by the main agent when deciding whether to call it],
  [`system_prompt`],
  [`str`],
  [Instructions for the subagent],
  [`tools`],
  [`list`],
  [Tools available to the subagent],
)

=== Optional Fields
#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  [`model`],
  [`str`],
  [Model override (`"provider:model"`)],
  [`middleware`],
  [`list`],
  [Additional middleware],
  [`interrupt_on`],
  [`dict`],
  [Human-in-the-loop configuration],
  [`skills`],
  [`list[str]`],
  [Skill source paths],
  [`response_format`],
  [`BaseModel`],
  [Structured-output schema (`deepagents>=0.5.3`)],
  [`permissions`],
  [`Permissions`],
  [Per-path ACL — restrict the subagent's filesystem access],
)


#code-block(`````python
from typing import Literal
from tavily import TavilyClient
from deepagents import create_deep_agent

tavily_client = TavilyClient(api_key=os.environ["TAVILY_API_KEY"])


def internet_search(
    query: str,
    max_results: int = 5,
    topic: Literal["general", "news", "finance"] = "general",
    include_raw_content: bool = False,
) -> dict:
    """Search the internet for information.

    Args:
        query: Question or keyword to search for
        max_results: Maximum number of results to return
        topic: Search topic category
        include_raw_content: Whether to include raw source content
    """
    return tavily_client.search(
        query,
        max_results=max_results,
        include_raw_content=include_raw_content,
        topic=topic,
    )


research_subagent = {
    "name": "researcher",
    "description": "Investigates a topic on the internet and summarizes the key information. Use it when research is required.",
    "system_prompt": """You are an expert researcher.
Search the internet, collect accurate information, and summarize only the essentials.
Always write in English.
Keep the final result under 500 words.""",
    "tools": [internet_search],
}

print(f"Subagent created: {research_subagent['name']}")
print(f"Description: {research_subagent['description'][:60]}...")

`````)

#code-block(`````python
# Create a main agent that can delegate work to the subagent
main_agent = create_deep_agent(
    model=model,
    system_prompt="""You are a project manager.
Analyze the user's request, delegate work to a specialist subagent when needed,
and combine the result into the final answer.
Respond in English.""",
    subagents=[research_subagent],
)

print("Main agent created (subagent: researcher)")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. `CompiledSubAgent` — Plugging in a Custom LangGraph Runnable

You can also use a precompiled LangGraph runnable as a subagent.
This is useful when the delegated work needs more complex workflow logic such as branching or loops.


#code-block(`````python
from deepagents import CompiledSubAgent

# Example: wrap another runnable as a CompiledSubAgent
custom_graph = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="You are a data analyst. Gather information, analyze it, and produce insights.",
)

# Wrap the runnable
# TypedDict-like structure used by Deep Agents
# (same interface, but the runnable is already compiled)
data_analyst_subagent: CompiledSubAgent = {
    "name": "data-analyst",
    "description": "Collects data and produces analytical insights.",
    "runnable": custom_graph,
}

print(f"CompiledSubAgent created: {data_analyst_subagent['name']}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. General-Purpose Subagents

Deep Agents automatically provides a built-in _general-purpose subagent_ even if you do not define one explicitly.

=== Default Behavior
- Uses the _same system prompt_ as the main agent
- Has access to the _same tools_ as the main agent
- Uses the _same model_ as the main agent
- Inherits the main agent's _skills_

=== Overriding It
If you define a subagent with `name="general-purpose"`, it overrides the built-in one.


#code-block(`````python
# Example: override the built-in general-purpose subagent
custom_gp_agent = create_deep_agent(
    model=model,
    tools=[internet_search],
    system_prompt="You are a multi-task coordinator.",
    subagents=[
        research_subagent,
        {
            "name": "general-purpose",
            "description": "A general-purpose agent that handles multi-step work beyond research.",
            "system_prompt": "You are a general assistant. Solve the task step by step.",
            "tools": [internet_search],
        },
    ],
)

print("Created an agent that overrides the general-purpose subagent")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Context Propagation

Runtime context is automatically propagated to all subagents.
You define the shape with `context_schema`, and you pass values through the `context` key in `config`.


=== Passing Subagent-Specific Context with Namespace Keys

If you use the format `"subagent-name:key"`, you can pass configuration that only a specific subagent receives.

#code-block(`````python
config = {
    "context": {
        "user_id": "user-123",              # propagated to every agent
        "researcher:max_depth": 3,           # only for researcher
        "data-analyst:strict_mode": True,    # only for data-analyst
    }
}
`````)

=== Identifying subagents during streaming — `lc_agent_name`

When you stream tokens through `agent.stream(..., stream_mode="messages")` or `astream_events()`, each event's _metadata_ includes the `lc_agent_name` key. Use it to label UI output as "researcher searching...", "analyzer summarizing...", and similar.

#code-block(`````python
# Identify which subagent is emitting tokens during streaming
async for event in main_agent.astream_events(
    {"messages": [{"role": "user", "content": "..."}]},
    version="v2",
):
    name = event.get("metadata", {}).get("lc_agent_name")
    if event["event"] == "on_chat_model_stream" and name:
        print(f"[{name}] {event['data']['chunk'].content}", end="")
`````)


#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. Multi-Subagent Pipelines

You can combine several subagents to build a pipeline such as _collect → analyze → write_.

#image("../../../../book/assets/diagrams/png/subagent_pipeline.png")


#code-block(`````python
# Multi-subagent pipeline
pipeline_agent = create_deep_agent(
    model=model,
    system_prompt="""You are a project coordinator.
Analyze the user's request and delegate work in order:
1. Use data-collector to gather information.
2. Pass the results to data-analyzer for analysis.
3. Pass the analysis to report-writer to produce the final report.
Return the final report in English.""",
    subagents=[
        {
            "name": "data-collector",
            "description": "Collects raw information from external sources.",
            "system_prompt": "Collect as much relevant information as possible and return it in structured form.",
            "tools": [internet_search],
        },
        {
            "name": "data-analyzer",
            "description": "Analyzes the collected data and extracts key insights.",
            "system_prompt": "Extract patterns, trends, and key insights. Return the analysis as bullet points.",
            "tools": [],
        },
        {
            "name": "report-writer",
            "description": "Writes a professional report based on the analysis.",
            "system_prompt": "Write a clear report with the following structure: overview → key findings → conclusion.",
            "tools": [],
        },
    ],
)

print("Multi-subagent pipeline agent created")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Best Practices

=== 1. Write clear descriptions
The subagent `description` is how the main agent decides when to call it. Make it specific.

=== 2. Keep the result focused
A subagent should return a compact result rather than flooding the parent agent with raw data.

=== 3. Use specialized tools per role
Give each subagent only the tools it actually needs.

=== 4. Separate simple from complex work
Do not create subagents for tasks that the main agent can solve directly in one step.


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
  [Why subagents matter],
  [They solve context bloat and enable specialization],
  [Basic definition],
  [Subagent dictionary with `name`, `description`, `system_prompt`, `tools` plus optional `response_format` / `permissions`],
  [Advanced form],
  [`CompiledSubAgent` wraps a precompiled runnable],
  [Built-in fallback],
  [`SubAgentMiddleware` is always attached (not removable); a default `general-purpose` subagent fills the slot],
  [Dispatch pattern],
  [`write_todos` → `task()` → compressed result],
  [Context propagation],
  [Runtime context is inherited; namespace keys (`"agent:key"`) target specific subagents],
  [Streaming],
  [`lc_agent_name` in event metadata identifies the active subagent],
  [Pipeline pattern],
  [Subagents can be chained into collect → analyze → write workflows],
)

== Next Steps
→ _#link("./06_memory_and_skills.ipynb")[06_memory_and_skills.ipynb]_: learn how long-term memory and skills work in Deep Agents.

