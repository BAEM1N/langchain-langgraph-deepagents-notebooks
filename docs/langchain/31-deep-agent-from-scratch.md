# Build a Deep Agent from Scratch

## Overview

Deep Agents can be used in two ways:

1. `create_deep_agent()` — batteries-included harness factory
2. `create_agent()` + Deep Agents middleware — assemble the harness one layer at a time

The second route is useful for teaching because it shows that a deep agent is not a separate runtime: it is a LangChain agent running on LangGraph with middleware for filesystem context, planning, subagents, skills, memory, sandbox execution, and optional grading/interpreter capabilities.

## Layering Model

| Layer | Purpose | Typical API |
|------|---------|-------------|
| Base agent | Tool-calling loop | `langchain.agents.create_agent` |
| Filesystem/context | Read/write working files | Deep Agents filesystem middleware/backend |
| Planning | Track multi-step work | `write_todos` middleware/tool |
| Skills | Load domain instructions on demand | SKILL.md directories |
| Sandbox | Execute code outside host process | sandbox backend |
| Rubric | Runtime self-evaluation loop | `RubricMiddleware` |

## Teaching Pattern

Start with a minimal `create_agent()` example, then add one Deep Agents concern at a time:

```python
from langchain.agents import create_agent

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[analyze_csv],
    system_prompt="You are a careful data analyst.",
)
```

Then compare with the harness shortcut:

```python
from deepagents import create_deep_agent
from deepagents.backends import LocalShellBackend
from langgraph.checkpoint.memory import InMemorySaver

backend = LocalShellBackend(
    root_dir="./agent-work",
    virtual_mode=True,
    env={"PATH": "/usr/bin:/bin"},
    inherit_env=False,
)
agent = create_deep_agent(
    model="openai:gpt-5.4",
    tools=[analyze_csv],
    backend=backend,
    checkpointer=InMemorySaver(),
    interrupt_on={"execute": True},
    system_prompt="You are a careful data analyst.",
)
```

This is a development-only host shell. `root_dir` and `virtual_mode=True` constrain filesystem-tool paths, not shell access; `execute` still has no shell isolation. Use a sandbox backend in production.

The point is not to replace `create_deep_agent()`, but to make the hidden harness layers visible before learners use the shortcut.

## When to Use This Route

| Use `create_agent()` + middleware | Use `create_deep_agent()` |
|-----------------------------------|---------------------------|
| Teaching the architecture | Building quickly |
| Need exact middleware ordering | Accepting harness defaults |
| Migrating existing LangChain agents | Starting a new deep-agent app |
| Comparing cost/latency per layer | Multi-step autonomous task by default |

## Related

- `03-agents.md` — LangChain v1 agent factory
- `10-middleware-overview.md` — middleware lifecycle
- `../deepagents/05-harness.md` — Deep Agents harness architecture
- `../deepagents/19-rubric.md` — runtime grading loop
