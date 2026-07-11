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
    model="gpt-5.4",
)

print("Model ready:", model.model_name)
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

@tool
def ask_user(question: str) -> str:
    """Ask the user for information needed to continue."""
    return "No response provided"

hitl = HumanInTheLoopMiddleware(interrupt_on={
    "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
    "delete_file": {"allowed_decisions": ["approve", "reject"]},
    "ask_user": {"allowed_decisions": ["respond"]},
})

agent = create_agent(
    model=model,
    tools=[send_email, delete_file, ask_user],
    system_prompt="Review side effects and call ask_user when information is missing.",
    middleware=[hitl],
    checkpointer=InMemorySaver(),
)

print("HITL agent created")
print("  -> Reject denied side effects; respond only to ask_user prompts.")
`````)

== 7.4 The `interrupt` and `Command(resume=...)` Pattern

A HITL agent pauses at a tool call and resumes with a decision dictionary:

+ _Phase 1 (`invoke(..., version="v2")`)_: the agent proposes a tool call and is interrupted
+ _Phase 2_: resume with `Command(resume={"decisions": [...]})` on the same `thread_id`

Use `reject` to deny email, file, or SQL side effects. Use `respond` only when the human acts as an `ask_user` tool; its message is treated as a successful tool result.


#code-block(`````python
from langgraph.types import Command

config = {"configurable": {"thread_id": "hitl-demo"}}

# Step 1: run the agent -> pause at the tool call
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Please send an email to bob@example.com with the subject 'Greeting' and the body 'Hello Bob!'"}]},
    config={**config, **lf_config},
    version="v2",
)

# Check the interrupted state
print("Interrupts:", result.interrupts)
print("\nThe agent paused before executing the tool.")
print("Resume with an ordered decisions list.")

# Step 2: approve and continue
try:
    result = agent.invoke(
        Command(resume={"decisions": [{"type": "approve"}]}),
        config={**config, **lf_config}, version="v2",
    )
    print("\nResult after approval:", result.value["messages"][-1].content)
except Exception as e:
    print(f"\nNote: the HITL demo works best in an interactive environment. ({e})")
`````)

== 7.5 `ToolRuntime` — Access Runtime Information from a Tool

`ToolRuntime` lets a tool access runtime context such as the current user or session data while it executes.

=== Core idea
- Add a `runtime: ToolRuntime[T]` parameter to the tool function
- `T` is a context dataclass defined by the developer
- When you create the agent, set `context_schema=T`, and when invoking the agent, pass `context=T(...)`


#code-block(`````python
from langchain.tools import ToolRuntime
from dataclasses import dataclass

@dataclass
class UserContext:
    """Runtime context that includes user information."""
    user_id: str
    role: str

@tool
def get_user_profile(runtime: ToolRuntime[UserContext]) -> str:
    """Fetches the current user profile information."""
    ctx = runtime.context
    return f"User ID: {ctx.user_id}, role: {ctx.role}"

@tool
def check_permissions(action: str, runtime: ToolRuntime[UserContext]) -> str:
    """Checks whether the current user has permission for the action."""
    ctx = runtime.context
    if ctx.role == "admin":
        return f"User {ctx.user_id} '{action}'has permission"
    return f"User {ctx.user_id} '{action}'does not have permission"

agent_ctx = create_agent(
    model=model,
    tools=[get_user_profile, check_permissions],
    system_prompt="You can inspect user profiles and permissions.",
    context_schema=UserContext,
)

result = agent_ctx.invoke(
    {"messages": [{"role": "user", "content": "Who am I, and can I delete files?"}]},
    context=UserContext(user_id="user-42", role="admin"),
    config=lf_config,
)
print("Result:", result["messages"][-1].content)
`````)

== 7.6 Context Engineering — Dynamic Control of Prompts and Tools

Context engineering is the practice of dynamically shaping the _prompt_, _available tools_, and _message history_ given to the agent.

=== Common use cases
- Provide a different system prompt depending on user role
- Filter the available tools depending on the situation
- Summarize and reorganize long conversation histories

The `dynamic_prompt` middleware makes it possible to customize the prompt for every request.


#code-block(`````python
from langchain.agents.middleware import dynamic_prompt

@tool
def basic_search(query: str) -> str:
    """Performs a basic web search."""
    return f"'{query}'basic search result for"

@tool
def advanced_analytics(query: str) -> str:
    """Performs advanced data analysis."""
    return f"'{query}'analysis report for"

# Provide different prompts and tools based on the user's role
@dynamic_prompt
def role_based_prompt(request):
    """Customizes the prompt based on the context."""
    return "You are a specialist assistant. Answer the user efficiently."

agent_ctx_eng = create_agent(
    model=model,
    tools=[basic_search, advanced_analytics],
    middleware=[role_based_prompt],
)

result = agent_ctx_eng.invoke(
    {"messages": [{"role": "user", "content": "Please search for machine learning trends"}]},
    config=lf_config,
)
print("Context engineering result:", result["messages"][-1].content[:200])
`````)

== 7.7 MCP (Model Context Protocol) Integration Overview

_MCP_ is a standardized way to connect tool servers.

=== Core MCP concepts
- _MCP server_: provides tools through HTTP/SSE or stdio
- _MCP client_: connects to the server and discovers or calls tools
- _Standardization_: any tool can be connected as long as it follows the MCP protocol

=== MCP support in LangChain v1
- You can connect to a local MCP server with `mcp.client.stdio.stdio_client()` and `ClientSession`
- `load_mcp_tools(session)` from `langchain-mcp-adapters` converts MCP session tools into LangChain tools


#code-block(`````python
from pathlib import Path
import tempfile
import sys
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from langchain_mcp_adapters.tools import load_mcp_tools

server_path = Path(tempfile.gettempdir()) / "lc_mcp_echo_server.py"
server_path.write_text("""from mcp.server.fastmcp import FastMCP
mcp = FastMCP("echo")
@mcp.tool()
def echo(text: str) -> str:
    return f"Echo: {text}"
if __name__ == "__main__":
    mcp.run(transport="stdio")
""")

async def run_mcp_agent():
    params = StdioServerParameters(command=sys.executable, args=[str(server_path)])
    async with stdio_client(params) as (read, write), ClientSession(read, write) as session:
        await session.initialize()
        tools = await load_mcp_tools(session)
        agent = create_agent(model=model, tools=tools, system_prompt="You can use MCP tools.")
        return await agent.ainvoke(
            {"messages": [{"role": "user", "content": "Use the echo tool to repeat hello."}]},
            config=lf_config,
        )

result = await run_mcp_agent()
print(result["messages"][-1].content)

`````)

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
