// Auto-generated from 04_context_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Context Engineering & Memory Deepening", subtitle: "- Static/Dynamic Context, InMemoryStore, Skills Pattern")

Deep learning of LangGraph's context system and long-term memory (Store). Covers everything from static/dynamic runtime contexts to long-term memory based on semantic search, and Progressive Disclosure (Skills) patterns.

== Learning Objectives

- Understand the two-dimensional (Mutability x Lifetime) matrix of context engineering.
- Implement a static runtime context with `context_schema` + `@dataclass`
- Manage dynamic runtime context with `state_schema` and `AgentState` customizations
- Utilizes `InMemoryStore`’s namespace, put, get, and search APIs
- Build long-term memory based on semantic search
- Design by distinguishing between 3 types of memory (Semantic, Episodic, Procedural)
- Implement Progressive Disclosure using Skills pattern
- Compare hot path vs background memory writing strategies

== 4.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

model = ChatOpenAI(model="gpt-4.1")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("Environment ready.")
`````)

== 4.2 Context Engineering Overview

Context engineering is the design of systems that provide AI with “the right information, in the right format, at the right time.” Beyond simple prompt engineering, it is an architectural approach to programmatically assembling contexts at runtime.

There are two main reasons why agents fail:
+ Lack of LLM skills
+ _Lack of context or inappropriate context_ (more frequent cause)

Therefore, context engineering is a core role for AI engineers and a fundamental solution to agent reliability.

=== Two-dimensional matrix: Mutability x Lifetime

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[_Static_ (immutable)],
  text(weight: "bold")[User ID, DB connection, tool definition],
  text(weight: "bold")[config files, etc.],
  [_Dynamic_ (variable)],
  [Conversation history, intermediate results],
  [User Preferences, Learned Memory],
)

=== 3 context types

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Mutability],
  text(weight: "bold")[Lifetime],
  text(weight: "bold")[Example],
  text(weight: "bold")[LangGraph Implementation],
  [Static Runtime],
  [Static],
  [Single run],
  [User ID, DB conn],
  [`context_schema`],
  [Dynamic Runtime (State)],
  [Dynamic],
  [Single run],
  [Messages, interim results],
  [`state_schema`],
  [Dynamic Cross-conv (Store)],
  [Dynamic],
  [Cross-conversation],
  [Affinity, Memory],
  [`InMemoryStore`],
)

=== 3 controllable context categories

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Control object],
  text(weight: "bold")[Characteristics],
  [_Model Context_],
  [Instructions, message history, tool, response format],
  [Transient],
  [_Tool Context_],
  [tool Access, read/write state, runtime context],
  [Persistent],
  [_Life-cycle Context_],
  [Transformation between stages, Summary, guardrails],
  [Persistent],
)

LangChain implements context engineering with a _middleware_ mechanism. Middleware such as `@dynamic_prompt` and `@wrap_model_call` can be used to update context or control between lifecycle stages.

== 4.3 Static runtime context -- `context_schema` + `\@dataclass`

Injects _unchanging_ information into `context_schema` while the agent is running. Define the schema as `@dataclass`, and access it as `ToolRuntime[Context]` from tool.

#code-block(`````python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime
from langchain.agents import create_agent

@dataclass
class UserContext:
    user_id: str
    role: str
    department: str
`````)

#code-block(`````python
@tool
def get_permissions(runtime: ToolRuntime[UserContext]) -> str:
    """View permissions based on the current user's role."""
    ctx = runtime.context
    perms = {"admin": "read,write,delete", "editor": "read,write"}
    return f"User {ctx.user_id} ({ctx.department}): {perms.get(ctx.role, 'read')}"
`````)

=== Key points

- You can use a type-safe context by passing `@dataclass` to `context_schema`
- Automatically injected as `runtime: ToolRuntime[Context]` type hint in tool function
- _read-only_ and unchangeable while running
- Suitable data: User ID, DB connection, API key, session metadata

== 4.4 Dynamic runtime context -- `state_schema`, `AgentState` custom

This state _changes_ as the agent processes messages and calls tool. Add custom fields by inheriting `AgentState`.

#code-block(`````python
from langchain.agents import AgentState

class RAGState(AgentState):
    """State including dynamic search context."""
    retrieved_docs: list[str]
    query_count: int

