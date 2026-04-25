// Source: 06_langsmith/03_datasets_and_evaluation.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Datasets and the Evaluation Loop", subtitle: "Code · LLM-as-judge · Pairwise · Summary · Online")

Traces show "how the system is running right now"; evaluation answers "did it get better when you changed the prompt, model, or code". LangSmith lifts traces directly into datasets and runs code evaluators · LLM-as-judge · pairwise · summary evaluations on top. This chapter covers the full evaluation pipeline: manual seed datasets, ingestion from production traces, the four evaluator types, the `evaluate` runner, and online evaluators.

#learning-header()
#learning-objectives(
  [Create a dataset and examples with `client.create_dataset` + `client.create_examples`],
  [Ingest production traces into a dataset with `client.create_examples(dataset_id=..., examples=[...])`],
  [Write a code evaluator with the `(inputs, outputs, reference_outputs) → dict` signature],
  [Run an LLM-as-judge evaluator that produces a structured score],
  [Use pairwise / summary evaluators for A/B comparison and dataset-level metrics],
  [Kick off experiments with the `from langsmith.evaluation import evaluate` runner],
  [Auto-apply *online evaluators* to production traces],
)

== 3.1 Creating a dataset — manual examples

A domain expert writes golden Q&A by hand and pushes them in with `create_examples`. Both `inputs` and `outputs` are dicts. `outputs` is the reference answer for code evaluators and LLM-as-judge comparisons.

#code-block(`````python
from langsmith import Client

client = Client()
dataset = client.create_dataset(
    "weather-bot-qa",
    description="Golden examples for city extraction",
)

client.create_examples(
    dataset_id=dataset.id,
    inputs=[
        {"question": "What's the weather in Seoul?"},
        {"question": "Temperature in Busan City?"},
        {"question": "Will it rain in Daejeon this weekend?"},
    ],
    outputs=[
        {"city": "Seoul"},
        {"city": "Busan"},
        {"city": "Daejeon"},
    ],
)
`````)

#figure(image("../../../../assets/images/langsmith/03_datasets_and_evaluation/01_datasets_list.png", width: 95%), caption: [Datasets & Experiments list — the two datasets `weather-bot-qa` and `agent-golden-traces`])

== 3.2 Ingesting production traces into a dataset

Manual authoring only seeds the initial set; real volume comes from _production traces_. `add_runs_to_dataset` was removed in `langsmith 0.7`, so use `client.create_examples(...)` to convert each run's `inputs`/`outputs` into examples. In practice you usually push only runs that a human has approved via the Annotation Queue.

#code-block(`````python
good_runs = [r for r in client.list_runs(project_name="prod") if is_good(r)]
client.create_examples(
    dataset_id=client.read_dataset(dataset_name="weather-bot-qa").id,
    examples=[
        {"inputs": r.inputs,
         "outputs": r.outputs,
         "metadata": {"source_run_id": str(r.id)}}
        for r in good_runs if r.outputs
    ],
)
`````)

#figure(image("../../../../assets/images/langsmith/03_datasets_and_evaluation/03_dataset_examples_tab.png", width: 95%), caption: [Dataset Examples tab — Korean question Inputs and expected city-name Reference Outputs with a JSON/YAML toggle and a Splits column])

== 3.3 Evaluation target + code evaluator

For the example, we take an LLM function that "extracts a city from the question" as the target. A target only needs the signature `inputs: dict → outputs: dict`.

An evaluator takes *`(inputs, outputs, reference_outputs)`* and returns a `{"key": ..., "score": ...}` dict. Deterministic heuristics cost zero and add nearly zero latency — add as many as you can.

#code-block(`````python
def city_exact_match(inputs, outputs, reference_outputs):
    return {
        "key": "city_exact_match",
        "score": int(outputs["city"] == reference_outputs["city"]),
    }

def city_non_empty(inputs, outputs, reference_outputs):
    return {
        "key": "city_non_empty",
        "score": int(bool(outputs.get("city"))),
    }
