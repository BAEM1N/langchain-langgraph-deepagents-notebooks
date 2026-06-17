// Auto-generated from 02_tracing_agents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Tracing Agents", subtitle: "Trace Structures of Complex Agents")

If you saw a single `create_agent` execution in the UI in `01_quickstart`, now we'll see how agents with nested structures—such as _LangGraph StateGraph, Deep Agents subagents, and asynchronous tasks_—are visualized in traces.

== Learning Objectives

- Understand the relationship between `Run`, `Trace`, and `Project` (run = span, trace = span tree)
- See how LangGraph subgraphs are displayed as namespace children within a parent trace
- Distinguish between synchronous and asynchronous subagent traces (`async_tasks` channel) in Deep Agents
- Group multiple executions into a session view using `thread_id` / `session_id` / `conversation_id`
- Attach evaluation scores to runs using `client.create_feedback(run_id, key, score)`
- Programmatically filter using tags/metadata with `client.list_runs(filter=...)`
- _Permanently store_ important traces as datasets to overcome the 400-day retention limit

== Prerequisites

Your `.env` file should contain the following three lines (see `01_quickstart`).

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-tracing-agents
`````)

This notebook covers synchronous/asynchronous subagent structures in Deep Agents, so `deepagents>=0.5.0` is required.

#code-block(`````python
# !pip install -U langsmith langchain langgraph deepagents langchain-openai

from dotenv import load_dotenv
import os
load_dotenv(override=True)

assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY not set"
assert os.environ.get("LANGSMITH_TRACING") == "true", "LANGSMITH_TRACING=true required"
# If the project is not set, LangSmith records to `default`.
os.environ.setdefault("LANGSMITH_PROJECT", "langsmith-tracing-agents")
print("Project:", os.environ["LANGSMITH_PROJECT"])
`````)

== 6.02.1 Run · Trace · Project Concepts

LangSmith's data hierarchy is built on four levels.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Level],
  text(weight: "bold")[Definition],
  text(weight: "bold")[Example],
  [_Project_],
  [Container that groups traces from the same application],
  [`langsmith-tracing-agents`],
  [_Trace_],
  [The run tree created during a single user request (up to 25,000 runs per trace)],
  [One agent invocation],
  [_Run_],
  [A single span — LLM call, tool call, chain node, etc.],
  [`ChatOpenAI`, `get_weather`],
  [_Thread_],
  [Multiple traces grouped by `thread_id`/`session_id`/`conversation_id` — multi-turn conversation view],
  [One user's session],
)

Each run has `parent_run_id`, `trace_id`, `start_time`, `end_time`, `inputs`, `outputs`, `total_tokens`, `total_cost`, etc. _A trace is a tree of runs sharing the same `trace_id`._

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/02_tracing_agents/00_runs_populated_full.png")

_Runs tab — after two days of executions. Provides 17 columns: Name/Input/Output/Error/Latency/Dataset/Tokens/Cost/Tags/Metadata, etc._

#image("../../assets/images/langsmith/02_tracing_agents/01_subgraph_tree_namespace.png")

_Trace View of `Thread t_demo_0001`. The chain `PatchToolCallsMiddleware → model → ChatOpenAI → TodoListMiddleware` is organized as namespaces within a single chat-turn. The right Attributes tab shows automatically captured Tags/Metadata/Runtime._

== 6.02.2 LangGraph StateGraph Trace Tree

A LangGraph graph is displayed as _the graph as the root run_, each node as a child run, and subgraphs as grandchild runs with namespaces. In the UI, subgraph node names appear in the format `parent_node:child_node`.

#code-block(`````python
from typing import TypedDict
from langgraph.graph import StateGraph, START, END
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-5.4")

class State(TypedDict):
    topic: str
    outline: str
    draft: str

# --- Subgraph: Draft Writing ---
def write_outline(state: State) -> dict:
    out = llm.invoke(f"Summarize the following topic in 3 lines: {state['topic']}").content
    return {"outline": out}

def write_draft(state: State) -> dict:
    out = llm.invoke(f"Expand the following outline into a paragraph: {state['outline']}").content
    return {"draft": out}

writer = (
    StateGraph(State)
    .add_node("outline", write_outline)
    .add_node("draft", write_draft)
    .add_edge(START, "outline")
    .add_edge("outline", "draft")
    .add_edge("draft", END)
    .compile()
)

