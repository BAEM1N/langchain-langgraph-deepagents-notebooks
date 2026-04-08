// Auto-generated from 03_multi_agent_handoffs_router.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "multi", subtitle: "agent: Handoffs & Router — State machines and parallel routing")

== Learning Objectives

- Handoffs pattern: Implements state variable-based dynamic configuration (prompt + tool replacement)
- Trigger a state transition from tool to the `Command` object.
- Router pattern: structured output classification → `Send` API parallel execution → result synthesis

#line(length: 100%, stroke: 0.5pt + luma(200))
== Part A — Handoffs: Customer Support State Machine
#line(length: 100%, stroke: 0.5pt + luma(200))

== 3.1 Environment Setup

This notebook covers two multi-agent patterns:
- _Part A — Handoffs_: State machine pattern where a single agent dynamically swaps prompts and tool based on state variables.
- _Part B — Router_: A pattern that classifies queries, routes them in parallel to professional agents, and synthesizes the results.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 3.2 Handoffs Overview

The Handoffs pattern is an architecture where a _single agent_ dynamically changes its behavior based on state variables. Rather than switching between multiple agents, one agent uses different sets of system prompts and tool depending on the step.

#image("../../assets/images/handoffs_state_machine.png")

=== Core Mechanism

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mechanism],
  text(weight: "bold")[Description],
  [`current_step`],
  [State variable that tracks the current step. This value determines the agent's behavior],
  [`Command(update={...})`],
  [tool returns, triggering a state transition. `current_step` Change + Save Additional Data],
  [`\@wrap_model_call`],
  [Middleware reads `current_step` and dynamically replaces tool with system prompt],
)

=== Key characteristics of Handoffs

- _State-driven behavior_: Settings are adjusted based on tracked state variables
- _tool-based transitions_: tool returns a `Command` object to update state
- _Direct user interaction_: Messages are processed independently at each stage
- _Persistent state_: The state persists beyond conversation turns

=== Important implementation details

When tool updates a message through `Command`, it must include `ToolMessage` with a matching `tool_call_id`. LLM expects responses to be paired with tool calling, so missing them will result in a malformed conversation history.

=== When to use

This is ideal when you need sequential constraints, interact directly with the user in each state, or collect information in a specific order in a multi-step flow (e.g. customer support).

== 3.3 SupportState definition

Inherit from `AgentState` and add the `current_step` field. This field determines the current node of the state machine and limits the valid steps to type `Literal`.

The default is `"identify_customer"`, which means all conversations start at the customer identification stage. Afterwards, when tool returns `Command(update={"current_step": "..."})`, it automatically transitions to Next Steps.

#code-block(`````python
from langchain.agents import AgentState
from typing import Literal

class SupportState(AgentState):
    current_step: Literal[
        "identify_customer", "diagnose_issue",
        "resolve_issue", "close_ticket",
    ] = "identify_customer"
`````)

== 3.4 Step-by-step tool definition

Each step is assigned tool that matches the role of that step. tool is divided into two types:

- _State transition tool_: Returns `Command(update={...})` to change `current_step` and store additional data in the state. The string result to be shown to LLM is also delivered to the `result` field.
- _General tool_: Returns a string and does not change state. Used for information retrieval, etc.

Design recommendations:
- State transitions must only occur through tool, which returns `Command`
- Backward transitions (going back to the previous step) are also allowed when necessary.
- Prevent step skipping by validating invalid transitions in middleware

#code-block(`````python
from langchain_core.tools import tool
from langgraph.types import Command

# --- Identify Customer ---
@tool
def lookup_customer(email: str) -> Command:
    """Track customers by email."""
    return Command(
        update={"customer": {"name": "Alice", "id": "C-1234"}, "current_step": "diagnose_issue"},
        result="Customer found: Alice (C-1234). Go to the diagnosis step.",
    )
`````)

#code-block(`````python
# --- Diagnose Issue ---
@tool
def check_service_status(service_name: str) -> str:
    """Check the current status of the service."""
    return f"Service '{service_name}': healthy (99.9% uptime)"
