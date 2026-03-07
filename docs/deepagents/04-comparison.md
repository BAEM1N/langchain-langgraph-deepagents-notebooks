# Comparison with OpenCode and Claude Agent SDK

## Overview

This documentation compares three agent-building frameworks:

| Feature | LangChain Deep Agents | OpenCode | Claude Agent SDK |
|---------|----------------------|----------|-----------------|
| **Model Support** | Model-agnostic (Anthropic, OpenAI, 100s others) | 75+ providers including local (Ollama) | Claude models only |
| **License** | MIT | MIT | MIT (SDK), proprietary (Claude Code) |
| **SDKs** | Python, TypeScript + CLI | Terminal, Desktop, IDE extension | Python, TypeScript |

## Key Feature Distinctions

### Core Tools
All three support file operations, shell execution, search capabilities, and planning features. Each implements human-in-the-loop controls with slightly different permission frameworks.

### Sandbox Integration
LangChain uniquely enables agents to run operations in sandboxes as integrated tools — a capability the other frameworks lack.

### Architecture
LangChain provides pluggable storage backends and virtual filesystem with pluggable backends — features absent from competitors.

### State Management
LangChain and Claude Agent SDK both support time travel (state branching), while OpenCode doesn't. LangChain includes LangSmith for native tracing; the others lack comparable observability solutions.

*Last updated: February 18, 2026*