`````)

#figure(image("../../../../assets/images/langsmith/03_datasets_and_evaluation/04_dataset_evaluators_tab.png", width: 95%), caption: [Evaluator template gallery — PII Leakage · Prompt Injection · Toxicity · Bias & Fairness · Hallucination · Correctness · Perceived Error · User Satisfaction + custom-written])

== 3.4 LLM-as-judge evaluator

Use an LLM judge when there is no reference string, or when you need to grade natural-language quality (tone · accuracy · helpfulness). The key is to call the same LLM but _force structured output_.

#code-block(`````python
from pydantic import BaseModel
from langchain_openai import ChatOpenAI

class Judgement(BaseModel):
    score: float   # 0.0 ~ 1.0
    reason: str

judge_llm = ChatOpenAI(model="gpt-4.1-mini").with_structured_output(Judgement)

def semantic_city_match(inputs, outputs, reference_outputs):
    j = judge_llm.invoke(
        f"Question: {inputs['question']}\n"
        f"Reference city: {reference_outputs['city']}\n"
        f"Extracted: {outputs['city']}\n"
        "Score 0.0–1.0 + reason",
    )
    return {"key": "semantic_city_match", "score": j.score, "comment": j.reason}
`````)

== 3.5 The `evaluate` runner + experiment name

`from langsmith.evaluation import evaluate` is the standard runner. Give a meaningful `experiment_prefix` and it shows up directly in the UI's Experiments view for comparison.

#code-block(`````python
from langsmith.evaluation import evaluate

result = evaluate(
    target=city_extractor,
    data="weather-bot-qa",
    evaluators=[city_exact_match, city_non_empty, semantic_city_match],
    experiment_prefix="city-extractor:gpt-4.1-mini",
    metadata={"prompt_commit": "12344e88"},
)
`````)

#figure(image("../../../../assets/images/langsmith/03_datasets_and_evaluation/05_pairwise_experiments_tab.png", width: 95%), caption: [Pairwise Experiments tab — outputs of two experiments compared side by side. Run via the `evaluate_comparative` API])

== 3.6 Pairwise + Summary evaluators

- *Pairwise*: Given the same example, picks "which experiment output is better". Use for A/B prompt experiments. Runner: `evaluate_comparative`.
- *Summary*: Dataset-level metrics (for example, macro-average accuracy). The signature differs — it takes _lists_ of runs and examples.

#code-block(`````python
def macro_accuracy(runs, examples):
    correct = sum(
        r.outputs.get("city") == e.outputs["city"]
        for r, e in zip(runs, examples)
    )
    return {"key": "macro_accuracy", "score": correct / len(runs)}

evaluate(
    target=city_extractor,
    data="weather-bot-qa",
    evaluators=[city_exact_match],
    summary_evaluators=[macro_accuracy],
)
`````)

== 3.7 Online evaluator — automatic evaluation on production traces

Offline experiments are for pre-deploy regression testing; in production you attach *online evaluators* to emit real-time feedback. UI flow:

+ Project → *Evaluators* tab → `+ Evaluator`
+ Select *LLM-as-judge* and write the evaluation prompt (e.g., "does the response answer the user's intent?")
+ Specify a filter — e.g., only runs matching `has(tags, "env:prod")`
+ Setting a *Sampling rate* of 0.1 evaluates 10% of matching traces — cost control
+ On save, feedback keys start attaching to new traces automatically

To apply retroactively, turn on *Apply to past runs* and specify the time range.

#figure(image("../../../../assets/images/langsmith/03_datasets_and_evaluation/02_dataset_detail_examples.png", width: 95%), caption: [Experiment results + evaluator charts — feedback scores (`city_exact_match`/`city_non_empty`/`semantic_city_match`), latency P50/P99, and Input/Output token time series])

== Key Takeaways

- Accumulate datasets as a mix of manual seeds and production-trace ingestion
- Four evaluator types: Code (deterministic, low-cost) / LLM-as-judge (natural-language quality) / Pairwise (A/B comparison) / Summary (dataset level)
- `evaluate` runner + `experiment_prefix` makes experiment names visible in the UI
- Online evaluators attach feedback keys automatically — they become triggers for dashboards and alerts
- Attaching metadata such as `prompt_commit` to an experiment makes "which version produced this number" reproducible
