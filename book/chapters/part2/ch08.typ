// Auto-generated from 08_multi_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "멀티 에이전트 패턴")

== 학습 목표
5가지 멀티 에이전트 패턴을 이해하고 구현합니다.

이 노트북에서 다루는 내용:
- _Subagents_: 메인 에이전트가 전문 서브에이전트를 도구로 호출
- _Handoffs_: `Command(goto=...)`로 에이전트 간 상태 전환
- _Skills_: 단일 에이전트가 상황에 따라 전문 프롬프트를 로드
- _Router_: 분류기가 입력을 적절한 에이전트로 라우팅
- _Custom_: 개발자가 완전히 제어하는 복잡한 워크플로

== 8.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("모델 준비 완료:", model.model_name)
`````)
#output-block(`````
모델 준비 완료: gpt-4.1
`````)

== 8.2 멀티 에이전트 패턴 비교

아래 표는 5가지 멀티 에이전트 패턴을 비교합니다. 각 패턴은 서로 다른 상황에 적합하므로, 프로젝트 요구사항에 맞게 선택해야 합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[라우팅 주체],
  text(weight: "bold")[상태 공유],
  text(weight: "bold")[적합한 상황],
  [_Subagents_],
  [메인 에이전트],
  [도구로 격리],
  [병렬 처리, 분산 개발],
  [_Handoffs_],
  [도구 호출],
  [상태 전환],
  [순차적 멀티홉],
  [_Skills_],
  [단일 에이전트],
  [프롬프트 교체],
  [도메인 특화],
  [_Router_],
  [분류기],
  [병렬 실행],
  [멀티 도메인],
  [_Custom_],
  [개발자 정의],
  [완전 제어],
  [복잡한 워크플로],
)

=== 핵심 차이점
- _Subagents_는 각 서브에이전트가 독립적으로 실행되어 결과만 반환합니다.
- _Handoffs_는 대화 상태가 에이전트 간에 전달됩니다.
- _Skills_는 하나의 에이전트가 여러 역할을 전환합니다.
- _Router_는 입력을 분류한 뒤 적절한 에이전트에게 위임합니다.

=== 패턴 선택 매트릭스 (요구사항 → 최적 패턴)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[요구사항],
  text(weight: "bold")[최적 패턴],
  text(weight: "bold")[이유],
  [1],
  [_One-shot 단순 작업_ — 한 번의 도구 호출로 끝나는 단일 도메인],
  [_Single agent_ (멀티 에이전트 불필요)],
  [오버헤드만 늘어남. `create_agent` 한 개로 충분],
  [2],
  [_반복(repeat) 호출_ — 같은 도구를 여러 번 호출해 데이터를 축적],
  [_Subagents_],
  [메인이 결과를 모으며, 각 subagent 호출이 독립 컨텍스트로 격리됨],
  [3],
  [_병렬 멀티 도메인_ — 분류 후 도메인별 전문가에게 동시 분배],
  [_Router_ (+ `Send`)],
  [분류 노드 → fan-out. 동시 실행으로 지연 최소화],
  [4],
  [_대용량 컨텍스트_ — 문서 1만 토큰 이상을 부분별로 분석],
  [_Subagents_ (격리된 컨텍스트) 또는 _Skills_],
  [메인 에이전트 토큰을 보존. Skills는 프롬프트 교체로 추가 도구 없이 처리],
  [5],
  [_팀 기반(team-based)_ — 여러 역할이 서로 결과를 검토·반복],
  [_Handoffs_],
  [`Command(goto=...)`로 대화 상태가 다음 역할로 전달됨],
  [6],
  [_다이렉트 대화(direct conversation)_ — 사용자와 끊김 없이 대화하면서 부서 이관],
  [_Handoffs_ (subgraph + conversation history)],
  [메시지 히스토리가 보존되어 사용자가 같은 톤·맥락으로 계속 진행 가능],
)

=== 성능 비교 (3-step task 기준)

같은 3-step 작업을 패턴별로 수행했을 때 도구 호출 횟수와 컨텍스트 비용(approx.):

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[시나리오],
  text(weight: "bold")[패턴],
  text(weight: "bold")[도구 호출 수],
  text(weight: "bold")[컨텍스트(approx.)],
  text(weight: "bold")[비고],
  [_One-Shot_ (단일 질의)],
  [Single agent],
  [1 call],
  [~3K],
  [베이스라인],
  [_Repeat_ (반복 검색·집계)],
  [Subagents],
  [_4–5 calls_],
  [_~9K_],
  [권장],
  [_Multi-Domain_ (병렬 분배)],
  [Router (+ Send)],
  [3 calls],
  [_~9K_],
  [분류 1 + 도메인 fan-out 병렬],
)

#tip-box[수치는 `docs/langchain/22-multi-agent.md` 기준 추정치. 실제는 모델·프롬프트·tool schema에 따라 ±30% 변동.]

=== Router vs Supervisor 용어

#tip-box[_Router_ — _단순 함수형_ 라우팅. 입력을 분류한 뒤 결정론적으로 다음 노드를 선택합니다. 대화 상태를 인식하지 않고, 한 번 위임하면 끝납니다. (예: `classify_query()` → `math` / `code` / `general` 분기)]
\>
#tip-box[_Supervisor_ — _대화 인식(conversation-aware)_ 감독자. 메시지 히스토리를 보면서 다음 단계에 어떤 subagent를 호출할지 LLM이 판단합니다. 반복 호출, 결과 통합, 재시도 의사결정이 가능합니다. (LangChain v1에서는 `create_agent` + subagent 도구 묶음 = 사실상 supervisor 패턴)]
\>
#note-box[본 노트북의 8.3은 _Supervisor_(LLM이 위임 판단), 8.6은 _Router_(함수형 분류)입니다.]

== 8.3 서브에이전트 패턴

메인 에이전트(감독자)가 전문 서브에이전트를 _도구로_ 호출하는 패턴입니다.

=== 특징
- 각 서브에이전트는 도구 함수로 캡슐화됩니다.
- 메인 에이전트가 어떤 서브에이전트를 호출할지 판단합니다.
- 서브에이전트의 내부 상태는 메인 에이전트와 격리됩니다.
- 병렬 실행이 가능하여 성능에 유리합니다.

=== 8.3.1 Subagent-local history — `checkpointer=True`

서브에이전트를 `create_agent`로 만들 때 `checkpointer=True`를 전달하면, 그 서브에이전트만의 _로컬 대화 히스토리_가 유지됩니다. 메인 에이전트는 서브에이전트의 내부 multi-turn 추론을 보지 않고 최종 결과만 받습니다.

- 메인 컨텍스트 보존 (서브의 reasoning step 미노출)
- 서브 내부에서는 도구 호출-결과-재추론 multi-turn 유지
- 부모와 자식이 별도 checkpointer를 가질 수 있음 (격리)

=== 8.3.2 단일 dispatch tool — 서브에이전트 노출 방식 3가지

서브에이전트가 많아지면 도구 슬롯 폭증을 막기 위해 단일 `dispatch` 도구 하나로 묶고, 어떤 서브를 호출할지는 인자로 받습니다. 노출 방식은 세 가지가 있습니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[적합 규모],
  text(weight: "bold")[장점],
  text(weight: "bold")[단점],
  [_(A) System prompt 열거_],
  [\\\< 10개],
  [간단·즉시 발견],
  [프롬프트 토큰 증가, 대규모 시 흐려짐],
  [_(B) `Literal` 인자 제약_],
  [10–30개],
  [tool schema가 enum을 강제 → 모델 hallucination 감소],
  [명단을 코드에서 관리해야 함],
  [_(C) Tool-based discovery_],
  [30+ 개],
  [`list_subagents()` / `describe(name)` 도구로 동적 탐색. 무한 확장],
  [호출 1–2회 추가],
)

=== 8.3.3 부모 state 주입 — `ToolRuntime[None, CustomState]`

서브에이전트 도구가 부모 그래프의 커스텀 state(예: `user_id`, `tenant`, 누적 결과)에 접근해야 할 때 `ToolRuntime[ContextSchema, StateSchema]`로 의존성을 주입합니다. 도구 인자 시그니처에 명시하면 LangChain이 자동으로 그래프 state를 전달합니다.

=== 8.3.4 비동기 서브에이전트 — 3-tool 패턴

장시간(분 단위) 실행되는 서브에이전트는 동기 호출로 메인을 블록하면 안 됩니다. _`start_job` / `check_status` / `get_result`_ 세 도구로 분리하면 메인 에이전트가 백그라운드 작업을 폴링하면서 다른 일을 병행할 수 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[역할],
  text(weight: "bold")[반환],
  [`start_job(task)`],
  [작업 제출 (즉시 반환)],
  [`job_id`],
  [`check_status(job_id)`],
  [진행 상태 폴링],
  [`pending` / `running` / `done` / `failed`],
  [`get_result(job_id)`],
  [완료된 결과 회수],
  [최종 출력 (미완료 시 에러)],
)

=== 8.3.5 `Command` 반환으로 부모 state 업데이트

도구가 단순 문자열 대신 `Command(update={...})`를 반환하면, 부모 그래프의 state를 직접 갱신할 수 있습니다. 누적 로그·집계 결과·중간 산출물을 메시지 히스토리 밖에 두고 싶을 때 유용합니다.

== 8.4 핸드오프 패턴

`Command(goto=...)`로 에이전트 간 _상태를 전환_하는 패턴입니다.

=== 특징
- 도구가 `Command` 객체를 반환하여 다른 에이전트로 전환합니다.
- 대화 상태(메시지 히스토리)가 다음 에이전트로 전달됩니다.
- `StateGraph`로 에이전트 간 흐름을 정의합니다.
- 고객 서비스의 부서 이관 같은 순차적 멀티홉 시나리오에 적합합니다.

=== 8.4.1 단일 에이전트 핸드오프 — `\@wrap_model_call` 미들웨어

위의 multi-subgraph 방식은 부서가 많아질수록 노드 수가 폭증합니다. _docs 권장 1순위_는 단일 에이전트에 `@wrap_model_call` 미들웨어를 붙여, 모드(`role`)에 따라 `system_prompt`와 `tools`를 동적으로 교체하는 방식입니다.

- _노드 1개_ — `StateGraph` 불필요
- _상태 자연 전이_ — `role` 필드만 업데이트하면 다음 호출부터 새 프롬프트·도구 셋 적용
- _핸드오프 = 도구 호출_ — `transfer_to_sales`가 state의 `role`을 바꾸고 다음 모델 호출 시 sales 페르소나로 작동

=== 8.4.2 Subgraph 핸드오프의 conversation history 규칙

서브그래프 방식(8.4 원본 예제)으로 핸드오프를 만들 때는 _부모 그래프의 메시지 히스토리에 정확히 2개만 흘러야_ 다음 에이전트가 정상 작동합니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[\#],
  text(weight: "bold")[메시지],
  text(weight: "bold")[누가 만드는가],
  text(weight: "bold")[역할],
  [1],
  [`AIMessage(tool_calls=[transfer_to_X])`],
  [라우터 에이전트의 LLM],
  ["이관 결정"의 흔적],
  [2],
  [`ToolMessage(tool_call_id=...)`],
  [`transfer_to_X` 도구 자체],
  [OpenAI tool-call 규칙: 모든 tool_call에는 짝 ToolMessage 필요],
)

_부모 history에 흘리지 말아야 할 것:_
- 라우터의 중간 reasoning 메시지 (서브그래프 내부에서 처리)
- 도구의 길고 자세한 결과 (요약만 ToolMessage로)

_왜 중요한가:_
- 다음 에이전트(sales/support)는 이 2개 메시지를 보고 _방금 이관됐다_를 인지함
- OpenAI/Anthropic은 짝 없는 `tool_calls`가 있으면 다음 turn에서 에러를 냅니다
- 부모 history가 깨끗할수록 컨텍스트가 가볍고, 같은 thread에서 추가 이관이 가능

→ 위 8.4.1의 `wrap_model_call` 패턴은 이 규칙을 자동으로 따릅니다 (도구가 `ToolMessage` 하나만 흘리고 state.role을 갱신).

== 8.5 스킬 패턴

단일 에이전트가 상황에 따라 _전문 프롬프트를 로드_하는 패턴입니다.

=== 특징
- 하나의 에이전트가 여러 "스킬"을 가집니다.
- 각 스킬은 특화된 시스템 프롬프트입니다.
- 에이전트가 필요한 스킬을 동적으로 로드합니다.
- 여러 에이전트를 관리하지 않고도 하나의 에이전트로 다양한 작업을 처리할 수 있습니다.

== 8.6 라우터 패턴

분류기가 입력을 적절한 에이전트로 _라우팅_하는 패턴입니다.

=== 특징
- 먼저 쿼리를 분류(classify)합니다.
- 분류 결과에 따라 적절한 전문 에이전트(도구)로 위임합니다.
- 멀티 도메인 시스템에서 유용합니다.
- 분류 로직은 규칙 기반 또는 LLM 기반으로 구현할 수 있습니다.

=== 8.6.1 진짜 fan-out 라우터 — `Send`로 병렬 분배

위 8.6 예제의 `from langgraph.types import Send`는 사실 dead import였습니다(분류 후 단일 분기만 실행). 실제 라우터의 강점은 _분류 결과를 여러 노드에 동시에 fan-out_하는 능력입니다. 한 질문이 여러 도메인에 걸칠 때 `Send(node, payload)` 리스트를 반환하면 LangGraph가 병렬로 실행합니다.

== 8.7 패턴 선택 가이드

어떤 멀티 에이전트 패턴을 선택해야 할까요? 아래 가이드를 참고하세요.

=== 결정 트리

+ _에이전트가 독립적으로 작업 가능한가?_
- YES -\> _Subagents_ (병렬 실행, 결과 취합)
- NO -\> 다음 질문으로

+ _대화 상태가 에이전트 간에 전달되어야 하는가?_
- YES -\> _Handoffs_ (상태 전환, 멀티홉)
- NO -\> 다음 질문으로

+ _하나의 에이전트가 여러 역할을 전환하면 되는가?_
- YES -\> _Skills_ (프롬프트 교체)
- NO -\> 다음 질문으로

+ _입력을 분류한 뒤 적절한 처리기로 보내면 되는가?_
- YES -\> _Router_ (분류 후 위임)
- NO -\> _Custom_ (완전 커스텀 그래프)

=== 실용적 권장사항
- 처음에는 _가장 단순한 패턴_(Subagents 또는 Skills)으로 시작하세요.
- 요구사항이 복잡해지면 Handoffs나 Router로 전환하세요.
- Custom 패턴은 다른 패턴으로 해결할 수 없을 때만 사용하세요.
- 패턴을 _조합_할 수도 있습니다 (예: Router + Handoffs).

#chapter-summary-header()

이 노트북에서 학습한 핵심 내용:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[핵심 API],
  text(weight: "bold")[사용 시기],
  [_Subagents_],
  [`create_agent` + 도구 함수],
  [독립적 병렬 작업],
  [_Handoffs_],
  [`Command(goto=...)`, `StateGraph`],
  [상태 전환이 필요한 멀티홉],
  [_Skills_],
  [도구로 프롬프트 로드],
  [단일 에이전트 다중 역할],
  [_Router_],
  [분류 도구 + 전문 도구],
  [멀티 도메인 분류],
  [_Custom_],
  [`StateGraph` 완전 제어],
  [복잡한 비즈니스 로직],
)

=== 핵심 원칙
- 단순한 것부터 시작하고, 필요에 따라 복잡도를 높이세요.
- 각 에이전트는 _하나의 책임_만 가지도록 설계하세요.
- 에이전트 간 _인터페이스_(입력/출력)를 명확히 정의하세요.