# --- Parent graph: Calls writer subgraph after research ---
def research(state: State) -> dict:
    return {"topic": f"[researched] {state['topic']}"}

parent = (
    StateGraph(State)
    .add_node("research", research)
    .add_node("writer", writer)      # Insert subgraph as a node
    .add_edge(START, "research")
    .add_edge("research", "writer")
    .add_edge("writer", END)
    .compile()
)

result = parent.invoke(
    {"topic": "Building observable agents with LangSmith"},
    config={"run_name": "writer-pipeline", "tags": ["demo:subgraph"]},
)
print(result["draft"][:200], "...")
`````)

When you open the `writer-pipeline` trace in the UI, the root (`writer-pipeline`) has `research` and `writer` as children, and inside `writer` you see the grandchild runs `writer:outline` and `writer:draft` with namespaces. _Since the subgraph path is embedded in the run name_, you can use filters like `name contains writer:`.

== 6.02.3 Deep Agents Subagent Traces (Synchronous · Asynchronous)

Deep Agents subagents appear as independent child trees under the parent run.

- _Synchronous_ (`SubAgent` dict): The parent is blocked, so it's a single trace. Under the `task` tool call run, the subagent's LLM/tool calls are nested.
- _Asynchronous_ (`AsyncSubAgent`): Runs on a separate Agent Protocol server, so it's recorded as a _different trace_ from the parent. Only the `task_id` remains in the parent's `async_tasks` channel, and the parent trace only shows management tool calls like `start_async_task` / `check_async_task`.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/02_tracing_agents/02_subagent_sync_trace.png")

_Turn 2 selected. In the tree, you see the `tools → task → researcher` subagent chain, and in the right Feedback tab, the `user_thumbs 1.00` score. Next to the AI response, the `task(description=..., subagent_type=researcher)` tool call is shown. The Turn 2 hover tooltip's `cache read 5K / $0.0005` indicates Anthropic/OpenAI prompt caching._

#image("../../assets/images/langsmith/02_tracing_agents/05_thread_detail_conversation.png")

_Turn View of the same thread — see each turn's Input/Output as conversation bubbles. In Turn 2 AI output, the `task call_Qks...` description and `subagent_type: researcher` are shown in YAML._

#code-block(`````python
from deepagents import create_deep_agent
from langchain.tools import tool

@tool
def fake_search(query: str) -> str:
    """Fake search tool — returns a fixed response without actual network calls."""
    return f"Summary for {query}: LangSmith is the official observability platform for LangChain."

research_subagent = {
    "name": "researcher",
    "description": "Briefly search a topic and summarize in 3 lines.",
    "system_prompt": "Summarize the search results in Korean within 3 lines.",
    "tools": [fake_search],
}

supervisor = create_deep_agent(
    model="openai:gpt-5.4",
    system_prompt="Delegate to researcher if research is needed, and summarize the final answer in Korean.",
    subagents=[research_subagent],
)

out = supervisor.invoke(
    {"messages": [{"role": "user", "content": "Summarize what LangSmith is in one paragraph."}]},
    config={
        "run_name": "deepagent:sync-subagent",
        "tags": ["demo:deepagent", "mode:sync"],
    },
)
print(out["messages"][-1].content)
`````)

When you open `deepagent:sync-subagent` in the UI, you see the `task` tool call, and under it, the subagent's LLM and `fake_search` calls are nested. For the asynchronous case, you can only check the structure with the snippet below—actual execution requires a `langgraph dev` server.

#code-block(`````python
from deepagents import AsyncSubAgent
researcher = AsyncSubAgent(name="researcher", description="Long-running research", graph_id="researcher")
# Parent trace: only shows start_async_task tool call
# Child trace: researcher graph is a separate trace (grouped by the same thread_id)
# State retention: async_tasks channel survives even after compaction
`````)

== 6.02.4 Session View — `thread_id` · `session_id` · `conversation_id`

To group multiple invokes into _a single conversation_, add a session identifier to `metadata`. If LangSmith finds any of `thread_id`, `session_id`, or `conversation_id`, it automatically links them in the Threads view.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/02_tracing_agents/04_thread_view.png")

_Threads tab — runs sharing the same `thread_id` are grouped as a single conversation session. First Input / Last Output / turns / tokens / cost / P50·P99 Latency columns are automatically aggregated._

#code-block(`````python
session_config = {
    "run_name": "chat-turn",
    "metadata": {
        "thread_id": "t_demo_0001",   # Sharing the same value groups them as one line in the Threads view
        "user_id": "u_00123",
        "app_version": "0.5.0",
    },
    "tags": ["env:dev", "feature:chat"],
}

