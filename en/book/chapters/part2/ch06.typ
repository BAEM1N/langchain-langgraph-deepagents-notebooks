// Auto-generated from 06_middleware.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Middleware and Guardrails")

Learn the _middleware_ system and _guardrails_ used by LangChain v1 agents.


== Learning Objectives

- _Middleware concepts:_ Understand how to add hooks to each stage of the agent execution pipeline
- _Built-in middleware:_ Use built-in middleware such as `SummarizationMiddleware`
- _Custom middleware:_ Implement custom middleware with `@before_model`, `@after_model`, `@wrap_model_call`, and `@dynamic_prompt`
- _Guardrails:_ Learn how to block unsafe input and output


== 6.1 Environment Setup


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

== 6.2 Middleware Concepts

Middleware is the mechanism that _adds hooks to each stage of the agent execution pipeline_ so you can control how the agent behaves.

#image("../../assets/images/middleware_pipeline.png")

_Five middleware hooks:_

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Hook],
  text(weight: "bold")[When it runs],
  text(weight: "bold")[Main Use Case],
  [`\@before_model`],
  [Before a model call],
  [Input validation, message editing, guardrails],
  [`\@after_model`],
  [After a model response],
  [Output logging, response filtering],
  [`\@wrap_model_call`],
  [Around a model call],
  [Retry, fallback, caching],
  [`\@wrap_tool_call`],
  [Around a tool call],
  [Control tool execution],
  [`\@dynamic_prompt`],
  [During prompt creation],
  [Runtime prompt changes],
)


== 6.3 Built-In Middleware

LangChain v1 provides _built-in middleware_ for common patterns. `SummarizationMiddleware` automatically summarizes earlier messages when a conversation becomes long, reducing token usage.


#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def search(query: str) -> str:
    """Searches for information."""
    return f"'{query}'search result for"

# SummarizationMiddleware — automatically summarizes long conversations
from langchain.agents.middleware import SummarizationMiddleware

summarization = SummarizationMiddleware(
    model=model,
    trigger=("messages", 10),
)

agent_with_summary = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant.",
    middleware=[summarization],
)
print("SummarizationMiddleware agent created")
`````)

== 6.4 Custom Middleware: `\@before_model`

The `@before_model` decorator runs _before the model is called_.

Common uses:
- Logging input messages
- Modifying or filtering messages
- Input validation (guardrails)
- Adding context


#code-block(`````python
from langchain.agents.middleware import before_model

@before_model
def log_model_input(state, runtime):
    """Logs messages before sending them to the model."""
    msg_count = len(state["messages"])
    print(f"  Model input: {msg_count} messages")

agent_logged = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant.",
    middleware=[log_model_input],
)

print("Model-call logging test:")
result = agent_logged.invoke(
    {"messages": [{"role": "user", "content": "Please search for a Python tutorial"}]},
    config=lf_config,
)
print("Response:", result["messages"][-1].content[:200])
`````)

== 6.5 Custom Middleware: `\@after_model`

The `@after_model` decorator runs _after the model response has been generated_.

Common uses:
- Logging model output
- Filtering or modifying responses
- Monitoring tool calls
- Validating output quality


#code-block(`````python
from langchain.agents.middleware import after_model

@after_model
def log_model_output(state, runtime):
    """Logs model output after it is generated."""
    msg = state["messages"][-1] if state["messages"] else None
    if msg and hasattr(msg, 'content') and msg.content:
        print(f"  Model output: {msg.content[:100]}...")
    if msg and hasattr(msg, 'tool_calls') and msg.tool_calls:
        print(f"  Tool calls: {[tc['name'] for tc in msg.tool_calls]}")

agent_full_log = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant.",
    middleware=[log_model_input, log_model_output],
)

print("Full logging test:")
result = agent_full_log.invoke(
    {"messages": [{"role": "user", "content": "Please search for LangChain v1 features"}]},
    config=lf_config,
)
`````)

== 6.6 `\@wrap_model_call`

The `@wrap_model_call` decorator _wraps the model call itself_, which lets you implement retry, fallback, caching, and similar patterns.

You execute the original model call through the `handler` function and can add custom logic before or after it.


#code-block(`````python
from langchain.agents.middleware import wrap_model_call
import time

@wrap_model_call
def retry_on_error(request, handler):
    """Retries model calls with exponential backoff on failure."""
    max_retries = 2
    for attempt in range(max_retries + 1):
        try:
            return handler(request)
        except Exception as e:
            if attempt < max_retries:
                wait = 2 ** attempt
                print(f"  Retry {attempt + 1}/{max_retries} ({wait}s wait)")
                time.sleep(wait)
            else:
                raise

