// Auto-generated from 03_customization.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Agent Customization")

== Learning Objectives
- Learn how to choose different LLM providers and models
- Write effective system prompts
- Build custom tools from docstrings and type hints
- Produce structured Pydantic output with `response_format`
- Understand the middleware architecture


#code-block(`````python
# Environment setup
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
print("Environment setup complete")

# Initialize the OpenAI gpt-4.1 model
from deepagents import create_deep_agent
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")
print(f"Default model: {model.model_name}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Choosing a Model

Deep Agents supports a wide range of LLMs through either a *LangChain chat model object* or the *`provider:model`* format.

This notebook uses _OpenAI gpt-4.1_ as the default model.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Provider],
  text(weight: "bold")[Example model],
  text(weight: "bold")[Environment variable],
  text(weight: "bold")[Notes],
  [_OpenAI_],
  [`gpt-4.1`],
  [`OPENAI_API_KEY`],
  [_Default in this notebook_],
  [Anthropic],
  [`anthropic:claude-sonnet-4-6`],
  [`ANTHROPIC_API_KEY`],
  [Direct connection],
  [Google],
  [`google_genai:gemini-2.5-flash`],
  [`GOOGLE_API_KEY`],
  [],
  [Azure],
  [`azure_openai:gpt-4o`],
  [`AZURE_OPENAI_*`],
  [],
  [AWS Bedrock],
  [`bedrock:anthropic.claude-sonnet-4-6`],
  [AWS credentials],
  [],
)

The default model is `gpt-4.1`, and it includes built-in retry and timeout behavior.


#code-block(`````python
# Use the OpenAI gpt-4.1 model (the model object initialized above)
agent_claude = create_deep_agent(
    model=model,
)

print(f"Agent created: {type(agent_claude).__name__}")

# Reference examples for other providers:
# agent_openai = create_deep_agent(model="openai:gpt-4o")
# agent_gemini = create_deep_agent(model="google_genai:gemini-2.5-flash")
# agent_anthropic = create_deep_agent(model="anthropic:claude-sonnet-4-6")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Custom System Prompts

The system prompt defines the agent's _role_, _behavioral rules_, and _output style_.
It is added on top of the default prompt, so you can provide domain-specific instructions without rebuilding everything from scratch.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Building Custom Tools

Deep Agents converts Python functions into tools using the following rules:
+ _Function name_ → tool name
+ _Docstring_ → tool description (used by the agent to decide whether to call the tool)
+ _Type hints_ → parameter schema (generated automatically)
+ _Default values_ → optional parameters


#code-block(`````python
import math


def calculate_compound_interest(
    principal: float,
    annual_rate: float,
    years: int,
    compounds_per_year: int = 12,
) -> dict:
    """Calculate compound interest.

    Args:
        principal: Principal amount
        annual_rate: Annual interest rate (for example 0.05 = 5%)
        years: Number of years
        compounds_per_year: Number of compounding periods per year (default: 12 = monthly)
    """
    amount = principal * (1 + annual_rate / compounds_per_year) ** (compounds_per_year * years)
    interest = amount - principal
    return {
        "principal": f"{principal:,.0f}",
        "final_amount": f"{amount:,.0f}",
        "interest_earned": f"{interest:,.0f}",
        "return_rate": f"{(interest / principal) * 100:.2f}%",
    }


def convert_temperature(
    value: float,
    from_unit: str,
    to_unit: str,
) -> str:
    """Convert between temperature units.

    Args:
        value: Temperature value to convert
        from_unit: Source unit ('celsius', 'fahrenheit', 'kelvin')
        to_unit: Target unit ('celsius', 'fahrenheit', 'kelvin')
    """
    if from_unit == "fahrenheit":
        celsius = (value - 32) * 5 / 9
    elif from_unit == "kelvin":
        celsius = value - 273.15
    else:
        celsius = value

    if to_unit == "fahrenheit":
        result = celsius * 9 / 5 + 32
    elif to_unit == "kelvin":
        result = celsius + 273.15
    else:
        result = celsius

    return f"{value} {from_unit} = {result:.2f} {to_unit}"


