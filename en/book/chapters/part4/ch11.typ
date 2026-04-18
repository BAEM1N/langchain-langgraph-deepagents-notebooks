// Source: docs/deepagents/12-async-subagents.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Async Subagents", subtitle: "AsyncSubAgent · Non-blocking · Mid-flight steering")

The flagship feature of Deep Agents 0.5.0, `AsyncSubAgentMiddleware`, lets the supervisor spawn subagents in the background without blocking. It is the infrastructure that pushes past the limits of the old synchronous subagent for long-running work — multi-minute to multi-hour research, coding, and parallel subagent orchestration. One caveat: this feature requires an _Agent Protocol server_ — it only runs on top of LangSmith Deployments or a self-hosted setup such as `langgraph dev`.

#learning-header()
#learning-objectives(
  [Explain the execution-model differences between a synchronous subagent and `AsyncSubAgent`],
  [Distinguish the five tools injected by the middleware: `start_async_task` / `check_async_task` / `update_async_task` / `cancel_async_task` / `list_async_tasks`],
  [Compare ASGI (co-deploy) and HTTP (remote) transport modes and build hybrid configurations],
  [Understand how the `async_tasks` state channel preserves state across context compaction],
  [Know mid-flight steering patterns (update/cancel) and how to tune `--n-jobs-per-worker` slots],
)

== 11.1 Limitations of the old synchronous subagent

The original subagent was _synchronous_. When the `task` tool was invoked, the supervisor stalled until the subagent finished, and the user could not issue a new instruction in the meantime. Running a multi-minute research task synchronously froze the frontend for a long stretch with no way for the user to check whether the agent was still alive.

The 0.5.0 `AsyncSubAgentMiddleware` removes this constraint.

- *Non-blocking execution*: `start_async_task` returns a task id immediately. The supervisor keeps talking to the user.
- *Mid-flight steering*: You can send follow-up instructions to a running subagent or cancel it.
- *Independent threads*: Each subagent task has its own thread and run. State is not lost even when the supervisor's context is compacted.

== 11.2 Five tools injected into the supervisor

`AsyncSubAgentMiddleware` injects five tools into the supervisor.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tool],
  text(weight: "bold")[Role],
  [`start_async_task`],
  [Launch a subagent in the background. Returns the task id immediately],
  [`check_async_task`],
  [Query current status; extract final output if the task completed],
  [`update_async_task`],
  [Inject a new instruction into the same thread of a running task (interrupt strategy)],
  [`cancel_async_task`],
  [Send a cancel signal to the server and mark the task as `cancelled`],
  [`list_async_tasks`],
  [Batch-query the current status of all tracked tasks],
)

== 11.3 Basic usage

Pass a list of `AsyncSubAgent` specs to `subagents` and `create_deep_agent` attaches `AsyncSubAgentMiddleware` automatically.

#code-block(`````python
from deepagents import AsyncSubAgent, create_deep_agent

async_subagents = [
    AsyncSubAgent(
        name="researcher",
        description="Research work that needs information gathering and synthesis",
        graph_id="researcher",
    ),
    AsyncSubAgent(
        name="coder",
        description="Code generation / review work",
        graph_id="coder",
        url="https://coder-deployment.langsmith.dev",  # remote HTTP call
    ),
]

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    subagents=async_subagents,
)
`````)

=== Key fields on `AsyncSubAgent`

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Description],
  [`name`],
  [Unique identifier the supervisor references],
  [`description`],
  [The basis the supervisor uses to decide what to delegate. As important as it is for synchronous subagents],
  [`graph_id`],
  [Must match a graph name in `langgraph.json`],
  [`url`],
  [Optional. Without it, ASGI (in-process); with it, remote HTTP call],
  [`headers`],
  [Optional. Auth headers for a self-hosted server],
)

== 11.4 The `async_tasks` state channel

Task metadata is stored in the `async_tasks` state channel, _separate_ from the message history. Each record contains:

- task id
- agent name
- thread id, run id
- status (`pending` / `running` / `success` / `error` / `cancelled`)
- `created_at`, `updated_at`

This separation means that even when the supervisor's context is compacted (summarization) and older messages are replaced by summaries, _task ids are not lost_. `check_async_task` / `update_async_task` still work after compaction.

#warning-box[If a custom state reducer or middleware reshapes state and overwrites the `async_tasks` channel, you lose tracking for running tasks. Make the merge strategy explicit.]

== 11.5 Transport modes

=== ASGI (co-deploy, the recommended default)

If you omit `url`, the subagent runs in the _same process_ as the supervisor, like a function call. Zero network latency; register both graphs in the same `langgraph.json`.

#code-block(`````json
// langgraph.json
{
  "dependencies": ["."],
  "graphs": {
    "supervisor": "./agent.py:supervisor",
    "researcher": "./subagents/researcher.py:graph",
    "coder": "./subagents/coder.py:graph"
  },
  "env": ".env"
}
`````)

#code-block(`````python
AsyncSubAgent(
    name="researcher",
    description="...",
    graph_id="researcher",   # no url → ASGI
)
`````)

=== HTTP (remote)

Call an independently deployed subagent by `url`. Use this when you need to scale subagents with _different resource profiles_ separately — for example, a low-cost model deployment dedicated to research and a GPU deployment dedicated to coding.

#code-block(`````python
import os

