// Source: 08_langsmith/03_datasets_and_evaluation.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "데이터셋과 평가 루프", subtitle: "Code · LLM-as-judge · Pairwise · Summary · Online")

트레이스는 "지금 어떻게 굴러가는지"를 보여주고, 평가는 "프롬프트·모델·코드를 바꿨을 때 더 좋아졌는지"를 답합니다. LangSmith는 _트레이스를 그대로 데이터셋으로 끌어올리고_, 그 위에 code evaluator · LLM-as-judge · pairwise · summary 평가를 돌립니다. 본 장은 수동 시드 데이터셋부터 프로덕션 trace 이관, 4종 evaluator, `evaluate` 러너, online evaluator까지 평가 파이프라인 전체를 다룹니다.

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

도메인 전문가가 골든 Q&A를 직접 적어 `create_examples`로 넣습니다. `inputs`와 `outputs`는 모두 dict. `outputs`는 reference 정답으로 code evaluator / LLM-as-judge의 비교 대상이 됩니다.

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

수동 작성은 초기 시드에만 쓰고, 실제 규모는 _프로덕션 trace_에서 옵니다. `langsmith 0.7`부터 `add_runs_to_dataset`이 제거되었으므로 `client.create_examples(...)`로 run의 `inputs`/`outputs`를 example로 변환해 넣습니다. 실제 운영에서는 Annotation Queue로 사람이 리뷰한 run만 올리는 게 일반적입니다.

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

예제용으로 "질문에서 도시명을 뽑는" LLM 함수를 대상(target)으로 삼습니다. target은 `inputs: dict → outputs: dict` 형태면 됩니다.

Evaluator는 *`(inputs, outputs, reference_outputs)`*를 받아 `{"key": ..., "score": ...}` dict를 반환합니다. 결정적 휴리스틱은 비용 0, 지연 ~0 ms — 가능한 한 많이 넣는 게 이득입니다.

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

judge_llm = ChatOpenAI(model="gpt-4.1-mini").with_structured_output(Judgement)

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

`from langsmith.evaluation import evaluate`가 표준 러너입니다. `experiment_prefix`에 의미 있는 이름을 주면 UI의 Experiments 뷰에서 바로 비교 가능합니다.

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

== 3.7 Online evaluator — 프로덕션 trace 자동 평가

Offline experiment는 배포 전 회귀 테스트용이고, 운영 중에는 *online evaluator*로 실시간 feedback을 붙입니다. UI 흐름:

+ 프로젝트 → *Evaluators* 탭 → `+ Evaluator`
+ *LLM-as-judge* 선택, 평가 프롬프트 작성 (예: "응답이 사용자의 의도에 답하는가?")
+ 필터 지정 — 예: `has(tags, "env:prod")`인 run만
+ *Sampling rate*를 0.1로 두면 매칭 trace의 10%만 평가 — 비용 제어
+ 저장하면 신규 trace에 자동으로 feedback key가 붙기 시작

과거 trace에도 소급 적용하려면 *Apply to past runs*를 켜고 기간을 지정합니다.

#figure(image("../../../assets/images/langsmith/03_datasets_and_evaluation/02_dataset_detail_examples.png", width: 95%), caption: [Experiment 결과 + evaluator 차트 — Feedback 점수(`city_exact_match`/`city_non_empty`/`semantic_city_match`), Latency P50/P99, Tokens Input/Output 시계열])

== 핵심 정리

- 데이터셋은 수동 시드 + 프로덕션 trace 이관의 조합으로 누적
- Evaluator 4종: Code(결정적, 저비용) / LLM-as-judge(자연어 품질) / Pairwise(A/B 비교) / Summary(데이터셋 수준)
- `evaluate` 러너 + `experiment_prefix`로 experiment 이름을 UI에 노출
- Online evaluator는 프로덕션 trace에 feedback key를 자동 부착, 대시보드·알림의 트리거가 됨
- `prompt_commit` 같은 metadata를 실험에 부착하면 "어떤 버전에서 낸 수치인지" 재현 가능
