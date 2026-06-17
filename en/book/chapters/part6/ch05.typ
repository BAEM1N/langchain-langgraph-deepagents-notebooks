// Auto-generated from 05_production_monitoring.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Production Monitoring", subtitle: "Observation · Alerts · PII")

Production is not just about "let's just add some traces"—it requires _real-time dashboards + automated evaluation + alerts + personal data protection_ all running together. This notebook groups together the LangSmith features needed after deployment from an operational perspective.

== Learning Objectives

- Read latency p50/p95, cost, and success rate from the project dashboard (Overview / Analytics)
- Register an online evaluator as an autoeval rule for automatic execution
- Send user thumbs/star ratings from the app using `client.create_feedback(run_id, ...)`
- Understand metadata-based alert rules (failure rate \> N% -\> webhook)
- Sample traces in high-volume production using `LANGSMITH_TRACING_SAMPLING_RATE`
- PII scrubbing — combining LangChain `PIIMiddleware` and LangSmith `hide_inputs`/`anonymizer`
- Slack / PagerDuty webhook receiving patterns

== Prerequisites

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-prod-demo
# Optional: In high-volume environments, trace only 10%
# LANGSMITH_TRACING_SAMPLING_RATE=0.1
# Optional: Block all inputs/outputs
# LANGSMITH_HIDE_INPUTS=true
# LANGSMITH_HIDE_OUTPUTS=true
OPENAI_API_KEY=sk-...
`````)

In production, it is standard practice to _separate projects by environment_, as in this notebook's example project (`langsmith-prod-demo`).

#code-block(`````python
# !pip install -U langsmith langchain langchain-openai

from dotenv import load_dotenv
import os
load_dotenv(override=True)

assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY not set"
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY not set"
# If the project is not set, LangSmith records to `default`.
os.environ.setdefault("LANGSMITH_PROJECT", "langsmith-prod-demo")
print("Project:", os.environ["LANGSMITH_PROJECT"])
print("sampling rate:", os.environ.get("LANGSMITH_TRACING_SAMPLING_RATE", "1.0 (all)"))
`````)

== 6.05.1 Project Dashboard — latency · cost · success rate

The UI project page has three main tabs:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tab],
  text(weight: "bold")[What you see],
  text(weight: "bold")[Alert integration],
  [_Runs_],
  [Trace list, filters, quick search],
  [—],
  [_Monitor_],
  [latency p50·p95·p99, success rate, error distribution, token/cost time series],
  [Alerts via Rules],
  [_Evaluators_],
  [Attached online evaluators and score distribution],
  [Alert on drop in specific key scores],
)

If you want to build your own dashboard, you can group custom charts in `Dashboards`. You can also extract the same metrics with `client.list_runs` and connect them to internal systems like Grafana.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/05_production_monitoring/01_monitoring_dashboards_list.png")

_Monitoring \> Dashboards — 6 tabs (Traces / LLM Calls / Cost & Tokens / Tools / Run Types / Feedback Scores) × period (default: Last 7 days). In the image above, the Fri 17 spike is a pattern caused by running this curriculum all at once. Trace Count / Latency / Error Rate / LLM Count / LLM Latency are all displayed as time-series._

#code-block(`````python
# The single request limit for /runs/query is capped at 100 on the server side.
# list_runs is a generator, so use itertools.islice for automatic pagination up to N items.
from itertools import islice
from langsmith import Client
import statistics

client = Client()
runs = list(islice(
    client.list_runs(project_name=os.environ["LANGSMITH_PROJECT"]),
    500,   # Automatically collect up to 500, exceeding the server cap of 100
))

durations = [
    (r.end_time - r.start_time).total_seconds()
    for r in runs if r.end_time and r.start_time
]
if durations:
    print(f"Sample size {len(durations)} — p50={statistics.median(durations):.2f}s "
          f"p95={statistics.quantiles(durations, n=20)[-1]:.2f}s "
          f"p99={statistics.quantiles(durations, n=100)[-1]:.2f}s")
