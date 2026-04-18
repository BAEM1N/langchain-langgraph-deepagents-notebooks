// Source: docs/deepagents/13-going-to-production.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "Going to Production", subtitle: "Ten areas anchored on Thread · User · Assistant")

This chapter covers the ten areas to work through when turning a local prototype into a multi-user, multi-tenant, long-running production agent. Treat it as a checklist just before shipping a Deep Agent to a live service, or when you are cleaning up operational issues on one already deployed.

#learning-header()
#learning-objectives(
  [Understand the three abstractions — Thread, User, Assistant — as the starting point for production design],
  [Know the infrastructure auto-provisioned by `langgraph.json` + LangSmith Deployments],
  [Distinguish multi-tenant authz, end-user credentials, and memory scoping],
  [Pick between thread-scoped and assistant-scoped sandbox patterns],
  [Assemble durability, rate limits, three-tier error handling, PII, and the real-time frontend via middleware and SDKs],
)

== 12.1 Three core abstractions

Production Deep Agents operate on three core abstractions.

- *Thread* — a single conversation. The unit for messages, files, and checkpoints
- *User* — an authenticated identity. The unit for resource ownership and access scope
- *Assistant* — a configured agent instance (prompt · tools · model combination)

Ten areas of concern sit on top of these three concepts. Each area can be adopted independently, picked up according to your risk profile.

== 12.2 LangSmith Deployments

Deploying via the `deepagents deploy` CLI or a LangSmith Deployment auto-provisions the following infrastructure.

- Assistants / Threads / Runs APIs
- Store + Checkpointer (persistence)
- Authentication, webhooks, cron, observability
- MCP / A2A exposure options

#code-block(`````json
// minimal langgraph.json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:agent"
  },
  "env": ".env"
}
`````)

== 12.3 Multi-tenant access control

=== Custom auth / authz handlers

LangSmith Deployments establish user identity via custom authentication, and a separate authorization handler controls access to threads / assistants / store namespaces. Handlers can tag resources with ownership metadata, filter visibility per user, and return HTTP 403 for denied access.

=== Workspace RBAC

Team-level permissions (a LangSmith built-in feature).

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Role],
  text(weight: "bold")[Permissions],
  [Workspace Admin],
  [Full permissions],
  [Workspace Editor],
  [Create / edit; cannot delete or manage members],
  [Workspace Viewer],
  [Read-only],
)

== 12.4 End-user credential management

When the agent has to call external services on the user's behalf (GitHub, Slack, Gmail, etc.), manage credentials _outside the agent code_.

=== Agent Auth (OAuth 2.0)

A managed OAuth flow. On the first call the user is shown a consent URL as an interrupt; once the token is received the flow auto-resumes and refreshes.

#code-block(`````python
from langchain_auth import Client
from langchain.tools import tool, ToolRuntime

auth_client = Client()

@tool
async def github_action(runtime: ToolRuntime):
    """Perform a GitHub action on the user's behalf."""
    auth_result = await auth_client.authenticate(
        provider="github",
        scopes=["repo", "read:org"],
        user_id=runtime.server_info.user.identity,
    )
    # Call the GitHub API with auth_result.token
`````)

=== Sandbox Auth Proxy

When user code (or agent-generated code) running in a sandbox calls external APIs, the proxy _injects_ credentials. API keys are never exposed to the code inside the sandbox.

#code-block(`````json
{
  "proxy_config": {
    "rules": [
      {
        "name": "openai-api",
        "match_hosts": ["api.openai.com"],
        "inject_headers": {
          "Authorization": "Bearer ${OPENAI_API_KEY}"
        }
      }
    ]
  }
}
`````)

`${SECRET_KEY}` is resolved from the workspace secrets.

== 12.5 Memory persistence scoping

The `StoreBackend` `namespace` function determines the memory scope. The default pattern routes only `/memories/` through `StoreBackend` while keeping everything else on the ephemeral `StateBackend` via `CompositeBackend`.

=== User-scoped (recommended default)

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    backend=CompositeBackend(
        default=StateBackend(),
        routes={
            "/memories/": StoreBackend(
                namespace=lambda rt: (
                    rt.server_info.assistant_id,
                    rt.server_info.user.identity,
                ),
            ),
        },
    ),
    system_prompt=(
        "At the start of every conversation, read /memories/instructions.txt. "
        "Update it with durable insights."
    ),
)
`````)

=== Assistant-scoped / Organization-scoped

Memory can be shared by all users of the same assistant (assistant-scoped) or across the whole organization (org-scoped). _Always keep org-shared memory read-only._

#warning-box[*Prompt-injection warning*: Shared memory is a prompt-injection vector. Do not grant write permission to surfaces that a user can manipulate. For detailed policy, see Part IV ch15 (Permissions).]

== 12.6 Execution isolation — Sandbox

Do not expose the host filesystem or network directly; route through a _sandbox_.

=== Thread-scoped sandbox (most common pattern)

#code-block(`````python
from daytona import CreateSandboxFromSnapshotParams, Daytona
from deepagents import create_deep_agent
from langchain_core.runnables import RunnableConfig
from langchain_daytona import DaytonaSandbox

