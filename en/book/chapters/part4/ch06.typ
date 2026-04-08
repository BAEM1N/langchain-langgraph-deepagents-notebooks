// Auto-generated from 06_memory_and_skills.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Long", subtitle: "Term Memory & Skills")

== Learning Objectives
- Implement long-term memory with `CompositeBackend` + `StoreBackend`
- Understand the cross-thread memory-sharing pattern
- Inject agent context through `AGENTS.md`
- Understand the structure of skills (`SKILL.md`) and Progressive Disclosure
- Understand the difference between Skills and Memory


#code-block(`````python
# Environment setup
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
print("Environment setup complete")

`````)

#code-block(`````python
# Configure the OpenAI gpt-4.1 model
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. Why Long-Term Memory Matters

A default `StateBackend` agent _forgets everything when the conversation thread ends_.
But a useful assistant often needs to preserve information _across threads_, such as:

- user preferences (coding style, preferred language)
- project conventions (architecture decisions, naming rules)
- feedback learned in previous conversations
- frequently referenced information (API docs, configuration values)

=== Solution: `CompositeBackend`

#image("../../assets/images/composite_backend.png")

Files stored under `/memories/` can be accessed _from any conversation thread_.


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend, StoreBackend, CompositeBackend, FilesystemBackend
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver


# 1. Create a store and a checkpointer
store = InMemoryStore()          # Development only (production: PostgresStore)
checkpointer = MemorySaver()     # Preserve agent state


# 2. Composite backend factory — persist only /memories/, keep the rest ephemeral
def memory_backend_factory(runtime):
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={
            "/memories/": StoreBackend(runtime),
        },
    )


# 3. Create the agent
memory_agent = create_deep_agent(
    model=model,
    system_prompt="""You are a personal assistant.
Save information the user wants to remember under /memories/.
If there is previously saved memory, use it when responding.
Respond in English.""",
    backend=memory_backend_factory,
    store=store,
    checkpointer=checkpointer,
)

print("Long-term memory agent created")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. Cross-Thread Memory Sharing

Data stored in `StoreBackend` is _shared across threads_.
In the example below, thread 1 stores preferences and thread 2 reads them later.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. Injecting Context with `AGENTS.md`

If you use the `memory` parameter, the agent automatically loads *`AGENTS.md` files at startup* and injects them into the system prompt.

=== What is `AGENTS.md`?
It is a Markdown file that contains _rules, conventions, and context information_ that should always apply to the agent.

=== Characteristics
- Always loaded when the agent starts (not on demand)
- Injected into the system prompt through `<agent_memory>`
- You can specify multiple memory sources
- The agent can update `AGENTS.md` itself with `edit_file`


#code-block(`````python
import tempfile

# Create a temporary directory to use as the root_dir for FilesystemBackend
tmp_dir = tempfile.mkdtemp()
print(f"Temporary directory created: {tmp_dir}")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. Skills

Skills are modular instruction bundles that give the agent _specialized domain knowledge_.

=== Memory vs Skills

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Comparison],
  text(weight: "bold")[Memory (`AGENTS.md`)],
  text(weight: "bold")[Skills (`SKILL.md`)],
  [_Loading_],
  [Always loaded],
  [Loaded only when needed],
  [_File format_],
  [`AGENTS.md`],
  [`SKILL.md` (YAML frontmatter)],
  [_Best fit_],
  [Rules and conventions that always apply],
  [Large context needed for specific tasks],
  [_Token efficiency_],
  [Always consumes tokens],
  [Saves tokens through Progressive Disclosure],
  [_Size_],
  [Best kept concise],
  [Can be large (up to 10 MB)],
  [_Updates_],
  [Can be edited by the agent],
  [Usually static],
)

=== Progressive Disclosure

Skills are not fully loaded all at once:
+ At first, only the _frontmatter_ (name, description, metadata) is loaded
+ The agent decides which skills are relevant to the user's request
+ Only then is the _full content_ of the necessary skills loaded

This approach saves tokens while still giving the agent access to deep task-specific knowledge.


=== `SKILL.md` Structure

#code-block(`````yaml
---
name: web-research
description: >
  Step-by-step guide for structured web research.
  Covers information gathering, verification, and summarization.
license: MIT
compatibility: Python 3.8+
metadata:
  category: research
allowed-tools: ls read_file write_file
---

# Web Research Skill

## When to use it
- When the user asks for research on a topic
- When the request depends on current information

## Workflow
1. Design search queries
2. Gather information from multiple sources
3. Cross-check the information
4. Write a structured report
`````)


#code-block(`````python
# Create an agent that uses skills
skilled_agent = create_deep_agent(
    model=model,
    system_prompt="You are a senior developer. Use the available skills to complete the task.",
    backend=FilesystemBackend(root_dir=tmp_dir, virtual_mode=True),
    skills=["/skills/"],
)

print("Skill-enabled agent created")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. Skill Source Priority

If you specify multiple skill sources, the _later source wins_.

#code-block(`````python
skills=[
    "/skills/base/",     # base skills
    "/skills/user/",     # can override base
    "/skills/project/",  # highest priority
]
`````)

If the same skill name exists in multiple locations, the version from the last source is used.


#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. Skill Inheritance for Subagents

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Subagent Type],
  text(weight: "bold")[Skill Inheritance],
  [Built-in general-purpose subagent],
  [_Automatically inherits_ the main agent's skills],
  [Custom `SubAgent`],
  [Requires an explicit `skills` parameter],
)

#code-block(`````python
subagent = {
    "name": "reviewer",
    "description": "Code review specialist",
    "system_prompt": "...",
    "tools": [],
    "skills": ["/skills/code-review/"],
}
`````)


#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [Long-term memory],
  [Persist `/memories/` with `CompositeBackend` + `StoreBackend`],
  [`AGENTS.md`],
  [`memory=["/path/AGENTS.md"]` → always injected into the system prompt],
  [Skills],
  [`skills=["/skills/"]` → `SKILL.md` with Progressive Disclosure],
  [Progressive Disclosure],
  [Load frontmatter first → load full skill only when needed],
  [Skill priority],
  [Later sources win],
  [Memory vs Skills],
  [Memory = always loaded / Skills = loaded on demand],
)

== Next Steps
→ _#link("./07_advanced.ipynb")[07_advanced.ipynb]_: learn advanced features such as Human-in-the-Loop, streaming, sandboxes, and ACP.

