// Auto-generated from 08_multi_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Multi", subtitle: "Agent Patterns")


== Learning Objectives

Understand and implement five multi-agent patterns.

This notebook covers:
- _Subagents_: the main agent calls specialized subagents as tools
- _Handoffs_: state transitions between agents with `Command(goto=...)`
- _Skills_: one agent loads specialized prompts depending on the task
- _Router_: a classifier routes input to the right agent
- _Custom_: developer-controlled complex workflows


== 8.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

print("Model ready:", model.model_name)
`````)

== 8.2 Comparing Multi-Agent Patterns

The table below compares five multi-agent patterns. Each one fits a different situation, so you should choose based on your project requirements.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Routing Owner],
  text(weight: "bold")[State Sharing],
  text(weight: "bold")[Best Fit],
  [_Subagents_],
  [Main agent],
  [Isolated through tools],
  [Parallel work, distributed execution],
  [_Handoffs_],
  [Tool call],
  [State transition],
  [Sequential multi-hop flows],
  [_Skills_],
  [Single agent],
  [Prompt swapping],
  [Domain specialization],
  [_Router_],
  [Classifier],
  [Parallel execution],
  [Multi-domain systems],
  [_Custom_],
  [Developer-defined],
  [Full control],
  [Complex workflows],
)

=== Key differences
- _Subagents_ run independently and return only the result
- _Handoffs_ pass conversation state between agents
- _Skills_ let one agent switch roles
- _Router_ classifies input and delegates it to the right specialist


== 8.3 The Subagent Pattern

In this pattern, the main agent (supervisor) calls specialized subagents _as tools_.

=== Characteristics
- Each subagent is wrapped in a tool function
- The main agent decides which subagent to call
- The internal state of each subagent is isolated from the main agent
- Parallel execution is possible, which can improve performance


== 8.4 The Handoff Pattern

This pattern uses `Command(goto=...)` to _transfer state_ between agents.

=== Characteristics
- A tool returns a `Command` object that routes execution to another agent
- Conversation state (message history) is passed to the next agent
- A `StateGraph` defines the flow between agents
- This fits multi-hop scenarios such as customer-service transfers


== 8.5 The Skill Pattern

A single agent dynamically _loads a specialized prompt_ depending on the task.

=== Characteristics
- One agent has multiple skills
- Each skill is implemented as a specialized system prompt
- The agent dynamically loads the skill it needs
- One agent can handle many tasks without managing multiple separate agents


== 8.6 The Router Pattern

A classifier _routes_ input to the most appropriate agent.

=== Characteristics
- The query is classified first
- It is then delegated to the right specialist agent or tool
- This is useful in multi-domain systems
- Routing logic can be rule-based or model-based


== 8.7 Choosing a Pattern

Which multi-agent pattern should you choose? Use the guide below.

=== Decision tree

+ _Can the agents work independently?_
- YES → _Subagents_ (parallel execution, result aggregation)
- NO → move to the next question

+ _Must conversation state be passed between agents?_
- YES → _Handoffs_ (state transition, multi-hop)
- NO → move to the next question

+ _Can a single agent just switch roles?_
- YES → _Skills_ (prompt switching)
- NO → move to the next question

+ _Is classifying input and sending it to a handler enough?_
- YES → _Router_ (classify and delegate)
- NO → _Custom_ (fully custom graph)

=== Practical guidance
- Start with the _simplest pattern_ (usually Subagents or Skills)
- Move to Handoffs or Router only when requirements become more complex
- Use a Custom pattern only when the other patterns are not enough
- You can also _combine_ patterns (for example, Router + Handoffs)


== 8.8 Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Core API],
  text(weight: "bold")[When to use it],
  [_Subagents_],
  [`create_agent` + tool functions],
  [Independent parallel work],
  [_Handoffs_],
  [`Command(goto=...)`, `StateGraph`],
  [Multi-hop state transfer],
  [_Skills_],
  [Load prompts as tools],
  [One agent with many roles],
  [_Router_],
  [Classifier tool + specialist tools],
  [Multi-domain classification],
  [_Custom_],
  [Full `StateGraph` control],
  [Complex business logic],
)

=== Key principles
- Start simple and increase complexity only when necessary
- Design each agent around _one clear responsibility_
- Define the _interfaces_ between agents (inputs and outputs) clearly

=== Next Steps
→ _#link("./09_custom_workflow_and_rag.ipynb")[09_custom_workflow_and_rag.ipynb]_: Learn about custom workflows and RAG.

