# Deep Agents Harness

## Overview
The agent harness provides a comprehensive set of capabilities for building long-running autonomous agents. These include planning, filesystem access, task delegation, context management, code execution, and human oversight features.

## Core Capabilities

### Planning Tools
Agents access a `write_todos` tool for maintaining structured task lists with status tracking (pending, in_progress, completed). This helps organize complex multi-step workflows.

### Virtual Filesystem Access
A configurable filesystem backend supports standard operations:
- **ls**: Directory listing with metadata (size, modified time)
- **read_file**: Content retrieval with line numbers and offset/limit for large files; returns multimodal content for images (PNG, JPG, GIF, WebP, HEIC), video (MP4, MOV, AVI), audio (WAV, MP3, AAC, FLAC), and documents (PDF, PPT)
- **write_file**: File creation
- **edit_file**: Exact string replacement with optional global replace mode
- **glob**: Pattern-based file discovery (e.g., `**/*.py`)
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

1. **Offloading**: Large tool results exceeding a configurable threshold are stored to disk with pointer references in active memory
2. **Summarization**: When context approaches the model's window limit, conversation history gets compressed into a structured summary while preserving original messages in filesystem storage

### Code Execution
Two execution paths are supported:
- **Sandbox backends** expose an `execute` tool for isolated shell command execution — security, clean environments, and reproducibility without affecting host systems.
- **Interpreters** offer lightweight JavaScript evaluation through a QuickJS runtime with no shell or network access, useful for deterministic tool composition and data transformation.

### Human-in-the-Loop
Optional interruption configuration pauses execution at specified tool calls for human approval or input modification.

## Supporting Features

**Skills**: Specialized workflows following the Agent Skills standard, loaded progressively when relevant to reduce token consumption.

**Memory**: Persistent context files (AGENTS.md format) providing reusable guidelines, preferences, and project knowledge across conversations.
