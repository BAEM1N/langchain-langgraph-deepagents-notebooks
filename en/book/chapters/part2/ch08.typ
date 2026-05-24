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
    model="gpt-5.4",
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

=== Pattern Selection Matrix (requirement → pattern)

While the table above lists pattern _properties_, the matrix below starts from _requirements_ and points to the best-fit pattern.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Requirement],
  text(weight: "bold")[Best-fit pattern],
  [Single simple task (one-shot)],
  [_Skills_ (or single agent)],
  [Repeat the same task],
  [_Subagents_],
  [Parallel work across multiple domains],
  [_Router_ (classify then fan-out)],
  [Very large context (long docs/history)],
  [_Subagents_ (token savings via isolation)],
  [Team-based — agents collaborate],
  [_Handoffs_ (shared state)],
  [Direct conversation with a role],
  [_Handoffs_ + supervisor],
)

=== Approximate cost per pattern

Rough call count and cumulative tokens for the same task implemented in different patterns. The numbers vary by scenario and model, but they illustrate the _relative_ cost.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Scenario],
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Calls],
  text(weight: "bold")[Cumulative tokens],
  [One-Shot (single domain)],
  [_Subagents_],
  [4–5 calls],
  [~9K],
  [Repeat (same task)],
  [_Skills_],
  [2–3 calls],
  [~15K],
  [Multi-Domain (collaboration)],
  [_Handoffs_],
  [3–7+ calls],
  [~14K+],
  [Multi-Domain (classify then fan-out)],
  [_Router_],
  [\~1 classify + N domains],
  [~9K],
)

#tip-box[_Router vs Supervisor_ — the terms are often used interchangeably but they differ in implementation. A _Router_ is a _simple functional_ node that classifies input once and _fans out_ to the right agent (or `Send`). A _Supervisor_ is itself an agent that decides _conversation-aware_ which subagent to invoke on every turn, retaining message history. Use Router for one-shot classification; pick Supervisor for multi-turn collaboration.]


== 8.3 The Subagent Pattern

In this pattern, the main agent (supervisor) calls specialized subagents _as tools_.

=== Characteristics
- Each subagent is wrapped in a tool function
- The main agent decides which subagent to call
- The internal state of each subagent is isolated from the main agent
- Parallel execution is possible, which can improve performance

=== Subagent-local history (`checkpointer=True`)

`create_agent(..., checkpointer=True)` lets a subagent keep its _own_ message history on a separate thread. The main agent still only sees the final result, but the subagent can run multi-turn reasoning internally and resume from the same `thread_id`.

=== Exposing N subagents via a single dispatch tool

With many subagents, registering each one as its own tool bloats the parent tool list. The alternative is a single `dispatch(agent_name, query)` tool combined with one of three discovery strategies.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Strategy],
  text(weight: "bold")[Recommended scale],
  text(weight: "bold")[Notes],
  [Enumerate in system prompt],
  [< 10],
  [LLM picks the name from text. Simple, flexible],
  [`Literal["a", "b", ...]` type constraint],
  [10–30],
  [Schema-level validation, rejects unknown names],
  [Tool-based discovery (`list_agents`)],
  [> 30],
  [Dynamic registration; separate tools to search/filter],
)

=== Injecting parent state with `ToolRuntime[None, CustomState]`

When a subagent tool needs to read part of the parent state, take a `ToolRuntime[None, CustomState]` argument.

#code-block(`````python
from langchain.tools import tool, ToolRuntime

@tool
def research_subagent(query: str, runtime: ToolRuntime[None, ResearchState]) -> str:
    """Research subagent that reads user_id from the parent state."""
    user_id = runtime.state["user_id"]
    # ... call subagent ...
    return result
`````)

=== Async work: start / status / get_result three-tool pattern

Long-running subagents are safer when split into _three_ tools instead of a single blocking call.

#code-block(`````python
@tool
def start_research_job(query: str) -> str:
    """Start the research job and return a job_id."""
    ...

