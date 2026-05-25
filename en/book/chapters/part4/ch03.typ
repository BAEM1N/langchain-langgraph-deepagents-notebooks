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
assert os.environ.get("ANTHROPIC_API_KEY"), "ANTHROPIC_API_KEY is not set!"
print("Environment setup complete")

# Recommended default — Anthropic Claude Sonnet 4.6 (provider:model string)
from deepagents import create_deep_agent

model = "anthropic:claude-sonnet-4-6"
print(f"Default model: {model}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 0. Full `create_deep_agent()` Signature (17 parameters)

Before diving into individual customization axes, here is the full _17-parameter_ signature. All parameters are _optional_; only `model` is enough to get a working agent.

#code-block(`````python
def create_deep_agent(
    model=None,             # 1. LLM (ChatModel object or "provider:model")
    tools=None,             # 2. custom tools
    system_prompt=None,     # 3. user-provided prompt (USER segment)
    middleware=(),          # 4. extra user middleware
    subagents=None,         # 5. SubAgent dicts / CompiledSubAgent
    skills=None,            # 6. SKILL.md directories (progressive disclosure)
    memory=None,            # 7. AGENTS.md path (always injected)
    response_format=None,   # 8. Pydantic schema for structured output
    context_schema=None,    # 9. runtime context TypedDict (propagated to subagents)
    checkpointer=None,      # 10. LangGraph checkpointer (persistence)
    store=None,             # 11. LangGraph BaseStore (for StoreBackend)
    cache=None,             # 12. prompt cache config (e.g. Anthropic)
    backend=None,           # 13. BackendProtocol or `lambda runtime: ...`
    permissions=None,       # 14. allow_read/allow_write/deny_* ACL
    interrupt_on=None,      # 15. {"tool_name": True} HITL gates
    debug=False,            # 16. debug logging
    name=None,              # 17. graph name
):
    ...
`````)

#tip-box[`permissions`, `context_schema`, and `cache` are recent additions (`deepagents>=0.5.0`). Older versions require adding middleware directly.]

=== Prompt assembly order

The string you pass to `system_prompt` is _not_ used verbatim. Deep Agents' prompt builder assembles three segments in a fixed order:

#code-block(`````
[USER]    system_prompt (string from the caller)
   ↓
[BASE]    harness BASE prompt (TodoList/Filesystem/SubAgent usage)
   + CUSTOM  per-middleware injections (Memory, Skills, Permissions, ...)
   ↓
[SUFFIX]  harness SUFFIX (safety guidance, output contract)
`````)

The order is _USER → BASE/CUSTOM → SUFFIX_. You only fill in the USER segment; BASE and SUFFIX are managed by middleware. Nothing is overwritten, so there is no need to repeat built-in tool usage in your own prompt.

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Choosing a Model

Deep Agents supports a wide range of LLMs through either a *LangChain chat model object* or the *`provider:model`* format.

This notebook uses _Anthropic Claude Sonnet 4.6_ (`anthropic:claude-sonnet-4-6`) as the recommended default. OpenAI examples use `gpt-5.4`.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Provider],
  text(weight: "bold")[Example model (provider:model)],
  text(weight: "bold")[Environment variable],
  text(weight: "bold")[Notes],
  [_Anthropic_],
  [`anthropic:claude-sonnet-4-6`],
  [`ANTHROPIC_API_KEY`],
  [_Recommended default_ — best for prompt caching and HITL],
  [OpenAI],
  [`openai:gpt-5.4`],
  [`OPENAI_API_KEY`],
  [Strong tool-calling accuracy],
  [Google],
  [`google_genai:gemini-3.5-flash`],
  [`GOOGLE_API_KEY`],
  [Cost-effective],
  [Azure],
  [`azure_openai:gpt-5.4`],
  [`AZURE_OPENAI_*`],
  [Enterprise deployments],
  [AWS Bedrock],
  [`bedrock:anthropic.claude-sonnet-4-6`],
  [AWS credentials],
  [VPC isolation],
)

The recommended default is `anthropic:claude-sonnet-4-6`, with built-in retry (6 attempts) and timeout. The `model` parameter accepts either a `BaseChatModel` object or a `"provider:model-name"` string.


#code-block(`````python
# Recommended default — Anthropic Claude Sonnet 4.6 via provider:model string
agent_default = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
)

print(f"Agent created: {type(agent_default).__name__}")

# Reference examples for other providers:
# agent_openai = create_deep_agent(model="openai:gpt-5.4")
# agent_gemini = create_deep_agent(model="google_genai:gemini-3.5-flash")
# agent_bedrock = create_deep_agent(model="bedrock:anthropic.claude-sonnet-4-6")

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
1.  TodoListMiddleware                  — task management (write_todos)
2.  MemoryMiddleware                    — load AGENTS.md when `memory` is used
3.  SkillsMiddleware                    — load SKILL.md when `skills` is used
4.  FilesystemMiddleware                — file tools (ls, read, write, edit, glob, grep)
5.  SubAgentMiddleware  [required, not removable]  — subagent support (task tool)
6.  SummarizationMiddleware             — context compression (~85% auto-summary)
7.  AnthropicPromptCachingMiddleware    — prompt caching (auto-applied for Anthropic)
8.  PatchToolCallsMiddleware            — repair malformed/missing tool calls
9.  [User custom middleware]            — `middleware` parameter
10. HumanInTheLoopMiddleware            — approval workflow (`interrupt_on`)
`````)

#warning-box[`SubAgentMiddleware` cannot be removed via `excluded_middleware`. The `task` tool is the core delegation mechanism, so it stays enabled even when you do not declare any subagents — a built-in `general-purpose` subagent fills the slot.]

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
== 6. Sandbox Options

Beyond `tools`, Deep Agents ships _sandbox options_ that isolate untrusted code execution. Use them for coding agents or data-analysis agents that run arbitrary scripts.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Sandbox],
  text(weight: "bold")[Execution environment],
  text(weight: "bold")[Best fit],
  [Modal],
  [Remote container (GPU available)],
  [Long-running code, GPU inference],
  [Daytona],
  [Remote development container],
  [Git workspace integration, multi-language],
  [Deno],
  [Local TypeScript/JavaScript isolation],
  [Lightweight JS/TS execution],
  [Local VFS],
  [In-process virtual filesystem],
  [Unit tests with no network or disk access],
)

#tip-box[Sandboxes can be exposed either as _tools_ (for example an `execute_python` tool) or as _backends_ (for example a `SandboxBackend` for file isolation). The two layers can be combined to get both code and file isolation.]


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
  [`model="anthropic:claude-sonnet-4-6"` or any provider prefix],
  [System prompt],
  [Assembled USER → BASE/CUSTOM → SUFFIX],
  [Custom tools],
  [function + docstring + type hints → `tools=[func]`],
  [Structured output],
  [`response_format=PydanticModel` → `result["structured_response"]`],
  [Middleware],
  [`SubAgentMiddleware` is required; the rest are wired automatically],
  [Full parameter list],
  [17 — includes `permissions`, `context_schema`, `checkpointer`, `store`, `cache`, `interrupt_on`],
  [Sandboxes],
  [Modal, Daytona, Deno, local VFS — exposed as tools or backends],
)

== Next Steps
→ _#link("./04_backends.ipynb")[04_backends.ipynb]_: learn how storage backends define the agent filesystem.