print(f"State keys: {list(RAGState.__annotations__.keys())}")
`````)

=== Static vs Dynamic Comparison

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Static Runtime (`context_schema`)],
  text(weight: "bold")[Dynamic Runtime (`state_schema`)],
  [Whether to change],
  [immutable (read-only)],
  [variable (node ​​updates)],
  [Delivery method],
  [`context=` parameters],
  [invoke input dict],
  [Approach],
  [`runtime.context.field`],
  [`state["field"]`],
  [suitable data],
  [Authentication Information, Settings],
  [Conversation history, intermediate results],
)

== 4.5 Long-term memory -- InMemoryStore native API

Use `InMemoryStore` for cross-conversation context. Long-term memory is per-user or app-level data that persists across sessions and threads.

=== Storage structure
The memory is stored as a _JSON document_, organized hierarchically into _namespace_:
- _namespace_: Folder role to classify memory (e.g. `(user_id, "preferences")`)
- _key_: Unique identifier for each memory (e.g. `"theme"`)
- Namespaces usually include user IDs or organization IDs to facilitate information management.

=== Basic API
#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[API],
  text(weight: "bold")[Description],
  [`store.put(namespace, key, value)`],
  [Save memory (upsert)],
  [`store.get(namespace, key)`],
  [Memory query by specific key],
  [`store.search(namespace)`],
  [Search all within a namespace],
  [`store.search(namespace, filter={...})`],
  [Search by filter conditions],
)

In production environments, you should use _DB-based Store_ (e.g. PostgreSQL) instead of `InMemoryStore`.

#code-block(`````python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
user_id = "user_42"
store.put((user_id, "preferences"), "theme", {"value": "dark"})
store.put((user_id, "preferences"), "language", {"value": "ko"})

item = store.get((user_id, "preferences"), "theme")
print(f"Theme: {item.value}")
`````)

#code-block(`````python
items = store.search((user_id, "preferences"))
for item in items:
    print(f"  [{item.key}] = {item.value}")

filtered = store.search(
    (user_id, "preferences"), filter={"value": "dark"}
)
print(f"Filtered results: {len(filtered)}")
`````)

== 4.6 Long-Term Memory -- Semantic Search

Setting the embedding function makes `InMemoryStore` support _semantic search_. Perform semantic-based similarity search with the `query` parameter.

#code-block(`````python
semantic_store = InMemoryStore(
    index={"embed": embeddings, "dims": 1536}
)
ns = ("user_42", "memories")
semantic_store.put(ns, "mem1", {"content": "Prefer pytest over unittest"})
semantic_store.put(ns, "mem2", {"content": "Use type hints for all functions"})
semantic_store.put(ns, "mem3", {"content": "Favorite food is sushi"})
semantic_store.put(ns, "mem4", {"content": "Works on the ML Infrastructure team"})
print("Four memories have been saved along with embedding.")
`````)

#code-block(`````python
results = semantic_store.search(
    ("user_42", "memories"), query="testing preferences", limit=2
)
for r in results:
    print(f"  [{r.key}] {r.value['content']}")
`````)

#code-block(`````python
results2 = semantic_store.search(
    ("user_42", "memories"), query="machine learning work", limit=2
)
for r in results2:
    print(f"  [{r.key}] {r.value['content']}")
`````)

=== Basic Store vs Semantic Store comparison

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[`InMemoryStore()`],
  text(weight: "bold")[`InMemoryStore(index={...})`],
  [Accurate key lookup],
  [`get(ns, key)`],
  [`get(ns, key)`],
  [Filter Search],
  [`search(ns, filter={...})`],
  [`search(ns, filter={...})`],
  [Semantic Search],
  [Not possible],
  [`search(ns, query="...", limit=N)`],
  [Production],
  [Use DB backend instead of `InMemoryStore`],
  [PostgreSQL-based Store recommended],
)

== 4.7 Reading/Writing Store from tool -- `ToolRuntime.store`

You can access the Store from within the agent's tool to read and write user information. If you connect a Store to `create_agent(store=...)`, it will be automatically injected into `runtime.store`.

=== Reading Pattern
Search for user information saved through `runtime.store` in tool. Both context and Store can be accessed with `ToolRuntime[Context]` type hints.

=== Writing Pattern
Receives user input with the tool parameter and saves the memory as `store.put()`. This allows agents to permanently store information learned during a conversation.

=== Key points
- `runtime.store`: Access Store instance
- `runtime.context`: Access static runtime context
- By combining Store and Context, you can systematically manage _"whose (context) information (store)"_

#code-block(`````python
@tool
def get_user_info(runtime: ToolRuntime[UserContext]) -> str:
    """Search the saved information of the current user."""
    store = runtime.store
    user_id = runtime.context.user_id
    info = store.get(("users",), user_id)
    return str(info.value) if info else "User information not found."
