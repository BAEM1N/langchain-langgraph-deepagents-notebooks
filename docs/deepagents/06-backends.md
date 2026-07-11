# Deep Agents Backends

## Overview
Deep agents expose filesystem operations through pluggable backends. Tools like `ls`, `read_file`, `write_file`, `edit_file`, `glob`, and `grep` operate via configurable backend implementations. The `read_file` tool supports image files across all backends as multimodal content.

## Available Backends

### StateBackend (Default)
Stores files in LangGraph agent state for the current thread. Ideal for scratch pads and automatic eviction of large outputs. Files persist across agent turns via checkpoints but only within a single thread. Note: calling backend methods outside of a graph run won't take effect until the graph executes.

### FilesystemBackend
Provides local disk access with configurable `root_dir`. Setting `virtual_mode=True` blocks `..`, `~`, and absolute paths outside `root_dir`. **Security warning**: agents can read any accessible file including secrets (API keys, `.env`, credentials). Combined with network tools, secrets may be exfiltrated via SSRF attacks.

### LocalShellBackend
Extends FilesystemBackend with unrestricted shell command execution via the `execute` tool. Commands run with `subprocess.run(shell=True)` with **no sandboxing**. `root_dir` sets the working directory and `virtual_mode=True` normalizes paths for file tools, but neither prevents shell commands from reaching other host paths. Run it only for local development with a minimal environment and HITL; never use it on shared or production systems.

### StoreBackend
Leverages LangGraph's `BaseStore` for cross-thread persistent storage. Works with Redis, Postgres, or cloud implementations. Supports namespace factories for multi-user isolation — as of `deepagents>=0.5.2`, the factory receives a LangGraph `Runtime` object. Automatically provisioned when deployed via LangSmith.

### ContextHubBackend
Stores files in LangSmith Hub repositories. Pulls the Hub repo tree lazily on first use, serves reads from an in-memory cache, commits writes, and handles optimistic parent-commit conflicts automatically.

### CompositeBackend
Routes different filesystem paths to different backends. Common pattern: ephemeral state by default with persistent `/memories/` directory backed by a store. Routing precedence: longer prefixes win.

### Sandboxes
Execute code in isolated environments (Modal, Daytona, Deno, or local VFS) with filesystem tools and shell execution capabilities.

## Custom Implementation

Implement `BackendProtocol` with these required methods:
- `ls(path)` – returns `LsResult` with entries (`path`, optionally `is_dir`, `size`, `modified_at`), sorted deterministically
- `read(file_path, offset=0, limit=2000)` – returns `ReadResult` with data or `ReadResult(error=...)` on missing files
- `grep(pattern, path=None, glob=None)` – returns structured matches in `GrepResult`; on error return `GrepResult(error=...)` (do not raise)
- `glob(pattern, path="/")` – returns matched `FileInfo` entries, empty list if none match
- `write(file_path, content)` – create-only semantics; on conflict return `WriteResult(error=...)`. Return `files_update=None` for external backends
- `edit(file_path, old_string, new_string, replace_all=False)` – enforce uniqueness of `old_string` unless `replace_all=True`; include `occurrences` count on success

### Stable package versus hosted docs

The course pins the latest stable package, `deepagents==0.6.12`. Its runtime `BackendProtocol` has no `delete` method. The hosted documentation already describes optional `delete(file_path) -> DeleteResult`; that contract is present in the `0.7.0a6` prerelease, where unsupported backends hide the tool. Treat it as a preview until a stable 0.7 release is adopted and verified here.

## Security Considerations

Both `FilesystemBackend` and `LocalShellBackend` pose significant risks in production:
- Enable Human-in-the-Loop middleware for sensitive operations
- Use sandbox backends for production filesystem access
- Never expose API keys or credentials to agent-accessible paths
- Use `root_dir` plus `virtual_mode=True` to limit file-tool paths
- Do not treat `virtual_mode` as shell isolation for `LocalShellBackend`

## Policy Enforcement

Two approaches beyond path-based backends:

1. **Permissions system** — declaratively control which files and directories an agent can read or write (see the separate permissions guide for rule ordering and subagent control).
2. **Policy hooks** — subclass backends or wrap them with custom validation logic (e.g., a `GuardedBackend` that denies writes/edits under selected prefixes by overriding `write()` and `edit()`).

## Usage Examples

```python
# Basic StateBackend (default)
agent = create_deep_agent(model="google_genai:gemini-3.5-flash")

# CompositeBackend with routing
agent = create_deep_agent(
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/workspace/": FilesystemBackend(root_dir="/path/to/project", virtual_mode=True),
        },
    )
)

# StoreBackend with namespace factory
backend = StoreBackend(
    namespace=lambda rt: (rt.server_info.user.identity,),
)

# Development only: this reduces exposure but is not a sandbox
backend = LocalShellBackend(
    root_dir="./agent-work",
    virtual_mode=True,
    env={"PATH": "/usr/bin:/bin"},
    inherit_env=False,
)
agent = create_deep_agent(
    backend=backend,
    interrupt_on={"execute": True},
)
```

## Version Notes

- Pre-constructed backend instances are preferred over factory functions (the older factory pattern is deprecated).
- Namespace factories receive a LangGraph `Runtime` object as of `deepagents>=0.5.2` (previously a `BackendContext` wrapper).
