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

Load API keys and initialize an OpenAI model.


#code-block(`````python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv(override=True)

# Initialize the model with OpenAI
model = ChatOpenAI(
    model="gpt-4.1",
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