agent_retry = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant.",
    middleware=[retry_on_error],
)
print("Retry middleware agent created")
`````)

== 6.7 `\@dynamic_prompt`

The `@dynamic_prompt` decorator _changes the system prompt dynamically at runtime_.

Common uses:
- Adding the current date and time
- Per-user prompt customization
- Changing behavior based on state
- A/B testing


#code-block(`````python
from langchain.agents.middleware import dynamic_prompt
from datetime import datetime

@dynamic_prompt
def add_datetime_context(request):
    """Adds the current date and time to the system prompt."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return f"Current date and time: {now}\n\nYou are a helpful assistant."

agent_dynamic = create_agent(
    model=model,
    tools=[search],
    middleware=[add_datetime_context],
)

result = agent_dynamic.invoke(
    {"messages": [{"role": "user", "content": "What are the current date and time?"}]},
    config=lf_config,
)
print("Dynamic prompt response:", result["messages"][-1].content)
`````)

== 6.8 `\@wrap_tool_call`

The `@wrap_tool_call` decorator _wraps a tool call itself_, so you can add custom logic before and after tool execution.

Like `@wrap_model_call`, it uses a `handler` function to run the original tool. You can use it for timing, logging, and error handling.

Common uses:
- _Measuring execution time:_ monitor performance by tool
- _Logging:_ record tool input and output
- _Error handling:_ apply fallback behavior if a tool fails
- _Access control:_ block or restrict specific tools


#code-block(`````python
from langchain.agents.middleware import wrap_tool_call
import time

@wrap_tool_call
def tool_timing_logger(request, handler):
    """Measures execution time and logs tool inputs/outputs."""
    tool_name = request.tool_call["name"]
    tool_args = request.tool_call["args"]
    print(f"  [Tool start] {tool_name} | Input: {tool_args}")

    start = time.perf_counter()
    try:
        result = handler(request)
        elapsed = time.perf_counter() - start
        print(f"  [Tool complete] {tool_name} | Elapsed: {elapsed:.3f}s | Output: {str(result)[:100]}")
        return result
    except Exception as e:
        elapsed = time.perf_counter() - start
        print(f"  [Tool failed] {tool_name} | Elapsed: {elapsed:.3f}s | Error: {e}")
        raise

agent_tool_logged = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant. Use the search tool to find information.",
    middleware=[tool_timing_logger],
)

print("Tool timing/logging middleware test:")
result = agent_tool_logged.invoke(
    {"messages": [{"role": "user", "content": "Please search for LangChain middleware documentation"}]},
    config=lf_config,
)
print("\nFinal response:", result["messages"][-1].content[:200])
`````)

== 6.9 Simple Guardrails

Middleware can also act as a lightweight guardrail. In the example below, a `before_model` hook blocks requests that contain prohibited keywords before the model is called.


#code-block(`````python
# Keyword-based guardrail
@before_model
def keyword_guardrail(state, runtime):
    """Blocks requests that contain prohibited keywords."""
    prohibited = ["hack", "exploit", "malware"]
    last_msg = state["messages"][-1]
    content = last_msg.content if hasattr(last_msg, 'content') else str(last_msg)

    for keyword in prohibited:
        if keyword.lower() in content.lower():
            raise ValueError(f"The request was blocked by the safety policy.")

agent_guarded = create_agent(
    model=model,
    tools=[search],
    system_prompt="You are a helpful assistant.",
    middleware=[keyword_guardrail],
)

# Safe request
result = agent_guarded.invoke(
    {"messages": [{"role": "user", "content": "Please search for a Python tutorial"}]},
    config=lf_config,
)
print("Safe request:", result["messages"][-1].content[:100])

# Blocked request
try:
    result = agent_guarded.invoke(
        {"messages": [{"role": "user", "content": "How to hack a website"}]}
    )
except ValueError as e:
    print(f"Blocked request: {e}")
`````)

== 6.10 Summary

This notebook covered:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Core API],
  text(weight: "bold")[Description],
  [Built-in middleware],
  [`SummarizationMiddleware`],
  [Automatically summarizes long conversations],
  [Before-model hook],
  [`\@before_model`],
  [Logs, validates, or modifies input before model execution],
  [After-model hook],
  [`\@after_model`],
  [Logs or validates model output after generation],
  [Wrapped model call],
  [`\@wrap_model_call`],
  [Adds retry, fallback, or caching around model calls],
  [Dynamic prompt],
  [`\@dynamic_prompt`],
  [Changes the system prompt at runtime],
  [Wrapped tool call],
  [`\@wrap_tool_call`],
  [Adds logging, timing, and control around tool execution],
  [Guardrails],
  [`\@before_model` and middleware],
  [Blocks unsafe or disallowed input],
)

=== Next Steps
→ _#link("./07_hitl_and_runtime.ipynb")[07_hitl_and_runtime.ipynb]_: Learn about human-in-the-loop, runtime context, and MCP.