`````)

#code-block(`````python
@tool
def save_preference(key: str, value: str, runtime: ToolRuntime[UserContext]) -> str:
    """Stores user preferences."""
    store = runtime.store
    user_id = runtime.context.user_id
    store.put((user_id, "preferences"), key, {"value": value})
    return f"Preference saved: {key}={value}"
`````)

== 4.8 3 types of memory: Semantic, Episodic, Procedural

Long-term memory is categorized into three types inspired by cognitive science. _Storage structure_ and _utilization_ are different for each type.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  text(weight: "bold")[Example],
  text(weight: "bold")[structure],
  [_Semantic_],
  [factual knowledge about entities],
  [User preferences, profile information],
  [Profile or Collection],
  [_Episodic_],
  [Memories of past experiences and events],
  [Few-shot example, past action log],
  [Collection],
  [_Procedural_],
  [Rules/Guidelines on how to do it],
  [Fix system prompt, guidelines],
  [Profile (list of rules)],
)

=== Semantic Memory -- Profile vs Collection

Semantic memory has two approaches depending on the storage strategy:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Approach],
  text(weight: "bold")[structure],
  text(weight: "bold")[Suitable for],
  text(weight: "bold")[Example],
  [_Profile_],
  [Single JSON document, continuously updated],
  [Few well-known properties],
  [`{"name": "Alice", "language": "Python", "preferred_style": "concise"}`],
  [_Collection_],
  [Multiple narrow documents, high recall],
  [Open-end or large-scale knowledge],
  [`[{"topic": "testing", "content": "Prefers pytest"}, ...]`],
)

=== Episodic Memory
Record how you have behaved in similar situations in the past. It is used as a few-shot example, allowing the agent to learn from past experiences.

=== Procedural Memory
Stores the agent's behavioral rules. This has the effect of dynamically modifying system prompts, allowing the agent to follow user-specific instructions.

#code-block(`````python
mem_store = InMemoryStore(index={"embed": embeddings, "dims": 1536})
uid = "user_42"

# Semantic -- Profile (single JSON)
mem_store.put((uid, "profile"), "main", {
    "name": "Alice", "language": "Python",
    "preferred_style": "concise",
})
# Semantic -- Collection (multiple docs)
mem_store.put((uid, "facts"), "f1", {"content": "pytest preferred"})
`````)

#code-block(`````python
# Episodic -- past experiences (few-shot)
mem_store.put((uid, "episodes"), "ep1", {
    "content": "SQL Optimization -> Use EXPLAIN ANALYZE",
})

# Procedural -- rules/guidelines
mem_store.put((uid, "procedures"), "rules", {
    "content": "Always includes error handling. Use logging.",
})
print("All three memory types have been saved.")
`````)

#code-block(`````python
# Episodic search: find similar past experiences
episodes = mem_store.search(
    (uid, "episodes"), query="database query help", limit=1
)
for ep in episodes:
    print(f"Related episode: {ep.value['content']}")
`````)

== 4.9 Progressive Disclosure -- Skills pattern

Putting all the context in the prompt increases token cost and reduces accuracy. The Skills pattern is a Progressive Disclosure method that loads relevant information only when needed.

=== Structure of Skill
Skill is a unit of knowledge consisting of `{name, description, content}`:
- _name_: Skill identifier (e.g. `"customers_schema"`)
- _description_: Short description (included in system prompt)
- _content_: Details (load on demand with `load_skill` tool)

=== Strategies by Size

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[size],
  text(weight: "bold")[strategy],
  text(weight: "bold")[Example],
  [_\\\<1K tokens_],
  [Included directly in the system prompt],
  [table names, high-level relationships],
  [_1-10K tokens_],
  [Load on demand with `load_skill` tool],
  [Table schema, query patterns, best practices],
  [_\\\>10K tokens_],
  [Load on demand with pagination],
  [Large reference data, historical query logs],
)

=== Action flow
+ _Middleware_ injects the names and descriptions of all skills into the system prompt
+ The agent analyzes the question and determines the skills needed
+ Call `load_skill` tool to load details
+ Perform actions based on loaded content

=== Advantages

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Advantages],
  text(weight: "bold")[Description],
  [_Token Efficiency_],
  [Load only the information needed for the current query],
  [_Scalability_],
  [DB with hundreds of tables is also supported],
  [_Accuracy_],
  [Provide detailed schema at the point you need it],
  [_Cost Savings_],
  [Reduce input tokens per request],
)

#code-block(`````python
skills = [
    {"name": "db_overview",
     "description": "High-level Overview for all tables",
     "content": "Table: customers, orders, products"},
    {"name": "customers_schema",
     "description": "Full schema of the customers table",
     "content": "CREATE TABLE customers (id INT PK, name VARCHAR)"},
]
SKILL_MAP = {s["name"]: s for s in skills}
print(f"Defined {len(skills)} skills.")
`````)

#code-block(`````python
from langchain_core.tools import tool

