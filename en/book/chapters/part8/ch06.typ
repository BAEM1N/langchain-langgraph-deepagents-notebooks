// Source: 08_integration/11_provider_middleware/05_anthropic_file_search.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Anthropic File Search", subtitle: "glob + grep over virtual files")

`StateFileSearchMiddleware` offers a Claude native tool that runs _glob + grep_ over virtual files sitting inside graph state (for example `text_editor_files`, `memory_files`). If the text editor / memory middleware "create and edit files", this middleware "finds and reads" files on top of them.

#learning-header()
#learning-objectives(
  [Select the target store via `StateFileSearchMiddleware(state_key=...)`],
  [Complete the "write → find → read" loop by pairing it with `StateClaudeTextEditorMiddleware`],
  [Switch the search target to memory files via `state_key="memory_files"`],
  [Know the duplicate-middleware constraint and the subclassing workaround],
)

== 6.1 When to use it

- The agent has accumulated _tens to hundreds_ of virtual files in state and needs to explore them
- You know only the name and want to find files by pattern (`**/*.md`) or filter by a keyword
- You want the model to `grep` its own accumulated past notes in memory to reference them

== 6.2 Environment setup

Required packages: `langchain`, `langchain-anthropic`. `ANTHROPIC_API_KEY` in `.env`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeTextEditorMiddleware,
    StateFileSearchMiddleware,
)

load_dotenv()
`````)

== 6.3 Text editor + file search combination

Search by itself is meaningless — _the files must exist in state first_. The most common pairing is to create files with the text editor and find them with file search.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Default],
  text(weight: "bold")[Description],
  [`state_key`],
  [`"text_editor_files"`],
  [State key containing the dict of files to search. Switch to `"memory_files"` to search memory],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(),
        StateFileSearchMiddleware(state_key="text_editor_files"),
    ],
)
`````)

== 6.4 Step 1 — seed state with multiple files

Ask the model to create a few notes under `/docs/`. These become the targets for the later search query.

#code-block(`````python
cfg = {"configurable": {"thread_id": "search-demo"}}
agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": (
                    "Create three short drafts: "
                    "/docs/architecture.md, /docs/api.md, /docs/release-notes.md."
                ),
            }
        ]
    },
    config=cfg,
)
`````)

== 6.5 Step 2 — the same agent searches with glob/grep

Calling again on the same thread carries the previous files in state. The model uses `glob` and `grep` tools provided by `StateFileSearchMiddleware` to find files and read their content.

#code-block(`````python
result = agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "Among md files under /docs/, tell me which ones mention 'API'",
            }
        ]
    },
    config=cfg,
)
print(result["messages"][-1].content)
`````)

== 6.6 Targeting memory files too

Switch to `state_key="memory_files"` and you can search the memos accumulated by `StateClaudeMemoryMiddleware`.

#warning-box[*Duplicate-middleware constraint* — LangChain 1.2 `create_agent` rejects duplicate instances of the same middleware class (`AssertionError: Please remove duplicate middleware instances.`). To search both text-editor files and memory files at once, register only one at a time — or subclass `StateFileSearchMiddleware` into a separate class.]

#code-block(`````python
class MemoryFileSearchMiddleware(StateFileSearchMiddleware):
    """Search middleware dedicated to `memory_files`."""

agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(),
        StateClaudeMemoryMiddleware(),
        StateFileSearchMiddleware(state_key="text_editor_files"),
        MemoryFileSearchMiddleware(state_key="memory_files"),
    ],
)
`````)

== 6.7 When to pick this over a vector store

- Exact filename/patterns matter, and _literal grep_ is enough — no semantic search needed
- Document count is _tens to hundreds_ and you would rather not pay to re-embed each turn
- The files are _just created in the current session_ and no vector index exists yet

For large corpora or semantic search, move over to Part VIII's Chat Models / Vector Stores area (future expansion).

== Key Takeaways

- `StateFileSearchMiddleware` provides glob + grep over virtual files in state
- text editor + file search is the standard "write → find → read" loop
- Switch `state_key` to search memory files; work around the duplicate-middleware limit via subclassing
- When literal search suffices, this middleware is much cheaper than a vector store
