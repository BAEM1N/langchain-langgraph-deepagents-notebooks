// Auto-generated from 03_datasets_and_evaluation.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Datasets & Evaluation", subtitle: "From Trace to Automated Evaluation Loop")

A trace shows "how things are currently running," while evaluation answers "did things improve when we changed the prompt, model, or code?" In LangSmith, _traces can be directly promoted to datasets_, and on top of those, you can run code evaluators, LLM-as-judge, pairwise, and summary evaluations.

== Learning Objectives

- Create a dataset and add examples using `client.create_dataset` + `client.create_examples`
- Transfer production traces to a dataset using `client.add_runs_to_dataset`
- Write a code evaluator in the form `def my_eval(inputs, outputs, reference_outputs) -> dict`
- Run an LLM-as-judge evaluator to get structured scores
- Use pairwise/summary evaluators to compare two experiments and get dataset-level metrics
- Run experiments and assign names using the `from langsmith.evaluation import evaluate` runner
- Understand the flow of automatically applying _online evaluators_ to production traces

== Prerequisites

You need three LangSmith keys and an OpenAI key in your `.env` file.

#code-block(`````dotenv
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=langsmith-eval-demo
OPENAI_API_KEY=sk-...
`````)

While running evaluations, experiment projects are automatically separated and recorded, so they don't get mixed with the production project.

#code-block(`````python
# !pip install -U langsmith langchain langchain-openai agentevals

from dotenv import load_dotenv
import os
load_dotenv(override=True)

assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY not set"
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY not set"
# If the project is not set, LangSmith records to `default`.
os.environ.setdefault("LANGSMITH_PROJECT", "langsmith-eval-demo")
print("Project:", os.environ["LANGSMITH_PROJECT"])
`````)

== 6.03.1 Creating a Dataset — Adding Examples Manually

A domain expert writes golden Q&A examples directly and adds them using `create_examples`. Both `inputs` and `outputs` are dicts. `outputs` serve as reference answers for code evaluators and LLM-as-judge comparisons.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/03_datasets_and_evaluation/01_datasets_list.png")

_Datasets & Experiments list — Two datasets: `weather-bot-qa` (3 examples · 2 experiments) and `agent-golden-traces` (for permanent storage of excellent traces). The `kv` in the Type column indicates a key-value structured dataset._

#code-block(`````python
from langsmith import Client

client = Client()
DATASET_NAME = "weather-bot-qa"

try:
    dataset = client.create_dataset(
        dataset_name=DATASET_NAME,
        description="Weather bot golden Q&A — for city name normalization and response tone validation",
    )
except Exception:
    dataset = client.read_dataset(dataset_name=DATASET_NAME)

client.create_examples(
    dataset_id=dataset.id,
    examples=[
        {"inputs": {"question": "What's the weather in Seoul?"},        "outputs": {"city": "Seoul"}},
        {"inputs": {"question": "How's the weather in Busan Metropolitan City?"},     "outputs": {"city": "Busan"}},
        {"inputs": {"question": "How's the weather in Jeju Island today?"}, "outputs": {"city": "Jeju"}},
    ],
)
print(f"Dataset ready: {dataset.name} ({dataset.id})")
`````)

== 6.03.2 Transferring Production Traces to a Dataset

Manual creation is only for the initial seed; real scale comes from _production traces_. With `client.add_runs_to_dataset`, the run's `inputs`/`outputs` are copied directly as examples. In actual operations, it's common to only upload runs reviewed by humans via the Annotation Queue.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/03_datasets_and_evaluation/03_dataset_examples_tab.png")

_Examples tab of `weather-bot-qa` — 3 examples uploaded via `client.create_examples(...)`. The Inputs column contains Korean questions, and the Reference Outputs column shows the expected city names. There are toggles for JSON/YAML format conversion and a Splits column (for train/validation/test separation)._

#code-block(`````python
# Select a few root runs from the current project and transfer them to the dataset
# Since langsmith 0.7.x, add_runs_to_dataset has been removed. Convert to create_examples instead.
root_runs = list(client.list_runs(
    project_name=os.environ["LANGSMITH_PROJECT"],
    is_root=True,
    limit=5,
))

