// Auto-generated from 04_tools_and_structured_output.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Tools and Structured Output")

Learn how to build custom tools with the `@tool` decorator in LangChain v1 and how to receive structured responses with `with_structured_output()`.


== Learning Objectives

- Build tools with the `@tool` decorator and inspect their schemas
- Define complex input schemas with Pydantic models
- Connect tools to `create_agent()` and build an agent
- Access runtime context from inside a tool with `ToolRuntime`
- Configure structured output with `with_structured_output()`
- Understand the difference between `ToolStrategy` and `ProviderStrategy`


== 4.1 Environment Setup

#tip-box[Some examples in this chapter require _deepagents ≥ 0.5.0_ or _langgraph ≥ 1.1.5_, and the `ToolRuntime` `execution_info` / `server_info` extensions require _langchain ≥ 1.2_. Older versions raise `AttributeError`, so confirm with `uv pip list | grep -E "langchain|langgraph|deepagents"`.]

Load API keys and initialize an OpenAI model.


#code-block(`````python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv(override=True)

# Initialize the model with OpenAI
model = ChatOpenAI(
    model="gpt-5.4",
)

print("Model initialized:", model.model_name)
`````)

== 4.2 The Basics of the `\@tool` Decorator

When you add `@tool` to a function, it becomes a tool that an agent can use.
LangChain automatically parses the function name, docstring, and type hints to build the tool schema.

#code-block(`````python
from langchain.tools import tool

@tool
def my_tool(param: str) -> str:
    """Tool description for the LLM."""
    return result
`````)


#code-block(`````python
from langchain.tools import tool

@tool
def get_weather(city: str) -> str:
    """Look up the current weather for a city."""
    weather_data = {
        "Seoul": "Clear, 15\u00b0C",
        "Tokyo": "Cloudy, 12\u00b0C",
        "New York": "Rain, 8\u00b0C",
    }
    return weather_data.get(city, f"Weather data is not available for: {city}")

# Inspect the tool schema
print("Tool name:", get_weather.name)
print("Tool description:", get_weather.description)
print("Input schema:", get_weather.args_schema.model_json_schema())
`````)

== 4.3 Complex Schemas with Pydantic

If you need a richer input structure, define the schema with a Pydantic `BaseModel`.
When you pass it as `@tool(args_schema=MySchema)`, the LLM can understand the exact parameter structure.

- `Field(description=...)`: passes a field description to the LLM
- `Field(default=...)`: defines a default value


#code-block(`````python
from pydantic import BaseModel, Field

class SearchQuery(BaseModel):
    """Search parameters for a database query."""
    query: str = Field(description="Search query string")
    max_results: int = Field(default=5, description="Maximum number of results to return")
    category: str = Field(default="all", description="Search category: all, tech, science, news")

@tool(args_schema=SearchQuery)
def search_database(query: str, max_results: int = 5, category: str = "all") -> str:
    """Search the database with advanced filtering options."""
    return f"Found {max_results} results for '{query}' in the '{category}' category"

print("Complex schema:", search_database.args_schema.model_json_schema())
`````)

== 4.4 Connecting Tools to an Agent

When you pass a list of tools into `create_agent()`, the agent can automatically choose and execute the right tool for the situation.

#code-block(`````python
from langchain.agents import create_agent

agent = create_agent(
    model=model,
    tools=[tool1, tool2],
    system_prompt="...",
)
`````)

#note-box[_Note:_ In LangChain v1, `create_react_agent` was removed. Always use `create_agent`.]


== 4.5 ToolRuntime

`ToolRuntime` lets a tool function access the current conversation state at runtime.
This makes it possible to build tools that use message history, settings, or other runtime context.

#code-block(`````python
@tool
def my_tool(runtime: ToolRuntime) -> str:
    messages = runtime.state["messages"]
    # ...
`````)

==== `runtime.execution_info` — Execution Metadata

`ToolRuntime` exposes more than state access. The `execution_info` field carries metadata about the current execution unit and is heavily used for logging, tracing, and retry policies.

#code-block(`````python
@tool
def log_call(payload: str, runtime: ToolRuntime) -> str:
    """Process input and log execution metadata."""
    info = runtime.execution_info
    print(f"thread={info.thread_id} run={info.run_id} attempt={info.node_attempt}")
    return f"received: {payload}"
`````)

- `execution_info.thread_id`: session ID that groups a multi-turn conversation
- `execution_info.run_id`: ID of one `invoke()` / `stream()` run (linked to the LangSmith trace)
- `execution_info.node_attempt`: attempt count for the current node (increments on retries)

==== `runtime.server_info` — Server and User Info

When executed on LangGraph Platform or a LangSmith server, `runtime.server_info` identifies the deployed assistant and the calling user.

#code-block(`````python
@tool
def user_summary(runtime: ToolRuntime) -> str:
    """Return information about the current user."""
    s = runtime.server_info
    return f"assistant={s.assistant_id} user={s.user.email if s.user else 'anonymous'}"
