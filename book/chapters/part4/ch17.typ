// Auto-generated from 13_programmatic_subagents.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(17, "Programmatic Subagents", subtitle: "코드로 fan-out/fan-in 설계하기")

== 학습 목표
#learning-objectives([일반 `SubAgent`, `AsyncSubAgent`, programmatic subagents의 차이를 구분합니다.], [현재 환경에서 programmatic 기능을 실행할 수 있는지 dependency gate로 확인합니다.], [기능이 없을 때도 동일한 설계 의도를 deterministic fallback으로 연습합니다.])

#code-block(`````python
from dotenv import load_dotenv
import importlib.util, os

load_dotenv(override=True)
`````)

#code-block(`````python
import deepagents

capabilities = {
    "deepagents_version": getattr(deepagents, "__version__", "unknown"),
    "quickjs_available": importlib.util.find_spec("langchain_quickjs") is not None,
    "SubAgent": hasattr(deepagents, "SubAgent"),
    "AsyncSubAgent": hasattr(deepagents, "AsyncSubAgent"),
}
capabilities
`````)

== 13.1 언제 programmatic subagent가 필요한가

모델이 알아서 `task`를 호출하게 두는 대신, 코드가 작업 목록을 만들고 여러 worker 결과를 모아야 할 때 필요합니다.

#code-block(`````python
tasks = [
    {"name": "coverage", "question": "공식 문서와 로컬 문서의 누락은?"},
    {"name": "tests", "question": "검증은 어떻게 할 것인가?"},
    {"name": "risks", "question": "외부 서비스 위험은?"},
]

[t["name"] for t in tasks]
`````)

== 13.2 deterministic fallback으로 fan-out/fan-in 연습

실제 subagent 실행 대신 worker 함수를 사용해 결과 수집 형태를 고정합니다.

#code-block(`````python
def worker(task: dict) -> dict:
    return {
        "name": task["name"],
        "finding": f"{task['question']} → checklist로 관리",
    }

worker_results = [worker(task) for task in tasks]
worker_results
`````)

== 13.3 fan-in synthesis

여러 worker의 결과는 그대로 출력하지 말고, 최종 의사결정 기준으로 합칩니다.

#code-block(`````python
summary = {
    "total_workers": len(worker_results),
    "findings": [item["finding"] for item in worker_results],
    "next_action": "공식 slug별 action matrix를 구현 체크리스트로 전환",
}

summary
`````)

== 13.4 실제 기능으로 승격할 때

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[조건],
  text(weight: "bold")[확인],
  [dependency],
  [`langchain_quickjs` 또는 공식 요구 extras 설치 여부],
  [fallback],
  [미설치 환경에서 실행 가능한 대체 예제],
  [observability],
  [worker별 trace/tag 분리],
  [reducer],
  [병렬 결과를 덮어쓰지 않고 누적],
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
  [dependency gate, fan-out/fan-in, deterministic fallback],
  [_핵심 개념_],
  [programmatic subagent는 “모델에게 맡기는 위임”이 아니라 “코드가 제어하는 병렬 작업 분해”입니다.],
  [_다음 단계_],
  [`14_event_streaming.ipynb`],
)

#references-box[
- `docs/deepagents/programmatic-subagents.md`
- `docs/deepagents/subagents.md`
- `docs/deepagents/async-subagents.md`
- `docs/langgraph/workflows-agents.md`
]
#chapter-end()