examples = [
    {"inputs": r.inputs, "outputs": r.outputs, "metadata": {"source_run_id": str(r.id)}}
    for r in root_runs if r.outputs
]
if examples:
    client.create_examples(dataset_id=dataset.id, examples=examples)
print(f"Transferred {len(examples)} runs to {DATASET_NAME}")
`````)

== 6.03.3 Evaluation Target + Code Evaluator

As an example, we'll use an LLM function that "extracts the city name from a question" as the target. The target should be in the form `inputs: dict -> outputs: dict`.

The evaluator receives _`(inputs, outputs, reference_outputs)`_ and returns a dict like `{"key": ..., "score": ...}`. Deterministic heuristics cost nothing and have ~0 ms latency — the more you add, the better.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/03_datasets_and_evaluation/04_dataset_evaluators_tab.png")

_Evaluators page — 8 templates (PII Leakage · Prompt Injection · Toxicity · Bias & Fairness · Hallucination · Correctness · Perceived Error · User Satisfaction) + custom evaluators (LLM-as-a-Judge · Code Evaluator)._

#code-block(`````python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-5.4", temperature=0)

def extract_city(inputs: dict) -> dict:
    """Extracts only the city name from the question (removes metropolitan/special city suffixes)."""
    q = inputs["question"]
    msg = llm.invoke(f"Answer with only the city name as a single word from the following question (e.g., Seoul, Busan, Jeju). Question: {q}")
    return {"city": msg.content.strip()}

def city_exact_match(inputs: dict, outputs: dict, reference_outputs: dict) -> dict:
    """Checks if the predicted city exactly matches the reference."""
    return {
        "key": "city_exact_match",
        "score": int(outputs.get("city") == reference_outputs.get("city")),
    }

def city_non_empty(inputs: dict, outputs: dict, reference_outputs: dict) -> dict:
    """Defends against empty responses — for monitoring failure modes."""
    return {"key": "city_non_empty", "score": int(bool(outputs.get("city", "").strip()))}

print(extract_city({"question": "How's the weather in Busan Metropolitan City?"}))
`````)

== 6.03.4 LLM-as-judge Evaluator

Use this when there is no exact answer string or when you need to measure natural language quality (tone, accuracy, helpfulness). The key is to _force the output into a structured score_ even though the same LLM is called.

#code-block(`````python
from pydantic import BaseModel, Field

class Judgement(BaseModel):
    score: int = Field(..., ge=0, le=1, description="1 if the response is semantically the same as the reference answer")
    reason: str

judge_llm = llm.with_structured_output(Judgement)

def semantic_city_match(inputs: dict, outputs: dict, reference_outputs: dict) -> dict:
    verdict: Judgement = judge_llm.invoke(
        "Compare the question, expected city, and the city extracted by the model to determine if they are semantically the same.\n"
        f"Question: {inputs['question']}\nExpected: {reference_outputs.get('city')}\nModel: {outputs.get('city')}"
    )
    return {"key": "semantic_city_match", "score": verdict.score, "comment": verdict.reason}
`````)

== 6.03.5 `evaluate` Runner + Experiment Name

`from langsmith.evaluation import evaluate` is the standard runner. If you give a meaningful name to `experiment_prefix`, you can compare directly in the UI's Experiments view.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/03_datasets_and_evaluation/05_pairwise_experiments_tab.png")

_Pairwise Experiments tab — Compare the outputs of two experiments side by side. Run via the `evaluate_comparative` API (as of April 2026, the full session name is required, so the `evaluate_comparative` call in this notebook fails with drift and is shown empty)._

#code-block(`````python
from langsmith.evaluation import evaluate