client = Daytona()

async def agent(config: RunnableConfig):
    thread_id = config["configurable"]["thread_id"]
    try:
        sandbox = await client.find_one(labels={"thread_id": thread_id})
    except Exception:
        sandbox = await client.create(
            CreateSandboxFromSnapshotParams(
                labels={"thread_id": thread_id},
                auto_delete_interval=3600,  # TTL
            )
        )
    return create_deep_agent(
        model="google_genai:gemini-3.1-pro-preview",
        backend=DaytonaSandbox(sandbox=sandbox),
    )
`````)

=== Assistant-scoped sandbox

Use when every thread should share one sandbox so tool-chain caches and installed binaries are preserved.

== 12.7 Durability · Async I/O

=== Checkpoint on every step

LangSmith Deployments attach a checkpointer automatically. State is saved on every step, which gives you:

- *Indefinite interrupt*: A HITL approval can sit for _days_ and still resume exactly where it paused
- *Time travel*: Rewind to an arbitrary checkpoint and branch
- *Audit trail*: State audit just before sensitive operations like payments or admin actions

#code-block(`````python
await agent.ainvoke(
    {"messages": [...]},
    config={"configurable": {"thread_id": "thread-abc"}},
)
`````)

=== Async I/O

LLM apps are I/O-bound. Using async tools and async middleware hooks (`abefore_agent`, `astream`) significantly increases throughput.

== 12.8 Rate limits and cost control

#code-block(`````python
from deepagents import create_deep_agent
from langchain.agents.middleware import (
    ModelCallLimitMiddleware,
    ToolCallLimitMiddleware,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        ModelCallLimitMiddleware(run_limit=50),
        ToolCallLimitMiddleware(run_limit=200),
    ],
)
`````)

`run_limit` resets for every `invoke`; `thread_limit` accumulates over the thread's lifetime. Cut off runaway loops before they become cost bombs.

== 12.9 Three-tier error handling

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Category],
  text(weight: "bold")[Examples],
  text(weight: "bold")[Strategy],
  text(weight: "bold")[Middleware],
  [Transient],
  [Timeouts, rate limits, transient network failures],
  [Auto-retry with backoff],
  [`ModelRetryMiddleware`, `ToolRetryMiddleware`],
  [Recoverable],
  [Bad tool arguments, parse failures],
  [Feed back to the model → retry],
  [Tool-wrapper error messages],
  [Human required],
  [Missing permissions, ambiguous request],
  [Pause the agent],
  [HITL `interrupt_on`],
)

#code-block(`````python
from langchain.agents.middleware import (
    ModelRetryMiddleware,
    ModelFallbackMiddleware,
    ToolRetryMiddleware,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    middleware=[
        ModelRetryMiddleware(max_retries=3, backoff_factor=2.0, initial_delay=1.0),
        ModelFallbackMiddleware("gpt-4.1"),
        ToolRetryMiddleware(
            max_retries=2,
            tools=["search", "fetch_url"],
            retry_on=(TimeoutError, ConnectionError),
        ),
    ],
)
`````)

== 12.10 Data privacy and real-time frontend

=== PIIMiddleware

Process PII — email, card numbers, national IDs — at the input and output boundaries. Strategies include `redact` (remove), `mask` (mask), `hash` (hash), and `block` (block); custom detectors can also be registered. The key is to process PII at the input side before it enters anything you log. LangSmith traces also record masked content only.

=== `useStream` hook

The `useStream` hook from `@langchain/react` handles real-time streaming, reconnection, and history loading in one place.

#code-block(`````tsx
import { useStream } from "@langchain/react";

function App() {
  const stream = useStream<typeof agent>({
    apiUrl: "https://your-deployment.langsmith.dev",
    assistantId: "agent",
    reconnectOnMount: true,
    fetchStateHistory: true,
  });
}
`````)

Deep Agents that spawn many subagents also stream subgraph events so the UI can render subagent progress cards (`streamSubgraphs: true`).

== 12.11 Production checklist

- [ ] Graphs and env are declared in `langgraph.json`
- [ ] Per-user authz handlers are applied to threads and the store
- [ ] External-service tokens are managed via Agent Auth / Proxy and never hardcoded
- [ ] `/memories/` is routed to `StoreBackend` with an explicit scope (user/assistant/org)
- [ ] Shared memory is read-only or write access is tightly restricted
- [ ] Host filesystem and shell are not exposed directly; access goes through a sandbox
- [ ] Cost ceilings are set via `ModelCallLimitMiddleware` / `ToolCallLimitMiddleware`
- [ ] Retry, fallback, and HITL are all configured
- [ ] PII is masked at input/output boundaries
- [ ] The frontend uses `reconnectOnMount` + `fetchStateHistory`

== Key Takeaways

- Roll out the ten operational areas independently on top of Thread · User · Assistant
- `langgraph.json` + LangSmith Deployments auto-provision checkpointer, Store, auth, and observability
- Memory scope defaults to user-scoped; shared scopes must be read-only
- Classify errors into three tiers (Transient / Recoverable / Human) and respond with middleware plus HITL
- Defend PII in two layers: at the model-input stage and at the trace-transmission stage
