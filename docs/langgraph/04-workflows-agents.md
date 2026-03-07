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

## Parallelization

Multiple LLM calls execute simultaneously for:
- **Speed**: Running independent subtasks concurrently
- **Confidence**: Executing identical tasks multiple times for validation

Common use cases include parallel document analysis (keyword extraction + formatting checks) or multi-criteria scoring.

## Routing

Input processing directs requests to context-specific tasks. A routing workflow evaluates input type and delegates to specialized handlers, such as routing product questions to pricing, refunds, or returns processes.

## Orchestrator-Worker Pattern

The orchestrator:
- Breaks tasks into subtasks
- Delegates work to workers
- Synthesizes outputs into final results

LangGraph's `Send` API enables dynamic worker creation with parallel execution and shared state access.

## Evaluator-Optimizer

One LLM generates responses; another evaluates them. Feedback loops continue until acceptable output is produced. Effective for tasks requiring iteration, such as translation refinement.

## Agents

LLMs perform autonomous actions using tools in continuous feedback loops. More flexible than workflows for unpredictable problems. Agents decide which tools to use and how to solve problems while operating within defined constraints.

Key implementation requires:
- Tool definitions with proper documentation
- Tool binding to LLM
- Conditional logic for tool invocation routing
