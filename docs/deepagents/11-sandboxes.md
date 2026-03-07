# Sandboxes

## Overview
Sandboxes provide isolated execution environments where AI agents can safely run code, manage files, and execute shell commands without accessing the host system, credentials, or network resources.

## Key Concepts

**Purpose**: Execute code in isolated environments with sandbox backends, enabling agents to operate autonomously while protecting host systems.

**Architecture**: Sandboxes function as backends in deep agents, providing filesystem tools (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`) and an `execute` tool for shell commands.

## Integration Patterns

### Agent in Sandbox
The agent runs inside the sandbox with external communication via network protocols.
- **Benefits**: Development parity
- **Drawbacks**: Credential exposure risks, infrastructure complexity

### Sandbox as Tool
The agent operates externally, calling sandbox APIs for code execution.
- **Benefits**: Separates agent state from execution, keeps secrets outside sandboxes, enables parallel task execution
- **Drawbacks**: Network latency

## Supported Providers

- **Modal**: ML/AI workloads with GPU capabilities
- **Daytona**: TypeScript/Python development with fast cold starts
- **Runloop**: Disposable devboxes for isolated execution

## Critical Security Guidelines

**Never put secrets inside a sandbox** — context-injected agents can read and exfiltrate credentials stored as environment variables or mounted files.

**Safe Practices**:
- Keep credentials in external tools outside sandboxes
- Use human-in-the-loop approval for sensitive operations
- Block unnecessary network access
- Monitor for unexpected outbound connections
- Review all sandbox outputs before application use

## File Operations

Two distinct file access methods:
1. **Agent filesystem tools** (via `execute()`)
2. **File transfer APIs** (`uploadFiles()`, `downloadFiles()`) for seeding sandboxes and retrieving artifacts

## Lifecycle Management

Sandboxes require explicit shutdown to avoid unnecessary costs. Configure time-to-live settings for automatic cleanup in chat applications using unique sandboxes per conversation thread.