results = evaluate(
    extract_city,
    data=DATASET_NAME,
    evaluators=[city_exact_match, city_non_empty, semantic_city_match],
    experiment_prefix="city-extractor:gpt-5.4",
    description="Baseline — temperature 0, single prompt",
    max_concurrency=4,
    metadata={"model": "gpt-5.4", "temperature": 0},
)
print("Experiment URL ->", results)
`````)

== 6.03.6 Pairwise + Summary Evaluator

- _Pairwise_: Compares the outputs of two experiments for the same example and selects "which one is better." Used for A/B prompt experiments. Uses the `evaluate_comparative` runner.
- _Summary_: Provides dataset-level metrics (e.g., macro average accuracy). The signature is different in that it receives a _list_ of runs/examples.

#code-block(`````python
from langsmith.evaluation import evaluate_comparative

# 1) Second experiment for comparison (different prompt)
def extract_city_v2(inputs: dict) -> dict:
    q = inputs["question"]
    msg = llm.invoke(f"Return only the city name, without any suffix, from the question: {q}")
    return {"city": msg.content.strip()}

results_v2 = evaluate(
    extract_city_v2,
    data=DATASET_NAME,
    evaluators=[city_exact_match],
    experiment_prefix="city-extractor:v2-strict-prompt",
)

# 2) pairwise: Select the better output between the two
def pref_shorter_city(runs: list, example) -> dict:
    # runs[i].outputs may be None, so handle defensively
    a = (runs[0].outputs or {}).get("city", "")
    b = (runs[1].outputs or {}).get("city", "")
    winner = 0 if len(a) <= len(b) else 1
    return {"key": "shorter_city", "scores": {runs[0].id: 1-winner, runs[1].id: winner}}

# evaluate_comparative requires the exact session name (or UUID).
# Retrieve the full name including the auto hash suffix created by experiment_prefix.
# Also, `experiments` is a positional-only argument, so pass as a tuple, not a kwarg.
sessions = list(client.list_projects(reference_dataset_id=dataset.id))
v1_name = next(s.name for s in sessions if s.name.startswith("city-extractor:gpt-5.4"))
v2_name = next(s.name for s in sessions if s.name.startswith("city-extractor:v2-strict-prompt"))
print(f"Comparison targets: {v1_name}  vs  {v2_name}")

evaluate_comparative(
    (v1_name, v2_name),                # positional-only
    evaluators=[pref_shorter_city],
)

# 3) summary evaluator: Exact-match ratio for the entire dataset
def summary_accuracy(runs: list, examples: list) -> dict:
    total = len(runs)
    if total == 0:
        return {"key": "accuracy", "score": 0.0}
    correct = sum(
        1 for r, e in zip(runs, examples)
        if r.outputs and e.outputs and r.outputs.get("city") == e.outputs.get("city")
    )
    return {"key": "accuracy", "score": correct / total}

