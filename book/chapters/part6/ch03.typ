// Source: 06_langsmith/03_datasets_and_evaluation.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "데이터셋과 평가 루프", subtitle: "Code · LLM-as-judge · Pairwise · Summary · Online")

트레이스는 "지금 어떻게 굴러가는지"를 보여주고, 평가는 "프롬프트·모델·코드를 바꿨을 때 더 좋아졌는지"를 답합니다. LangSmith는 _트레이스를 그대로 데이터셋으로 끌어올려_ code evaluator · LLM-as-judge · pairwise · summary 평가를 돌립니다. 수동 시드 데이터셋부터 프로덕션 trace 이관, 4종 evaluator, `evaluate` 러너, online evaluator까지 평가 파이프라인 전체를 다룹니다.

#learning-header()
#learning-objectives(
  [`client.create_dataset` + `client.create_examples`로 데이터셋과 예시를 만든다],
  [프로덕션 trace를 `client.create_examples(dataset_id=..., examples=[...])`로 데이터셋에 이관한다],
  [Code evaluator를 `(inputs, outputs, reference_outputs) → dict` 형식으로 작성한다],
  [LLM-as-judge evaluator를 구조적 score로 돌린다],
  [Pairwise / summary evaluator로 두 실험 비교와 데이터셋 수준 지표를 낸다],
  [`from langsmith.evaluation import evaluate` 러너로 experiment를 실행한다],
  [프로덕션 trace에 *online evaluator*를 자동 적용한다],
)

== 3.1 Dataset 생성 — 수동 예시 추가

도메인 전문가가 골든 Q&A를 직접 적어 `create_examples`로 넣습니다. `inputs`와 `outputs`는 모두 dict입니다. `outputs`는 reference 정답으로 code evaluator / LLM-as-judge의 비교 대상이 됩니다.

#code-block(`````python
from langsmith import Client

client = Client()
dataset = client.create_dataset(
    "weather-bot-qa",
    description="도시 추출 골든 예시",
)

client.create_examples(
    dataset_id=dataset.id,
    inputs=[
        {"question": "서울 날씨 알려줘"},
        {"question": "부산시 기온은?"},
        {"question": "대전 주말에 비와?"},
    ],
    outputs=[
        {"city": "서울"},
        {"city": "부산"},
        {"city": "대전"},
    ],
)
`````)

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/01_datasets_list.png", width: 95%), caption: [Datasets & Experiments 리스트 — `weather-bot-qa`와 `agent-golden-traces` 두 dataset])

== 3.2 프로덕션 trace를 데이터셋으로 이관

수동 작성은 초기 시드에만 쓰고, 규모 있는 데이터는 _프로덕션 trace_에서 옵니다. `langsmith 0.7`부터 `add_runs_to_dataset`이 제거됐으므로 `client.create_examples(...)`로 run의 `inputs`/`outputs`를 example로 변환해 넣습니다. 운영에서는 Annotation Queue로 사람이 리뷰한 run만 올리는 게 보통입니다.

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

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/03_dataset_examples_tab.png", width: 95%), caption: [Dataset Examples 탭 — 한국어 질문 Inputs와 기대 도시명 Reference Outputs. JSON/YAML 토글, Splits 컬럼 제공])

== 3.3 평가 대상 + Code evaluator

예제용으로 "질문에서 도시명을 뽑는" LLM 함수를 대상(target)으로 씁니다. target은 `inputs: dict → outputs: dict` 형태면 됩니다.

Evaluator는 *`(inputs, outputs, reference_outputs)`*를 받아 `{"key": ..., "score": ...}` dict를 돌려줍니다. 결정적 휴리스틱은 비용 0, 지연 ~0 ms — 가능한 한 많이 넣는 게 이득입니다.

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

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/04_dataset_evaluators_tab.png", width: 95%), caption: [Evaluator 템플릿 갤러리 — PII Leakage · Prompt Injection · Toxicity · Bias & Fairness · Hallucination · Correctness · Perceived Error · User Satisfaction + 직접 작성])

== 3.4 LLM-as-judge evaluator

정답 문자열이 없거나 자연어 품질(톤·정확성·도움됨)을 재야 할 때 씁니다. 같은 LLM을 호출하지만 _출력을 구조화된 score로 강제_하는 것이 핵심입니다.

#code-block(`````python
from pydantic import BaseModel
from langchain_openai import ChatOpenAI

class Judgement(BaseModel):
    score: float   # 0.0 ~ 1.0
    reason: str

judge_llm = ChatOpenAI(model="gpt-5.4").with_structured_output(Judgement)

def semantic_city_match(inputs, outputs, reference_outputs):
    j = judge_llm.invoke(
        f"질문: {inputs['question']}\n"
        f"정답 도시: {reference_outputs['city']}\n"
        f"추출: {outputs['city']}\n"
        "0.0~1.0 score + reason",
    )
    return {"key": "semantic_city_match", "score": j.score, "comment": j.reason}
`````)

== 3.5 `evaluate` 러너 + experiment 이름

표준 러너는 두 가지 import 경로 모두 동일하게 동작합니다 — 새 코드는 짧은 쪽인 `from langsmith import evaluate`를 권장합니다. `Client` 인스턴스가 있다면 `client.evaluate(...)`로도 동일하게 호출할 수 있습니다. `experiment_prefix`에 의미 있는 이름을 주면 UI Experiments 뷰에서 바로 비교됩니다.

#code-block(`````python
from langsmith import Client, evaluate     # 권장 (langsmith ≥ 0.3)
# from langsmith.evaluation import evaluate  # 구 경로, 여전히 호환

