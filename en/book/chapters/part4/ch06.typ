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

#image("../../../../book/assets/diagrams/png/composite_backend.png")

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

#tip-box[Follow _least privilege_ when assigning skills to subagents. Handing a review-focused subagent unrelated deployment skills wastes tokens and invites confusion. Give each subagent only the skills that match its role.]

#line(length: 100%, stroke: 0.5pt + luma(200))
== 6.10 Long-term Memory Types (in 0.5)

Deep Agents 0.5 classifies stored information into three categories. Each type uses a different storage mechanism, update cadence, and backend. The core rule is _not_ to push all three into one backend, but to distribute them across the mechanisms that match their nature.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Meaning],
  text(weight: "bold")[Storage example],
  text(weight: "bold")[Mechanism],
  [*Episodic*],
  [Past experience — conversation sessions, problem-solving trajectories],
  [Thread history of past conversations],
  [Checkpointers (per thread)],
  [*Procedural*],
  [Reusable instructions · skills · workflows],
  [`SKILL.md`, procedure docs],
  [Skills (loaded on demand)],
  [*Semantic*],
  [Facts · preferences · policies],
  [`AGENTS.md`, `/memories/*.txt`],
  [StoreBackend (always-on files)],
)

Example: long-running preferences in `/memories/` (semantic) + episodic case retrieval via checkpointer (episodic) + repeated procedures as skills (procedural).

=== Scope patterns: agent-scoped vs user-scoped

The tuple returned by `StoreBackend`'s `namespace` function _is_ the scope of the memory. The two most common patterns are:

*Agent-scoped — shared identity accumulation.* Namespace is `(assistant_id,)`. _All user conversations_ that use the same assistant share the same memory. Suitable for organization-wide conventions and domain knowledge, but _do not store sensitive information here_ because information flows between users.

#code-block(`````python
from deepagents.backends import StoreBackend

agent_scoped = StoreBackend(
    namespace=lambda rt: (rt.server_info.assistant_id,),
)
`````)

*User-scoped — per-user isolation.* Namespace is `(user_id,)` or `(assistant_id, user_id,)`. Each user's memory is fully isolated, so user A's preferences are never exposed in user B's conversation. This is the default for production personalization assistants.

#code-block(`````python
user_scoped = StoreBackend(
    namespace=lambda rt: (rt.server_info.user.identity,),
)
`````)

=== Episodic memory via checkpointers

To turn past conversations from passive storage into _searchable memory_, wrap the threads saved by the checkpointer as a tool.

#code-block(`````python
from langchain.tools import tool, ToolRuntime

@tool
async def search_past_conversations(query: str, runtime: ToolRuntime) -> str:
    """Find related context from prior conversations."""
    user_id = runtime.server_info.user.identity
    threads = await client.threads.search(
        metadata={"user_id": user_id},
        limit=5,
    )
    # Summarize threads into the needed format and return
    ...
`````)

With this pattern the agent can reference "how did I solve this before" on its own.

=== Read-only policy (organization-wide)

Shared organizational memory is an injection vector. Enforce _write-blocking_ as follows.

#code-block(`````python
# policies is org-scoped and read-only
routes = {
    "/policies/": StoreBackend(
        namespace=lambda rt: (rt.context.org_id,),
    ),
}
`````)

Combined with pattern 4 from Part IV ch15 (permissions), apply `write deny` on `/policies/**`. Policies should only be updated from application code.

=== Background consolidation agent

Updating memory _during the conversation (hot path)_ increases latency, and the summary quality ends up tracking the model's hurried decisions. The alternative is to run a separate consolidation agent on a _cron schedule_.

#code-block(`````json
// langgraph.json
{
  "graphs": {
    "agent": "./agent.py:agent",
    "consolidation_agent": "./consolidation_agent.py:agent"
  }
}
`````)

Register the cron schedule:

#code-block(`````python
cron_job = await client.crons.create(
    assistant_id="consolidation_agent",
    schedule="0 */6 * * *",   # every 6 hours
    input={"messages": [{"role": "user", "content": "Consolidate recent memories."}]},
)
`````)

#warning-box[Keep the cron interval (`0 */6 * * *`) and the lookback window (`timedelta(hours=6)`) _aligned_ to avoid gaps and duplicates.]

=== Update-timing comparison

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Timing],
  text(weight: "bold")[Approach],
  text(weight: "bold")[Latency],
  text(weight: "bold")[Takes effect],
  [Hot path],
  [Agent calls `edit_file` mid-conversation],
  [Yes],
  [Immediately],
  [Background],
  [Consolidation agent processes between sessions],
  [Invisible to user],
  [From next conversation],
)

The default composition splits by type: sensitive or must-be-immediate preferences go on the hot path; long-term pattern accumulation runs in the background.


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
  [Three memory types],
  [Episodic (checkpointer) / Procedural (skills) / Semantic (store)],
  [Scope patterns],
  [agent-scoped (shared accumulation) / user-scoped (isolated, default) / org-scoped (read-only)],
  [Consolidation],
  [Hot path: immediate, adds latency / Background cron: non-blocking, reflected from next conversation],
)

Long-term memory and the skill system let agents accumulate knowledge beyond a single conversation and surface specialist capabilities when needed. The next chapter covers production-grade advanced features: Human-in-the-Loop, streaming, sandboxes, ACP, and the CLI.

== Next Steps
→ _#link("./07_advanced.ipynb")[07_advanced.ipynb]_: learn advanced features such as Human-in-the-Loop, streaming, sandboxes, and ACP.

