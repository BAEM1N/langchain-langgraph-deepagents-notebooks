# Skills

## Overview
Skills extend agent capabilities through reusable, specialized workflows following the Agent Skills specification. They enable agents to access domain-specific knowledge without cluttering the main system prompt.

## Structure

Skills organize as directories containing:
- `SKILL.md` file with instructions and metadata
- Optional scripts, reference docs, and assets
- All supporting files must be documented in `SKILL.md`

## How Skills Load

The agent uses **progressive disclosure**: it reads skill descriptions in frontmatter, matches relevant skills to user prompts, then accesses full skill content only when needed. This reduces token overhead compared to loading everything upfront.

## Key Configuration

**Frontmatter fields in SKILL.md:**
- `name`: Skill identifier
- `description`: Task-matching criteria (max 1024 characters)
- `module`: Optional path to a Python/TypeScript file exposed to the interpreter (interpreter skills only)
- `license`, `compatibility`, `metadata`, `allowed-tools`: Optional metadata
- File size limit: 10 MB per skill (oversized files are skipped during loading)

## Usage Patterns

```python
agent = create_deep_agent(
    skills=["/skills/"],
    checkpointer=checkpointer,
)
```

Four backend options support skills:
- **StateBackend**: Seed files via `invoke(files={...})` with `create_file_data()`
- **StoreBackend**: Load skills from persistent storage namespaces (`InMemoryStore`, `PostgresStore`)
- **FilesystemBackend**: Read skills from disk relative to the agent's root directory
- **CompositeBackend**: Route skill files to one backend (typically `StoreBackend`) while delegating execution to another (e.g., a sandbox)

## Source Precedence

When multiple sources contain same-named skills, the skill from the source listed later in the `skills` array takes precedence (last one wins). This enables layering from different origins in order of importance.

## Code Execution Patterns

Skills support two complementary code-execution shapes.

- **Interpreter skills**: Expose importable functions to the interpreter through the `module` frontmatter field. Use for reusable, deterministic helpers — parsing, validation, scoring, normalization — that must produce consistent results across invocations.
- **Sandbox script execution**: Run scripts that need dependencies, CLI tools, or OS filesystem access. Requires syncing skill files into the sandbox via custom middleware before agent startup (see `11-sandboxes.md`).

## Subagent Skills

- General-purpose subagents inherit main agent skills automatically
- Custom subagents require explicit `skills` parameters and remain isolated from parent agent skills

## Skills vs. Memory

| Aspect | Skills | Memory |
|--------|--------|--------|
| **Loading** | On-demand via progressive disclosure | Always injected into system prompt |
| **Format** | `SKILL.md` in named directories | `AGENTS.md` files |
| **Layering** | Last source wins | User + project combined |
| **Best for** | Large, task-specific contexts; bundled capabilities | Always-relevant project conventions |

## Design Recommendations

- Write detailed descriptions for accurate matching
- Use skills for substantial context bundles
- Prefer tools for agents without filesystem access
- Use skills to reduce system prompt token usage