calculator_agent = create_deep_agent(
    model=model,
    tools=[calculate_compound_interest, convert_temperature],
    system_prompt="You are an assistant for calculations and unit conversion. Always use tools for exact results.",
)

print("Calculator agent created!")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Structured Output — `response_format`

You can structure the agent's final response as a _Pydantic model_.
That makes the result much easier to use programmatically.


#code-block(`````python
from pydantic import BaseModel, Field


class BookRecommendation(BaseModel):
    """Single book recommendation"""
    title: str = Field(description="Book title")
    author: str = Field(description="Author")
    reason: str = Field(description="Reason for the recommendation (2–3 sentences)")
    difficulty: str = Field(description="Difficulty level: beginner/intermediate/advanced")


class BookRecommendationList(BaseModel):
    """Book recommendation list"""
    topic: str = Field(description="Topic of the recommendation")
    books: list[BookRecommendation] = Field(description="Recommended books")


book_agent = create_deep_agent(
    model=model,
    system_prompt="You are a book recommendation expert. Suggest books that match the user's interests.",
    response_format=BookRecommendationList,
)

print("Book recommendation agent created")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Middleware Architecture

`create_deep_agent()` builds an internal _middleware stack_.
Middleware is the plugin layer that extends and controls the agent's behavior.

=== Default middleware stack (execution order)

#code-block(`````python
1. TodoListMiddleware        — task management (`write_todos`)
2. MemoryMiddleware          — load `AGENTS.md` when `memory` is used
3. SkillsMiddleware          — load `SKILL.md` when `skills` is used
4. FilesystemMiddleware      — file tools (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`)
5. SubAgentMiddleware        — subagent support (`task` tool)
6. SummarizationMiddleware   — context compression
7. AnthropicCachingMiddleware — prompt caching for Anthropic models
8. PatchToolCallsMiddleware  — fix malformed tool calls
9. [User custom middleware]  — `middleware` parameter
10. HumanInTheLoopMiddleware — approval workflow (`interrupt_on`)
`````)

=== What each middleware does

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Tools Added],
  text(weight: "bold")[Role],
  [`TodoListMiddleware`],
  [`write_todos`],
  [Manage structured task lists],
  [`FilesystemMiddleware`],
  [`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`],
  [Filesystem access],
  [`SubAgentMiddleware`],
  [`task`],
  [Create and call subagents],
  [`SummarizationMiddleware`],
  [none],
  [Summarize context when it reaches about 85% of the limit],
  [`MemoryMiddleware`],
  [none],
  [Inject `AGENTS.md` into the system prompt],
  [`SkillsMiddleware`],
  [none],
  [Progressively load relevant `SKILL.md` files],
)


#code-block(`````python
# Verify available middleware imports
from deepagents.middleware import (
    FilesystemMiddleware,
    MemoryMiddleware,
    SubAgentMiddleware,
    SkillsMiddleware,
    SummarizationMiddleware,
)

print("Available middleware:")
for mw in [FilesystemMiddleware, MemoryMiddleware, SubAgentMiddleware, SkillsMiddleware, SummarizationMiddleware]:
    print(f"  - {mw.__name__}")

`````)

#note-box[_Note_: `create_deep_agent()` configures middleware automatically in most cases. You can still add custom middleware through the `middleware` parameter if you need advanced behavior.]


#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Method],
  [Model selection],
  [`model="provider:model-name"`],
  [System prompt],
  [`system_prompt="define the role and rules"`],
  [Custom tools],
  [function + docstring + type hints → `tools=[func]`],
  [Structured output],
  [`response_format=PydanticModel` → `result["structured_response"]`],
  [Middleware],
  [Automatically configured (TodoList, Filesystem, SubAgent, Summarization, etc.)],
)

== Next Steps
→ _#link("./04_backends.ipynb")[04_backends.ipynb]_: learn how storage backends define the agent filesystem.

