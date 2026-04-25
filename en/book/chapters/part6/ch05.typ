// Source: 08_langsmith/05_production_monitoring.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Production Monitoring", subtitle: "Dashboards · Alerts · Sampling · PII")

Production is not "let's capture a clean trace" — it is a real-time dashboard + automatic evaluation + alerting + PII defense running together. This chapter bundles the LangSmith features you need after deployment from an operational angle: Monitoring dashboards, autoeval rules, the user-feedback API, alert rules, sampling, PII scrubbing, and Slack/PagerDuty webhook integration.

#learning-header()
#learning-objectives(
  [Read latency p50/p95, cost, and success rate on the project dashboard (Overview / Analytics)],
  [Register an online evaluator as an autoeval rule that runs automatically],
  [Send user thumbs/ratings from the app with `client.create_feedback(run_id, ...)`],
  [Understand metadata-based alert rules (failure rate > N% → webhook)],
  [Sample high-volume production traffic with `LANGSMITH_TRACING_SAMPLING_RATE`],
  [Defend in depth with `PIIMiddleware` and `hide_inputs`/`anonymizer`],
  [Configure Slack / PagerDuty webhook receivers],
)

== 5.1 Project dashboard

Each project page has three default tabs in the UI.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tab],
  text(weight: "bold")[What you see],
  text(weight: "bold")[Alert integration],
  [*Runs*],
  [Trace list, filters, quick search],
  [—],
  [*Monitor*],
  [Latency p50·p95·p99, success rate, error distribution, token/cost time series],
  [Threshold alerts via Rules],
  [*Evaluators*],
  [Attached online evaluators and score distributions],
  [Alerts on specific key-score drops],
)

To _build your own dashboard_, assemble custom charts in `Dashboards`. Or pull the same metrics with `client.list_runs` and attach them to an in-house system like Grafana.

#figure(image("../../../../assets/images/langsmith/05_production_monitoring/01_monitoring_dashboards_list.png", width: 95%), caption: [Project Monitoring Dashboards — six tabs (Traces / LLM Calls / Cost & Tokens / Tools / Run Types / Feedback Scores) × time range])

== 5.2 Online evaluator — autoeval rule

Chapter 3 showed how to attach one from the UI; here we look at _operational design_.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Role],
  text(weight: "bold")[Example setup],
  [Real-time quality gauge],
  [LLM-as-judge (`useful` score 0–1) on runs matching `has(tags, "env:prod")`],
  [Cost control],
  [Sampling rate 0.05 → evaluate only 5%],
  [Regression detection],
  [Rule triggers a webhook when the `useful` average drops below N%],
  [Specific use case],
  [Attach only to runs with `metadata.feature == "checkout"`],
)

autoeval results are stored as feedback keys, so alert rules, dashboards, and experiment comparisons all reuse them.

#figure(image("../../../../assets/images/langsmith/05_production_monitoring/03_automations_tab.png", width: 95%), caption: [Project > Automations tab — `+ Automation` to define condition (Feedback score < 0.5) → action (dataset ingestion / webhook / annotation queue)])

== 5.3 User feedback collection API

The canonical pattern is: thumbs-up / rating / "not helpful" button in the app UI → server calls `client.create_feedback`. Fire in the _background_ so the client does not wait (Python SDK handles this automatically if you pass a `trace_id`).

#code-block(`````python
from langsmith import Client

