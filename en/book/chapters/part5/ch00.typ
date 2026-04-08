// Auto-generated from 00_migration.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "v0 → v1 migration guide")

Covers the breaking changes and code mapping you need to know when transitioning from LangChain/LangGraph v0 to v1.

== Learning Objectives

- Understand v1 package structure changes and import paths
- Perform `create_react_agent` → `create_agent` migration
- Apply middleware-based dynamic prompting, state management, and context injection
- Utilizes standard content blocks and structured output strategies

== 0.1 Change package structure

In v1, the `langchain` namespace has been significantly reduced to five core modules essential for building an agent:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v1 module],
  text(weight: "bold")[Role],
  text(weight: "bold")[Main API],
  [`langchain.agents`],
  [Agent creation and state management],
  [`create_agent`, `AgentState`],
  [`langchain.messages`],
  [Message types and content blocks],
  [`HumanMessage`, `AIMessage`, `content_blocks`],
  [`langchain.tools`],
  [tool Definition],
  [`\@tool` decorator, `BaseTool`],
  [`langchain.chat_models`],
  [model initialization],
  [`init_chat_model`],
  [`langchain.embeddings`],
  [Embedding Utility],
  [Embedding model wrapper],
)

=== Legacy code migration — `langchain-classic`

Chains, Retrievers, Hub, and Indexing API, which were previously used in the `langchain` package, have all been separated into a separate package called `langchain-classic`. If you need to keep your existing code, change the import path after installation to `pip install langchain-classic`:

The 
== v0 — Legacy approach
from langchain.chains import LLMChain
from langchain.retrievers import MultiQueryRetriever
from langchain import hub

== v1 — langchain-classicmigration path
from langchain_classic.chains import LLMChain
from langchain_classic.retrievers import MultiQueryRetriever
from langchain_classic import hub
#code-block(`````python

Because of this split, the v1 `langchain` package became a lightweight layer focused on agent building, while legacy functionality is maintained separately.
`````)

== 0.2 Agent creation API changes

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
from langchain.tools import tool
from langchain.agents import create_agent

model = ChatOpenAI(model="gpt-4.1")

@tool
def add(a: int, b: int) -> int:
    """Add two numbers together."""
    return a + b

# v0: from langgraph.prebuilt import create_react_agent
# v1: from langchain.agents import create_agent
agent = create_agent(
    model=model,
    tools=[add],
    system_prompt="You are a math assistant.",  # v0: prompt=
)
print("✓ v1 agent creation completed")
`````)

=== Major changes

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  text(weight: "bold")[Remarks],
  [`from langgraph.prebuilt import create_react_agent`],
  [`from langchain.agents import create_agent`],
  [import path + function name],
  [`prompt=`],
  [`system_prompt=`],
  [Parameter name],
  [`ToolNode` Support],
  [Not supported],
  [Functions/BaseTool/dict only],
  [`pre_hooks`, `post_hooks`],
  [`middleware=[]`],
  [Integrated middleware],
  [Pydantic/dataclass status],
  [`TypedDict` only],
  [state schema],
)

== 0.3 State Schema — TypedDict only

In v1, custom state must inherit from `TypedDict` based on `AgentState`.

== 0.4 Runtime context injection (new)

In v1, _immutable runtime data_ can be passed to the agent via the `context_schema` and `context` parameters. This is a pattern that safely passes data that varies from request to request, such as user ID, role, and session information, but does not change during execution, to the agent and tool.

_How it works:_
+ Define the context schema with `@dataclass`.
+ Register the schema with `create_agent(context_schema=...)`.
+ Pass the value to runtime with `agent.invoke(..., context=ContextInstance(...))`.
+ In tool, the context is accessed with the `ToolRuntime[ContextType]` parameter.

Context is read-only data that _does not change_ between tool calling, unlike agent state (`AgentState`). The state is updated during the agent loop, but the context is fixed when calling `invoke`.

== 0.5 Dynamic Prompts — Middleware Approach (New)

Instead of the static prompt in v0, `@dynamic_prompt` creates a prompt dynamically based on the runtime context.

== 0.6 tool Error handling — `\@wrap_tool_call` (new)

Instead of v0's `handle_tool_errors`, v1 handles tool errors with middleware.

#code-block(`````python
from langchain.agents.middleware import wrap_tool_call
from langchain.messages import ToolMessage

@wrap_tool_call
def handle_errors(request, handler):
    try:
        return handler(request)
    except Exception as e:
        return ToolMessage(
            content=f"Tool error: {e}",
            tool_call_id=request.tool_call["id"],
        )

agent = create_agent(
    model=model,
    tools=[add],
    middleware=[handle_errors],
)
print("✓ Application of error handling middleware")
`````)

== 0.7 Standard Content Block & structured output (New)

In v1, messages support provider-agnostic `content_blocks`.
structured output was split into two branches: `ToolStrategy` (based on tool calling) and `ProviderStrategy` (native).

== 0.8 Streaming changes

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[v0],
  text(weight: "bold")[v1],
  [Agent node name],
  [`"agent"`],
  [`"model"`],
  [`.text`],
  [method `.text()`],
  [Property `.text`],
)

== 0.9 Guitar Breaking Change

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[change],
  text(weight: "bold")[Description],
  [_Python 3.10+_],
  [All LangChain packages require Python 3.10 or higher. Versions 3.9 and below are not supported.],
  [_return type_],
  [The return type of the chat model has been fixed from `BaseMessage` to `AIMessage`.],
  [_OpenAI Responses API_],
  [Message content is in standard block format by default. You can restore the previous behavior with `output_version="v0"`.],
  [_Anthropic max_tokens_],
  [Default value changed from 1024 to automatic setting per model.],
  [_AIMessage.example_],
  [The `example` parameter has been removed. Use `additional_kwargs`.],
  [_AIMessageChunk_],
  [Added `chunk_position` attribute (value `'last'` in last chunk).],
  [`.text` properties],
  [`.text()` method changed to `.text` property.],
  [_File Encoding_],
  [Files open with UTF-8 encoding by default.],
)

== Summary — Migration Checklist

- [ ] Python 3.10+ confirmed
- [ ] `create_react_agent` → `create_agent` changed
- [ ] `prompt=` → `system_prompt=` changed
- [ ] Convert state schema to `AgentState` based on `TypedDict`
- [ ] `pre_hooks`/`post_hooks` → `middleware=[]`
- [ ] `ToolNode` → Replaced with Function/BaseTool
- [ ] `.text()` → `.text` property
- [ ] Check streaming node name `"agent"` → `"model"`
- [ ] Move legacy imports to `langchain-classic`

=== Next Steps
→ _#link("./01_middleware.ipynb")[01_middleware.ipynb]_: v1’s biggest new feature — Deepening the middleware system
