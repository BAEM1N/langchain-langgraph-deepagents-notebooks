// Auto-generated from 09_runtime_rubric_evaluation.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Runtime Rubric Evaluation", subtitle: "실행 중 품질 게이트 만들기")

== 학습 목표
#learning-objectives([runtime rubric과 offline eval의 차이를 구분합니다.], [criterion별 feedback을 만들어 revision loop의 입력으로 사용하는 구조를 익힙니다.], [deterministic evaluator로 비용 없는 품질 게이트를 연습합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 9.1 Rubric criteria

Rubric은 최종 답변 직후 확인할 수 있는 명시적 기준이어야 합니다.

#code-block(`````python
criteria = {
    "has_sources": lambda text: "참고" in text,
    "has_tests": lambda text: "검증" in text,
    "has_next_step": lambda text: "다음" in text,
}

list(criteria)
`````)

== 9.2 evaluator

criterion별 실패 사유를 revision prompt로 되돌릴 수 있게 만듭니다.

#code-block(`````python
def grade(text: str) -> dict:
    checks = {name: fn(text) for name, fn in criteria.items()}
    feedback = [name for name, passed in checks.items() if not passed]
    return {"passed": all(checks.values()), "checks": checks, "feedback": feedback}

grade("요약과 다음 단계는 있지만 검증이 없습니다.")
`````)

== 9.3 offline eval과의 관계

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[시점],
  text(weight: "bold")[목적],
  [runtime rubric],
  [응답 직후],
  [self-revision, 필수 섹션 누락 방지],
  [offline eval],
  [batch/CI],
  [regression, model 비교, 장기 품질 추세],
  [smoke test],
  [PR/로컬],
  [실행 오류 탐지],
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
  [rubric criteria, deterministic grader, feedback list],
  [_핵심 개념_],
  [runtime rubric은 모델 품질 평가가 아니라 완료 조건 미충족을 즉시 되돌리는 게이트입니다.],
)

#references-box[
- `docs/deepagents/rubric.md`
- `docs/langchain/test/evals.md`
- `docs/langsmith` 관련 LangSmith 노트북
]
#chapter-end()
