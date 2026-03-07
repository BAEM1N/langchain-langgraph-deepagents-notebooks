# Deep Agents Backends

## Overview
Deep agents expose filesystem operations through pluggable backends. Tools like `ls`, `read_file`, `write_file`, `edit_file`, `glob`, and `grep` operate via configurable backend implementations. The `read_file` tool supports image files across all backends as multimodal content.

## Available Backends

### StateBackend (Default)
Stores files in LangGraph agent state for the current thread. Ideal for scratch pads and automatic eviction of large outputs. Files persist across agent turns via checkpoints but only within a single thread.

### FilesystemBackend
Provides local disk access with configurable `root_dir`. Includes `virtual_mode=True` option to restrict paths and prevent directory traversal. **Security warning**: agents can access any readable file including secrets.

### LocalShellBackend
Extends filesystem access with unrestricted shell command execution via the `execute` tool. Commands run directly on the host system with full user permissions. **Requires extreme caution** outside development environments.

### StoreBackend
Leverages LangGraph's `BaseStore` for cross-thread persistent storage. Works with Redis, Postgres, or cloud implementations. Automatically provisioned when deployed via LangSmith.

### CompositeBackend
Routes different filesystem paths to different backends. Common pattern: ephemeral state by default with persistent `/memories/` directory backed by a store.

### Sandboxes
Execute code in isolated environments (Modal, Daytona, Deno, or local VFS) with filesystem tools and shell execution capabilities.

## Custom Implementation

Implement `BackendProtocol` with these required methods:
- `ls_info()` – list directory contents
- `read()` – retrieve file with line numbering
- `grep_raw()` – pattern matching returning structured matches
- `glob_info()` – glob-based file matching
- `write()` – create-only file creation
- `edit()` – find-and-replace with uniqueness enforcement

## Security Considerations

Both `FilesystemBackend` and `LocalShellBackend` pose significant risks in production:
- Enable Human-in-the-Loop middleware for sensitive operations
- Use sandbox backends for production filesystem access
- Never expose API keys or credentials to agent-accessible paths
- Consider virtual_mode restrictions for local filesystem access

## Policy Enforcement

Subclass backends or wrap them with a `PolicyWrapper` to enforce rules like blocking writes to specific path prefixes, enabling enterprise-level access controls.
