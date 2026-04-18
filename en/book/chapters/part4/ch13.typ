// Source: docs/deepagents/14-context-engineering.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(13, "Context Engineering", subtitle: "Write big, read selective")

This chapter pulls together the full design of how a Deep Agent decides _what_ to show the model inside its limited context window, _when_ to offload, and _how_ to bring things back. Use it when you are tuning the drift in quality over long sessions, or when you want to organize subagents / skills / memory into a single pipeline.

#learning-header()
#learning-objectives(
  [Understand the four-layer architecture of context engineering (Layered / Dynamic / Compression / Retrieval)],
  [Know the nine-step automatic synthesis order of the system prompt],
  [Distinguish the automatic offloading (>20k tokens) and automatic summarization (85%) triggers],
  [Propagate runtime context via `@dynamic_prompt` and `context_schema`],
  [Prevent context pollution with subagent isolation and `/memories/` routing],
)

== 13.1 The four-layer architecture

Deep Agents' context engineering stacks in four layers.

+ *Layered input context* — system prompt, `AGENTS.md`, `SKILL.md`, and tool descriptions are synthesized in a fixed order
+ *Dynamic / runtime context* — `@dynamic_prompt` and `ToolRuntime` inject request-time data
+ *Automatic compression* — offloading (>20k tokens → disk), summarization (85% → structured summary)
+ *Filesystem-centric retrieval* — selective re-injection via `read_file` / `grep` / subagent isolation

Each layer can be toggled independently, but the defaults alone handle roughly 90% of long-session cases out of the box.

== 13.2 Layered input context — nine-step system prompt synthesis

The system prompt is synthesized automatically in this order.

+ Custom system prompt (user-supplied instructions)
+ Base agent prompt (planning / filesystem / subagent base instructions)
+ To-do list prompt
+ Memory prompt (`AGENTS.md`, always loaded when configured)
+ Skills prompt (only skill locations and frontmatter)
+ Filesystem prompt (tool documentation)
+ Subagent prompt (delegation guidance)
+ Middleware prompts (custom additions)
+ Human-in-the-loop prompt

=== AGENTS.md: permanent context loaded every time

Put content that must apply to _every_ conversation — project conventions, user preferences.

#code-block(`````python
from deepagents import create_deep_agent

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    memory=["/project/AGENTS.md", "~/.deepagents/preferences.md"],
)
`````)

Because it is always loaded, keep it minimal. Move detailed workflows into `SKILL.md`.

== 13.3 `@dynamic_prompt` — request-time data injection

Use this when a static string is not enough and the instruction has to change based on _request-time data_ (user role, organization id, current time, store contents). The middleware reads `request.runtime.context` and `request.runtime.store` to build the dynamic prompt. The dynamic prompt is decided at the _middleware layer_; tools receive runtime values through `ToolRuntime` with no extra wiring.

== 13.4 Progressive skill loading

Skills load in two phases.

- *Startup*: only the frontmatter (name · description) of `SKILL.md` is read → a few hundred tokens
- *On demand*: the full body is loaded only when a user request matches the skill

#code-block(`````python
agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    skills=["/skills/research/", "/skills/web-search/"],
)
`````)

Even with dozens of skills registered, the initial token cost is just the frontmatter.

== 13.5 Runtime context propagation

Context declared via `context_schema` is automatically forwarded not only to the agent but to _every subagent and tool_.

#code-block(`````python
from dataclasses import dataclass
from deepagents import create_deep_agent
from langchain.tools import tool, ToolRuntime

@dataclass
class Context:
    user_id: str
    api_key: str

@tool
def fetch_user_data(query: str, runtime: ToolRuntime[Context]) -> str:
    """Look up data for the current user."""
    user_id = runtime.context.user_id
    return f"Data for user {user_id}: {query}"

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    tools=[fetch_user_data],
    context_schema=Context,
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "Get my recent activity"}]},
    context=Context(user_id="user-123", api_key="sk-..."),
)
`````)

Thanks to this structure, tools can read runtime values without loading API keys into the message history, and subagents automatically inherit the same values.

#tip-box[*Tool doc quality is context.* The model picks tools purely from their _description_. Writing concrete docstrings + Args sections reduces wasted tokens. Enable automatic Args parsing with `@tool(parse_docstring=True)`.]

== 13.6 Automatic offloading (>20k tokens)

As context grows, two offloading behaviors kick in automatically.

- *Input offloading*: Results of large-file `write` / `edit` operations are replaced with a _file pointer reference_ instead of their actual content once context exceeds 85% capacity
- *Result offloading*: Tool responses over _20,000 tokens_ are written to storage; the context retains only _a file path + first 10-line preview_

Large results go to disk first and are pulled back selectively with `read_file` / `grep` when needed. This is the core rationale for the filesystem-centric design.

== 13.7 Automatic summarization (85% trigger)

When there is nothing left to offload but context is still large, _structured summarization_ kicks in. An LLM compresses the current conversation into three elements: Session intent, Artifacts created, Next steps. This summary _replaces_ the existing conversation history and the agent continues.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Default],
  [Trigger],
  [85% of the model's `max_input_tokens`],
  [Retained],
  [10%],
  [Fallback],
  [Triggers at 170,000 tokens, retains the last 6 messages],
  [Immediate trigger],
  [On `ContextOverflowError`],
)

=== Manual summarization tool

Beyond the automatic trigger, add middleware to let the agent invoke summarization explicitly.

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend
from deepagents.middleware.summarization import create_summarization_tool_middleware

backend = StateBackend
model = "google_genai:gemini-3.1-pro-preview"

agent = create_deep_agent(
    model=model,
    middleware=[create_summarization_tool_middleware(model, backend)],
)
`````)

