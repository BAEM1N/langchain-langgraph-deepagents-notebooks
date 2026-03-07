# Router Architecture Documentation

## Overview
The router pattern involves a routing step that classifies input and directs it to specialized agents. This approach works best when managing distinct knowledge domains requiring separate agent handling.

## Core Characteristics
- Query decomposition through classification
- Parallel invocation of zero or more specialized agents
- Result synthesis into coherent responses

## Use Cases
The router pattern suits scenarios with "distinct verticals (separate knowledge domains that each require their own agent)," parallel source querying, and synthesized result combining.

## Implementation Approaches

### Single Agent Routing
Using `Command` directs queries to one appropriate agent based on classification logic.

### Multiple Agent Routing (Parallel)
Using `Send` enables fan-out to multiple specialized agents simultaneously, with classifications determining which agents receive which queries.

## Architecture Modes

**Stateless**: Each request routes independently without memory between calls.

**Stateful**: Maintains conversation history across requests for multi-turn interactions.

### Stateful Implementation Options

1. **Tool Wrapper**: Wraps the stateless router as a tool within a conversational agent, keeping the router simple while the main agent manages memory.

2. **Full Persistence**: The router maintains state directly, storing message history and selectively including prior context when routing to agents.

## Router vs. Subagents

The documentation distinguishes these patterns: routers use "dedicated routing step (often a single LLM call or rule-based logic)" for classification, while subagents involve "supervisor agent dynamically decides" which agents to invoke during ongoing conversations.