`````)

== 6.05.2 Online evaluator — autoeval rule

If you saw the UI flow for attaching evaluators in `03_datasets_and_evaluation`, here we focus on _operational design_.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Role],
  text(weight: "bold")[Example setting],
  [Real-time quality gauge],
  [Attach LLM-as-judge (`useful` score 0~1) to runs with `has(tags, "env:prod")`],
  [Cost management],
  [Evaluate only 5% with sampling rate 0.05],
  [Regression detection],
  [Trigger webhook in Rules if average `useful` score drops below N%],
  [Specific use case],
  [Attach evaluation only to runs where `metadata.feature == "checkout"`],
)

autoeval results are saved as feedback keys, so they can be reused for alert rules, dashboards, and Experiments comparison in the next cells.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/05_production_monitoring/03_automations_tab.png")

_Project \> Automations tab — `No automations found` state. Define rules with `+ Automation`: condition (e.g., Feedback score \< 0.5) → action (e.g., move to dataset / call webhook / send to annotation queue)._

== 6.05.3 User feedback collection API

The standard pattern is to call `client.create_feedback` on the server when the app UI's thumbs-up / star rating / "This answer wasn't helpful" button is pressed. To avoid making the client wait, send it in the _background_ (the Python SDK automatically does this in the background if you provide a `trace_id`).

#code-block(`````python
# Example inside an application: capture the run id after agent execution and return it,
# then attach feedback to that id when user feedback arrives.
from langsmith import traceable

@traceable(name="answer-user")
def answer_user(question: str) -> str:
    # In reality, this would return the result of agent.invoke(...)
    return f"Answer to '{question}'."

# Example of getting the current run_id via run_tree at execution time
from langsmith.run_helpers import get_current_run_tree

@traceable(name="answer-with-id")
def answer_with_id(question: str):
    rt = get_current_run_tree()
    return {"answer": answer_user(question), "run_id": str(rt.id)}

reply = answer_with_id("Seoul weather?")
print(reply)

# Later, when the user presses thumbs-up
client.create_feedback(
    run_id=reply["run_id"],
    key="user_thumbs",
    score=1,
    comment="User responded that it was helpful",
)
print("Feedback sent successfully")
`````)

== 6.05.4 Metadata-based alert rules — failure rate \\> N% -\\> webhook

On the UI's project -\> _Rules_ tab, you can combine the following actions:

- `Add to annotation queue` (human review)
- `Add to dataset` (accumulate golden set)
- `Trigger webhook` (Slack, PagerDuty, custom incident system)
- `Extend data retention` (extend retention for important traces)
- `Run online evaluator` (conditional quality evaluation)

_Sample filter expression_

#code-block(`````python
and(
  has(tags, "env:prod"),
  eq(status, "error")
)
`````)

Action execution order (fixed in LangSmith): annotation queue -\> dataset -\> webhook -\> online evaluator -\> code evaluator -\> alert. You can also set different sampling rates per rule (e.g., 0.5 = 50% of matches).

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/05_production_monitoring/02_alerts_page.png")

_Monitoring \> Alerts — organization-wide alert rule hub. When you click `Create Alert`, a modal appears:_

#image("../../assets/images/langsmith/05_production_monitoring/05_create_alert_modal.png")

_After selecting the tracing project, specify conditions (error rate/latency/feedback changes) → set up sending to a webhook URL._

== 6.05.5 High-volume sampling — `LANGSMITH_TRACING_SAMPLING_RATE`

When you have hundreds of requests per second, sending every trace is a waste of cost and network. Control is done on two levels:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Level],
  text(weight: "bold")[Method],
  text(weight: "bold")[Characteristics],
  [Entire process],
  [`LANGSMITH_TRACING_SAMPLING_RATE=0.1`],
  [Applies to `\@traceable`, `RunTree`, and all automatic instrumentation],
  [Per request],
  [`Client(tracing_sampling_rate=...)` + `tracing_context`],
  [100% for important requests like admin/payment],
)

By combining these, you can implement operational policies like "sample 10% of general traffic, 100% of payment traffic."

#code-block(`````python
from langsmith import Client
from langsmith.run_helpers import tracing_context

