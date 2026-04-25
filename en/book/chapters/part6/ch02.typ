// Source: 08_langsmith/02_tracing_agents.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Agent Trace Structure", subtitle: "Subgraph · SubAgent · Thread · Feedback")

Chapter 1 showed one `create_agent` invocation in the UI. This chapter covers how nested-structure agents — _LangGraph StateGraph · Deep Agents subagents · async tasks_ — are drawn as traces. It collects operational concerns end to end: the four concepts of Run / Trace / Project / Thread, subgraph namespaces, the trace differences between sync and async subagents, the feedback API, and the 400-day retention limit.

#learning-header()
#learning-objectives(
  [Understand the relationship between Run · Trace · Project · Thread (run = span, trace = span tree)],
  [Confirm how LangGraph subgraphs appear as namespaced children inside the parent trace],
  [Distinguish Deep Agents sync vs async subagent (`async_tasks` channel) trace differences],
  [Group multiple runs into a Thread view via `thread_id` / `session_id`],
  [Attach evaluation scores to a run with `client.create_feedback(run_id, key, score)`],
  [Run programmatic filters based on tags and metadata with `client.list_runs(filter=...)`],
  [Persist important traces as _datasets_ to survive the 400-day retention limit],
)

== 2.1 Concepts: Run · Trace · Project · Thread

LangSmith's data layer stacks in four levels.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Level],
  text(weight: "bold")[Definition],
  text(weight: "bold")[Example],
  [*Project*],
  [Container for all traces from the same application],
  [`langsmith-tracing-agents`],
  [*Trace*],
  [Tree of runs created while servicing a single user request (up to 25,000 runs / trace)],
  [One agent invocation],
  [*Run*],
  [A single span — LLM call, tool call, chain node, etc.],
  [`ChatOpenAI`, `get_weather`],
  [*Thread*],
  [Multiple traces grouped by `thread_id`/`session_id`/`conversation_id` — the multi-turn conversation view],
  [A single user's session],
)

Each run carries `parent_run_id`, `trace_id`, `start_time`, `end_time`, `inputs`, `outputs`, `total_tokens`, `total_cost`, etc. _A trace is simply the tree of runs that share the same `trace_id`_.

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/00_runs_populated_full.png", width: 95%), caption: [Project Runs list — 17 columns including Name / Input / Output / Error / Latency / Dataset / Tokens / Cost / Tags / Metadata])

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/01_subgraph_tree_namespace.png", width: 95%), caption: [LangGraph subgraph trace tree — a `PatchToolCallsMiddleware → model → ChatOpenAI → TodoListMiddleware` chain built with namespaces])

== 2.2 LangGraph StateGraph trace tree

A LangGraph graph renders as _the graph at the root_, each node as a child run, and subgraphs as namespaced grandchildren. Subgraph node names are displayed in the UI as `parent_node:child_node`.

#code-block(`````python
from langgraph.graph import StateGraph
from langsmith import tracing_context

with tracing_context(name="writer-pipeline", tags=["env:dev"]):
    result = pipeline.invoke({"topic": "agent streaming"})
`````)

Opening the `writer-pipeline` trace in the UI shows `research` and `writer` nodes as children under the root, and grandchildren `writer:outline` and `writer:draft` inside `writer` carrying their namespace. Because the _subgraph path is baked into the run name_, filters like `name contains writer:` work.

== 2.3 Deep Agents subagent traces (sync · async)

Deep Agents subagents appear as independent child trees under the parent run.

- *Sync* (`SubAgent` dict): the parent blocks, so it all lives in a single trace. The subagent's LLM / tool calls nest under the `task` tool call run.
- *Async* (`AsyncSubAgent`): runs on a separate Agent Protocol server, so it is recorded as a _separate trace_ from the parent. Only the `task_id` lives in the parent's `async_tasks` channel; the parent trace shows only management tool calls such as `start_async_task` / `check_async_task`.

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/02_subagent_sync_trace.png", width: 95%), caption: [Deep Agents sync subagent + user_thumbs 1.00 feedback — the `tools → task → researcher` chain and the Feedback tab])

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/05_thread_detail_conversation.png", width: 95%), caption: [Thread Turn View — each turn's Input / Output shown as conversation bubbles with `task call` description and `subagent_type: researcher` YAML])

#code-block(`````python
from deepagents import AsyncSubAgent

