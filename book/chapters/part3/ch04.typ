// Auto-generated from 04_workflows.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "워크플로 패턴", subtitle: "5가지 핵심 패턴")

== 학습 목표
Prompt Chaining, Parallelization, Routing, Orchestrator-Worker, Evaluator-Optimizer 패턴을 이해합니다.

== 4.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

== 4.2 Prompt Chaining — 순차적 LLM 호출

- 각 단계의 출력이 다음 단계의 입력이 됨
- 용도: 번역 → 검증 → 교정, 분석 → 요약 → 포맷팅

== 4.3 Parallelization — 독립적 태스크의 동시 실행

== 4.4 Routing — 분류 기반 분기

#image("../../assets/images/conditional_routing.png")

== 4.5 Orchestrator-Worker — Send()로 동적 워커 생성

#image("../../assets/images/orchestrator_worker.png")

== 4.6 Evaluator-Optimizer — 생성-평가 반복 루프

== 4.7 패턴 비교표

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[결정적],
  text(weight: "bold")[병렬],
  text(weight: "bold")[반복],
  text(weight: "bold")[적합 상황],
  [Prompt Chaining],
  [O],
  [X],
  [순차],
  [단계별 변환],
  [Parallelization],
  [O],
  [O],
  [X],
  [독립 분석],
  [Routing],
  [O],
  [X],
  [X],
  [분류 기반 처리],
  [Orchestrator-Worker],
  [O],
  [O],
  [X],
  [동적 하위 작업],
  [Evaluator-Optimizer],
  [X],
  [X],
  [O],
  [품질 개선 루프],
)
