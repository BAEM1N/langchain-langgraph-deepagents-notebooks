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
    model="gpt-4.1",
)

print("Model ready:", model.model_name)
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


== 6.5 Custom Middleware: `\@after_model`

The `@after_model` decorator runs _after the model response has been generated_.

Common uses:
- Logging model output
- Filtering or modifying responses
- Monitoring tool calls
- Validating output quality


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


== 6.8 `\@wrap_tool_call`

The `@wrap_tool_call` decorator _wraps a tool call itself_, so you can add custom logic before and after tool execution.

Like `@wrap_model_call`, it uses a `handler` function to run the original tool. You can use it for timing, logging, and error handling.

Common uses:
- _Measuring execution time:_ monitor performance by tool
- _Logging:_ record tool input and output
- _Error handling:_ apply fallback behavior if a tool fails
- _Access control:_ block or restrict specific tools


== 6.9 Simple Guardrails

Middleware can also act as a lightweight guardrail. In the example below, a `before_model` hook blocks requests that contain prohibited keywords before the model is called.


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

