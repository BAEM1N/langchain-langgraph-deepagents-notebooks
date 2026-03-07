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

A primary agent coordinates subagents as tools, with all routing decisions passing through the main agent.

### 2. Handoffs

Agents dynamically transfer control based on state changes, with tool calls triggering routing or configuration modifications.

### 3. Skills

A single agent loads specialized knowledge on-demand while maintaining control throughout the process.

### 4. Router

An initial routing step classifies input and directs it to appropriate agents, synthesizing results afterward.

### 5. Custom Workflow

Bespoke execution flows built with LangGraph, combining deterministic logic and agentic behavior.

## Pattern Selection Criteria

Different patterns excel in different contexts:

- **Subagents** - Best for parallel execution and multi-domain tasks
- **Handoffs** - Optimal for sequential multi-step interactions with direct user engagement
- **Skills** - Ideal for simple, focused tasks with repeated requests
- **Router** - Strong for parallel execution with explicit routing needs

## Performance Analysis

The documentation provides detailed performance comparisons across three scenarios:

**Single Request**: Subagents (4 calls) vs. Handoffs/Skills/Router (3 calls each)

**Repeat Requests**: Stateful patterns (Handoffs, Skills) achieve 40-50% reduction in model calls by retaining context

**Multi-Domain Tasks**: Parallel patterns (Subagents, Router) process approximately 9K tokens vs. 14K+ for sequential approaches

## Key Design Principle

At the center of multi-agent design is context engineering -- deciding what information each agent sees. The quality of your system depends on ensuring each agent has access to the right data for its task.

Patterns can be mixed and nested for maximum flexibility in complex systems.
