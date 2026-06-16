# Deep Agents Overview

Deep Agents is a framework that streamlines agent development with built-in capabilities. It functions as an "agent harness" — a tool calling loop bundled with planning, filesystem management, subagent orchestration, and persistent memory.

## Key Components

The `deepagents` ecosystem ships three offerings:

1. **Deep Agents SDK** – A standalone library built on LangChain's core building blocks and running on the LangGraph runtime for durable execution and streaming.
2. **Deep Agents Code** – A terminal coding agent built on the Deep Agents SDK.
3. **ACP Integration** – An Agent Client Protocol connector that lets deep agents run inside code editors such as Zed.

## Core Capabilities

- **Planning & task decomposition** via the built-in `write_todos` tool
- **Context management** through filesystem tools (`ls`, `read_file`, `write_file`, `edit_file`)
- **Shell execution** with sandbox backend isolation
- **JavaScript interpreters** via a QuickJS runtime for lightweight tool composition (no shell or network)
- **Runtime grading rubrics** via `RubricMiddleware` for LLM-as-a-judge self-evaluation loops
- **Pluggable filesystem backends** — in-memory state, local disk, LangGraph store, ContextHub, sandboxes
- **Subagent spawning** for context isolation and parallel work
- **Long-term memory** across threads via the LangGraph Memory Store
- **Filesystem permissions** with declarative read/write rules
- **Human-in-the-loop** approval workflows via `interrupt_on`
- **Reusable skills** with specialized workflows
- **Opinionated system prompts** with customization hooks

## Installation

```bash
pip install -qU deepagents langchain-{provider}
```

Replace `{provider}` with one of `anthropic`, `openai`, `google-genai`, `openrouter`, `fireworks`, `baseten`, or `ollama` depending on the model you plan to use. For Deep Agents Code, use the `dcode` command provided by `deepagents-code`.

## Getting Started

Start with the Quickstart and Customization guides. Pair the SDK with LangSmith for tracing and debugging during development.

## Use Cases

The SDK suits complex multi-step autonomous tasks; Deep Agents Code targets interactive command-line coding; the ACP connector embeds the harness into editor workflows.
