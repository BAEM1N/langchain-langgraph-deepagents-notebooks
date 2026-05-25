# Workflows and Agents Documentation

## Overview

This guide covers common workflow and agent patterns used in LangChain:

- **Workflows**: Predetermined code paths operating in a defined order
- **Agents**: Dynamic systems that define their own processes and tool usage

LangGraph provides benefits including persistence, streaming, debugging support, and deployment capabilities.

## Setup

Install required dependencies:
```bash
pip install langchain_core langchain-anthropic langgraph
```

Initialize the LLM with Anthropic:
```python
from langchain_anthropic import ChatAnthropic
llm = ChatAnthropic(model="claude-sonnet-4-6")
```

## LLMs and Augmentations

Three key augmentation types enhance LLM capabilities:

1. **Tool calling** - Enable LLMs to invoke external functions
2. **Structured outputs** - Define expected response schemas using Pydantic models
3. **Short-term memory** - Maintain conversation context

Example augmentations:
```python
# Structured output schema
class SearchQuery(BaseModel):
    search_query: str
    justification: str

structured_llm = llm.with_structured_output(SearchQuery)

# Tool binding
def multiply(a: int, b: int) -> int:
    return a * b

llm_with_tools = llm.bind_tools([multiply])
```

## Prompt Chaining

Sequential LLM calls where each processes previous output. Useful for:
- Multi-language document translation
- Content consistency verification

Example workflow processes a joke through generation, improvement, and polish stages with conditional routing based on content validation.

**Key Components:**
- `StateGraph` for graph structure
- Conditional edges for gating logic
- `START` / `END` nodes
- Functional API alternative using `@task` and `@entrypoint()`

## Parallelization

Multiple LLM calls execute simultaneously for:
- **Speed**: Running independent subtasks concurrently
- **Confidence**: Executing identical tasks multiple times for validation

Common use cases include parallel document analysis (keyword extraction + formatting checks) or multi-criteria scoring.

**Structure:**
- Multiple nodes added to `StateGraph`
- All nodes connected to `START`
- Aggregator node collects results

## Routing

Input processing directs requests to context-specific tasks. A routing workflow evaluates input type and delegates to specialized handlers, such as routing product questions to pricing, refunds, or returns processes.

**Mechanism:**
- Router LLM with structured output determines the next step
- Conditional edge function maps decisions to nodes

**Schema Pattern:**
```python
class Route(BaseModel):
    step: Literal["poem", "story", "joke"] = Field(
        None, description="The next step in the routing process"
    )
```

## Orchestrator-Worker Pattern

The orchestrator:
- Breaks tasks into subtasks
- Delegates work to workers
- Synthesizes outputs into final results

LangGraph's `Send` API enables dynamic worker creation with parallel execution and shared state access. Each worker has isolated state, and a shared state key aggregates outputs — workers write to an `Annotated[list, operator.add]` field. Example: report generation with `planner` (orchestrator) and `llm_call` (workers).

Orchestrator-worker is more flexible than parallelization when subtasks cannot be predefined.

## Evaluator-Optimizer

One LLM generates responses; another evaluates them. Feedback loops continue until acceptable output is produced. Effective for tasks requiring iteration, such as translation refinement.

**Implementation Pattern:**
- Generator node produces output
- Evaluator node grades with structured feedback
- Conditional routing loops back on failure
- Example: joke generation with funny / not-funny grading

## Agents

LLMs perform autonomous actions using tools in continuous feedback loops. More flexible than workflows for unpredictable problems. Agents decide which tools to use and how to solve problems while operating within defined constraints.

### Agent Implementation

**Tool Definition:**
```python
@tool
def function_name(param: type) -> return_type:
    """Description."""
    return result
```

**Core Loop:**
1. LLM decides whether to call tools
2. Tool node executes selected tools
3. Results fed back to LLM
4. Process repeats until LLM produces a final response

**Routing Logic:**
```python
def should_continue(state: MessagesState) -> Literal["tool_node", END]:
    if state["messages"][-1].tool_calls:
        return "tool_node"
    return END
```

### `ToolNode` Utility

Prebuilt component handling:
- Parallel tool execution
- Error handling
- State injection
- Fine-grained control over tool execution

## API Patterns

**Graph API Elements:**
- `StateGraph(State)` — Define graph structure
- `add_node(name, function)` — Register nodes
- `add_edge(source, target)` — Direct connections
- `add_conditional_edges(source, function, mapping)` — Conditional routing
- `compile()` — Create executable graph
- `invoke(input)` — Execute once
- `stream(input)` — Execute with streaming

**Functional API Elements:**
- `@task` decorator — Mark async functions
- `@entrypoint()` decorator — Define workflow entry
- `.result()` — Await task completion
- `.stream(input, stream_mode="updates")` — Streaming execution

**State Management:**
- `TypedDict` for state schema
- `Annotated[list, operator.add]` for accumulating lists
- State passed through all nodes; updates merged automatically