AsyncSubAgent(
    name="coder",
    description="...",
    graph_id="coder",
    url="https://coder-deployment.langsmith.dev",
    headers={"x-api-key": os.environ["CODER_API_KEY"]},
)
`````)

=== Hybrid

You can mix the two. Lightweight subagents via ASGI, resource-intensive subagents via remote HTTP — split the deployment topology along the workload.

== 11.6 Execution lifecycle

+ *Launch* — `start_async_task` creates a new thread, starts a run, and returns the task id immediately
+ *Check* — `check_async_task` queries status and extracts the final output when complete
+ *Update* — `update_async_task` preserves history in the existing thread and starts a new run triggered by an interrupt carrying the new instruction
+ *Cancel* — `cancel_async_task` calls `runs.cancel()` and marks the task as cancelled
+ *List* — live-status queries for non-terminal tasks in parallel; cached responses for terminal ones

== 11.7 Mid-flight steering patterns

When the user changes direction mid-conversation, the supervisor calls `update_async_task`.

#code-block(`````text
User: Start competitor research.
Supervisor: [start_async_task(agent="researcher", ...)] → task_abc123

User: Actually, only Series A and above.
Supervisor: [update_async_task(task_id="task_abc123",
                               instruction="Narrow the scope to Series A and above")]

User: Stop, redirect to the SaaS segment instead.
Supervisor: [cancel_async_task(task_id="task_abc123")]
            [start_async_task(agent="researcher",
                              description="SaaS competitor research")]
`````)

Because `update_async_task` creates a new run on the _same thread_, the subagent carries its prior exploration forward and simply layers on the new instruction. Use cancel + start only when you truly want a fresh task.

== 11.8 Local development: `--n-jobs-per-worker`

The default worker pool for `langgraph dev` is small, so spawning concurrent subagents causes queuing. Raise the slot count.

#code-block(`````bash
langgraph dev --n-jobs-per-worker 10
`````)

A supervisor running three concurrent subagents needs at least *4 slots* (1 supervisor + 3 subagents). 10–20 gives comfortable headroom.

== 11.9 Sync vs Async selection criteria

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Axis],
  text(weight: "bold")[Sync SubAgent],
  text(weight: "bold")[AsyncSubAgent],
  [Execution],
  [Supervisor blocks, waits for completion],
  [Returns task id immediately, supervisor continues],
  [Result retrieval],
  [Automatically returned to the supervisor],
  [Poll with `check_async_task`],
  [Mid-task instructions],
  [Not supported],
  [Supported via `update_async_task`],
  [Cancellation],
  [Not supported],
  [Supported via `cancel_async_task`],
  [State preservation],
  [Stateless (one-shot)],
  [State kept in its own thread, interactive],
  [Infrastructure requirement],
  [No special requirements],
  [Requires Agent Protocol server],
  [Suited for],
  [Seconds to tens of seconds, result-only workloads],
  [Minute-to-hour tasks with room for intervention],
)

*Decision flow*

- Task finishes in seconds and the supervisor needs the result immediately → *Sync*
- Task takes multiple minutes, or you want _parallel_ subagents → *Async*
- User might redirect or cancel mid-flight → *Async*
- You cannot run LangSmith Deployments or an Agent Protocol server → *Sync only*

== 11.10 Caveats

- *Agent Protocol dependency*: Declaring `AsyncSubAgent` in a runtime without Agent Protocol support fails at initialization
- *Preserve the `async_tasks` channel*: Custom state reducers or middleware that reshape state must not overwrite it
- *Polling cost*: Instruct the system prompt to avoid calling `check_async_task` too frequently (for example, "spawn 2–3 tasks at a time, then wait for user feedback")
- *Long-running task cleanup*: Periodically sweep long unfinished tasks with `list_async_tasks` + `cancel_async_task`. LangSmith Deployments retain checkpoint-based cost
- *HTTP mode timeouts*: For remote URLs, verify headers, network timeout, and retry policy separately

== Key Takeaways

- `AsyncSubAgent` is the 0.5.0 flagship feature that spawns background subagents without blocking the supervisor
- Five tools (`start` / `check` / `update` / `cancel` / `list`) drive the lifecycle
- ASGI is the default for co-deploy; HTTP is used for resource separation; hybrid is possible
- The `async_tasks` state channel preserves task tracking across context compaction
- A good fit for multi-minute work, tasks that benefit from user intervention, and multiple parallel subagents
