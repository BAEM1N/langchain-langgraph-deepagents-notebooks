# Handoffs Architecture Documentation

## Overview

The handoffs pattern enables dynamic behavior changes in multi-agent systems by using tools to update state variables that persist across conversation turns. This approach supports both agent transitions and dynamic configuration adjustments.

## Core Concept

Behavior changes based on a state variable (e.g., `current_step` or `active_agent`) with tools managing state updates to move between workflow stages.

## Key Characteristics

- **State-driven behavior**: Configuration adjusts based on tracked state variables
- **Tool-based transitions**: Tools return `Command` objects updating state
- **Direct user interaction**: Each state handles messages independently
- **Persistent state**: State survives across conversation turns

## Implementation Approaches

### Single Agent with Middleware

A single agent dynamically adjusts behavior through middleware that intercepts model calls. Middleware applies different system prompts and tool sets based on the current state variable. This approach is recommended for most scenarios due to its simplicity.

### Multiple Agent Subgraphs

Distinct agents operate as separate graph nodes. Handoff tools use `Command.PARENT` to navigate between agents. This requires careful "context engineering" to ensure valid conversation history flows between agents.

## Critical Implementation Detail

When tools update messages via `Command`, include a `ToolMessage` with matching `tool_call_id`. This requirement ensures the conversation history becomes valid rather than malformed, as LLMs expect paired tool calls and responses.

## When to Use

This pattern suits scenarios requiring sequential constraints, direct user conversation across states, or multi-stage flows -- particularly customer support workflows needing information collected in specific sequences.
