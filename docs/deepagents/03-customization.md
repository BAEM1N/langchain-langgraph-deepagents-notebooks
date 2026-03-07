# Deep Agents Customization

## Overview
This guide covers customizing deep agents through `create_deep_agent()` with core configuration options including models, tools, system prompts, middleware, subagents, backends, human-in-the-loop features, skills, and memory.

## Core Configuration Options

The `create_deep_agent()` function accepts:

- **Model**: Defaults to Claude Sonnet 4.6; supports multiple providers
- **Tools**: Built-in planning, file management, and subagent tools; custom tools supported
- **System Prompt**: Custom instructions for agent behavior
- **Middleware**: Extensible hooks for functionality enhancement
- **Subagents**: Specialized agents for task delegation
- **Backends**: Virtual filesystem implementations
- **Human-in-the-loop**: Tool approval workflows
- **Skills**: Progressive disclosure of detailed capabilities
- **Memory**: Context persistence via AGENTS.md files

## Model Selection

Supports multiple LLM providers through standardized `provider:model` format:

- **Anthropic**: Claude models (default: claude-sonnet-4-6)
- **OpenAI**: GPT models
- **Azure OpenAI**: Enterprise deployments
- **Google Gemini**: Flash and advanced variants
- **AWS Bedrock**: Anthropic models
- **HuggingFace**: Open-source models

Connection resilience includes automatic retry logic (default: 6 attempts) for network errors, rate limits, and server errors. Parameters like `max_retries` and `timeout` are configurable.

## Tools & Custom Functions

Beyond built-in capabilities, agents accept custom tools as functions with docstrings defining behavior and parameters. Example: web search integration via Tavily API.

## System Prompts

Each agent should include domain-specific instructions. Default prompts contain detailed guidance for planning, filesystem operations, and subagent coordination.

## Middleware Architecture

Default middleware includes:

- **TodoListMiddleware** (task organization)
- **FilesystemMiddleware** (file operations)
- **SubAgentMiddleware** (delegation)
- **SummarizationMiddleware** (context management)
- **AnthropicPromptCachingMiddleware** (token optimization)
- **PatchToolCallsMiddleware** (error recovery)

Additional middleware: MemoryMiddleware, SkillsMiddleware, HumanInTheLoopMiddleware.

**Critical**: Use graph state for tracking values across invocations, not mutable object attributes, to prevent race conditions in concurrent execution.

## Subagents

Enable task isolation by delegating to specialized agents with their own:
- Name and description
- Custom system prompts
- Specific tool sets
- Optional model overrides

## Backends

- **StateBackend**: Ephemeral, thread-scoped filesystem (default)
- **FilesystemBackend**: Local machine access (requires caution)
- **LocalShellBackend**: Filesystem plus shell execution (extreme caution)
- **StoreBackend**: Persisted across threads for long-term storage
- **CompositeBackend**: Route different paths to different backend implementations
- **Sandboxes**: Isolated environments (Modal, Runloop, Daytona)

## Human-in-the-Loop

Configure tool approval requirements using `interrupt_on` with decision options like "approve," "edit," "reject." Requires checkpointer configuration.

## Skills

Task-specific expertise loaded progressively. Skills contain instructions, reference materials, and templates — loaded only when determined relevant.

## Memory

`AGENTS.md` files provide extra context to agents, enabling persistent knowledge across conversations when using StoreBackend or FilesystemBackend.

## Structured Output

Agents support Pydantic schema validation for generating structured responses. Pass `response_format` with model definitions; results appear in `structured_response` key.