# The default client records only 10%, the critical flow client records 100%
client_bulk     = Client(tracing_sampling_rate=0.1)
client_critical = Client(tracing_sampling_rate=1.0)

with tracing_context(client=client_critical, tags=["env:prod", "flow:checkout"]):
    # Critical flows like payment are executed in this block — all are recorded
    print("critical flow — 100% trace")

with tracing_context(client=client_bulk, tags=["env:prod", "flow:chat"]):
    # General chat — only 10% are sampled
    print("bulk flow — 10% sampling")
`````)

== 6.05.6 PII Scrubbing — `PIIMiddleware` + `anonymizer`

Defense is done in two layers:

+ _Model input stage_: `langchain.agents.middleware.PIIMiddleware` blocks/masks emails, card numbers, API keys, etc. in messages sent to the LLM—so the model itself never sees PII.
+ _Trace sending stage_: LangSmith client's `hide_inputs`/`hide_outputs` or `anonymizer` scrubs inputs/outputs again before sending to the server.

You should use both to avoid gaps like "PII went to the model but not the trace" or "model didn't see it but it ended up in the trace."

#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import PIIMiddleware
from langchain.tools import tool

@tool
def lookup_order(order_id: str) -> str:
    """Check order status (for demo)."""
    return f"{order_id} -> In delivery"

# 1) Model input stage — masking with PIIMiddleware
# PIIMiddleware in langchain 1.2.x defaults to 5 pii_types: email/credit_card/ip/mac_address/url.
# To use custom types like "api_key", you need to provide your own detector.
safe_agent = create_agent(
    model="openai:gpt-5.4",
    tools=[lookup_order],
    middleware=[
        PIIMiddleware("email",       strategy="redact"),
        PIIMiddleware("credit_card", strategy="redact"),
    ],
)

out = safe_agent.invoke({"messages": [
    {"role": "user", "content": "Check my order status for my email alice@example.com (order A-42)"}
]})
print(out["messages"][-1].content)
`````)

#code-block(`````python
# 2) Trace sending stage — re-masking input/output with anonymizer
from langsmith.anonymizer import create_anonymizer

