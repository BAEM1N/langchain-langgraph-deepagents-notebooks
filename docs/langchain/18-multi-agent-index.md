# Multi-Agent Systems in LangChain

## Core Concept

Multi-agent systems coordinate specialized components to handle complex workflows. However, not every complex task requires this approach -- a single agent with the right tools and prompt can often achieve similar results.

## Primary Use Cases

The documentation identifies three main reasons developers adopt multi-agent architectures:

1. **Context Management** - Distributing specialized knowledge across agents to avoid overwhelming token limits
2. **Distributed Development** - Enabling independent team development with clear boundaries
3. **Parallelization** - Executing specialized subtasks concurrently for faster results

## Five Main Architectural Patterns

### 1. Subagents

A primary agent (supervisor) coordinates subagents as tools, with all routing decisions passing through the main agent. See [`/multi-agent/subagents`](./19-subagents.md).

### 2. Handoffs

Agents dynamically transfer control based on state changes, with tool calls triggering routing or configuration modifications. See [`/multi-agent/handoffs`](./20-handoffs.md).

### 3. Skills

A single agent loads specialized knowledge on-demand while maintaining control throughout the process. See [`/multi-agent/skills`](./21-skills.md).

### 4. Router

An initial routing step classifies input and directs it to appropriate agents, synthesizing results afterward. See [`/multi-agent/router`](./22-router.md).

### 5. Custom Workflow

Bespoke execution flows built with LangGraph, combining deterministic logic and agentic behavior. See [`/multi-agent/custom-workflow`](./23-custom-workflow.md).

## Pattern Selection Matrix

| Requirement | Recommended Pattern |
|---|---|
| Single, simple one-shot request | **Skills** or **Handoffs** (3 calls) |
| Repeat / multi-turn requests sharing context | **Handoffs**, **Skills** (stateful, 40–50% fewer calls on turn 2) |
| Parallel multi-domain queries | **Subagents**, **Router** (fan-out execution) |
| Large or growing context windows | **Subagents** (clean context per invocation) |
| Team-based distributed development | **Subagents**, **Skills** |
| Direct conversation with user across stages | **Handoffs** |

## Performance Comparison

| Scenario | Subagents | Handoffs | Skills | Router |
|---|---|---|---|---|
| **One-Shot** ("Buy coffee") | 4 calls | 3 calls | 3 calls | 3 calls |
| **Repeat** (turn 2 of same task) | full flow (stateless) | 2 calls (40–50% saving) | 2 calls (40–50% saving) | full flow |
| **Multi-Domain** | 5 calls, ~9K tokens | 7+ calls, ~14K+ tokens | ~15K tokens (context accumulates) | 5 calls, ~9K tokens |

## Router vs. Supervisor

A **router** is a dedicated routing step — often a single LLM call or rule-based logic — that classifies input and dispatches to agents. It is preprocessing without built-in conversation awareness.

A **supervisor** is a main agent dynamically deciding which subagents to call as part of an ongoing conversation, maintaining context across turns. Use a router for clear input categories and deterministic dispatch; use a supervisor (the Subagents pattern) for flexible, conversation-aware orchestration where the LLM decides what to do next based on evolving context.

## Deep Agents and Observability

[Deep Agents](../deepagents/01-introduction.md) is a higher-level harness built on LangChain that bundles these patterns (subagents, skills, planning, filesystem) into a single `create_deep_agent` factory — useful when you want the supervisor + subagent + skills wiring out of the box.

For tracing and evaluation of multi-agent flows, instrument runs with **LangSmith**, which captures per-agent spans, tool calls, and token usage across all five patterns.

## Key Design Principle

At the center of multi-agent design is context engineering -- deciding what information each agent sees. The quality of your system depends on ensuring each agent has access to the right data for its task.

Patterns can be mixed and nested for maximum flexibility in complex systems.
