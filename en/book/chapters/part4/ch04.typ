// Auto-generated from 04_backends.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "Storage Backends")

== Learning Objectives
- Understand how backends implement the agent's filesystem
- Learn the characteristics and use cases of the five built-in backends
- Configure path-based routing with `CompositeBackend`
- Implement a custom backend with `BackendProtocol`


#code-block(`````python
# Environment setup
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
print("Environment setup complete")

from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")

`````)

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 1. What Is a Backend?

Deep Agents' built-in file tools (`ls`, `read_file`, `write_file`, `edit_file`, `glob`, `grep`) all operate through a _backend_.

A backend abstracts the _storage layer_ that the agent uses to read and write files.

#image("../../assets/images/backend_abstraction.png")

=== Available Backends

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Backend],
  text(weight: "bold")[Storage Location],
  text(weight: "bold")[Persistence],
  text(weight: "bold")[Use Case],
  [`StateBackend`],
  [Agent state (memory)],
  [Within a thread],
  [Scratch work, temporary tasks (default)],
  [`FilesystemBackend`],
  [Local disk],
  [Persistent],
  [Local file access, coding agents],
  [`StoreBackend`],
  [LangGraph Store],
  [Cross-thread],
  [Long-term memory, user preferences],
  [`CompositeBackend`],
  [Path-based routing],
  [Mixed],
  [Persistent memory + temporary files],
  [`LocalShellBackend`],
  [Disk + shell],
  [Persistent],
  [Development environments (security caution)],
)


#code-block(`````python
# Verify backend imports
from deepagents.backends import (
    StateBackend,
    FilesystemBackend,
    StoreBackend,
    CompositeBackend,
)
from deepagents.backends.protocol import BackendProtocol

print("stable delete contract:", hasattr(BackendProtocol, "delete"))
print("All backend classes imported successfully!")

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 2. `StateBackend` (Default)

`StateBackend` stores files in agent state (LangGraph state).
It is _ephemeral_: files live only inside the current conversation thread.

=== Characteristics
- Used automatically when you do not pass `backend` to `create_deep_agent()`
- Files survive across agent turns through checkpoints
- Files disappear when the thread ends
- No external storage required


#code-block(`````python
from deepagents import create_deep_agent

# StateBackend is the default, so you do not need to configure it explicitly
agent = create_deep_agent(
    model=model,
    system_prompt="You are a file-management assistant. Respond in English.",
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Create a file named 'hello.txt' with the text 'Hello!'. Then check the file list."}]},
    config=lf_config,
)

