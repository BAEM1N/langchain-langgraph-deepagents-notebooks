// Auto-generated from 07_testing_strategy.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "Testing Strategy", subtitle: "unit, integration, eval을 분리하기")

== 학습 목표
#learning-objectives([Agent 테스트를 _unit_, _integration_, _eval_로 분리합니다.], [외부 API 없이 deterministic unit test를 작성합니다.], [Agent Evals와 smoke test가 맡는 역할을 구분합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain_core.language_models.fake_chat_models import FakeListChatModel
from langchain_core.messages import HumanMessage

model = FakeListChatModel(responses=["테스트 응답"])
model.invoke([HumanMessage(content="ping")]).content
`````)

== 7.1 테스트 피라미드

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[층],
  text(weight: "bold")[목적],
  text(weight: "bold")[외부 서비스],
  [unit],
  [함수, prompt, parser, graph node],
  [없음],
  [integration],
  [provider, DB, retriever, server 연결],
  [opt-in],
  [eval],
  [trajectory/품질/회귀 평가],
  [선택적 LLM judge],
)

== 7.2 Unit test: 순수 함수부터 고정

LLM 호출 전에 입력 정규화, tool routing, state update 같은 작은 단위를 먼저 고정합니다.

#code-block(`````python
def normalize_question(text: str) -> str:
    return " ".join(text.strip().lower().split())

assert normalize_question("  Hello   Agent  ") == "hello agent"
print("unit test passed")
`````)

== 7.3 Integration gate

외부 서비스 테스트는 키가 있을 때만 실행합니다. 기본 smoke에서 실패하면 안 됩니다.

#code-block(`````python
def can_run_openai_integration() -> bool:
    return bool(os.getenv("OPENAI_API_KEY")) and os.getenv("RUN_LIVE_TESTS") == "1"

print("run live integration:", can_run_openai_integration())
`````)

== 7.4 Eval은 “정답 문자열”보다 경로를 본다

Agent는 같은 답을 여러 문장으로 말할 수 있으므로, tool trajectory와 rubric을 함께 봅니다.

#code-block(`````python
trajectory = [
    {"role": "user", "content": "서울 날씨"},
    {"role": "assistant", "tool_calls": [{"name": "get_weather"}]},
    {"role": "tool", "name": "get_weather", "content": "맑음"},
]

assert trajectory[1]["tool_calls"][0]["name"] == "get_weather"
`````)

== 7.5 CI/수동 검증 분리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[검증],
  text(weight: "bold")[기본 CI],
  text(weight: "bold")[수동 opt-in],
  [notebook JSON/cell ID],
  [yes],
  [yes],
  [deterministic unit cells],
  [yes],
  [yes],
  [provider integration],
  [no],
  [`RUN_LIVE_TESTS=1`],
  [LangSmith mutation],
  [no],
  [`--allow-langsmith-mutations`],
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
  [fake chat model, unit assertion, integration gate, trajectory check],
  [_핵심 개념_],
  [테스트 실패 원인을 작게 만들려면 unit/integration/eval을 섞지 않아야 합니다.],
  [_다음 단계_],
  [`06_agent_evals.ipynb`, `08_langgraph_testing.ipynb` 후보],
)

#references-box[
- `docs/langchain/test/index.md`
- `docs/langchain/test/unit-testing.md`
- `docs/langchain/test/integration-testing.md`
- `docs/langchain/test/evals.md`
- `docs/langgraph/test.md`
]
#chapter-end()
