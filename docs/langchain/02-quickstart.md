# LangChain Quickstart

## Overview

This guide demonstrates building AI agents from basic setup to production-ready implementations using LangChain with Claude.

## Prerequisites

- Install LangChain package
- Set up Anthropic account with API key
- Configure `ANTHROPIC_API_KEY` environment variable

## Basic Agent Example

The documentation shows creating a simple agent using `create_agent()` with Claude Sonnet 4.5, a weather tool function, and system instructions.

## Production Agent Components

### 1. System Prompt

A detailed prompt defines agent behavior. The example uses: "You are an expert weather forecaster, who speaks in puns" with specific tool access instructions.

### 2. Tools Definition

Tools enable external system interaction through decorated functions. The guide demonstrates:
- `@tool` decorator for function conversion
- Runtime context injection via `ToolRuntime`
- Tool documentation requirements

### 3. Model Configuration

Initialize language models with parameters like temperature, timeout, and max_tokens using `init_chat_model()`.

### 4. Structured Response Format

Optional dataclass definitions ensure consistent output schemas matching specific requirements.

### 5. Memory Management

`InMemorySaver()` provides conversation state persistence. Production deployments require persistent checkpointers for database storage.

### 6. Agent Assembly and Execution

Components combine into a functional agent using `create_agent()`, executed with unique thread identifiers for conversation tracking.

## Key Capabilities

The resulting agent can:
- Understand context
- Utilize multiple tools
- Provide structured responses
- Handle user-specific data
- Maintain conversation history

## Additional Resources

Documentation references LangSmith for tracing and MCP server integration for IDE assistants.
