// Auto-generated from 06_agent_evals.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Agent Evals", subtitle: "trajectory match and LLM-as-judge")

== Learning goals

- Understand how `agentevals` evaluates an agent's _tool-call path_, not just final text
- Distinguish `strict`, `unordered`, `subset`, and `superset` match modes
- Use an LLM-as-judge evaluator to compare actual and reference trajectories semantically
- Connect trajectory evaluators to LangSmith `evaluate()` for regression testing

== Overview

`03_datasets_and_evaluation.ipynb` covers the broad dataset/evaluate loop. This chapter focuses on _the agent's internal path_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Target],
  text(weight: "bold")[Generic evaluator],
  text(weight: "bold")[AgentEvals],
  [Final answer],
  [String/JSON comparison],
  [Possible, but not the main point],
  [Tool calls],
  [Manual parsing],
  [Built-in `tool_calls` trajectory comparison],
  [Path quality],
  [Custom LLM judge prompt],
  [Trajectory-specific judge prompt],
  [Regression tests],
  [LangSmith experiment],
  [LangSmith + trajectory evaluator],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
assert os.environ.get("LANGSMITH_API_KEY"), "Set LANGSMITH_API_KEY in .env"
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"
os.environ.setdefault("LANGSMITH_PROJECT", "langchain-langgraph-deepagents-notebooks")
`````)

#code-block(`````python
from agentevals.trajectory.match import create_trajectory_match_evaluator
from agentevals.trajectory.llm import create_trajectory_llm_as_judge
`````)

== 1) Build trajectories to evaluate

A trajectory can be represented as a list of message-like dictionaries with `role`, `content`, and `tool_calls`. The important question is: which tool did the agent call, and with which arguments?

#code-block(`````python
actual_trajectory = [
    {"role": "user", "content": "Weather in Seoul?"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "Seoul"}}]},
    {"role": "tool", "content": "Seoul: sunny, 21°C"},
    {"role": "assistant", "content": "It is sunny and 21°C in Seoul."},
]
reference_trajectory = [
    {"role": "user", "content": "Weather in Seoul?"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "Seoul"}}]},
]
`````)

== 2) Trajectory match evaluator

`trajectory_match_mode` defines the relationship between the actual and reference trajectories.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Meaning],
  [`strict`],
  [Order and calls must match exactly],
  [`unordered`],
  [The same call set matters more than order],
  [`subset`],
  [Actual trajectory must be a subset of the reference],
  [`superset`],
  [Actual trajectory may include extra calls if it includes the reference],
)

#code-block(`````python
trajectory_superset = create_trajectory_match_evaluator(
    trajectory_match_mode="superset",
    tool_args_match_mode="subset",
)
match_result = trajectory_superset(
    outputs=actual_trajectory,
    reference_outputs=reference_trajectory,
)
print(match_result)
assert match_result["score"] is True
`````)

== 3) LLM-as-judge trajectory evaluation

Use an LLM judge when the reference is abstract or when the question is whether the path was reasonable rather than whether every call was byte-for-byte identical.

#code-block(`````python
trajectory_judge = create_trajectory_llm_as_judge(
    model="openai:gpt-5.4",
    use_reasoning=False,
)
judge_result = trajectory_judge(
    outputs=actual_trajectory,
    reference_outputs=reference_trajectory,
)
print(judge_result)
`````)

== 4) Connect to LangSmith `evaluate()`

The next cell creates a real LangSmith dataset and experiment. The local harness skips remote write/evaluate cells by default, and runs them only when `--allow-langsmith-mutations` is set.

#code-block(`````python
from langsmith import Client
from langsmith.evaluation import evaluate

client = Client()
DATASET_NAME = "agent-eval-v1"
try:
    dataset = client.create_dataset(
        dataset_name=DATASET_NAME,
        description="Agent trajectory regression examples",
    )
except Exception:
    dataset = client.read_dataset(dataset_name=DATASET_NAME)
client.create_examples(dataset_id=dataset.id, examples=[{
    "inputs": {"question": "Weather in Seoul?"},
    "outputs": {"trajectory": reference_trajectory},
}])

def predict_agent_trajectory(inputs: dict) -> dict:
    return {"trajectory": actual_trajectory}

def trajectory_evaluator(inputs, outputs, reference_outputs):
    return trajectory_superset(
        outputs=outputs["trajectory"],
        reference_outputs=reference_outputs["trajectory"],
    )

results = evaluate(
    predict_agent_trajectory,
    data=DATASET_NAME,
    evaluators=[trajectory_evaluator],
    experiment_prefix="agent-eval-v1:gpt-5.4",
    metadata={"model": "gpt-5.4", "kind": "trajectory"},
)
print("Experiment:", results)
`````)

== Operations checklist

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Criterion],
  text(weight: "bold")[Recommendation],
  [_Regression test_],
  [Use `strict` or `unordered` for critical tool paths],
  [_Flexible agent_],
  [Use `superset` when extra helper calls are acceptable],
  [_Argument comparison_],
  [Use `subset` for required fields, `exact` for full contracts],
  [_No reference_],
  [Use LLM-as-judge for path reasonableness],
  [_Production linkage_],
  [Use LangSmith dataset + experiment prefix + model metadata],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- LangChain Agent Evals: https://docs.langchain.com/oss/python/langchain/test/evals
- LangSmith Evaluation: https://docs.langchain.com/langsmith/evaluation
- AgentEvals GitHub: https://github.com/langchain-ai/agentevals