When streaming, you can filter summarization tokens out of the UI (`metadata.get("lc_source") == "summarization"`).

== 13.8 Subagent isolation

Subagents run in _their own context_ and return only _one final report_ to the supervisor. Intermediate tool calls and search results stay in the subagent's context, keeping the supervisor window clean.

#code-block(`````python
research_subagent = {
    "name": "researcher",
    "description": "Run research on a specific topic",
    "system_prompt": (
        "You are a research assistant.\n"
        "IMPORTANT: Return only the essential summary (under 500 words).\n"
        "Do NOT include raw search results or detailed tool outputs."
    ),
    "tools": [web_search],
}
`````)

Explicitly stating "return only the final summary" in the subagent's prompt is the first line of defense against context pollution.

== 13.9 `/memories/` routing with CompositeBackend

Route only certain paths to a persistent store, leave the rest on ephemeral state. The agent uses the same `write_file` / `read_file` calls; different backends handle them under the hood.

#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

def make_backend(runtime):
    return CompositeBackend(
        default=StateBackend(runtime),
        routes={"/memories/": StoreBackend(runtime)},
    )

agent = create_deep_agent(
    model="google_genai:gemini-3.1-pro-preview",
    store=InMemoryStore(),
    backend=make_backend,
    system_prompt=(
        "When users tell you their preferences, save them to "
        "/memories/user_preferences.txt so you remember them in future conversations."
    ),
)
`````)

== 13.10 Filesystem-centric architecture

All of Deep Agents' context-compression strategies converge on a single principle.

#tip-box[*"Write big, read selective."* Write big artifacts to disk; when you need them again, inject only the relevant portions via `read_file` / `grep`.]

Because of this structure:

- Even when tool results exceed 20k tokens, the context retains only a file reference + 10-line preview
- Subagents can explore as widely as they want without touching the supervisor window
- Memory is not always loaded; instead it is pulled in via `read_file("/memories/...")` _when needed_
- Only the frontmatter of a skill is visible; the body is loaded on demand

== 13.11 Three patterns

=== Pattern 1: long research sessions

- `AGENTS.md` is minimal — only research style and citation rules
- Register 3–10 skills, expose only frontmatter
- Topic-specific subagents explore in parallel → return only the final summary
- Large search results are offloaded to files automatically → re-query via `grep`

=== Pattern 2: personalization assistant

- `/memories/` routing accumulates per-user preferences
- `@dynamic_prompt` injects tone and guardrails by user role
- Declare `user_id` / `org_id` on `context_schema` so every subagent sees them
- Shared policies live under `/policies/` (read-only) namespace

=== Pattern 3: cost optimization

- Lower the automatic summarization trigger slightly below the 85% default
- Declare "under 500 words" in subagent system prompts
- Wrap tools with large responses so they return a summary + file pointer

== 13.12 Caveats

- *Do not overload AGENTS.md* — it is always loaded, so anything over ~5 KB starts to hurt
- *Skill frontmatter is everything* — if matching fails, the body is never loaded
- *Summarization is destructive* — save important intermediate artifacts to files first
- *If a subagent returns a raw dump*, the supervisor window blows up faster than without it
- *Tool description quality = token efficiency* — vague docstrings cause costly retries

== Key Takeaways

- Context engineering is a four-layer architecture: Layered / Dynamic / Compression / Retrieval
- Automatic offloading (20k results) and automatic summarization (85%) are the primary compression mechanisms
- `@dynamic_prompt` and `context_schema` propagate runtime context across the entire graph
- Subagent isolation and `/memories/` routing are the two pillars against context pollution
- The full design distills to "Write big, read selective" — big outputs to disk, selective re-injection