for turn in ["Hello", "What's the weather in Seoul today?", "Thank you"]:
    supervisor.invoke(
        {"messages": [{"role": "user", "content": turn}]},
        config=session_config,
    )
print("Three turns have been recorded with thread_id=t_demo_0001 — check in the UI's Threads tab")
`````)

== 6.02.5 Attaching Feedback to Runs — `client.create_feedback`

Evaluation scores, user thumbs-up/down, and internal QA review results are attached to runs as _Feedback_.

- `key`: Feedback name (e.g., `"correctness"`, `"user_thumbs"`)
- `score`: Float between 0 and 1, or any arbitrary number
- `value`, `comment`: Optional

#code-block(`````python
from langsmith import Client

client = Client()

# Get the most recent root run and attach feedback
latest = next(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    is_root=True,
    limit=1,
))

client.create_feedback(
    run_id=latest.id,
    key="user_thumbs",
    score=1,                         # 1=up, 0=down
    comment="Fast and accurate",
)

print(f"Feedback attached → run {latest.id}")
`````)

== 6.02.6 Tag/Metadata-Based Filter Queries

You can use the same filter expressions as the UI in code with `client.list_runs(filter=...)`. Useful for regression tests, nightly batches, and dashboard feeding.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/02_tracing_agents/06_add_filter_menu.png")

_Field list shown when clicking `Add filter` — Input/Output/Run Name/Run Type/Latency/Status/Error Message/Tag/Metadata/Feedback/Run ID/Trace ID/Thread ID/Token Count/Cost + Advanced. Tag and Metadata are separate fields, so you can query with conditions like `tags contains env:dev`._

#code-block(`````python
# 1) Get only root runs with a specific tag
runs = list(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    filter='and(eq(is_root, true), has(tags, "demo:deepagent"))',
    limit=5,
))
for r in runs:
    print(f"{r.start_time:%H:%M:%S}  {r.name:30s}  tags={r.tags}")

# 2) Query runs with metadata.thread_id
thread_runs = list(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    filter='eq(metadata_key, "thread_id")',
    limit=20,
))
print(f"Number of runs with thread_id: {len(thread_runs)}")
`````)

== 6.02.7 `\@traceable` run_type Classification + Low-Level `create_run` / `update_run`

The `run_type` of `@traceable` maps directly to LangSmith UI colors, icons, and filters. The official types are `chain`, `llm`, `tool`, `retriever`, `embedding`, `prompt`, and `parser` (each shown as a different colored node).

For asynchronous tasks that can't be wrapped with a decorator (external workers, callbacks), you can create spans directly using the low-level `Client.create_run` / `Client.update_run` API.

#code-block(`````python
import uuid, time
from datetime import datetime, timezone

run_id = uuid.uuid4()
client.create_run(
    id=run_id,
    name="external-batch-job",
    run_type="chain",                # chain | llm | tool | retriever | embedding | prompt | parser
    inputs={"job": "nightly-rebuild"},
    start_time=datetime.now(timezone.utc),
    project_name=os.environ["LANGSMITH_PROJECT"],
    tags=["env:dev", "source:cron"],
    extra={"metadata": {"hostname": "worker-01"}},
)

# ... perform actual work ...
time.sleep(0.1)

client.update_run(
    run_id=run_id,
    end_time=datetime.now(timezone.utc),
    outputs={"ok": True, "indexed": 1234},
)
print(f"Low-level run creation/completion done → {run_id}")
`````)

== 6.02.8 `LangChainTracer` Callback + `with_config({"tags": [...]})`

If `LANGSMITH_TRACING=true`, a global callback is attached automatically. If you use multiple clients or want to send traces from only certain chains to a separate project, explicitly add a `LangChainTracer` to the callbacks. You can also attach tags per chain using `Runnable.with_config({"tags": [...]})`.

#code-block(`````python
from langchain_core.tracers import LangChainTracer
from langsmith import Client

# Separate tracer for a different project
side_project_tracer = LangChainTracer(
    project_name="langsmith-side-project",
    client=Client(),
)