`````)

- `server_info.assistant_id`: ID of the deployed assistant (graph version)
- `server_info.user`: authenticated user object (`user.id`, `user.email`, permissions)

#tip-box[`server_info` may be empty in local runs — it is populated only in deployed environments. Guard with `if runtime.server_info.user is not None:`.]

==== Tool Error Handling — `@wrap_tool_call`

To attach uniform error handling, logging, or retry policy to tool calls, use the `@wrap_tool_call` decorator. It receives a `ToolCallRequest` and acts as a middleware hook that intercepts tool execution.

#code-block(`````python
from langchain.tools import wrap_tool_call, ToolCallRequest
from langchain_core.messages import ToolMessage

@wrap_tool_call
def safe_invoke(request: ToolCallRequest, handler):
    """Wrap every tool call in try/except."""
    try:
        return handler(request)
    except Exception as exc:  # noqa: BLE001
        return ToolMessage(
            content=f"[error] {type(exc).__name__}: {exc}",
            tool_call_id=request.tool_call.id,
            status="error",
        )

agent = create_agent(
    model=model,
    tools=[get_weather, search_database],
    middleware=[safe_invoke],
)
`````)

#tip-box[`@wrap_tool_call` registers as middleware, so it applies to _every_ tool. Branch on `request.tool_call.name` if you need to guard only specific tools.]

==== `Command` Updates and Companion `ToolMessage`

When a tool needs to update _graph state_ or pick the _next node_ instead of returning plain text, return a `Command`. LangGraph applies `Command.update` to patch state and uses `Command.goto` to choose the next node. You must also return a `ToolMessage` that closes the `tool_call_id`, otherwise the model cannot proceed to the next turn.

#code-block(`````python
from langgraph.types import Command
from langchain_core.messages import ToolMessage

@tool
def transfer_to_specialist(topic: str, runtime: ToolRuntime) -> Command:
    """Hand control to a specialist sub-agent and update state."""
    return Command(
        update={
            "active_specialist": topic,
            "messages": [
                ToolMessage(
                    content=f"Routed to the {topic} specialist.",
                    tool_call_id=runtime.tool_call_id,
                )
            ],
        },
        goto="specialist_node",
    )
`````)

#tip-box[Omitting `tool_call_id` causes the model to error with "no response for tool call." Pull the current call ID from `runtime.tool_call_id` and pass it through verbatim.]


== 4.6 Structured Output

With `with_structured_output()`, you can receive the model's response directly as a Pydantic model or dataclass.
This pattern is used directly on the model, not through an agent.

#code-block(`````python
structured_model = model.with_structured_output(MySchema)
result = structured_model.invoke("...")
# result is an instance of MySchema
`````)


== 4.7 ToolStrategy vs ProviderStrategy

There are two main strategies for structured output inside an agent:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Strategy],
  text(weight: "bold")[Description],
  text(weight: "bold")[Advantage],
  [`ToolStrategy`],
  [Uses the tool-calling mechanism to produce structured output],
  [Works with every model and is stable],
  [`ProviderStrategy`],
  [Uses the provider's native structured-output feature],
  [Faster and more accurate when the model supports it],
)

Use the `response_format` parameter to structure the agent's final response.

#tip-box[`ProviderStrategy.strict=True` (schema enforcement) requires _langchain ≥ 1.2_. On older releases, use `strict=False` or `ToolStrategy`.]

#tip-box[`ProviderStrategy` is currently stable on OpenAI (`gpt-5.4`, `gpt-4.1`) and Anthropic (`claude-sonnet-4-6`). Google Gemini is _unofficially supported_: JSON mode works, but strict schema enforcement applies only to some models. Choose `ToolStrategy` when broad compatibility matters.]


== 4.8 Summary

Here is a summary of the main ideas in this notebook.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [`\@tool` decorator],
  [Converts a function into an agent tool],
  [`args_schema`],
  [Defines a complex input schema with Pydantic],
  [`create_agent()`],
  [Connects the model and tools to create an agent],
  [`ToolRuntime`],
  [Gives a tool access to runtime state such as conversation history],
  [`with_structured_output()`],
  [Structures model output as a Pydantic model or dataclass],
  [`ToolStrategy`],
  [Structured agent output through tool calling],
  [`ProviderStrategy`],
  [Provider-native structured output],
)

=== Next Steps
→ _#link("./05_memory_and_streaming.ipynb")[05_memory_and_streaming.ipynb]_: Learn about memory and streaming.

