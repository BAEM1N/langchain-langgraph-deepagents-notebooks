// Auto-generated from 02_multi_agent_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Multiagents: Subagents", subtitle: "Supervisor pattern")

== Learning Objectives

- Design a three-tier architecture of Supervisor → subagent → tool
- Wrap subagent with `@tool` and expose it to supervisors as tool
- Understand HITL, ToolRuntime, and asynchronous/dispatch patterns.

== 2.1 Environment Setup

The Subagents pattern is a multi-agent architecture in which a central supervisor agent delegates tasks by calling specialized subagents like tool. On this laptop, we build a personal assistant system that handles calendars and email domains.

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 2.2 Subagents Architecture Overview

The Subagents pattern consists of a _three-tier architecture_. The supervisor is responsible for all routing, subagent does not interact directly with the user, and returns results to the supervisor.

#image("../../assets/images/supervisor_subagents.png")

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[tier],
  text(weight: "bold")[Role],
  text(weight: "bold")[Features],
  [_Low Level tool_],
  [Direct call to external service (Calendar API, Email API)],
  [Simple function wrapper],
  [_subagent_],
  [Domain-specific inference + tool combination],
  [Expert system prompt, independent tool set],
  [_Supervisor_],
  [Decompose tasks, delegate, and aggregate results],
  [Remember entire conversation, treat subagent = tool],
)

=== Core Traits

- _Centralized Control_: All routing flows through the supervisor
- _Context Isolation_: subagent runs in a clean context window every time, preventing context bloat.
- _Parallel execution_: Multiple subagent can be called simultaneously in one turn
- _tool based calls_: Wrap subagent with `@tool` and expose it to the supervisor like a regular tool

=== When to use

The subagent pattern is suitable when you manage multiple domains (calendar, email, CRM, etc.), but subagent does not need to interact directly with users, and you need centralized workflow management. For simple scenarios with few tool, a single agent is sufficient.

== 2.3 Low-level tool definitions

Defines the low-level tool, the bottom layer of the three-tier architecture. These tool are simple function wrappers that interact directly with external services (Calendar API, Email API). In actual production, it integrates with Google Calendar API, Email Service, etc., but here we use a stub implementation for learning.

Important points when designing tool:
- One tool is responsible for only one function (single responsibility principle)
- The same tool should not be assigned redundantly to multiple subagent
- Write the docstring clearly so that LLM can select tool correctly

#code-block(`````python
from langchain_core.tools import tool

@tool
def create_calendar_event(
    title: str, start_time: str, end_time: str,
    attendees: list[str] = None,
) -> str:
    """Create a new calendar event."""
    return f"Event '{title}' created: {start_time} ~ {end_time}"
`````)

#code-block(`````python
@tool
def read_calendar_events(date: str) -> str:
    """Look up calendar events for a date (YYYY-MM-DD)."""
    return f"No events found on {date}."
