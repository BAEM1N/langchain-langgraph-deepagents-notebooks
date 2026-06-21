// Auto-generated from 12_router_knowledge_base.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "Router Knowledge Base", subtitle: "질문을 알맞은 지식원으로 보내기")

== 학습 목표
#learning-objectives([router와 handoff/subagent의 차이를 구분합니다.], [여러 지식원을 source별 retriever처럼 다루는 구조를 만듭니다.], [라우팅 결과를 간단한 테스트 케이스로 검증합니다.])

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

== 12.1 지식원 정의

지식원이 많아질수록 하나의 retriever보다 먼저 source를 고르는 router가 유용합니다.

#code-block(`````python
knowledge_sources = {
    "billing": ["환불은 결제일로부터 7일 이내 가능합니다."],
    "technical": ["오류 신고에는 로그와 재현 단계가 필요합니다."],
    "product": ["Deep Agents는 planning, files, subagents를 포함합니다."],
}

list(knowledge_sources)
`````)

== 12.2 deterministic router

실제 서비스에서는 structured output router를 쓰되, 먼저 규칙 기반 router로 테스트 모양을 고정합니다.

#code-block(`````python
def route_source(question: str) -> str:
    q = question.lower()
    if "환불" in q or "refund" in q:
        return "billing"
    if "오류" in q or "error" in q:
        return "technical"
    return "product"

route_source("Deep Agents 기능은?")
`````)

== 12.3 source-local search

라우터가 고른 source 안에서만 검색하면 context가 작아지고 근거 관리가 쉬워집니다.

#code-block(`````python
def retrieve(question: str) -> dict:
    source = route_source(question)
    docs = knowledge_sources[source]
    return {"source": source, "documents": docs}

retrieve("환불 조건 알려줘")
`````)

== 12.4 라우터 평가

라우터는 답변 품질과 별도로 source 선택 정확도를 평가합니다.

#code-block(`````python
cases = [
    ("환불 가능한가요?", "billing"),
    ("앱 오류가 납니다", "technical"),
    ("Deep Agents가 뭐예요?", "product"),
]

for question, expected in cases:
    actual = route_source(question)
    print(question, actual, actual == expected)
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
  [router, source-local retrieval, routing eval],
  [_핵심 개념_],
  [Router는 답변을 생성하기 전에 “어디에서 찾을지”를 결정하는 계층입니다.],
  [_다음 단계_],
  [`13_skills_sql_assistant.ipynb` 후보],
)

#references-box[
- `docs/langchain/multi-agent/router.md`
- `docs/langchain/multi-agent/router-knowledge-base.md`
- `docs/langchain/structured-output.md`
]
#chapter-end()
