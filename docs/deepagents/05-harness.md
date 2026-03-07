# Deep Agents Harness

## Overview
The agent harness provides a comprehensive set of capabilities for building long-running autonomous agents. These include planning, filesystem access, task delegation, context management, code execution, and human oversight features.

## Core Capabilities

### Planning Tools
Agents access a `write_todos` tool for maintaining structured task lists with status tracking (pending, in_progress, completed). This helps organize complex multi-step workflows.

### Virtual Filesystem Access
A configurable filesystem backend supports standard operations:
- **ls**: Directory listing with metadata
- **read_file**: Content retrieval with line numbers; supports images (PNG, JPG, GIF, WEBP)
- **write_file**: File creation
- **edit_file**: String replacement operations
- **glob**: Pattern-based file discovery
- **grep**: Content searching with multiple output modes
- **execute**: Shell command execution (sandbox backends only)

### Task Delegation (Subagents)
The harness allows the main agent to create ephemeral "subagents" for isolated multi-step tasks. Benefits include:
- Context isolation
- Parallel execution capability
- Specialization options
- Token efficiency through result compression

### Context Management

**Input Context**: System prompts, instructions, memory guidelines, skills information, and filesystem documentation assembled into a comprehensive initial prompt.

**Runtime Context Compression**: Two primary techniques:

1. **Offloading**: Content exceeding 20,000 tokens (configurable) gets stored to disk with pointer references in active memory
2. **Summarization**: When context approaches the model's window limit, conversation history gets compressed into a structured summary while preserving original messages in filesystem storage

### Code Execution
Sandbox backends expose an `execute` tool enabling isolated command execution. This provides security, clean environments, and reproducibility without affecting host systems.

### Human-in-the-Loop
Optional interruption configuration pauses execution at specified tool calls for human approval or input modification.

## Supporting Features

**Skills**: Specialized workflows following the Agent Skills standard, loaded progressively when relevant to reduce token consumption.

**Memory**: Persistent context files (AGENTS.md format) providing reusable guidelines, preferences, and project knowledge across conversations.