`````)

#code-block(`````python
@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Send an email message."""
    return f"Email sent to {to}: '{subject}'"

@tool
def read_emails(folder: str = "inbox", limit: int = 10) -> str:
    """Read recent emails from a folder."""
    return f"3 emails found in {folder}"
`````)

#code-block(`````python
@tool
def search_emails(query: str, limit: int = 10) -> str:
    """Search for emails with your search term."""
    return f"2 search results for '{query}'"
`````)

== 2.4 Create subagent

Each subagent is created by `create_agent()` and has three core elements:

+ _Specialized system prompts_: Define domain-specific roles and behavioral guidelines
+ _Set tool by domain_: Separate concerns by assigning only tool for that domain
+ *`name` identifier*: used by the supervisor to identify and call a subagent

The recommended granularity of subagent is domain-level (calendar, email, etc.). Too much granularity increases the routing burden on the supervisor, while too much integration reduces the benefits of context isolation.

#code-block(`````python
from langchain.agents import create_agent

calendar_agent = create_agent(
    model="gpt-4.1",
    tools=[create_calendar_event, read_calendar_events],
    system_prompt="You are a calendar assistant. Use ISO 8601 date format.",
    name="calendar_agent",
)
`````)

#code-block(`````python
email_agent = create_agent(
    model="gpt-4.1",
    tools=[send_email, read_emails, search_emails],
    system_prompt="You are an email assistant. Write your message professionally.",
    name="email_agent",
)
`````)

== 2.5 Wrapping subagent with tool

The standard pattern for exposing subagent to a supervisor is to wrap it with a `@tool` decorator. Inside the wrapping function, call `subagent.invoke()` and return `content` of the last message.

Advantages of this pattern:
- From the supervisor’s perspective, subagent is treated the same as regular tool
- Changes to the internal implementation of subagent do not affect the supervisor.
- The input/output format can be freely customized in the wrapping function.

_Choose an input/output strategy_: You can pass just the query (simple) or the entire context (sophisticated). When returning results, you have the option of returning only the final result or returning the entire history.

== 2.6 Supervisor Agent Assembly

The supervisor is created by passing the wrapped subagent tool to `tools`. The supervisor's system prompts include task decomposition and delegation instructions.

Supervisor design considerations:
- _Error handling_: subagent failures must be handled gracefully by the supervisor.
- _Result Aggregation_: Consolidates results from multiple subagent to provide consistent responses to users
- _Approval Scope_: Applies HITL only to operations that change the state (sending an email, creating an event)

#code-block(`````python
supervisor = create_agent(
    model="gpt-4.1",
    tools=[call_calendar, call_email],
    system_prompt=(
        "You are a personal assistant. complex request"
        "Decompose it into subtasks and delegate them to appropriate agents."
    ),
)
`````)

== 2.7 Run test

#code-block(`````python
User: "Schedule a meeting with Sarah tomorrow at 2 PM and send the invitation email"
Supervisor → call_calendar → create_calendar_event
Supervisor → call_email → send_email
Supervisor: "The meeting and invitation email are complete"
`````)

== 2.8 HITL (Human-in-the-Loop) Integration

Combining `HumanInTheLoopMiddleware` and `checkpointer` allows you to request user approval before high-risk tool calling (sending emails, creating schedules, etc.). When the agent attempts to call a protected tool, execution is paused and reviewed by the user.

=== Authorization response type

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Reply],
  text(weight: "bold")[Description],
  text(weight: "bold")[code],
  [_Approve_],
  [Run tool calling as is],
  [`Command(resume="approve")`],
  [_Edit_],
  [Execute after modifying tool argument],
  [`Command(resume={"type": "edit", "args": {...}})`],
  [_Reject_],
  [Cancel tool calling],
  [`Command(resume={"type": "reject", "reason": "..."})`],
)

It is recommended to apply HITL only to operations that change state (send_email, create_calendar_event, etc.). It is not applied to read-only operations to reduce unnecessary friction.

#code-block(`````python
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

hitl = HumanInTheLoopMiddleware(interrupt_on={
    "schedule_event": {"allowed_decisions": ["approve", "edit", "reject"]},
    "manage_email": {"allowed_decisions": ["approve", "reject"]},
})
`````)

#code-block(`````python
supervisor_hitl = create_agent(
    model="gpt-4.1",
    tools=[call_calendar, call_email],
    checkpointer=InMemorySaver(),
    middleware=[hitl],
    system_prompt="You are a personal assistant.",
)
`````)

== 2.9 Passing context (ToolRuntime)

`ToolRuntime` is a mechanism for passing runtime context (user ID, name, time zone, etc.) to tool without including it in the message. Instead of putting repetitive text in every prompt, you set the shared context with `ToolRuntime` just once.

The tool function accesses the context with the `runtime_context` keyword argument. Through this:
- User identity information may be used by tool (e.g. to automatically set sender email)
- Environment Setup (time zone, etc.) can be applied consistently
- Reduce token cost by reducing prompt length

#code-block(`````python
# ToolRuntime is the runtime context passing mechanism for LangChain v1 agents.
# This is a fallback in case it hasn't been released yet.
try:
    from langchain.runtime import ToolRuntime
except ImportError:
    # Simple fallback implementation if ToolRuntime is not yet released
    class ToolRuntime:
        """Fallback ToolRuntime for pre-release versions."""
        def __init__(self, context: dict):
            self.context = context
    print("ToolRuntime unreleased — use fallback stub")

runtime = ToolRuntime(context={
    "user_email": "me@example.com",
    "user_name": "Alice",
    "timezone": "Asia/Seoul",
})
`````)

#code-block(`````python
supervisor_ctx = create_agent(
    model="gpt-4.1",
    tools=[call_calendar, call_email],
    system_prompt="You are a personal assistant.",
)
`````)

#code-block(`````python
# Accessing runtime context in tool
@tool
def send_email_ctx(
    to: str, subject: str, body: str, *, runtime_context: dict
) -> str:
    """Send an email to the current user."""
    sender = runtime_context["user_email"]
    return f"Email sent from {sender} to {to}: '{subject}'"
`````)

== 2.10 Asynchronous execution pattern

subagent has two execution modes:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mode],
  text(weight: "bold")[Action],
  text(weight: "bold")[When to use],
  [_Synchronous_],
  [Supervisor waits for subagent completion and then proceeds],
  [When results are needed for next operation (default)],
  [_Asynchronous_],
  [Return Job ID immediately, run in background, view results later],
  [Independent work, long-time work],
)

Asynchronous patterns follow the structure _Job ID → Status → Result_. If subagent returns the Job ID immediately, the supervisor can continue working on other tasks and retrieve the results later.

#code-block(`````python
import uuid
job_store = {}

@tool("schedule_async", description="Event scheduling (asynchronous)")
def call_calendar_async(query: str) -> str:
    """Starts an asynchronous calendar task and returns the task ID."""
    job_id = str(uuid.uuid4())[:8]
    job_store[job_id] = {"status": "done", "result": "Event created"}
    return f"Job started: {job_id}"
`````)

#code-block(`````python
@tool("check_job", description="Check status of asynchronous task")
def check_job(job_id: str) -> str:
    """Check the status of an asynchronous operation."""
    job = job_store.get(job_id, {"status": "not_found"})
    return f"Status: {job['status']}, result: {job.get('result')}"
`````)

== 2.11 Single Dispatch tool Pattern

There are two approaches to the tool pattern:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[pattern],
  text(weight: "bold")[Description],
  text(weight: "bold")[Advantages],
  [_By agent tool_],
  [Create a separate wrapping tool for each subagent],
  [Detailed control, easy description customization],
  [_Single Dispatch tool_],
  [Call all subagent with one parameterized tool],
  [Excellent scalability, independent addition/removal of subagent],
)

The single dispatch pattern specifies the target of the call with the `agent_name` parameter. Because subagent registered in the agent registry is called by looking up its name, subagent can be added or removed independently in distributed teams, providing excellent scalability.

#code-block(`````python
supervisor_dispatch = create_agent(
    model="gpt-4.1",
    tools=[dispatch],
    system_prompt=(
        "Use delegate tool to route work."
        "Agent: 'calendar', 'email'."
    ),
)
`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[core],
  [_Tier 3_],
  [tool → subagent(`create_agent`) → Supervisor],
  [_Wrapping_],
  [`\@tool` + `subagent.invoke()` → Return last content],
  [_Quarantine_],
  [subagent = clean context, only supervisor remembers full],
  [_HITL_],
  [`HumanInTheLoopMiddleware` + `InMemorySaver`],
  [_Context_],
  [`ToolRuntime(context={...})` → `runtime_context`],
  [_Asynchronous_],
  [Job ID → Status → Result pattern],
  [_Dispatch_],
  [Single `dispatch(agent_name, query)` tool],
)

=== Next Steps
→ _#link("./03_multi_agent_handoffs_router.ipynb")[03_multi_agent_handoffs_router.ipynb]_: Learn Handoffs and Router patterns.