anonymizer = create_anonymizer([
    {"pattern": r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+", "replace": "<email>"},
    {"pattern": r"\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b",            "replace": "<card>"},
])

masked_client = Client(anonymizer=anonymizer)

# If you need to block everything, use environment variables or Client arguments
fully_hidden_client = Client(
    hide_inputs=lambda inputs: {},
    hide_outputs=lambda outputs: {},
)
print("anonymizer / full-hide client ready — swap in the Client instance as needed")
`````)

== 6.05.7 Slack / PagerDuty webhook integration

The webhook action in Rules sends a POST payload to the configured URL. The receiving side converts it to Slack/PagerDuty format and triggers an alert.

#code-block(`````python
# Example: Receiving webhook with FastAPI — relaying to Slack
from fastapi import FastAPI, Request
import httpx, os

app = FastAPI()
SLACK_URL     = os.environ["SLACK_INCOMING_WEBHOOK"]
PAGERDUTY_URL = os.environ.get("PAGERDUTY_EVENTS_V2_URL")

@app.post("/langsmith/alert")
async def on_alert(req: Request):
    event = await req.json()
    run_id  = event.get("run_id") or event.get("trace_id")
    status  = event.get("status", "unknown")
    tags    = event.get("tags", [])
    trace_url = f"https://smith.langchain.com/o/-/projects/-/r/{run_id}"

    async with httpx.AsyncClient() as hc:
        # Slack
        await hc.post(SLACK_URL, json={
            "text": f":rotating_light: LangSmith alert — status={status} tags={tags}\n<{trace_url}|Open trace>",
        })
        # PagerDuty (only for high severity)
        if PAGERDUTY_URL and "critical" in tags:
            await hc.post(PAGERDUTY_URL, json={
                "routing_key": os.environ["PAGERDUTY_ROUTING_KEY"],
                "event_action": "trigger",
                "payload": {"summary": f"LangSmith {status}", "severity": "error", "source": "langsmith"},
            })
    return {"ok": True}
`````)

Register this endpoint URL as the webhook target in the UI's Rules, and set the filter to `and(has(tags, "env:prod"), eq(status, "error"))` to receive only production errors in Slack.

== 6.05.8 Manual Run Tree control + LangSmith Deployments monitoring

For workers/CLI/batch jobs where automatic instrumentation doesn't reach, you can build the trace tree directly with `RunTree`. If you specify parent-child relationships, the UI tree will appear exactly as you constructed it.

All threads of _LangSmith Deployments_ deployed on the LangGraph Platform are automatically traced to the same project, and the Monitor / Rules / Online evaluator features described above work as is.

#code-block(`````python
from langsmith.run_trees import RunTree

# Start root run — pattern for external workers sending an entire trace at once
root = RunTree(
    name="batch-rebuild",
    run_type="chain",
    inputs={"job": "nightly-index"},
    project_name=os.environ["LANGSMITH_PROJECT"],
    tags=["env:prod", "source:cron"],
)

# Child run — simulating a tool call
child = root.create_child(
    name="fetch-shards",
    run_type="tool",
    inputs={"shards": 8},
)
child.end(outputs={"fetched": 8})
child.post()

root.end(outputs={"ok": True})
root.post()
print(f"RunTree sent successfully → root id={root.id}")
`````)

== Checklist

- [ ] Check p50/p95/p99 · success rate · cost in the project Monitor tab
- [ ] Register an online evaluator with prod tag filter + 5% sampling
- [ ] Implement thumbs feedback sending pattern in the app using `client.create_feedback(run_id, ...)`
- [ ] Attach webhook action to `status=error` + tag filter via Rules
- [ ] Use `LANGSMITH_TRACING_SAMPLING_RATE` and `tracing_context` to sample 100% only for critical flows
- [ ] Dual protection with `PIIMiddleware` (model) + `anonymizer`/`hide_inputs` (trace)
- [ ] Send external worker traces using `RunTree.create_child` + `post()`
- [ ] Check that threads in LangSmith Deployments (LangGraph Platform) automatically flow into the same project
- [ ] Verify that the webhook receiving service routes to Slack / PagerDuty

== Next

- This wraps up the `06_langsmith` curriculum. For a comparison with vendor-neutral observability like Langfuse or OTel, see `08_integration/12_observability/`.

== References

- Observability overview: https://docs.langchain.com/langsmith/observability
- Dashboards: https://docs.langchain.com/langsmith/dashboards
- Alerts: https://docs.langchain.com/langsmith/alerts
- Online evaluators: https://docs.langchain.com/langsmith/online-evaluations
- Rules · webhook: https://docs.langchain.com/langsmith/rules
- Sampling: https://docs.langchain.com/langsmith/sample-traces
- Mask inputs/outputs: https://docs.langchain.com/langsmith/mask-inputs-outputs
- Feedback API: https://docs.langchain.com/langsmith/attach-user-feedback
- LangSmith Deployments: https://docs.langchain.com/langsmith/deployments

\<!-- phase-c:embed --\>
== 6.05.X Insights Agent (Paid)

#image("../../assets/images/langsmith/05_production_monitoring/04_insights_tab.png")

_Project \> Insights tab — LangSmith's _Insights Agent_ automatically extracts usage patterns / common failure modes from production traces. Upgrade required for free plans._