`````)

#code-block(`````python
@tool
def escalate_to_resolve(diagnosis: str) -> Command:
    """After diagnosis, move on to resolution steps."""
    return Command(
        update={"diagnosis": diagnosis, "current_step": "resolve_issue"},
        result=f"Diagnosis complete: {diagnosis}. Moving to the resolution step.",
    )
`````)

#code-block(`````python
# --- Resolve Issue ---
@tool
def apply_fix(fix_type: str, customer_id: str) -> Command:
    """Apply modifications to customer accounts."""
    return Command(
        update={"resolution": {"type": fix_type}},
        result=f"Fix applied: {fix_type} for {customer_id}",
    )
`````)

#code-block(`````python
@tool
def mark_resolved(summary: str) -> Command:
    """Mark the issue as resolved and move it to the Close stage."""
    return Command(
        update={"current_step": "close_ticket", "resolution_summary": summary},
        result="Solved. Go to the termination step.",
    )
`````)

#code-block(`````python
# --- Close Ticket ---
@tool
def send_satisfaction_survey(customer_id: str) -> str:
    """Send a satisfaction survey."""
    return "Survey completed."

@tool
def close_ticket(ticket_id: str, notes: str) -> str:
    """Close the support ticket."""
    return f"Ticket {ticket_id} closed."
`````)

== 3.5 \@wrap_model_call middleware

`@wrap_model_call` Middleware is the core of the Handoffs pattern. Intercepts LLM calls and dynamically replaces system prompts and available tool depending on `current_step`.

_Sequence of operations:_
+ The middleware reads the `current_step` value from the state
+ Look up the settings (prompt + tool) for that step in the `STEP_CONFIG` dictionary.
+ Override `config` and pass it to LLM
+ Call LLM with modified settings with `next_fn(state, config)`

This is the core mechanic of Handoffs: a single agent will have completely different personas and abilities depending on their status. Achieve dynamic behavior changes with a single middleware, without the need to create multiple agents.

#code-block(`````python
STEP_CONFIG = {
    "identify_customer": {
        "tools": [lookup_customer],
        "system_prompt": "Identify your customers. Request your email or account ID.",
    },
    "diagnose_issue": {
        "tools": [check_service_status, escalate_to_resolve],
        "system_prompt": "Diagnose the issue. Call escalate_to_resolve after using tool.",
    },
}
`````)

#code-block(`````python
STEP_CONFIG["resolve_issue"] = {
    "tools": [apply_fix, mark_resolved],
    "system_prompt": "Solve the issue. After applying the fix, call mark_resolved.",
}
STEP_CONFIG["close_ticket"] = {
    "tools": [send_satisfaction_survey, close_ticket],
    "system_prompt": "Thank your customers, send surveys, and close tickets.",
}
`````)

#code-block(`````python
from langchain.agents.middleware import wrap_model_call

@wrap_model_call
def step_middleware(request, handler):
    """Dynamically configures agents based on current_step."""
    step = request.state.get("current_step", "identify_customer")
    cfg = STEP_CONFIG[step]
    request = request.override(
        system_prompt=cfg["system_prompt"],
        tools=cfg["tools"],
    )
    return handler(request)
`````)

== 3.6 Agent creation and execution flow

When creating an agent, register all tool, but specify `state_schema=SupportState` and middleware. Because the middleware filters tool according to `current_step` at runtime, each step only exposes tool for that step to the LLM.

_Example execution flow:_
This is done automatically by tool, which returns 
[identify_customer] User: "I can't log in. Email: alice\@example.com"
→ lookup_customer("alice\@example.com")
← Command(update={customer: {...}, current_step: "diagnose_issue"})

[diagnose_issue] Agent: "I found your account. What seems to be the issue?"
→ check_service_status("auth-service") → "healthy"
→ escalate_to_resolve("Locked after three failed login attempts")

[resolve_issue] → apply_fix("reset_password", "C-1234")
→ mark_resolved("Password reset completed")

[close_ticket] → send_satisfaction_survey("C-1234")
→ close_ticket("T-5678", notes="Password reset")
#code-block(`````python

Each step transition is driven by a `Command` object.
`````)

#code-block(`````python
from langchain.agents import create_agent