evaluate(
    extract_city,
    data=DATASET_NAME,
    evaluators=[city_exact_match],
    summary_evaluators=[summary_accuracy],
    experiment_prefix="city-extractor:with-summary",
)
print("pairwise + summary experiment completed")
`````)

== 6.03.7 Online Evaluator — Automatic Evaluation of Production Traces

Offline experiments are for regression testing before deployment, while during operation, you attach real-time feedback with an _online evaluator_. UI flow:

+ Go to the project -\> _Evaluators_ tab -\> `+ Evaluator`
+ Select _LLM-as-judge_, write the evaluation prompt (e.g., "Does the response answer the user's intent?")
+ Specify a filter — e.g., only runs with `has(tags, "env:prod")`
+ If you set the _Sampling rate_ to 0.1, only 10% of matching traces are evaluated — for cost control
+ Once saved, new traces automatically start getting feedback keys

To retroactively apply to past traces, turn on _Apply to past runs_ and specify the period. The resulting feedback can trigger dashboards/alerts and will be covered again with alert rules in `05_production_monitoring.ipynb`.

\<!-- phase-c:embed --\>
#image("../../assets/images/langsmith/03_datasets_and_evaluation/02_dataset_detail_examples.png")

_Experiments tab of `weather-bot-qa` — Three charts at the top (Feedback scores `city_exact_match`/`city_non_empty`/`semantic_city_match`, Latency P50/P99, Tokens Input/Output) + experiment table at the bottom (#1 `city-extractor:gpt-4.1-mini-...` / #2 `city-extractor:v2-strict-prompt-...`). Each experiment aggregates scores after running 3 runs._

== 6.03.8 Agent Trajectory Evaluation — `agentevals`

For agents, not only the final response but also the _sequence of tool calls_ determines quality. `agentevals` is a LangChain-specific evaluation package that compares the trajectory (message/tool call sequence) to a reference.

The four modes of `create_trajectory_match_evaluator(trajectory_match_mode=...)`:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Meaning],
  [`strict`],
  [Messages, tool call order, and arguments must be exactly the same],
  [`unordered`],
  [The same tools were called (order ignored)],
  [`subset`],
  [Actual is a subset of the reference],
  [`superset`],
  [All tools in the reference were called, extra calls allowed],
)

If there is no reference, `create_trajectory_llm_as_judge` lets the LLM directly evaluate the reasonableness of the trajectory.

#code-block(`````python
# pip install agentevals
from agentevals.trajectory.match import create_trajectory_match_evaluator
from agentevals.trajectory.llm import create_trajectory_llm_as_judge

# The most commonly used mode among the four is unordered — checks if the set of tools called is the same
trajectory_unordered = create_trajectory_match_evaluator(trajectory_match_mode="unordered")

# Message sequence (LangChain BaseMessage list)
outputs = [
    {"role": "user", "content": "Weather in Seoul"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "Seoul"}}]},
    {"role": "tool", "content": "Seoul: Clear, 21°C"},
    {"role": "assistant", "content": "It's clear and 21 degrees in Seoul."},
]
reference_outputs = [
    {"role": "user", "content": "Weather in Seoul"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "Seoul"}}]},
    {"role": "assistant", "content": "..."},
]

verdict = trajectory_unordered(outputs=outputs, reference_outputs=reference_outputs)
print("trajectory match (unordered):", verdict)

# LLM evaluates trajectory reasonableness without a reference
judge = create_trajectory_llm_as_judge(model="openai:gpt-5.4")
print("trajectory llm-as-judge:", judge(outputs=outputs))
`````)

== Checklist

- [ ] Manually create a golden set using `client.create_dataset` + `client.create_examples`
- [ ] Transfer production runs to the dataset using `client.create_examples` (replacing the old `add_runs_to_dataset`)
- [ ] Check the code evaluator signature `(inputs, outputs, reference_outputs) -> {"key","score"}`
- [ ] Structure LLM-as-judge with `with_structured_output`
- [ ] Run experiments with `evaluate(...)` and compare by name in the UI
- [ ] Understand the signature differences between pairwise (`evaluate_comparative`) and summary evaluators
- [ ] Know the four trajectory match modes of `agentevals` (strict/unordered/subset/superset)
- [ ] Attach an online evaluator in the UI to automatically provide feedback on production traces

== Next

- `04_prompt_hub.ipynb` — How to version and deploy prompts used in this experiment with the `prod` tag

== References

- Evaluation concepts: https://docs.langchain.com/langsmith/evaluation-concepts
- All about evaluation: https://docs.langchain.com/langsmith/evaluation
- Evaluate LLM application: https://docs.langchain.com/langsmith/evaluate-llm-application
- Pairwise evaluation: https://docs.langchain.com/langsmith/evaluate-pairwise
- Online evaluators: https://docs.langchain.com/langsmith/online-evaluations
- agentevals: https://github.com/langchain-ai/agentevals
