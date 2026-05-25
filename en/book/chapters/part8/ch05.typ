// Source: 08_integration/11_provider_middleware/04_claude_memory.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Claude Memory", subtitle: "The `/memories/*` path contract")

The Claude native `memory_20250818` tool implements _long-term memory_ the model writes and reads itself. The injected system prompt instructs the model each turn to "check `/memories` first", so preferences and facts accumulate naturally across multiple sessions with the same user. Understanding the persistence difference between the State and Filesystem variants is the core of this chapter.

#learning-header()
#learning-objectives(
  [Understand the Claude memory tool's `/memories/` path contract],
  [Distinguish persistence scope between State and Filesystem variants],
  [Know how the injected `system_prompt` instructs the model to use memory],
  [Clarify the division of labor with Deep Agents' `StoreBackend`],
)

== 5.1 When to use it

- A chatbot that must remember preferences / facts across _multiple sessions_ with the same user
- An agent working on a long task that needs to _write and later read its own intermediate notes_
- Unlike RAG, you want the _model itself to manage_ memory contents (write, delete, edit)

== 5.2 Environment setup

Required packages: `langchain`, `langchain-anthropic`. `ANTHROPIC_API_KEY` in `.env`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeMemoryMiddleware,
    FilesystemClaudeMemoryMiddleware,
)
from langgraph.checkpoint.memory import MemorySaver

load_dotenv()
`````)

== 5.3 State variant — persisted within the thread

`StateClaudeMemoryMiddleware` stores memo content in LangGraph state (`memory_files`). With a checkpointer such as `MemorySaver` / `PostgresCheckpointer`, content is _restored automatically when resuming the same `thread_id`_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`allowed_path_prefixes`],
  [`["/memories"]`],
  [Allowed memo paths. Usually leave as is],
  [`system_prompt`],
  [Anthropic default],
  [Instructs the model to "check /memories first" at the start of every turn],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    checkpointer=MemorySaver(),
    middleware=[StateClaudeMemoryMiddleware()],
)

cfg = {"configurable": {"thread_id": "user-42"}}

agent.invoke(
    {"messages": [{"role": "user", "content": "My name is Jihun."}]},
    config=cfg,
)

# Re-invoke with the same thread_id → memo reused
result = agent.invoke(
    {"messages": [{"role": "user", "content": "Do you remember my name?"}]},
    config=cfg,
)
print(result["messages"][-1].content)
`````)

On the second call, the model does not ask for the name — it reads `/memories` and answers with "Jihun".

== 5.4 Filesystem variant — across process boundaries

`FilesystemClaudeMemoryMiddleware` keeps memos on _an actual disk directory_. Even if the process exits or the checkpoint store changes, the files stay on disk and remain readable.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`root_path`],
  [(required)],
  [Actual directory to store memories in],
  [`allowed_prefixes`],
  [`["/memories"]`],
  [Allowed virtual paths for memo writes],
  [`max_file_size_mb`],
  [`10`],
  [Maximum per-memo file size],
  [`system_prompt`],
  [Built-in],
  [The prompt directing memory usage],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        FilesystemClaudeMemoryMiddleware(
            root_path="/var/data/claude-memory",
            max_file_size_mb=2,
        ),
    ],
)
`````)

== 5.5 Scaling to a durable checkpointer

`MemorySaver` is an in-process dict — it evaporates on restart. In production, use the context-manager pattern of `langgraph-checkpoint-postgres` or `-sqlite`: acquire a pool with `from_conn_string()`, then call `setup()` once to create the schema.

#code-block(`````python
from langgraph.checkpoint.postgres import PostgresSaver

DB = "postgresql://user:pass@localhost/agent"

with PostgresSaver.from_conn_string(DB) as checkpointer:
    checkpointer.setup()  # one-time — creates tables / indexes

    agent = create_agent(
        model="anthropic:claude-sonnet-4-6",
        checkpointer=checkpointer,
        middleware=[StateClaudeMemoryMiddleware()],
    )
`````)

#tip-box[For async graphs, wrap `AsyncPostgresSaver.from_conn_string(DB)` with `async with`. `setup()` also needs `await`. SQLite follows the same context-manager API (`SqliteSaver` / `AsyncSqliteSaver`).]

== 5.6 Multi-tenant isolation via `runtime.context.user_id`

When many users share the same disk directory (or the same Store), isolate with a _namespace_. From LangGraph 1.2, the standard pattern reads `runtime.context.user_id` directly and uses it as the Store namespace key.

#code-block(`````python
from langgraph.store.postgres import PostgresStore
from langgraph.runtime import get_runtime

with PostgresStore.from_conn_string(DB) as store:
    store.setup()

    def upsert_profile(profile: dict) -> str:
        rt = get_runtime()
        ns = ("profiles", rt.context.user_id)  # per-user namespace
        store.put(ns, "self", profile)
        return "ok"
`````)

#tip-box[The Claude Memory Middleware's `/memories/*` path contract and the LangGraph Store's `(namespace, key)` contract live at _different layers_. The former lets Claude manage memos autonomously; the latter requires the code to assign keys explicitly — so multi-tenant isolation is a more natural fit for the Store.]

== 5.7 Relationship with Deep Agents' `StoreBackend`

Deep Agents 0.5 ships a separate `StoreBackend` for persistent memory. The two have _similar roles but different scope_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Axis],
  text(weight: "bold")[Claude Memory Middleware],
  text(weight: "bold")[Deep Agents `StoreBackend`],
  [Provider],
  [Anthropic native tool],
  [LangGraph Store API wrapper],
  [Supported models],
  [Claude only],
  [All models],
  [Storage shape],
  [`/memories/*` files],
  [`(namespace, key) → dict`],
  [Retrieval],
  [File list + content read],
  [Embedding vector search supported],
  [Typical uses],
  [Claude freely managing memos],
  [Structured profiles / facts],
)

*Combine tip*: You can use both. Have Claude keep short-term work notes in `/memories`, and put long-term profiles in Deep Agents' `StoreBackend` to share with agents from other providers — a pragmatic pattern.

== Key Takeaways

- The Claude native memory tool enforces "check first, update when needed" via the `/memories/*` path contract and an auto-injected system prompt
- The State variant restores on thread resume via a checkpointer; the Filesystem variant persists on disk permanently
- `max_file_size_mb` prevents the model from dumping everything into a single memo
- Deep Agents' `StoreBackend` complements via vector search and cross-provider sharing
