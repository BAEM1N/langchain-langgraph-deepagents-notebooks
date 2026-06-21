// Auto-generated from 16_quality_profiles_rubric.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(20, "Quality Profiles and Rubrics", subtitle: "모델별 설정과 완료 기준")

== 학습 목표
#learning-objectives([Harness profile과 rubric의 역할을 구분합니다.], [모델/provider별 설정을 profile 형태로 관리하는 이유를 이해합니다.], [LLM judge 없이도 rubric evaluator의 구조를 연습합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from deepagents import HarnessProfile, register_harness_profile

profile = HarnessProfile(system_prompt_suffix="Respond with concise Korean bullets.")
register_harness_profile("course:demo", profile)

type(profile).__name__
`````)

== 16.1 Rubric은 완료 기준입니다

Rubric은 “좋아 보이는 답변”이 아니라 산출물이 반드시 만족해야 할 criterion 목록입니다.

#code-block(`````python
rubric = [
    {"name": "has_summary", "check": lambda text: "요약" in text},
    {"name": "has_next_step", "check": lambda text: "다음" in text},
]

rubric[0]["name"]
`````)

== 16.2 deterministic rubric evaluator

실제 `RubricMiddleware` 적용 전에도 criterion별 실패를 보여줄 수 있습니다.

#code-block(`````python
def evaluate(text: str) -> dict:
    results = {item["name"]: item["check"](text) for item in rubric}
    return {"passed": all(results.values()), "criteria": results}

evaluate("요약: 완료. 다음: 테스트 실행")
`````)

== 16.3 Profile과 Rubric의 경계

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[역할],
  [profile],
  [모델/provider별 harness 기본값],
  [rubric],
  [결과물이 만족해야 할 품질 기준],
  [eval],
  [batch/offline 회귀 평가],
  [middleware],
  [runtime self-revision loop],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_다룬 기술_],
  [`HarnessProfile`, rubric criteria, deterministic evaluator],
  [_핵심 개념_],
  [profile은 실행 환경, rubric은 완료 기준을 관리합니다.],
)

#references-box[
- `docs/deepagents/profiles.md`
- `docs/deepagents/rubric.md`
- `docs/langchain/test/evals.md`
]
#chapter-end()
