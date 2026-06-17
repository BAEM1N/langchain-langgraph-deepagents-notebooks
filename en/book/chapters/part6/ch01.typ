// Auto-generated from 01_quickstart.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LangSmith Quickstart")

This notebook covers sending your first trace to LangSmith and checking it in the UI.
_Just three environment variables + zero changes to your LangChain code_ are all that's needed.

== Learning Objectives

- Issue a LangSmith API key and inject it into your `.env`
- Confirm that simply setting `LANGSMITH_TRACING=true` automatically traces existing agent runs
- Attach `run_name`, `tags`, and `metadata` to traces to make them searchable
- Read the LLM/tool call tree, latency, token usage, and cost for a trace in the UI

== What You'll Gain

- Reproducible execution history to answer "why did the agent respond this way?"
- Source data for evaluation and prompt tuning stages

== 6.01.1 API Key & Environment Variables

+ Go to https://smith.langchain.com/ → `Settings → API Keys → Create API Key`
+ Add these three lines to your `.env`:

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_xxxxxxxx
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-quickstart
`````)

#tip-box[`LANGSMITH_PROJECT` is the project name shown in the UI. If unset, traces are recorded under `default`.]

_Onboarding Flow (First Time Only)_

#image("../../assets/images/langsmith/01_quickstart/00_onboarding_step1_role.png")

_Select Technical → code-first flow for developers._

#image("../../assets/images/langsmith/01_quickstart/01_onboarding_step2_mode.png")

_Branch between LangSmith (code-first) and Fleet (no-code). This notebook uses LangSmith._

#image("../../assets/images/langsmith/01_quickstart/02_home_empty_state.png")

_After onboarding, Home — Tracing/Datasets/Prompts all show 0/4._

#image("../../assets/images/langsmith/01_quickstart/03_get_started_tracing_dialog.png")

_First card on Home → 4-step quickstart dialog. `Generate API Key` button is step 1._

#image("../../assets/images/langsmith/01_quickstart/04_api_key_generated_RAW.png")

_Clicking Generate API Key creates an `lsv2_pt_…` key and auto-injects it into the env block in step 3. The key is shown only once, so copy it to `.env` immediately._

#code-block(`````python
# !pip install -U langsmith langchain langchain-openai

from dotenv import load_dotenv
import os
load_dotenv(override=True)

assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY not set"
assert os.environ.get("LANGSMITH_TRACING") == "true", "LANGSMITH_TRACING=true required"
# If LANGSMITH_PROJECT is not set, LangSmith records to the `default` project.
os.environ.setdefault("LANGSMITH_PROJECT", "default")
print("Project:", os.environ["LANGSMITH_PROJECT"])
`````)

== 6.01.2 First Trace — LangChain Agent

`create_agent` is automatically instrumented. As long as the environment variables are set, the following execution is recorded in LangSmith.

#code-block(`````python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def get_weather(city: str) -> str:
    """Returns the current weather for a city."""
    return f"{city}: Clear, 21°C"

agent = create_agent(
    model="openai:gpt-5.4",
    tools=[get_weather],
    system_prompt="You are a friendly weather bot.",
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "Tell me the weather in Seoul"}]
})
result["messages"][-1].content
`````)

After running, check in the UI:

+ Go to https://smith.langchain.com/ → left `Projects` → `langsmith-quickstart`
+ The recent run appears as a row (run_name = `AgentExecutor` by default)
+ Click to see the LLM call → tool call → LLM call tree, with input/output, latency, and tokens for each step

#image("../../assets/images/langsmith/01_quickstart/05_projects_list.png")

_Tracing menu → The `pr-jaunty-competitor-63` project just traced by the agent. Trace Count, P50/P99 Latency, Total Tokens, and Total Cost for the last 7 days are automatically populated._

#image("../../assets/images/langsmith/01_quickstart/06_project_runs_list.png")

_Click the project → individual run table. Input / Output / Latency / Tokens / Cost / Tags / Metadata at a glance. Tabs: Runs · Threads · Evaluators · Automations · Insights._

#image("../../assets/images/langsmith/01_quickstart/07_trace_tree_view.png")

_Click a run → waterfall tree. The sequence `model → tools → model` and each step's tokens/latency are visually reconstructed._

== 6.01.3 run_name · tags · metadata

Attach searchable/filterable metadata to traces using `invoke(..., config=...)`.

#code-block(`````python
config = {
    "run_name": "weather-bot:seoul-request",   # Name shown in the UI
    "tags": ["env:dev", "feature:weather"],     # Filter tags
    "metadata": {                                # Arbitrary key-value pairs
        "user_id": "u_00123",
        "session_id": "s_abc",
        "app_version": "0.5.0",
    },
}

