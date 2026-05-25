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

### Execution Model
Deep Agents lets the agent "run inside a sandbox, or outside a sandbox executing commands remotely." Claude Agent SDK restricts agents to sandbox-internal execution against local filesystems.

### Deployment & Multi-Tenancy
Deep Agents ships managed deployment via LangSmith plus self-hosted Docker, and includes built-in multi-tenant features (scoped threads, per-user sandboxes, RBAC). Claude Agent SDK requires you to "build the server, auth, and streaming layer" yourself.

| Aspect | Deep Agents | Claude Agent SDK |
|--------|------------|------------------|
| Execution backend | Pluggable (local, virtual, remote, custom) | Local filesystem |
| Per-model configuration | Harness profiles | Code-based tuning |
| License | MIT | MIT |

### When to Choose Which
- **Deep Agents** — model and infrastructure flexibility, built-in multi-tenant deployment, mixed-provider workloads.
- **Claude Agent SDK** — already invested in the Anthropic ecosystem and prefer to self-host.
- **OpenCode** — broad provider coverage (75+) including local Ollama, with terminal/desktop/IDE clients.

*Last updated: May 25, 2026*