all_tools = [
    lookup_customer, check_service_status,
    escalate_to_resolve, apply_fix, mark_resolved,
    send_satisfaction_survey, close_ticket,
]
support_agent = create_agent(
    model="gpt-4.1", tools=all_tools,
    state_schema=SupportState, middleware=[step_middleware],
)
`````)

#code-block(`````python
# [identify_customer]
#   User: "Can't log in. Email: alice@example.com"
#   Agent -> lookup_customer("alice@example.com")
#        <- Command(update={current_step: "diagnose_issue"})
#
# [diagnose_issue] (auto transition)
#   Agent -> check_service_status("auth-service")
#   Agent -> escalate_to_resolve("Locked out")
#
# [resolve_issue] -> [close_ticket]
`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== Part B — Router: Parallel routing and result synthesis
#line(length: 100%, stroke: 0.5pt + luma(200))

== 3.7 Router Overview

The Router pattern is an architecture that classifies input and routes it to specialized agents. Unlike the Subagents pattern, Router distributes queries via a dedicated classification step (either a single LLM call or rule-based logic).

#image("../../assets/images/router_fanout_fanin.png")

=== Pipeline

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[steps],
  text(weight: "bold")[Role],
  text(weight: "bold")[implementation],
  [_Classification_],
  [Analyze queries to create related sources and subqueries],
  [`with_structured_output(QueryClassification)`],
  [_Parallel Dispatch_],
  [Deliver subqueries to each classified source simultaneously],
  [`Send` API],
  [_Result synthesis (Reduction)_],
  [Gather all agent results to create a unified response],
  [Reducer node + LLM],
)

=== Router vs. Subagents Comparison

Routers have a “dedicated routing stage (classification),” while Subagents have “supervisor agents dynamically” deciding what to call. Router is suitable when distinct knowledge domains (verticals) are clearly distinguished and parallel queries are required.

=== Architecture Mode

- _Stateless_: Each request is routed independently (no memory)
- _Stateful_: Supports multi-turn interactions by maintaining conversation history. An alternative is to wrap a stateless router with tool, or have the router itself manage the state directly.

== 3.8 RouterState and classification schema

`QueryClassification` is a Pydantic model, which classifies queries into a structured form through LLM's `with_structured_output()`. `RouterState` tracks classification results, source lists, subqueries, and agent results.

Key fields in the classification schema:
- `sources`: Which knowledge sources are relevant (multiple choices possible)
- `reasoning`: Explain why you selected the source
- `sub_queries`: Subquery optimized for each source (original query reorganized for each source)

#code-block(`````python
from pydantic import BaseModel, Field
from typing import Literal

class SubQuery(BaseModel):
    """Subqueries by source."""
    source: Literal["github", "notion", "slack"] = Field(description="Knowledge source.")
    query: str = Field(description="Search queries optimized for that source.")

class QueryClassification(BaseModel):
    """Classification results from user queries."""
    sources: list[Literal["github", "notion", "slack"]] = Field(
        description="Related knowledge sources."
    )
    reasoning: str = Field(description="Why you chose that source.")
    sub_queries: list[SubQuery] = Field(description="Subqueries by source.")
`````)

#code-block(`````python
from langchain.agents import AgentState

class RouterState(AgentState):
    classification: QueryClassification = None
    sources: list[str] = []
    sub_queries: list[SubQuery] = []
    agent_results: list[dict] = []