result = evaluate(
    target=city_extractor,
    data="weather-bot-qa",
    evaluators=[city_exact_match, city_non_empty, semantic_city_match],
    experiment_prefix="city-extractor:gpt-5.4",
    metadata={"prompt_commit": "12344e88"},
)

# Client.evaluate(...) 도 동일 시그니처
client = Client()
result = client.evaluate(
    city_extractor,
    data="weather-bot-qa",
    evaluators=[city_exact_match],
)
`````)

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/05_pairwise_experiments_tab.png", width: 95%), caption: [Pairwise Experiments 탭 — 두 experiment의 output을 나란히 비교. `evaluate_comparative` API로 실행])

== 3.6 Pairwise + Summary evaluator

- *Pairwise*: 두 experiment의 같은 example 출력을 놓고 "어느 쪽이 더 나은가"를 뽑습니다. A/B 프롬프트 실험에 씁니다. `evaluate_comparative` 러너
- *Summary*: 데이터셋 전체 수준의 지표(예: 정확도 매크로 평균). 시그니처가 run/example의 _리스트_를 받도록 다릅니다

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

== 3.7 `agentevals` — 에이전트 trajectory 평가

도시 추출처럼 _최종 출력만_ 보는 평가는 단순 string 비교로 충분하지만, 에이전트는 _도구를 어떤 순서로 호출했는가_가 같이 중요합니다. `agentevals` 패키지(`pip install agentevals`)는 LangChain의 메시지 트레이스를 기준으로 reference trajectory와 실제 trajectory를 비교하는 평가기를 제공합니다.

비교 모드는 네 가지입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[일치 기준],
  text(weight: "bold")[언제 쓰나],
  [`strict`],
  [도구 이름·순서·인자까지 모두 일치],
  [고정된 워크플로우의 회귀 테스트],
  [`unordered`],
  [도구 집합 일치, 호출 순서는 무관],
  [parallel tool use, 순서가 중요하지 않은 파이프라인],
  [`subset`],
  [실제 trajectory ⊆ reference (allowed actions)],
  [에이전트가 _기대보다 적게_ 부른 경우만 허용],
  [`superset`],
  [reference ⊆ 실제 trajectory (required actions)],
  [에이전트가 _반드시_ 부르길 원하는 도구가 있을 때],
)

#code-block(`````python
from agentevals.trajectory.match import create_trajectory_match_evaluator

trajectory_strict = create_trajectory_match_evaluator(
    trajectory_match_mode="strict",
)

# evaluators 인자에 그대로 넘기면 LangSmith experiment의 점수로 합산
evaluate(
    target=run_agent,
    data="agent-golden-trajectories",
    evaluators=[trajectory_strict],
    experiment_prefix="agent:trajectory-strict",
)
`````)

LLM-as-judge로 trajectory를 자유 형식으로 평가하려면 `create_trajectory_llm_as_judge`를 씁니다. 도구 이름 비교가 아니라 _전체 reasoning chain의 적절성_을 LLM이 판단하게 만듭니다.

#code-block(`````python
from agentevals.trajectory.llm import create_trajectory_llm_as_judge

trajectory_judge = create_trajectory_llm_as_judge(
    model="openai:gpt-5.4",
    prompt="에이전트의 도구 호출 순서가 사용자의 의도를 효율적으로 달성했는가?",
)
`````)

#tip-box[
  `agentevals`는 `openevals`(범용 LLM 평가)와 한 쌍입니다. _최종 답변 품질_은 `openevals`, _과정의 적절성_은 `agentevals`로 분리해 두 점수를 같은 experiment에 함께 붙이는 것이 권장 패턴입니다.
]

== 3.8 Online evaluator — 프로덕션 trace 자동 평가

Offline experiment는 배포 전 회귀 테스트에 쓰고, 운영 중에는 *online evaluator*로 실시간 feedback을 붙입니다. UI 흐름:

+ 프로젝트 → *Evaluators* 탭 → `+ Evaluator`
+ *LLM-as-judge* 선택, 평가 프롬프트 작성 (예: "응답이 사용자의 의도에 답하는가?")
+ 필터 지정 — 예: `has(tags, "env:prod")`인 run만
+ *Sampling rate*를 0.1로 두면 매칭 trace의 10%만 평가 — 비용 제어
+ 저장하면 신규 trace에 자동으로 feedback key가 붙기 시작

과거 trace에도 소급하려면 *Apply to past runs*를 켜고 기간을 지정합니다.

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/02_dataset_detail_examples.png", width: 95%), caption: [Experiment 결과 + evaluator 차트 — Feedback 점수(`city_exact_match`/`city_non_empty`/`semantic_city_match`), Latency P50/P99, Tokens Input/Output 시계열])

== 핵심 정리

- 데이터셋은 수동 시드 + 프로덕션 trace 이관의 조합으로 누적
- Evaluator 4종: Code(결정적, 저비용) / LLM-as-judge(자연어 품질) / Pairwise(A/B 비교) / Summary(데이터셋 수준)
- `from langsmith import evaluate` 또는 `Client.evaluate(...)` 둘 다 동일한 시그니처
- `agentevals`의 trajectory match 4 모드(strict/unordered/subset/superset) + LLM-as-judge로 _과정의 적절성_ 평가
- Online evaluator는 프로덕션 trace에 feedback key를 자동 부착, 대시보드·알림의 트리거가 됨
- `prompt_commit` 같은 metadata를 실험에 붙이면 "어떤 버전에서 낸 수치인지" 재현됩니다
