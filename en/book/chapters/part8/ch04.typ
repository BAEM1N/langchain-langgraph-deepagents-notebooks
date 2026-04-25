// Source: 08_integration/11_provider_middleware/03_claude_text_editor.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Claude Text Editor", subtitle: "State vs Filesystem variants")

The Claude native `text_editor_20250728` tool supports six operations: `view` / `create` / `str_replace` / `insert` / `delete` / `rename`. LangChain ships middleware that wraps this tool in two variants — the _State variant_ writes into virtual files inside LangGraph state; the _Filesystem variant_ writes to a real directory. Choose based on whether the artifact's lifetime ends with the thread or must persist on disk.

#learning-header()
#learning-objectives(
  [Use the six operations of the Claude native text editor],
  [Distinguish the State and Filesystem variants by lifetime and sharing scope],
  [Restrict paths via `allowed_path_prefixes` / `allowed_prefixes`],
  [Bound the disk variant with `root_path` and `max_file_size_mb`],
)

== 4.1 When to use it

- Model edits that are inherently _multi-step_ (large changes that are hard to output as a single diff)
- The result needs to live _only inside the graph state_: use the State variant
- The result must _remain in a real repo / directory_: use the Filesystem variant
- When you would rather reuse Claude's learned tool schema than build a generic `@tool` for `read_file` / `write_file`

== 4.2 Environment setup

Required packages: `langchain`, `langchain-anthropic`. `ANTHROPIC_API_KEY` in `.env`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeTextEditorMiddleware,
    FilesystemClaudeTextEditorMiddleware,
)

load_dotenv()
`````)

== 4.3 State variant — virtual files in graph state

`StateClaudeTextEditorMiddleware` stores file contents under the `text_editor_files` key in LangGraph state. It does not touch disk, so it is a fit for temporary work that _disappears when the thread ends_.

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        StateClaudeTextEditorMiddleware(
            allowed_path_prefixes=["/src"],  # virtual-path restriction
        ),
    ],
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Write hello world to /src/hello.py"}]},
)
print(result.get("text_editor_files"))
`````)

- `allowed_path_prefixes`: allow-listed virtual-path prefixes. Unrestricted if omitted

#tip-box[If the model writes outside `allowed_path_prefixes`, the tool returns an error; the model reads that error and retries with a permitted path. Path restrictions are the compromise between _agent autonomy_ and _safety_.]

== 4.4 Filesystem variant — real disk

`FilesystemClaudeTextEditorMiddleware` uses a real directory as its root and reads/writes from there.

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
  [Actual root directory for file operations],
  [`allowed_prefixes`],
  [`["/"]`],
  [Allowed virtual-path prefixes (relative to `root_path`)],
  [`max_file_size_mb`],
  [`10`],
  [Maximum file size allowed for read/write],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        FilesystemClaudeTextEditorMiddleware(
            root_path="/tmp/editor-demo",
            allowed_prefixes=["/drafts", "/reports"],
            max_file_size_mb=5,
        ),
    ],
)
`````)

== 4.5 State vs Filesystem selection criteria

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Axis],
  text(weight: "bold")[State variant],
  text(weight: "bold")[Filesystem variant],
  [Storage],
  [LangGraph state dict],
  [Actual directory],
  [Lifetime],
  [Dies with the thread],
  [Permanent (remains on disk)],
  [Checkpointer compatibility],
  [Included in state → auto-saved],
  [Only the path is stored; files managed separately],
  [Concurrency],
  [Fully isolated per thread],
  [Possible conflicts when sharing `root_path`],
  [Typical uses],
  [Temporary drafts, one-off analyses],
  [Real codebase edits, report artifacts],
)

*Rule*: If the artifact must survive after the thread, go Filesystem; otherwise, go State.

== 4.6 Relationship with generic file tools

Deep Agents' `FilesystemMiddleware` or a custom `@tool` implementing `read_file` / `write_file` can reach the same goal. The difference is that _Claude already saw this tool during training_ — schema tokens drop and error rates are lower. Use this middleware first in Claude-only pipelines, and drop down to generic file tools for multi-provider setups.

== Key Takeaways

- Claude native text editor brings tool-schema tokens close to zero while supporting six operations
- Choose State (dies with thread) vs Filesystem (persistent on disk) based on artifact lifetime
- Enforce access boundaries with `allowed_path_prefixes` / `allowed_prefixes`
- The Filesystem variant uses `max_file_size_mb` to keep memory safe
