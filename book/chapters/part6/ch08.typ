// Auto-generated from 08_langgraph_testing.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "LangGraph Testing", subtitle: "state와 checkpoint를 검증하기")

== 학습 목표
#learning-objectives([LangGraph node와 compiled graph를 분리해 테스트합니다.], [state assertion으로 회귀를 잡습니다.], [checkpointer가 필요한 테스트와 필요 없는 테스트를 구분합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from typing_extensions import TypedDict
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import InMemorySaver

class CounterState(TypedDict):
    count: int
`````)

== 8.1 node unit test

node는 순수 함수처럼 입력 state와 출력 update를 검증합니다.

#code-block(`````python
def increment(state: CounterState) -> dict:
    return {"count": state["count"] + 1}

assert increment({"count": 1}) == {"count": 2}
print("node unit test passed")
`````)

== 8.2 graph integration test

compile된 graph는 end-to-end state를 검증합니다.

#code-block(`````python
builder = StateGraph(CounterState)
builder.add_node("increment", increment)
builder.add_edge(START, "increment")
builder.add_edge("increment", END)
graph = builder.compile()

assert graph.invoke({"count": 0})["count"] == 1
`````)

== 8.3 checkpoint smoke

thread_id가 필요한 실행은 config까지 테스트해야 합니다.

#code-block(`````python
checkpointer = InMemorySaver()
graph_with_memory = builder.compile(checkpointer=checkpointer)
config = {"configurable": {"thread_id": "test-1"}}

result = graph_with_memory.invoke({"count": 2}, config=config)
assert result["count"] == 3
`````)

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
  [node unit test, graph integration test, checkpoint smoke],
  [_핵심 개념_],
  [LangGraph 테스트는 state update와 compiled graph behavior를 따로 검증합니다.],
)

#references-box[
- `docs/langgraph/test.md`
- `docs/langgraph/checkpointers.md`
- `docs/langchain/test/unit-testing.md`
]
#chapter-end()
