# Custom Middleware Documentation

## Overview

This documentation covers building custom middleware in LangChain by implementing hooks that intercept agent execution at specific points.

## Hook Types

Two primary hook styles are available:

**Node-style hooks** execute sequentially at specific execution points and are useful for logging, validation, and state updates. Available options include:
- `before_agent` - Initial execution point
- `before_model` - Pre-model call
- `after_model` - Post-model response
- `after_agent` - Final execution point

**Wrap-style hooks** intercept execution around model and tool calls, allowing you to control whether the handler executes zero, one, or multiple times. This enables retry logic, caching, and transformation.

## Implementation Approaches

**Decorator-based middleware** works well for single-hook scenarios requiring minimal configuration. Multiple decorators can be imported from `langchain.agents.middleware`.

**Class-based middleware** extends `AgentMiddleware` and suits complex scenarios with multiple hooks, custom configuration, or both sync/async implementations needed for the same hook.

## Custom State Schema

Middleware can extend agent state by defining custom properties using `NotRequired` type hints. This enables tracking values across execution, sharing data between hooks, and implementing cross-cutting concerns like rate limiting or audit logging.

## Execution Order

When multiple middleware are registered, execution follows specific patterns:
- `before_*` hooks: First to last order
- `after_*` hooks: Last to first order (reversed)
- `wrap_*` hooks: Nested, with first middleware wrapping all others

## Agent Jumps

Early exits are possible by returning dictionaries containing `jump_to` fields targeting `'end'`, `'tools'`, or `'model'` nodes.

## Practical Examples

The documentation includes implementations for dynamic model selection, tool call monitoring, runtime tool filtering, and system message modification—including cache control support for Anthropic models.

## Best Practices

Keep middleware focused on single responsibilities, handle errors gracefully, select appropriate hook types for the use case, document custom state properties clearly, test middleware independently, and consider execution order when registering multiple middleware instances.