# Attach tags/callbacks per chain — Runnable.with_config
tagged_llm = llm.with_config({"tags": ["component:writer"], "run_name": "writer-llm"})

# You can also inject a one-time callback with config={"callbacks": [...]} when calling
tagged_llm.invoke(
    "Summarize the advantages of LangSmith tracing in one line.",
    config={"callbacks": [side_project_tracer], "tags": ["call:demo"]},
)
`````)

== 6.02.9 Selective tracing — `LANGSMITH_TRACING=false` + `tracing_context(enabled=True)`

In production, you often want to disable default tracing and only record _specific requests_ as traces. Priority — `tracing_context(enabled=...)` overrides the environment variable. If you set it to `false` globally and enable only the context block, nothing is visible from the outside and only the inside is recorded in LangSmith.

#code-block(`````python
import langsmith as ls
from langsmith import traceable

@traceable(run_type="chain", name="conditional-pipeline")
def conditional_pipeline(payload: dict) -> dict:
    return {"echo": payload}

# Scenario: Assume the global env is set to false and only the block is enabled
prev = os.environ.get("LANGSMITH_TRACING")
os.environ["LANGSMITH_TRACING"] = "false"
try:
    conditional_pipeline({"req": 1})                  # No trace
    with ls.tracing_context(enabled=True, tags=["audit:critical"]):
        conditional_pipeline({"req": 2, "vip": True}) # Trace recorded
finally:
    if prev is None:
        del os.environ["LANGSMITH_TRACING"]
    else:
        os.environ["LANGSMITH_TRACING"] = prev
print("Selective tracing demo complete")
`````)

== 6.02.10 400-Day Retention Limit → Permanent Storage as Dataset

SaaS LangSmith _deletes traces 400 days after ingestion_. To use important executions for evaluation regression, you must _permanently store them as Datasets_. This is covered in detail in `03_datasets_and_evaluation.ipynb`; here, we just show the pattern.

#code-block(`````python
# Permanently store traces as a dataset
# Since langsmith 0.7.x, add_runs_to_dataset has been removed. Use create_examples instead.
from langsmith import Client

client = Client()
DS_NAME = "agent-golden-traces"
try:
    ds = client.create_dataset(
        DS_NAME,
        description="Excellent traces for permanent retention",
    )
except Exception:
    ds = client.read_dataset(dataset_name=DS_NAME)

runs = list(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    run_type="chain",
    limit=5,
))

examples = [
    {"inputs": r.inputs, "outputs": r.outputs, "metadata": {"source_run_id": str(r.id)}}
    for r in runs if r.outputs
]
if examples:
    client.create_examples(dataset_id=ds.id, examples=examples)
print(f"Added {len(examples)} examples to dataset '{ds.name}'.")
`````)

== Checklist

- [ ] Check in the UI that the run names of LangGraph subgraphs are displayed as `parent:child` namespaces
- [ ] Understand that Deep Agents synchronous subagents are recorded as child trees under the `task` tool, while asynchronous ones are recorded as separate traces
- [ ] Confirm that executions with the same `metadata.thread_id` are grouped as a single line in the Threads view
- [ ] Attach feedback to the latest run using `client.create_feedback(run_id, key, score)`
- [ ] Programmatically query using tags/metadata with `client.list_runs(filter=...)`
- [ ] Use all 7 `run_type`s of `@traceable` (chain/llm/tool/retriever/embedding/prompt/parser) + low-level `Client.create_run` / `update_run`
- [ ] Explicitly inject `LangChainTracer` callback + use `Runnable.with_config({"tags": [...]})`
- [ ] Use `ls.tracing_context(enabled=True)` for selective tracing when `LANGSMITH_TRACING=false`
- [ ] Move important traces to a dataset to handle the 400-day retention limit

== Next

- `03_datasets_and_evaluation.ipynb` — How to attach code evaluators, LLM-as-judge, and pairwise evaluation to these traces/datasets

== References

- Observability concepts: https://docs.langchain.com/langsmith/observability-concepts
- Annotate code (`@traceable`): https://docs.langchain.com/langsmith/annotate-code
- Conditional tracing: https://docs.langchain.com/langsmith/conditional-tracing
- Threads (session) view: https://docs.langchain.com/langsmith/threads
- Feedback API: https://docs.langchain.com/langsmith/attach-user-feedback
- Filter query syntax: https://docs.langchain.com/langsmith/filter-traces-in-application
