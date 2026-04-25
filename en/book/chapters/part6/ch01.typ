// Source: 06_langsmith/01_quickstart.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangSmith Quickstart", subtitle: "From the first trace to a UI tour")

LangSmith is the _LLM application observability platform_ built by the LangChain team. Without changing a line of agent code, adding three environment variables is enough to record every LLM call and tool execution as traces automatically. This chapter walks from API key issuance, to confirming your first trace in the UI, to incorporating plain Python functions into traces via the `@traceable` decorator and `langsmith.Client`.

#learning-header()
#learning-objectives(
  [Issue a LangSmith API key and load it via `.env`],
  [Confirm that existing agents are auto-traced with just `LANGSMITH_TRACING=true`],
  [Make traces searchable with `run_name` · `tags` · `metadata`],
  [Read the trace tree, latency, token usage, and cost in the UI],
  [Incorporate plain functions into traces with `@traceable`],
)

== 1.1 API keys and environment variables

LangSmith enables tracing with no code changes — three environment variables do it. Add the following to your `.env`.

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_xxxxxxxx
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-quickstart
`````)

`LANGSMITH_PROJECT` is the namespace shown in the UI's left sidebar under _Projects_. If you leave it unset, runs are recorded in the `default` project. API keys are shown only once on creation, so copy the key into `.env` immediately.

=== Onboarding flow (first time only)

The first login goes through a four-step onboarding: role selection → mode selection → home → quickstart dialog. Choose the Technical role and LangSmith (code-first) mode to follow the developer track.

#figure(image("../../../../assets/images/langsmith/01_quickstart/00_onboarding_step1_role.png", width: 85%), caption: [Role selection — choosing Technical takes you into the developer-oriented code-first flow])

#figure(image("../../../../assets/images/langsmith/01_quickstart/01_onboarding_step2_mode.png", width: 85%), caption: [LangSmith (code-first) vs Fleet (no-code) — this chapter follows the LangSmith path])

#figure(image("../../../../assets/images/langsmith/01_quickstart/02_home_empty_state.png", width: 85%), caption: [Home right after onboarding — Tracing / Datasets / Prompts all in initial state])

#figure(image("../../../../assets/images/langsmith/01_quickstart/03_get_started_tracing_dialog.png", width: 85%), caption: [The four-step quickstart dialog that opens as the first card on Home])

#figure(image("../../../../assets/images/langsmith/01_quickstart/04_api_key_generated_RAW.png", width: 85%), caption: [Clicking Generate API Key produces an `lsv2_pt_…` key — shown only once, so copy it into `.env` immediately])

== 1.2 Your first trace — a LangChain agent

`create_agent` is _auto-instrumented_. As soon as the environment variables are set, the moment the code below runs it lands in LangSmith.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain.tools import tool

load_dotenv()

@tool
def get_weather(city: str) -> str:
    """Look up the weather for a city."""
    return f"{city} is sunny"

agent = create_agent(
    model="openai:gpt-4.1",
    tools=[get_weather],
)

agent.invoke({"messages": [{"role": "user", "content": "What's the weather in Seoul?"}]})
`````)

After running, that invocation appears as a single row under _Projects → langsmith-quickstart_ in the UI. Clicking it reconstructs the LLM-call → tool-call → LLM-call tree visually.

#figure(image("../../../../assets/images/langsmith/01_quickstart/05_projects_list.png", width: 95%), caption: [Projects list — Trace Count, P50/P99 Latency, Total Tokens, and Total Cost are aggregated automatically])

#figure(image("../../../../assets/images/langsmith/01_quickstart/06_project_runs_list.png", width: 95%), caption: [Run table on the project detail page — Input / Output / Latency / Tokens / Cost / Tags / Metadata in one view])

#figure(image("../../../../assets/images/langsmith/01_quickstart/07_trace_tree_view.png", width: 95%), caption: [Trace Tree — `model → tools → model` order with tokens / latency shown as a waterfall at each step])

== 1.3 run_name · tags · metadata

Attach search and filter metadata to traces with `invoke(..., config=...)`. This is the main lever that makes queries like "show only failures this user had this session" possible in operations.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "Weather in Busan"}]},
    config={
        "run_name": "weather-query-demo",
        "tags": ["env:dev", "feature:weather"],
        "metadata": {
            "user_id": "u_00123",
            "session_id": "s_demo",
            "app_version": "0.1.0",
        },
    },
)
`````)

Confirm filtering works in the UI with `Filter → Tags contains env:dev` or `Metadata.user_id = u_00123`.

#figure(image("../../../../assets/images/langsmith/01_quickstart/08_trace_attributes.png", width: 95%), caption: [Attributes tab — attached Tags / Metadata are visible, and environment / runtime info is auto-captured])

== 1.4 Tracing plain Python functions — `@traceable`

Preprocessing / postprocessing helpers that do not go through LangChain can also be incorporated into traces via `@traceable`. They nest as child spans under the parent trace, making it possible to track things like "why did we query this city".

#code-block(`````python
from langsmith import traceable

@traceable(run_type="chain", name="normalize_city")
def normalize_city(raw: str) -> str:
    return raw.strip().replace("City", "")

@traceable(run_type="chain", name="weather-pipeline")
def run_weather(user_text: str) -> str:
    city = normalize_city(user_text)
    result = agent.invoke(
        {"messages": [{"role": "user", "content": f"Weather in {city}"}]},
    )
    return result["messages"][-1].content

run_weather("Busan City")
`````)

In the UI, `weather-pipeline` is the root with `normalize_city` and `AgentExecutor` grouped beneath it as a single tree.

== 1.5 Re-querying traces from code

`langsmith.Client` lets you pull traces programmatically without the UI. Use it as inputs for regression tests, source data for nightly batch reports, or seeds for building datasets.

#code-block(`````python
from langsmith import Client

client = Client()

runs = list(
    client.list_runs(
        project_name="langsmith-quickstart",
        filter='and(has(tags, "env:dev"), eq(is_root, true))',
        limit=10,
    )
)

for r in runs:
    print(r.id, r.name, r.total_tokens, r.total_cost)
`````)

The `filter` expression uses the same DSL that the UI `Add filter` emits.

== 1.6 Cost and token aggregation

The _Analytics_ tab at the top-right of the UI project page shows project-level total cost and token time series. LangSmith fills `total_cost` automatically using per-model pricing; self-hosted models can have custom prices set under _Settings → Model pricing_.

== 1.7 Re-issuing API keys

To re-issue or revoke a key after onboarding, go to _Settings → Access and Security → API Keys_. Existing keys record their Last Used At automatically; if compromise is suspected, revoke immediately and issue a new one.

#figure(image("../../../../assets/images/langsmith/01_quickstart/09_settings_api_keys.png", width: 95%), caption: [Settings > API Keys — the Key column shows only the prefix/suffix automatically, and Last Used At is tracked])

== Key Takeaways

- Three environment variables (`LANGSMITH_API_KEY`, `LANGSMITH_TRACING=true`, `LANGSMITH_PROJECT`) auto-trace existing agents
- `run_name` · `tags` · `metadata` surface runs in UI filters and `client.list_runs(filter=...)` queries
- `@traceable` pulls non-LangChain functions into the same trace tree
- `langsmith.Client` fetches traces programmatically to seed evaluation and regression tests
- The three UI levels — Projects / Runs / Trace tree — reproduce "which call produced what"
