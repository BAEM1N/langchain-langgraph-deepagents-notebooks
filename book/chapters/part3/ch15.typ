// Auto-generated from 15_backward_compatibility.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(15, "Backward Compatibility", subtitle: "LangGraph 버전 변화에 안전하게 대응하기")

== 학습 목표
#learning-objectives([LangGraph API 변경을 노트북 코드에 안전하게 반영하는 방법을 익힙니다.], [runtime feature detection과 compatibility checklist를 만듭니다.], [migration note를 테스트와 함께 관리하는 방식을 확인합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
import inspect
from langgraph.graph import StateGraph
from langgraph.types import RetryPolicy

features = {
    "add_node_retry_policy": "retry_policy" in inspect.signature(StateGraph.add_node).parameters,
    "retry_policy_class": RetryPolicy.__name__,
}
features
`````)

== 15.1 호환성은 import 성공만으로 판단하지 않습니다

API가 존재해도 parameter, return type, behavior가 바뀔 수 있으므로 signature와 smoke test를 함께 봅니다.

#code-block(`````python
def require_feature(name: str, ok: bool) -> str:
    if not ok:
        return f"SKIP: {name} is not available"
    return f"OK: {name}"

require_feature("add_node.retry_policy", features["add_node_retry_policy"])
`````)

== 15.2 migration checklist

버전 업데이트 PR에는 코드 변경보다 먼저 이 체크리스트를 붙입니다.

#code-block(`````python
migration_checklist = [
    "공식 changelog 확인",
    "기존 notebook smoke 실행",
    "deprecated import 검색",
    "새 API 예제 1개 추가",
]

for item in migration_checklist:
    print("-", item)
`````)

== 15.3 compatibility matrix

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[영역],
  text(weight: "bold")[확인 방법],
  [import path],
  [`python -c` 또는 notebook smoke],
  [graph compile],
  [최소 StateGraph compile],
  [persistence],
  [checkpointer thread_id smoke],
  [streaming],
  [event/stream mode smoke],
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
  [feature detection, migration checklist, compatibility matrix],
  [_핵심 개념_],
  [버전 호환성은 문서 확인 + 작은 smoke test + migration note로 관리합니다.],
)

#references-box[
- `docs/langgraph/backward-compatibility.md`
- `docs/langgraph/changelog-py.md`
- `docs/langgraph/fault-tolerance.md`
]
#chapter-end()