agent.invoke(
    {"messages": [{"role": "user", "content": "Tell me the weather in Busan"}]},
    config=config,
)
`````)

In the UI, confirm you can filter with `Filter → Tags contains env:dev` or `Metadata.user_id = u_00123`.

#image("../../assets/images/langsmith/01_quickstart/08_trace_attributes.png")

_Attributes tab — The Tags (`env:dev`, `feature:weather`) and Metadata (`user_id`, `session_id`, `app_version`…) attached above are visible, and LangSmith environment variables and runtime (Python version, library versions, etc.) are automatically captured._

== 6.01.4 Tracing Pure Python Functions — `\@traceable`

Utility functions that don't use LangChain can also be included in traces with `@traceable`.

#code-block(`````python
from langsmith import traceable

@traceable(run_type="tool", name="normalize_city")
def normalize_city(raw: str) -> str:
    mapping = {"New York City": "New York", "San Francisco": "San Francisco"}
    return mapping.get(raw, raw)

@traceable(run_type="chain", name="weather-pipeline")
def weather_pipeline(raw_city: str) -> str:
    city = normalize_city(raw_city)
    result = agent.invoke({"messages": [{"role": "user", "content": f"Tell me the weather in {city}"}]})
    return result["messages"][-1].content

weather_pipeline("New York City")
`````)

In the UI, you will see `weather-pipeline` as the root, with `normalize_city` and `AgentExecutor` as children in a single tree.

=== `import langsmith as ls` — context manager pattern

Tracing starts automatically with environment variables, but if you want to _trace only a specific block_ or _disable tracing for a block_, use `langsmith.tracing_context`. It accepts `enabled`, `project_name`, `tags`, `metadata`, and `client` arguments.

#code-block(`````python
import langsmith as ls

# To temporarily send traces to a different project, or force-enable tracing over environment variables
with ls.tracing_context(
    enabled=True,
    project_name="default",          # Uses LANGSMITH_PROJECT if not specified
    tags=["block:ad-hoc"],
    metadata={"trigger": "manual"},
):
    weather_pipeline("San Francisco")
`````)

== 6.01.5 Retrieve Traces from Code

You can programmatically fetch traces without the UI using `langsmith.Client`. This is useful for evaluation or regression test inputs.

#code-block(`````python
from langsmith import Client
client = Client()

runs = list(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    run_type="chain",
    limit=5,
))
for r in runs:
    duration = (r.end_time - r.start_time).total_seconds() if r.end_time else 0.0
    print(f"{r.start_time:%H:%M:%S}  {r.name:30s}  {r.total_tokens or 0:>5} tok  {duration:.2f}s")
`````)

== 6.01.6 Cost & Token Aggregation

In the UI's project page, the `Analytics` tab (top right) shows total cost/token graphs per project.
Model-specific pricing is automatically calculated and filled in the `total_cost` field by LangSmith (custom models can be configured).

== 6.01.7 API Key Management Page

After onboarding, to reissue or revoke keys, go to `Settings → Access and Security → API Keys`.

#image("../../assets/images/langsmith/01_quickstart/09_settings_api_keys.png")

_Settings left nav: API Keys · Members · OAuth providers · Provider secrets · MCP servers · Model configurations · _Fleet webhooks_ · Model pricing · Feedback tags · Resource tags · Shared URLs · Plans · Usage · Credits · Invoices. The Key column in the table shows only the beginning and end by default, and Last Used At is recorded._

== Checklist

- [ ] Set `LANGSMITH_API_KEY`, `LANGSMITH_TRACING=true`, and `LANGSMITH_PROJECT` in `.env`
- [ ] Check the LLM/tool call tree of your recent agent run in the UI
- [ ] Attach `run_name` + `tags` + `metadata` and confirm UI filtering works
- [ ] Include regular functions in traces with `@traceable`
- [ ] Use `import langsmith as ls` + `ls.tracing_context(enabled=True, ...)` for block-level control
- [ ] Programmatically fetch traces with `Client().list_runs(...)`

== Next

- `02_tracing_agents.ipynb` — Trace structures for complex agents (LangGraph subgraph, Deep Agents subagent)
- `03_datasets_and_evaluation.ipynb` — Turn these traces into datasets for automated evaluation

== References

- LangSmith Observability: https://docs.langchain.com/langsmith/observability
- Trace with LangChain: https://docs.langchain.com/langsmith/trace-with-langchain
- Annotate code with `@traceable`: https://docs.langchain.com/langsmith/annotate-code
- `docs/langchain/30-observability.md`