client = Client()
client.create_feedback(
    trace_id=trace_id,
    key="user_thumbs",
    score=1.0,
    comment="Correct",
)
`````)

== 5.4 Metadata-based alert rules

Combine the following actions in the project's *Rules* tab.

- `Add to annotation queue` (human review)
- `Add to dataset` (golden set)
- `Trigger webhook` (Slack, PagerDuty, in-house incident system)
- `Extend data retention` (extend retention for important traces)
- `Run online evaluator` (conditional quality evaluation)

*Example filter expression*

#code-block(`````text
and(
  has(tags, "env:prod"),
  eq(status, "error")
)
`````)

Action execution order (fixed by LangSmith): annotation queue → dataset → webhook → online evaluator → code evaluator → alert. Sampling rate can also be set per rule (e.g., 0.5 = 50% of matches).

#figure(image("../../../../assets/images/langsmith/05_production_monitoring/02_alerts_page.png", width: 95%), caption: [Monitoring > Alerts — the organization-wide alert hub. Clicking `Create Alert` opens a modal])

#figure(image("../../../../assets/images/langsmith/05_production_monitoring/05_create_alert_modal.png", width: 95%), caption: [Create Alert modal — select a tracing project, then specify a condition (error rate / latency / feedback change) → webhook URL])

== 5.5 High-volume sampling

At hundreds of requests per second, sending every trace wastes cost and bandwidth. Control it in two layers.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Layer],
  text(weight: "bold")[Mechanism],
  text(weight: "bold")[Characteristic],
  [Process-wide],
  [`LANGSMITH_TRACING_SAMPLING_RATE=0.1`],
  [Applies to `@traceable`, `RunTree`, and all auto-instrumentation],
  [Per-request],
  [`Client(tracing_sampling_rate=...)` + `tracing_context`],
  [Keep admin / payment requests at 100%],
)

Combining them implements policies such as "10% sampling for normal traffic, 100% for payment traffic."

== 5.6 PII scrubbing

Defend in two layers.

+ *Model-input stage*: `langchain.agents.middleware.PIIMiddleware` blocks or masks email / card numbers / API keys in messages before they reach the LLM — so the model itself never sees PII
+ *Trace-transmission stage*: the LangSmith client's `hide_inputs` / `hide_outputs` or `anonymizer` scrubs inputs / outputs one more time before they ship to the server

You need both so there is no "made it into the model but not into the trace" and no "model never saw it but it ended up in the trace".

#code-block(`````dotenv
# .env
LANGSMITH_HIDE_INPUTS=true
LANGSMITH_HIDE_OUTPUTS=true
`````)

== 5.7 Slack / PagerDuty webhook integration

The webhook action in Rules POSTs a payload to the URL you configure. The receiver converts it into Slack/PagerDuty format and raises the alert.

#code-block(`````python
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
        await hc.post(SLACK_URL, json={
            "text": f":rotating_light: LangSmith alert — status={status} tags={tags}\n<{trace_url}|open trace>",
        })
        if PAGERDUTY_URL and "critical" in tags:
            await hc.post(PAGERDUTY_URL, json={
                "routing_key": os.environ["PAGERDUTY_ROUTING_KEY"],
                "event_action": "trigger",
                "payload": {"summary": f"LangSmith {status}", "severity": "error", "source": "langsmith"},
            })
    return {"ok": True}
`````)

Register this endpoint URL as a webhook target in the UI's Rules and set the filter to `and(has(tags, "env:prod"), eq(status, "error"))` to Slack only production errors.

== 5.8 Insights Agent (paid)

Project > Insights tab — the LangSmith *Insights Agent* automatically extracts usage patterns / common failure modes from production traces. The free plan requires an upgrade.

#figure(image("../../../../assets/images/langsmith/05_production_monitoring/04_insights_tab.png", width: 95%), caption: [Insights tab — Upgrade required. Production-trace auto-analysis on paid plans])

== Key Takeaways

- Dashboards · Evaluators · Automations — the three tabs are the production-observability backbone
- Online evaluator + Rules webhook connect "real-time quality → alerts"
- Send user feedback in the background and expose score trends per `key` on the dashboard
- Sampling combines global (env var) + per-request (`tracing_context`) layers
- PII is protected in two layers: `PIIMiddleware` (model) + `anonymizer`/`hide_inputs` (trace)
- A webhook receiver routes to Slack / PagerDuty — the default filter is `env:prod` + `status=error`