researcher = AsyncSubAgent(name="researcher", description="Long-running research", graph_id="researcher")
# parent trace: only the start_async_task tool call
# child trace: the researcher graph is a separate trace (grouped by the same thread_id)
# state preservation: the async_tasks channel survives compaction
`````)

== 2.4 Session view — `thread_id` · `session_id` · `conversation_id`

To group multiple invokes into _one conversation_, put a session identifier on the `metadata`. LangSmith automatically groups runs into the Threads view if any of `thread_id`, `session_id`, or `conversation_id` is present.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "..."}]},
    config={"metadata": {"thread_id": "t_demo_0001", "user_id": "u_alice"}},
)
`````)

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/04_thread_view.png", width: 95%), caption: [Threads tab — runs sharing a `thread_id` grouped as a conversation session. First Input / Last Output / turns / tokens / cost / P50·P99 latency auto-aggregated])

== 2.5 Attaching feedback to runs — `client.create_feedback`

Evaluation scores, user thumbs-up/down, and internal QA review results are attached as *Feedback* on a run.

- `key`: feedback name (e.g., `"correctness"`, `"user_thumbs"`)
- `score`: a float in 0–1 or an arbitrary number
- `value`, `comment`: optional

#code-block(`````python
from langsmith import Client

client = Client()
client.create_feedback(
    run_id=latest_run.id,
    key="user_thumbs",
    score=1.0,
    comment="Extracted the correct answer",
)
`````)

== 2.6 Tag- and metadata-based filter queries

The same expressions used in UI filters work from code through `client.list_runs(filter=...)`. Useful for regression tests, nightly batches, and dashboard feeds.

#code-block(`````python
runs = client.list_runs(
    project_name="langsmith-tracing-agents",
    filter='and(has(tags, "env:prod"), eq(run_type, "chain"))',
    limit=50,
)
`````)

#figure(image("../../../../assets/images/langsmith/02_tracing_agents/06_add_filter_menu.png", width: 95%), caption: [Add filter menu — Tag and Metadata exist as separate fields, enabling conditions such as `tags contains env:dev`])

== 2.7 The 400-day retention limit → persist to datasets

SaaS LangSmith deletes traces _400 days after ingestion_. Runs you want to keep for evaluation regression must be _persisted as a Dataset_. We cover datasets in depth in chapter 3; here, just the pattern.

#code-block(`````python
# langsmith 0.7 removed add_runs_to_dataset — use create_examples to convert
# each run's inputs/outputs into examples directly.
golden_runs = [r for r in runs if r.feedback.get("user_thumbs") == 1]
ds = client.create_dataset("agent-golden-traces",
                           description="Human-approved golden traces")
client.create_examples(
    dataset_id=ds.id,
    examples=[
        {"inputs": r.inputs,
         "outputs": r.outputs,
         "metadata": {"source_run_id": str(r.id)}}
        for r in golden_runs if r.outputs
    ],
)
`````)

== Key Takeaways

- The four-level concept — Project → Trace → Run + Thread (session grouping) — is the foundation of every UI view
- LangGraph subgraphs bake their namespaces into run names, making them filterable
- Deep Agents sync subagents are a single trace; async are separate traces — tracked via the `async_tasks` channel
- `thread_id` / `session_id` metadata triggers Thread-view grouping
- Feedback API + `list_runs(filter=...)` programmatically connect the evaluation loop
- Push traces into a Dataset to outlive the 400-day retention limit
