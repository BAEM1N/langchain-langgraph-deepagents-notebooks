# Context Engineering in Agents

## Overview

**Core Challenge**: Building reliable agents requires providing the right context to LLMs. The hard part of building agents (or any LLM application) is making them reliable enough.

### Why Agents Fail

Agents typically fail due to two factors:
1. Insufficient LLM capability
2. Missing or inadequate context

More often than not, it's actually the second reason that causes agents to not be reliable.

**Context Engineering Definition**: Supplying appropriate information and tools in proper format so LLMs can accomplish tasks effectively. This represents the number one job of AI Engineers.

### Agent Loop Structure

The agent operates through two core steps:
1. **Model Call** - Invokes LLM with prompts and available tools, returning either responses or tool execution requests
2. **Tool Execution** - Runs requested tools and returns results

This cycle continues until the LLM decides completion.

## Controllable Elements

Three primary context categories govern agent behavior:

| Category | Control | Type |
|----------|---------|------|
| **Model Context** | Instructions, message history, tools, response format | Transient |
| **Tool Context** | Tool access, state reads/writes, runtime context | Persistent |
| **Life-cycle Context** | Inter-step operations, summarization, guardrails | Persistent |

### Data Sources

Agents access three information layers:

1. **Runtime Context** - Static configuration (user IDs, API keys, permissions)
2. **State** - Short-term memory (current messages, files, authentication)
3. **Store** - Long-term memory (preferences, insights, historical data)

### Middleware Mechanism

LangChain uses middleware to implement context engineering, enabling developers to:
- Update context
- Jump between lifecycle steps

## Model Context Details

### System Prompt Engineering

Dynamic system prompts adapt to conversation state. Examples include:
- Adjusting length based on message count
- Incorporating user preferences from persistent storage
- Including compliance rules from runtime configuration

### Messages Management

Message context can be modified transiently (affecting single calls) or persistently (updating state permanently). Common patterns include:
- Injecting uploaded file information
- Including user writing style examples
- Adding compliance requirements

**Key Distinction**: The examples above use `wrap_model_call` to make **transient** updates - modifying what messages are sent to the model for a single call without changing what's saved in state.

### Tools Definition and Selection

**Clear Tool Specification**: Each tool requires descriptive names, detailed documentation, argument specifications, and clear parameter descriptions to guide LLM reasoning.

**Dynamic Selection**: Tools can filter based on:
- Authentication status
- User permissions (from runtime context)
- Feature flags (from persistent storage)
- Conversation stage (from state)

### Model Selection

Different models suit different scenarios. Selection criteria include:
- Conversation length
- User preferences
- Cost constraints
- Environment (production vs. development)

### Response Format

Structured output ensures validated, formatted results. Schemas adapt based on:
- Conversation progression
- User preferences
- User role/environment

## Tool Context

### Reading Context

Tools access information through:
- **State**: Current session data (authentication status)
- **Store**: Persisted preferences and historical information
- **Runtime Context**: Configuration like API keys and database connections

### Writing Context

Tools update context through:
- **State Updates**: Session-specific changes via Command objects
- **Store Writes**: Persistent changes across sessions
- **Return Values**: Direct results to the model

Example from documentation: Tools use `Command(...)` to update state persistently while model context changes remain transient.

## Life-cycle Context

Middleware hooks into the agent loop to:
- Transform data between steps
- Implement cross-cutting concerns
- Persist important information

### Summarization Pattern

Built-in `SummarizationMiddleware` automatically:
1. Summarizes older messages when conversations exceed token limits
2. Replaces them with summaries in state
3. Preserves recent messages for immediate context

Configuration example includes triggering on token count (4000) and keeping recent messages (20).

## Best Practices

The documentation recommends:

1. **Incremental Implementation** - Start with static configurations, add dynamics as needed
2. **Gradual Testing** - Introduce one context feature at a time
3. **Performance Monitoring** - Track model calls, tokens, and latency
4. **Built-in Solutions** - Leverage `SummarizationMiddleware` and similar tools
5. **Strategic Documentation** - Clearly explain context flow and reasoning
6. **Transient vs. Persistent Understanding** - Distinguish between per-call and state-persisting changes

## Related Documentation

The page references:
- Context conceptual overview
- Middleware documentation
- Tools creation guide
- Memory patterns
- Agent concepts

---

**Key Takeaway**: Context engineering -- facilitating context engineering through proper information structuring -- represents the primary mechanism for building reliable AI agents beyond simple prototypes.