print(result["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 3. `FilesystemBackend` — Accessing the Local Disk

`FilesystemBackend` lets the agent access the _real local filesystem_.

=== Key Options
- `root_dir` — the root directory the agent can access (default: current directory)
- `virtual_mode=True` — limits paths and blocks escapes such as `..` and `~`
- `max_file_size_mb` — maximum readable file size

=== ⚠️ Security Considerations
#tip-box[`FilesystemBackend` gives the agent access to the real filesystem. In production, use `virtual_mode=True` or consider a sandbox backend instead.]


#code-block(`````python
import tempfile
from pathlib import Path

# Use a temporary directory for safe testing
with tempfile.TemporaryDirectory() as tmp_dir:
    Path(tmp_dir, "sample.txt").write_text("This is a sample file.", encoding="utf-8")
    Path(tmp_dir, "data.csv").write_text("name,age\nAlice,30\nBob,25", encoding="utf-8")

    fs_agent = create_deep_agent(
        model=model,
        system_prompt="You are a file analysis assistant. Respond in English.",
        backend=FilesystemBackend(
            root_dir=tmp_dir,
            virtual_mode=True,
        ),
    )

    result = fs_agent.invoke(
        {"messages": [{"role": "user", "content": "Show me the files in the current directory, read each file, and summarize the contents."}]},
        config=lf_config,
    )

    print(result["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 4. `StoreBackend` — Cross-Thread Persistent Storage

`StoreBackend` uses LangGraph's `BaseStore` to persist files _across conversation threads_.

=== Characteristics
- The same files can be accessed from different threads
- Supports different store implementations such as Redis and PostgreSQL
- Can be provisioned automatically in LangSmith deployments
- Uses assistant-level namespacing to isolate agents


#code-block(`````python
from langgraph.store.memory import InMemoryStore
from langgraph.checkpoint.memory import MemorySaver

# InMemoryStore is useful for development (use PostgresStore or similar in production)
store = InMemoryStore()
checkpointer = MemorySaver()

# StoreBackend must be passed as a backend factory
store_agent = create_deep_agent(
    model=model,
    system_prompt="You are an assistant that manages notes. Respond in English.",
    backend=lambda runtime: StoreBackend(runtime),
    store=store,
    checkpointer=checkpointer,
)

print("StoreBackend agent created!")

`````)

#code-block(`````python
# Save a note in thread 1
config_thread1 = {"configurable": {"thread_id": "thread-1"}}

result1 = store_agent.invoke(
    {"messages": [{"role": "user", "content": "Create a file named 'memo.txt' and write 'Important: the meeting is every Monday at 10 AM'."}]},
    config={**config_thread1, **lf_config},
)
print("[Thread 1] Result:")
print(result1["messages"][-1].content)
print()

`````)

#code-block(`````python
# Read the same note from thread 2 — confirm cross-thread access
config_thread2 = {"configurable": {"thread_id": "thread-2"}}

result2 = store_agent.invoke(
    {"messages": [{"role": "user", "content": "Is there a file named 'memo.txt'? If so, read it for me."}]},
    config={**config_thread2, **lf_config},
)
print("[Thread 2] Result:")
print(result2["messages"][-1].content)

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== 5. `CompositeBackend` — Path-Based Routing

`CompositeBackend` routes different filesystem paths to different backends.
A common pattern is to persist `/memories/*` while keeping everything else ephemeral.

#image("../../assets/images/composite_backend.png")


#code-block(`````python
# CompositeBackend factory function
def create_composite_backend(runtime):
    """Create a backend with path-based routing."""
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={
            "/memories/": StoreBackend(runtime),
        },
    )


composite_store = InMemoryStore()
composite_checkpointer = MemorySaver()

composite_agent = create_deep_agent(
    model=model,
    system_prompt="""You are a memory-management assistant.
- Save notes that need to persist under /memories/.
- Save temporary work files under the root path /.
Respond in English.""",
    backend=create_composite_backend,
    store=composite_store,
    checkpointer=composite_checkpointer,
)

print("CompositeBackend agent created!")

`````)

#code-block(`````python
# Test persistent vs ephemeral routing
config = {"configurable": {"thread_id": "composite-test"}}

result = composite_agent.invoke(
    {"messages": [{"role": "user", "content": """
Please create two files:
1. /memories/preferences.txt — 'Preferred language: Python, editor: VS Code'
2. /scratch.txt — 'Temporary note: organize tomorrow's tasks'
Then verify that both files were created correctly.
"""}]},
    config={**config, **lf_config},
)

print(result["messages"][-1].content)

`````)

#note-box[_Note_: `CompositeBackend` removes the route prefix before storing the file internally. Example: `/memories/preferences.txt` → stored internally as `/preferences.txt` But the agent always accesses it with the full path (`/memories/preferences.txt`).]


#line(length: 100%, stroke: 0.5pt + luma(200))
== 6. `LocalShellBackend` — Shell Execution

`LocalShellBackend` extends `FilesystemBackend` by adding shell command execution through the `execute` tool.

=== ⚠️ Security Warning
#tip-box[Commands run directly on the host system _with your user permissions_. Use this only in development environments. In production, prefer a _sandbox backend_.]

#code-block(`````python
from deepagents.backends import LocalShellBackend

# ⚠️ Development only!
agent = create_deep_agent(
    model=model,
    backend=LocalShellBackend(root_dir="./workspace", virtual_mode=True),
    interrupt_on={"execute": True},  # require approval before shell commands
)
`````)

#note-box[For safety, this notebook does _not_ run `LocalShellBackend` directly.]


#line(length: 100%, stroke: 0.5pt + luma(200))
== 7. Implementing a Custom Backend

If you implement `BackendProtocol`, you can build your own backend.

=== Required methods in stable `deepagents==0.6.12`

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Method],
  text(weight: "bold")[Result],
  [`ls(path)`],
  [`LsResult`],
  [`read(file_path, offset, limit)`],
  [`ReadResult`],
  [`write(file_path, content)`],
  [`WriteResult`],
  [`edit(file_path, old_string, new_string, replace_all=False)`],
  [`EditResult`],
  [`grep(pattern, path, glob)`],
  [`GrepResult`],
  [`glob(pattern, path)`],
  [`GlobResult`],
)

#note-box[Hosted docs already describe optional `delete(file_path) -> DeleteResult`. It is present in prerelease `0.7.0a6`, not stable 0.6.12, so this notebook treats it as a preview.]


#code-block(`````python
# Simple example: read-only dictionary-backed backend
from deepagents.backends.protocol import (
    FileInfo, LsResult, ReadResult, WriteResult, EditResult,
    GrepResult, GrepMatch, GlobResult,
)


class ReadOnlyDictBackend:
    """Example of a read-only backend backed by a Python dictionary."""

    def __init__(self, files: dict[str, str]):
        self._files = files

    def ls(self, path: str = "/") -> LsResult:
        entries = [
            FileInfo(path=p, is_dir=False, size=len(c), modified_at=None)
            for p, c in self._files.items()
            if p.startswith(path)
        ]
        return LsResult(entries=sorted(entries, key=lambda item: item["path"]))

    def read(self, file_path: str, offset: int = 0, limit: int = 2000) -> ReadResult:
        content = self._files.get(file_path)
        if content is None:
            return ReadResult(error=f"File not found: {file_path}")
        lines = content.splitlines()
        selected = lines[offset:offset + limit]
        text = "\n".join(f"{i + offset + 1}\t{line}" for i, line in enumerate(selected))
        return ReadResult(file_data={"content": text, "encoding": "utf-8"})

    def write(self, file_path: str, content: str) -> WriteResult:
        return WriteResult(error="This backend is read-only.")

    def edit(self, file_path: str, old_string: str, new_string: str, replace_all: bool = False) -> EditResult:
        return EditResult(error="This backend is read-only.")

    def grep(self, pattern: str, path: str | None = None, glob: str | None = None) -> GrepResult:
        matches = []
        for fpath, content in self._files.items():
            for i, line in enumerate(content.splitlines(), 1):
                if pattern in line:
                    matches.append(GrepMatch(path=fpath, line=i, text=line))
        return GrepResult(matches=matches)

    def glob(self, pattern: str, path: str = "/") -> GlobResult:
        import fnmatch
        matches = [
            FileInfo(path=p, is_dir=False, size=len(c), modified_at=None)
            for p, c in self._files.items()
            if fnmatch.fnmatch(p, pattern)
        ]
        return GlobResult(matches=matches)


custom_backend = ReadOnlyDictBackend({
    "/docs/guide.md": "# Guide\nThis is a guide document.\n## Installation\npip install deepagents",
    "/docs/faq.md": "# FAQ\nQ: Which models are supported?\nA: Anthropic, OpenAI, and more.",
})

print("File list:", custom_backend.ls("/"))
print()
print("File contents:")
print(custom_backend.read("/docs/guide.md"))
print()
print("Search results:", custom_backend.grep("Installation"))

`````)

#line(length: 100%, stroke: 0.5pt + luma(200))
== Backend Selection Guide

#image("../../assets/images/backend_decision_tree.png")


#line(length: 100%, stroke: 0.5pt + luma(200))
== Summary

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Backend],
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[Parameters],
  [`StateBackend`],
  [Ephemeral, default],
  [Used automatically when `backend` is omitted],
  [`FilesystemBackend`],
  [Local disk access],
  [`root_dir`, `virtual_mode`],
  [`StoreBackend`],
  [Cross-thread persistence],
  [requires `store` + `checkpointer`],
  [`CompositeBackend`],
  [Path-based routing],
  [`default` + `routes`],
  [`LocalShellBackend`],
  [Development host shell, no isolation],
  [`root_dir`, minimal `env`, `inherit_env=False`],
)

Stable 0.6.12 uses `ls/read/write/edit/grep/glob`; hosted-doc `delete` is a 0.7 prerelease preview.

== Next Steps
→ _#link("./05_subagents.ipynb")[05_subagents.ipynb]_: learn how to delegate work with subagents.