`````)

== 3.9 Classification Node

`with_structured_output` classifies queries by source and creates subqueries optimized for each source.

=== Classification example

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[user query],
  text(weight: "bold")[Category Source],
  text(weight: "bold")[Reason],
  ["How to deploy the auth service"],
  [`["github", "notion"]`],
  [Distribution code exists on GitHub, procedure documentation exists on Notion],
  ["How the decision was made to change the API"],
  [`["slack", "notion"]`],
  [Discussions are recorded in Slack, decision documents are recorded in Notion],
  [“Login bug PR”],
  [`["github"]`],
  [PR only exists on GitHub],
  [“Onboarding Process and Starter Repo”],
  [`["github", "notion", "slack"]`],
  [Repo is GitHub, process is Notion, context is Slack],
)

Subquery creation is important: optimize the original query “auth service deployment” to `"auth service deployment scripts CI/CD pipeline"` for GitHub and `"auth service deployment process procedure runbook"` for Notion, respectively.

== 3.10 Parallel Routing (Send API)

The `Send` API dispatches subqueries to each classified source simultaneously. In the form of `Send(node_name, payload)`, data is passed in parallel to specific nodes in the graph.

This parallel execution is the core strength of the Router pattern: sequentially querying multiple knowledge sources adds up the latency, but parallel execution via `Send` takes only as long as the response time of the slowest source.

=== Add new source

The Router pattern is simple to extend:
+ Define source-specific tool
+ Create a professional agent
+ Add new source to `QueryClassification.sources`
+ Add agent nodes to the graph
+ Connect to Reducer

#code-block(`````python
from langchain_core.tools import tool
from langchain.agents import create_agent

@tool
def search_github_code(query: str) -> str:
    """Search the GitHub repository."""
    return f"GitHub result for '{query}'"

@tool
def search_notion_pages(query: str) -> str:
    """Search for your Notion workspace."""
    return f"Notion result for '{query}'"
`````)

#code-block(`````python
@tool
def search_slack_messages(query: str) -> str:
    """Search for Slack messages."""
    return f"Slack result for '{query}'"
`````)

#code-block(`````python
github_agent = create_agent(
    model="gpt-4.1", tools=[search_github_code],
    system_prompt="Search for code and PRs on GitHub.",
    name="github_agent",
)
notion_agent = create_agent(
    model="gpt-4.1", tools=[search_notion_pages],
    system_prompt="Search documents in Notion.",
    name="notion_agent",
)
`````)

#code-block(`````python
slack_agent = create_agent(
    model="gpt-4.1", tools=[search_slack_messages],
    system_prompt="Search for discussions in Slack.",
    name="slack_agent",
)
`````)

#code-block(`````python
from langgraph.types import Send

def dispatch_to_agents(state):
    """Subqueries are passed to agents in parallel."""
    cls = state["classification"]
    sq_dict = {sq.source: sq.query for sq in cls.sub_queries}
    return [
        Send(src, {"messages": [{"role": "user", "content": sq_dict.get(src, "")}], "source": src})
        for src in cls.sources
    ]
`````)

== 3.11 Result synthesis

Reducer collects the results from all agents and uses LLM to synthesize an integrated response. When synthesizing, the source of each information is cited so that the user can determine where the information came from.

The synthesis prompt instructs you to indicate the source. For example, respond with "The deployment script is in the `payment-service` repo on GitHub (GitHub), and for deployment procedures, please refer to Notion's 'Payment Service Ops' document (Notion)."

#code-block(`````python
from langgraph.graph import StateGraph, START, END

graph = StateGraph(RouterState)
graph.add_node("router", route_query)
graph.add_node("github", github_agent)
graph.add_node("notion", notion_agent)
graph.add_node("slack", slack_agent)
graph.add_node("reducer", reduce_results)
`````)

#code-block(`````python
graph.add_edge(START, "router")
graph.add_conditional_edges("router", dispatch_to_agents)
graph.add_edge("github", "reducer")
graph.add_edge("notion", "reducer")
graph.add_edge("slack", "reducer")
graph.add_edge("reducer", END)

app = graph.compile()
`````)

== Summary

=== Part A — Handoffs

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[core],
  [_Pattern_],
  [Single agent + `current_step` based dynamic configuration],
  [_Transition_],
  [`Command(update={"current_step": "next"})`],
  [_Dynamic Configuration_],
  [prompt with `\@wrap_model_call` + replace tool],
)

=== Part B — Router

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[core],
  [_Category_],
  [`with_structured_output(QueryClassification)`],
  [_Parallel_],
  [`Send(source, payload)` API],
  [_Synthesis_],
  [LLM integrated response from reducer node],
)

=== Next Steps
→ _#link("./04_context_memory.ipynb")[04_context_memory.ipynb]_: Learn context engineering and memory.
