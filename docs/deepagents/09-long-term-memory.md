# Long-term Memory

## Overview
Deep agents can implement persistent memory across conversation threads using a `CompositeBackend` that routes specific file paths to permanent storage while keeping other files ephemeral.

## Key Architecture

The system uses a path-based routing strategy:

- **`/memories/*` paths**: Stored persistently via `StoreBackend`
- **Other paths**: Remain transient in agent state via `StateBackend`

## Setup Implementation

Configuration requires three components:

1. A checkpointer (e.g., `MemorySaver`)
2. A store implementation (e.g., `InMemoryStore` for dev, `PostgresStore` for production)
3. A `CompositeBackend` with routing rules

The backend factory function receives a runtime parameter and returns the configured router.

## Storage Behavior

- **Transient files**: Persist only within a single conversation thread, discarded when it ends
- **Persistent files**: Survive thread completion and agent restarts, accessible across all conversations

## Important Implementation Detail

`CompositeBackend` strips the route prefix before storing — meaning `/memories/preferences.txt` is stored internally as `/preferences.txt`, though agents always reference the full path.

## Cross-Thread Access

Different threads with unique IDs can access the same `/memories/` files, enabling knowledge sharing between separate conversations.

## Production Considerations

For deployed agents on LangSmith, external code can interact with memories via the Store API using namespace tuples like `(assistant_id, "filesystem")`. Data uses a standardized format with content lines, creation timestamps, and modification timestamps.

## Common Use Cases

- Accumulating user preferences across sessions
- Self-improving instructions updated via feedback
- Building knowledge bases incrementally
- Maintaining research progress across multiple conversations
