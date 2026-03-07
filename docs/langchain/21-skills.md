# Skills Architecture Documentation

## Overview

The skills pattern structures specialized capabilities as invokable components that enhance agent behavior. Per the documentation, "Skills are primarily prompt-driven specializations that an agent can invoke on-demand."

## Core Concept

This architecture applies progressive disclosure to specialized prompts and domain knowledge. The documentation notes that this pattern is "conceptually identical to Agent Skills and llms.txt," using tool calling to reveal information gradually rather than loading everything upfront.

## Key Characteristics

According to the source material, skills feature:

- Prompt-driven definition and specialization
- Progressive disclosure based on context
- Independent team development and maintenance
- Lightweight composition compared to sub-agents
- Ability to reference scripts, templates, and resources

## When to Apply

The documentation recommends this pattern when implementing a single agent with multiple specializations, when inter-skill constraints aren't necessary, or when different teams develop capabilities independently. Example use cases include coding assistants, knowledge bases, and creative tools.

## Basic Implementation

The documentation provides this Python example:

```python
from langchain.tools import tool
from langchain.agents import create_agent

@tool
def load_skill(skill_name: str) -> str:
    """Load a specialized skill prompt."""
    # Load skill content from file/database
    ...
```

## Extension Possibilities

The source identifies three enhancement approaches:

1. **Dynamic tool registration**: Register new tools as skills load
2. **Hierarchical skills**: Nested specializations organized in tree structures
3. **Reference awareness**: Skills reference assets progressively disclosed as needed
