// Auto-generated from 07_hitl_and_runtime.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Human", subtitle: "in-the-Loop, ToolRuntime, and MCP")

Learn how LangChain v1 handles _human approval workflows_, _runtime context inside tools_, _context engineering_, and _MCP (Model Context Protocol)_.


== Learning Objectives

This notebook covers:
- _Human-in-the-Loop (HITL):_ how to pause agent execution and request approval before a tool call
- _ToolRuntime:_ how tools can access runtime context such as user information and session data
- _Context engineering:_ techniques for dynamically controlling prompts and tools
- _MCP (Model Context Protocol):_ a standardized way to connect tool servers


== 7.1 Environment Setup


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

== 7.2 Human-in-the-Loop Concepts

Ask for human approval before the agent calls a tool.

=== Why is this needed?

Autonomous agents are powerful, but _irreversible actions_ such as sending email, deleting files, or processing payments still require human confirmation.

=== Workflow

#code-block(`````python
Agent → proposes a tool call → [interrupt] → human approves/rejects → tool runs → result is returned
`````)

In LangChain v1, this is implemented by combining `HumanInTheLoopMiddleware` with `InMemorySaver` (a checkpointer). The checkpointer stores the agent state so the workflow can resume after interruption.


== 7.3 `HumanInTheLoopMiddleware`

`HumanInTheLoopMiddleware` automatically pauses execution on tool calls and waits for human approval. Use it with an `InMemorySaver` checkpointer so interrupted state can be preserved.


#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import InMemorySaver

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """Sends an email to the specified recipient."""
    return f"{to} email sent to: {subject}"

@tool
def delete_file(path: str) -> str:
    """Deletes a file at the specified path."""
    return f"File deleted: {path}"

# Require approval only for risky tools
hitl = HumanInTheLoopMiddleware(interrupt_on={
    "send_email": True,
    "delete_file": True,
})

agent = create_agent(
    model=model,
    tools=[send_email, delete_file],
    system_prompt="You are an assistant that can send emails and manage files.",
    middleware=[hitl],
    checkpointer=InMemorySaver(),
)

print("HITL agent created")
print("  -> The run pauses for human approval before executing tools")
`````)

== 7.4 The `interrupt` and `Command(resume=...)` Pattern

A HITL agent works in two phases:

+ *Phase 1 (`invoke`):* the agent proposes a tool call and is automatically *interrupted*
+ *Phase 2 (`Command(resume=True)`):* after a human approves, execution *resumes* with `Command(resume=True)`

To reject a request, use `Command(resume=False)` or provide a different decision.


== 7.5 `ToolRuntime` — Access Runtime Information from a Tool

`ToolRuntime` lets a tool access runtime context such as the current user or session data while it executes.

=== Core idea
- Add a `runtime: ToolRuntime[T]` parameter to the tool function
- `T` is a context dataclass defined by the developer
- When you create the agent, set `context_schema=T`, and when invoking the agent, pass `context=T(...)`


== 7.6 Context Engineering — Dynamic Control of Prompts and Tools

Context engineering is the practice of dynamically shaping the _prompt_, _available tools_, and _message history_ given to the agent.

=== Common use cases
- Provide a different system prompt depending on user role
- Filter the available tools depending on the situation
- Summarize and reorganize long conversation histories

The `dynamic_prompt` middleware makes it possible to customize the prompt for every request.


== 7.7 MCP (Model Context Protocol) Integration Overview

_MCP_ is a standardized way to connect tool servers.

=== Core MCP concepts
- _MCP server_: provides tools through HTTP/SSE or stdio
- _MCP client_: connects to the server and discovers or calls tools
- _Standardization_: any tool can be connected as long as it follows the MCP protocol

=== MCP support in LangChain v1
- You can connect to a local MCP server with `mcp.client.stdio.stdio_client()` and `ClientSession`
- `load_mcp_tools(session)` from `langchain-mcp-adapters` converts MCP session tools into LangChain tools


== 7.8 Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Concept],
  text(weight: "bold")[Description],
  text(weight: "bold")[Core API],
  [_HITL_],
  [Requests human approval before tool execution],
  [`HumanInTheLoopMiddleware`, `Command(resume=...)`],
  [_ToolRuntime_],
  [Gives tools access to runtime context],
  [`ToolRuntime[T]`, `context_schema`],
  [_Context engineering_],
  [Dynamically controls prompts and tools],
  [`dynamic_prompt` middleware],
  [_MCP_],
  [Standardized tool protocol],
  [`ClientSession + load_mcp_tools()`],
)

=== Next Steps
- The next notebook introduces _multi-agent patterns_.
- You will explore Subagents, Handoffs, Skills, Routers, and other collaboration patterns.

