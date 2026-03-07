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
- `license`, `compatibility`, `metadata`, `allowed-tools`: Optional metadata
- File size limit: 10 MB per skill

## Usage Patterns

```python
agent = create_deep_agent(
    skills=["/skills/"],
    checkpointer=checkpointer,
)
```

Three backend options support skills:
- **StateBackend**: Seed files via `invoke(files={...})`
- **StoreBackend**: Store in InMemoryStore
- **FilesystemBackend**: Load from disk

## Source Precedence

When multiple sources contain same-named skills, the last listed source wins. This enables layering from different origins.

## Subagent Skills

- General-purpose subagents inherit main agent skills automatically
- Custom subagents require explicit `skills` parameters and remain isolated from parent agent skills

## Skills vs. Memory

| Aspect | Skills | Memory |
|--------|--------|--------|
| **Loading** | On-demand via relevance | Always loaded |
| **Format** | `SKILL.md` | `AGENTS.md` |
| **Best for** | Large, task-specific contexts | Always-relevant conventions |

## Design Recommendations

- Write detailed descriptions for accurate matching
- Use skills for substantial context bundles
- Prefer tools for agents without filesystem access
- Use skills to reduce system prompt token usage
