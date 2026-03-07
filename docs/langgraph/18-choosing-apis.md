# Choosing between Graph and Functional APIs

## Overview

LangGraph offers two distinct approaches for building agent workflows: the **Graph API** and the **Functional API**. Both share the same runtime and can coexist in applications, but serve different use cases.

## Quick Decision Guide

**Use Graph API for:**
- "Complex workflow visualization for debugging and documentation"
- Explicit state management across multiple nodes
- Multiple decision points requiring conditional branching
- Parallel execution paths that need merging
- Team collaboration where visual diagrams aid comprehension

**Use Functional API for:**
- "Minimal code changes to existing procedural code"
- Standard control flow (if/else, loops, function calls)
- Function-scoped state without explicit management
- Rapid prototyping with reduced boilerplate
- Simple linear workflows

## Graph API Use Cases

**Complex decision trees:** Multiple conditional branches become visually explicit and debuggable through node and edge definitions.

**Shared state management:** "Multiple nodes can access and modify shared state" across workflow components through TypedDict schemas.

**Parallel processing:** Multiple nodes execute simultaneously and synchronize at merge points naturally.

**Team development:** Visual graph structure enables clear separation of concerns among team members.

## Functional API Use Cases

**Existing code integration:** Add LangGraph capabilities to procedural code with minimal refactoring using decorators.

**Linear workflows:** Sequential operations with straightforward conditionals flow naturally.

**Rapid prototyping:** "Fast iteration - no state schema needed" for quick experimentation.

**Function-scoped state:** Local variables within functions handle state without broader sharing requirements.

## Combining Both APIs

Applications can use both APIs simultaneously. The Graph API handles complex multi-agent coordination while the Functional API processes simpler data pipelines, with outputs passing between them as needed.

## Migration Paths

Workflows can migrate from Functional to Graph API as complexity increases, or from Graph to Functional API when over-engineering becomes apparent.