@tool
def load_skill(skill_name: str) -> str:
    """Loads detailed information about the database skill."""
    skill = SKILL_MAP.get(skill_name)
    if skill is None:
        return f"Not found. Available: {', '.join(SKILL_MAP.keys())}"
    return f"## {skill['name']}\n\n{skill['content']}"
`````)

== 4.10 Hot Path vs Background Memory Write

Depending on _when_ you use memory, it will affect user response latency.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[method],
  text(weight: "bold")[Timing],
  text(weight: "bold")[Available immediately?],
  text(weight: "bold")[Delay Impact],
  [_Hot path_],
  [Real-time within conversation loop],
  [Instantly (available next turn)],
  [Increased response delay],
  [_Background_],
  [Separate asynchronous task],
  [Delayed (Eventual Consistency)],
  [No delay impact],
)

=== Write Hot Path
Save memory inline within the agent loop. This is perfect when you need to use that memory in the very next turn. Example: When you need to immediately reflect the preferences that the user just shared.

=== Background writing
Save memory as a separate process or asynchronous task. Used when Eventual Consistency is allowed and does not affect response delay. Examples: conversation pattern analysis, long-term learning data accumulation.

=== Selection criteria
- Is an immediate recall necessary? -\> _Hot path_
- Is reducing delay a priority? -\> _Background_
- In most cases, background writing is preferred.

#code-block(`````python
from langgraph.store.base import BaseStore

# Hot path: write inline (adds latency)
def reflect_node(state, store: BaseStore):
    """Extract and store memory inline."""
    last_msg = state["messages"][-1].content
    store.put(("user", "reflections"), "latest", {"content": last_msg})
    return state

print("Hot path: Immediately save, available next turn.")
`````)

#code-block(`````python
import asyncio

# Background: write in separate async task
async def background_memory_writer(state, store: BaseStore):
    """Saves memory in the background (no delays)."""
    last_msg = state["messages"][-1].content
    await store.aput(
        ("user", "reflections"), "latest", {"content": last_msg}
    )
print("Background: Eventual consistency, no delay.")
`````)

== Summary

=== Context Engineering Triad

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[element],
  text(weight: "bold")[implementation],
  text(weight: "bold")[API],
  [static runtime],
  [`context_schema` + `\@dataclass`],
  [`runtime.context.field`],
  [dynamic runtime],
  [`state_schema` + `AgentState`],
  [`state["field"]`],
  [long term memory],
  [`InMemoryStore` + `store=`],
  [`store.put/get/search`],
)

=== Memory 3 types

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Use],
  text(weight: "bold")[Namespace example],
  [Semantic],
  [User Profile/Facts],
  [`(user_id, "profile")`, `(user_id, "facts")`],
  [Episodic],
  [Past experience (few-shot)],
  [`(user_id, "episodes")`],
  [Procedural],
  [Edit Rule/Prompt],
  [`(user_id, "procedures")`],
)

=== Best Practices

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Principle],
  text(weight: "bold")[Description],
  [minimize static context],
  [Include only what is needed for the current task],
  [Namespace structuring],
  [Use hierarchical namespace to avoid collisions],
  [Semantic search priority],
  [Embedding-based search is more scalable than exact matching],
  [Background writing preference],
  [Reduce delay to background when immediate recall is not required],
  [Skills pattern application],
  [Large-scale context can be found in Progressive Disclosure],
)

=== Next Steps
→ _#link("./05_agentic_rag.ipynb")[05_agentic_rag.ipynb]_: Learn Agentic RAG.
