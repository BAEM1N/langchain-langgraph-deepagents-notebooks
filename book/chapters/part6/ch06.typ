// Auto-generated from 06_agent_evals.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Agent Evals", subtitle: "trajectory match와 LLM-as-judge")

== 학습 목표
#learning-objectives([`agentevals`의 trajectory evaluator가 최종 답변이 아니라 _도구 호출 경로_를 평가하는 방식을 이해한다], [`strict`, `unordered`, `subset`, `superset` match mode를 구분한다], [LLM-as-judge evaluator로 reference trajectory와 실제 trajectory의 의미적 일치 여부를 평가한다], [LangSmith `evaluate()`와 연결해 agent trajectory 회귀 테스트를 남긴다])

== 개요

기존 `03_datasets_and_evaluation.ipynb`가 dataset/evaluate 전체 루프를 다뤘다면, 이 장은 _에이전트 내부 경로_에 집중합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[평가 대상],
  text(weight: "bold")[일반 evaluator],
  text(weight: "bold")[AgentEvals],
  [최종 답변],
  [문자열·JSON 정답 비교],
  [가능하지만 주 목적은 아님],
  [도구 호출],
  [직접 파싱 필요],
  [`tool_calls` 시퀀스 비교],
  [경로 품질],
  [LLM judge 직접 작성],
  [trajectory 전용 prompt 제공],
  [회귀 테스트],
  [LangSmith experiment],
  [LangSmith + trajectory evaluator],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
assert os.environ.get("LANGSMITH_API_KEY"), "LANGSMITH_API_KEY 미설정"
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY 미설정"
os.environ.setdefault("LANGSMITH_PROJECT", "langchain-langgraph-deepagents-notebooks")
`````)

#code-block(`````python
from agentevals.trajectory.match import create_trajectory_match_evaluator
from agentevals.trajectory.llm import create_trajectory_llm_as_judge
`````)

== 1) 평가할 trajectory 만들기

trajectory는 LangChain message처럼 `role`, `content`, `tool_calls`를 가진 dict list로 표현할 수 있습니다. 핵심은 “어떤 도구를 어떤 인자로 호출했는가”입니다.

#code-block(`````python
actual_trajectory = [
    {"role": "user", "content": "서울 날씨 알려줘"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "서울"}}]},
    {"role": "tool", "content": "서울: 맑음, 21°C"},
    {"role": "assistant", "content": "서울은 맑고 21도입니다."},
]
reference_trajectory = [
    {"role": "user", "content": "서울 날씨 알려줘"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather", "args": {"city": "서울"}}]},
]
`````)

== 2) Trajectory match evaluator

`trajectory_match_mode`는 실제 trajectory와 reference의 관계를 정합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[의미],
  [`strict`],
  [순서와 호출이 정확히 같아야 함],
  [`unordered`],
  [같은 호출 집합이면 순서는 덜 중요],
  [`subset`],
  [실제 trajectory가 reference의 일부여야 함],
  [`superset`],
  [reference 호출을 포함하면 추가 호출 허용],
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

== 3) LLM-as-judge trajectory 평가

reference가 너무 추상적이거나, tool 호출 순서보다 “합리적인 경로였는가”가 중요하면 LLM judge를 씁니다. 여기서는 작은 trajectory 한 건만 평가합니다.

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

== 4) LangSmith `evaluate()`와 연결

아래 셀은 실제 LangSmith dataset과 experiment를 만듭니다. 로컬 실행 harness에서는 기본적으로 remote write/evaluate 셀을 건너뛰고, `--allow-langsmith-mutations`를 켰을 때만 실행합니다.

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
    "inputs": {"question": "서울 날씨 알려줘"},
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

== 운영 기준

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기준],
  text(weight: "bold")[권장],
  [_회귀 테스트_],
  [핵심 tool path는 `strict` 또는 `unordered`],
  [_유연한 agent_],
  [보조 호출을 허용하려면 `superset`],
  [_인자 비교_],
  [중요 필드는 `subset`, 전체 계약은 `exact`],
  [_reference 없음_],
  [LLM-as-judge로 합리성 평가],
  [_프로덕션 연결_],
  [LangSmith dataset + experiment prefix + 모델 metadata],
)


#references-box[
- LangChain Agent Evals: https://docs.langchain.com/oss/python/langchain/test/evals
- LangSmith Evaluation: https://docs.langchain.com/langsmith/evaluation
- AgentEvals GitHub: https://github.com/langchain-ai/agentevals
]
#chapter-end()
