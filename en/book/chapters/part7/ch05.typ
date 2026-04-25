// Auto-generated from 05_deep_research_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Deep Research Agent", subtitle: "Parallel Subagents and a Five-Step Workflow")

== Learning Objectives

- Configure three parallel subagents (`researcher-1`, `researcher-2`, `fact-checker`)
- Implement strategic reflection with `think_tool`
- Design a five-step workflow (Plan → Delegate → Synthesize → Verify → Report)
- Apply v1 middleware (`SummarizationMiddleware`, `ModelCallLimitMiddleware`, `ModelFallbackMiddleware`)


== Overview

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Details],
  [_Framework_],
  [Deep Agents],
  [_Core components_],
  [Three parallel subagents, `think_tool`],
  [_Workflow_],
  [5 steps: Plan → Delegate → Synthesize → Verify → Report],
  [_Backend_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_Built-in tools_],
  [`write_todos` (planning), `task` (subagent call)],
  [_Skill_],
  [`skills/deep-research/SKILL.md` — research method + citation rules],
)


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

== Step 1: `think_tool` — A Strategic Reflection Tool

`think_tool` lets the agent record “thoughts” before it acts. This pattern can improve the quality of agent decision-making:

- Analyze search results and plan the next action
- Evaluate whether the collected information is sufficient
- Make delegated tasks more specific before sending them to subagents


#code-block(`````python
from langchain.tools import tool

@tool
def think_tool(thought: str) -> str:
    """Strategic reflection — analyze the current situation and plan the next action."""
    return f"Reflection recorded: {thought}"

`````)

== Step 2: A Simplified `web_search` Tool

In a real deep research workflow, you would typically use the Tavily API. Here, for learning purposes, we define a simplified search tool.


#code-block(`````python
@tool
def web_search(query: str) -> str:
    """Perform a web search (simulated)."""
    results = {
        "AI agent": "AI agents are systems that perform tasks autonomously. Their adoption has accelerated rapidly since 2024.",
        "LangGraph": "LangGraph is a stateful workflow framework. It supports both the Graph API and the Functional API.",
        "Deep Agents": "Deep Agents is an all-in-one agent SDK. It supports subagents, backends, and skills.",
    }
    for key, val in results.items():
        if key.lower() in query.lower():
            return val
    return f"Search result for '{query}': no relevant information found."

`````)

== Step 3: Prompt for the Five-Step Research Workflow

The prompt loader pulls the prompt using the following order: LangSmith Hub → Langfuse → local default.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Step],
  text(weight: "bold")[Name],
  text(weight: "bold")[Description],
  [1],
  [_Plan_],
  [Create a research plan with `write_todos`],
  [2],
  [_Delegate_],
  [Parallelize investigation across subagents (up to 3 at once)],
  [3],
  [_Synthesize_],
  [Combine the gathered information],
  [4],
  [_Verify_],
  [Ask the fact-checker to verify the claims],
  [5],
  [_Report_],
  [Produce the final report],
)


#code-block(`````python
from prompts import RESEARCH_AGENT_PROMPT

print(RESEARCH_AGENT_PROMPT)

`````)

== Step 4: Define Three Subagents

The deep research agent uses three specialized subagents:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Subagent],
  text(weight: "bold")[Role],
  text(weight: "bold")[Tools],
  [`researcher-1`],
  [Primary topic research],
  [`web_search`, `think_tool`],
  [`researcher-2`],
  [Complementary or contrasting research],
  [`web_search`, `think_tool`],
  [`fact-checker`],
  [Verify factual accuracy],
  [`web_search`],
)


#code-block(`````python
researcher_1 = {
    "name": "researcher-1",
    "description": "Performs in-depth research on the topic",
    "system_prompt": "You are a research specialist. Investigate the topic deeply and summarize the key findings. Reflect with think_tool after searching.",
    "tools": [web_search, think_tool],
}

`````)

#code-block(`````python
researcher_2 = {
    "name": "researcher-2",
    "description": "Performs complementary research from another perspective",
    "system_prompt": "You are a complementary researcher. Collect additional information from a different angle. Reflect with think_tool after searching.",
    "tools": [web_search, think_tool],
}

`````)

#code-block(`````python
fact_checker = {
    "name": "fact-checker",
    "description": "Verifies the factual correctness of collected information",
    "system_prompt": "You are a fact-checker. Verify the accuracy of the provided information and point out any errors.",
    "tools": [web_search],
}

`````)

== Step 5: Create the Deep Research Agent (with v1 Middleware)

Combine the tools and subagents into the final agent. The v1 middleware improves stability and reliability:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Role],
  [`SummarizationMiddleware`],
  [Automatically summarizes long research conversations to save context],
  [`ModelCallLimitMiddleware`],
  [Prevents research loops by limiting the run to 30 model calls],
  [`ModelFallbackMiddleware`],
  [Falls back to a backup model if the primary model fails],
)

Enable checkpointing with `InMemorySaver` so interrupted research runs can resume.


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import (
    SummarizationMiddleware,
    ModelCallLimitMiddleware,
    ModelFallbackMiddleware,
)

research_agent = create_deep_agent(
    model=model,
    tools=[web_search, think_tool],
    subagents=[researcher_1, researcher_2, fact_checker],
    system_prompt=RESEARCH_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    middleware=[
        SummarizationMiddleware(model=model, trigger=("messages", 15)),
        ModelCallLimitMiddleware(run_limit=30),
        ModelFallbackMiddleware("gpt-4.1-mini"),
    ],
)

`````)

== Step 6: Run the Research Workflow

Give the agent a research topic and let it execute the five-step workflow.


== Step 7: Streaming — Track Namespaces

With `stream(subgraphs=True)`, you can follow the execution of the main agent and the subagents by namespace. This makes it easy to see when each subagent is called.


== Subagent Design Best Practices

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Principle],
  text(weight: "bold")[Description],
  [_Clear descriptions_],
  [Write specific `description` values so the main agent knows when to delegate],
  [_Specialized prompts_],
  [Put output format, constraints, and workflow expectations into `system_prompt`],
  [_Minimal tools_],
  [Give each subagent only the tools it actually needs],
  [_Concise outputs_],
  [Tell subagents to return summaries rather than raw data],
)


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Point],
  [`think_tool`],
  [Strategic reflection — analyze search results and plan the next step],
  [_Subagents_],
  [Parallel execution with `researcher-1`, `researcher-2`, and `fact-checker`],
  [_Workflow_],
  [Plan → Delegate → Synthesize → Verify → Report],
  [_Context management_],
  [Only subagent results are passed back to the main agent; intermediate work stays isolated],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/deepagents/examples/02-deep-research.md`
- `docs/deepagents/07-subagents.md`
- `docs/deepagents/06-backends.md`

_Previous Step:_ ← #link("./04_ml_agent.ipynb")[04_ml_agent.ipynb]: Machine learning agent