@tool
def check_job_status(job_id: str) -> str:
    """Return the job status: running / done / failed."""
    ...

@tool
def get_job_result(job_id: str) -> str:
    """Return the result of a completed job."""
    ...
`````)

=== Updating parent state with `Command`

A subagent tool can return `Command(update={...})` instead of a plain string to update the parent graph's state directly — useful when you need to update custom fields, not just messages.

#code-block(`````python
from langgraph.types import Command

@tool
def research_with_state_update(query: str) -> Command:
    result = run_research(query)
    return Command(update={
        "research_results": result,
        "messages": [{"role": "tool", "content": result}],
    })
`````)


== 8.4 The Handoff Pattern

This pattern uses `Command(goto=...)` to _transfer state_ between agents.

=== Characteristics
- A tool returns a `Command` object that routes execution to another agent
- Conversation state (message history) is passed to the next agent
- A `StateGraph` defines the flow between agents
- This fits multi-hop scenarios such as customer-service transfers

=== Single agent + middleware handoff (preferred)

The LangChain v1 docs recommend a _single agent + `@wrap_model_call` middleware_ over multiple subgraphs as the primary handoff pattern. The middleware overrides the system prompt and tool set dynamically based on routing state, so persona switches happen inside one agent node.

#code-block(`````python
from langchain.agents.middleware import wrap_model_call, ModelRequest
from langchain.agents import create_agent

@wrap_model_call
def role_router(request: ModelRequest, handler):
    state = request.state
    role = state.get("active_role", "general")

    if role == "billing":
        return handler(request.override(
            system_prompt="You are a billing specialist.",
            tools=[refund_tool, charge_tool],
        ))
    elif role == "tech":
        return handler(request.override(
            system_prompt="You are a technical support agent.",
            tools=[diagnose_tool, escalate_tool],
        ))
    return handler(request)

agent = create_agent(model="gpt-5.4", tools=ALL_TOOLS, middleware=[role_router])
`````)

The multi-subgraph handoff still has its place when the flow between departments must be explicit, but the middleware approach is much lighter for plain persona switches.

=== Handoff tool with `ToolRuntime` and `tool_call_id` echo-back

A handoff tool should accept `ToolRuntime[None, SupportState]` so it can access parent state and the current `tool_call_id`. When switching with `Command(goto=..., update={"messages": [...]})`, you must include a `ToolMessage` that matches the originating tool call — otherwise OpenAI's tool-call contract breaks.

#code-block(`````python
from langchain.tools import tool, ToolRuntime
from langchain_core.messages import ToolMessage
from langgraph.types import Command

@tool
def transfer_to_billing(reason: str, runtime: ToolRuntime[None, SupportState]) -> Command:
    """Transfer the conversation to the billing team."""
    return Command(
        goto="billing_agent",
        update={
            "messages": [
                ToolMessage(
                    content=f"Transferred to billing: {reason}",
                    tool_call_id=runtime.tool_call_id,
                ),
            ],
            "active_role": "billing",
        },
    )
`````)

#tip-box[_Exactly two messages should flow on a subgraph handoff_ — (1) the `AIMessage(tool_calls=[...])` that triggered the handoff and (2) its matching `ToolMessage`. Inserting anything else between them causes the OpenAI provider to reject the next call because the tool-call pair no longer matches.]


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

=== Multi-domain fan-out with `Send`

When a query spans _several_ domains at once, use `Send` for parallel fan-out instead of routing to a single agent. If a routing function passed to `add_conditional_edges` returns a `list[Send]`, the LangGraph runtime executes those nodes _in parallel_.

#code-block(`````python
from langgraph.types import Command, Send

def route_to_agents(state: RouterState) -> list[Send]:
    """Fan out to every category produced by the classifier."""
    return [
        Send(c["agent"], {"query": c["query"]})
        for c in state["classifications"]
    ]

graph.add_conditional_edges("classifier", route_to_agents,
                             ["billing_agent", "tech_agent", "general_agent"])
`````)


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

