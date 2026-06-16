// Auto-generated from 08_interrupts_and_time_travel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "인터럽트와 타임 트래블", subtitle: "실행 중단, 승인, 되감기")

== 학습 목표
`interrupt()`로 실행을 중단하고, `Command(resume=...)`로 재개합니다. 타임 트래블로 이전 상태로 돌아갑니다.

- Human-in-the-loop 패턴을 구현할 수 있습니다
- Functional API에서도 interrupt를 사용할 수 있습니다
- 체크포인트 히스토리를 활용한 타임 트래블을 수행할 수 있습니다
- `update_state()`로 외부에서 상태를 수정할 수 있습니다

== 8.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI

# docs/langgraph 패치 기준 canonical 모델 ID
model = ChatOpenAI(model="gpt-5.4-mini")
print("모델 준비 완료")
`````)

== 8.2 interrupt() — 실행을 중단하고 사람의 입력을 기다립니다

- `interrupt(value)`: 현재 상태를 체크포인트에 저장하고 실행을 중단합니다
- `Command(resume=value)`: 중단된 지점에서 값을 전달하며 재개합니다

민감한 작업 전 사람의 승인을 받거나, 추가 정보를 입력받을 때 사용합니다.

== 8.3 Command(resume=...) — 중단된 실행을 재개합니다

`Command(resume=value)`를 사용하면 `interrupt()`가 호출된 지점에서 실행이 재개됩니다. `resume`에 전달한 값이 `interrupt()`의 반환값이 됩니다.

== 8.4 Functional API에서의 interrupt

Functional API(`@entrypoint`, `@task`)에서도 `interrupt()`를 동일하게 사용할 수 있습니다.

== 8.5 Common Patterns — 5가지 표준 interrupt 패턴

공식 문서는 interrupt 활용을 5가지 패턴으로 분류합니다. 모두 `interrupt()` + `Command(resume=...)` 조합이며, 차이는 _resume payload의 형태_와 _노드 내부 로직_입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패턴],
  text(weight: "bold")[resume 형태],
  text(weight: "bold")[용도],
  [Approval],
  [`bool` (`True` / `False`)],
  [API 호출·DB 변경 같은 critical action 직전 승인],
  [Review & Edit],
  [`str` 또는 edited dict],
  [LLM 출력 검토·수정 후 재주입],
  [Tool Interrupt],
  [`{"action": "approve", ...}` decision dict],
  [tool 함수 내부에 interrupt를 두고 부분 편집 + 승인],
  [Input Validation],
  [임의 값, 루프 안에서 재시도],
  [유효한 값이 들어올 때까지 다시 묻기],
  [Multiple Interrupts],
  [`{interrupt_id: 응답값}` map],
  [병렬 노드의 동시 interrupt에 id로 매칭],
)

`Command(resume=...)`는 단일 값 / dict 어떤 형태든 받을 수 있고, 노드의 `interrupt()` 반환값으로 그대로 전달됩니다.

=== 8.5.1 패턴 1 — Approval (`resume=True/False`)

`Command(goto=...)`와 결합해 승인 여부에 따라 라우팅합니다.

=== 8.5.2 패턴 2 — Review & Edit (`resume="edited text"`)

LLM 출력을 사람이 검토·수정한 뒤 그래프에 다시 주입합니다. resume 값이 그대로 state에 반영됩니다.

=== 8.5.3 패턴 3 — Tool Interrupt (`resume={"action": "approve", ...}`)

tool 함수 내부에 `interrupt()`를 두면 tool 실행 직전 사람이 승인·편집할 수 있습니다. resume payload는 보통 `{"action": "approve", ...}` 형태의 decision dict로, 승인 여부와 부분 편집을 함께 전달합니다.

=== 8.5.4 패턴 4 — Input Validation (루프 안 interrupt)

루프 안에서 `interrupt()`를 반복 호출해, 유효한 값이 들어올 때까지 다시 묻습니다. _노드 안 interrupt 호출 순서는 일관성이 보장_되므로 루프 안에서도 안전합니다.

=== 8.5.5 패턴 5 — Multiple Interrupts (`resume={interrupt_id: 응답}`)

병렬 노드가 동시에 interrupt를 일으키면, _interrupt id를 키로 하는 resume map_으로 응답을 일대일 매칭합니다.

#code-block(`````python
interrupted = graph.invoke({"vals": []}, config, version="v2")

resume_map = {
    i.id: f"answer for {i.value}" for i in interrupted.interrupts
}
result = graph.invoke(Command(resume=resume_map), config, version="v2")
`````)

`interrupted.interrupts`는 v2의 `GraphOutput.interrupts`로, 각 `Interrupt`에는 고유 `id`와 노드가 넘긴 `value`가 들어 있습니다. resume map의 키가 일치해야 해당 노드로 값이 전달됩니다.

== 8.6 타임 트래블 — Replay vs Fork

LangGraph의 체크포인트 시스템은 모든 실행 상태를 저장합니다. `get_state_history()`로 이전 체크포인트를 조회하고, 그 시점에서 두 가지 동작을 할 수 있습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[동작],
  text(weight: "bold")[API],
  text(weight: "bold")[효과],
  [_Replay_],
  [`invoke(None, prev.config)`],
  [그 시점부터 _다시 실행_. `next`로 표시된 노드부터 재실행되고, 이전 노드 결과는 캐시에서 재사용],
  [_Fork_],
  [`update_state(prev.config, values=...)` → 반환된 `fork_config`로 `invoke(None, fork_config)`],
  [그 시점에서 state를 _수정한 새 branch_ 생성 → 대체 경로 탐색. 원본 thread는 그대로 유지],
)

#warning-box[_주의_ — Replay는 결과를 "캐시에서 읽기만 하는" 게 아니라 _실제로 다시 실행_합니다. LLM 호출 / API 호출 / interrupt가 다시 발생하며 결과가 달라질 수 있습니다.]

=== 8.6.1 Replay 표준 패턴 — `invoke(None, prev.config)`

문서 표준 예제로 다시 짚어봅니다. 2-노드 그래프(`generate_topic` → `write_joke`)에서 `write_joke` 직전 체크포인트로 돌아가 replay하면, `generate_topic`은 캐시된 결과를 재사용하고 `write_joke`만 재실행됩니다.

=== 8.6.2 Fork 표준 패턴 — `update_state(prev.config, values=...)` + `as_node`

같은 `before_joke` 시점에서 _topic을 바꿔 다른 농담_을 만들어봅니다.

- `update_state(before_joke.config, values={"topic": "chickens"})` → 수정된 state를 적용한 _새 checkpoint(fork_config)_ 반환
- `invoke(None, fork_config)`로 fork branch 실행 → 원본 thread는 그대로 유지
- `as_node="generate_topic"` 옵션으로 "이 update가 generate_topic이 만든 것"임을 명시 → 후속 노드(`write_joke`)부터 실행 재개

== 8.7 update_state() — 외부에서 상태 직접 수정

`update_state()`로 외부에서 그래프의 상태를 직접 수정할 수 있습니다. 디버깅, 테스트, 또는 수동 개입이 필요한 경우에 유용합니다.

채널에 reducer가 있으면 값이 _병합_되고, reducer가 없으면 _덮어쓰기_됩니다. `MessagesState`의 `messages` 채널은 reducer로 append되므로 아래 호출은 메시지 목록 끝에 새 메시지를 추가합니다.

== 8.8 `version="v2"` — `GraphOutput`으로 인터럽트 분기 (LangGraph 1.1+)

v1의 `invoke()`는 state dict에 인터럽트 정보가 섞여 반환됩니다. 호출 측에서 _"이번 결과가 최종인지, 인터럽트 대기 중인지"_ 구분하려면 `graph.get_state(config)`를 따로 호출해야 했습니다.

v2에서는 **`GraphOutput` 객체**가 반환됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[속성],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`.value`],
  [`StateT`],
  [최종 state (Pydantic/dataclass면 자동 인스턴스화)],
  [`.interrupts`],
  [`tuple[Interrupt, ...]`],
  [실행 중 발생한 인터럽트 목록],
)

→ `if result.interrupts:` 한 줄로 분기 가능. 위 Common Patterns 코드도 모두 이 형태로 사용했습니다.

=== 서브그래프 타임트래블 버그 수정 (1.1)

LangGraph 1.1은 _인터럽트 + 서브그래프 타임트래블_에서 과거 `RESUME` 값을 재사용하던 버그도 함께 수정했습니다. 서브그래프를 쓰며 타임트래블하는 코드가 있다면 1.1로 올리고, 가능하면 `version="v2"`도 함께 적용하길 권장합니다.

#chapter-summary-header()

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[API],
  text(weight: "bold")[비고],
  [`interrupt(value)`],
  [`langgraph.types`],
  [실행 중단, JSON-serializable value 전달],
  [`Command(resume=value)`],
  [`langgraph.types`],
  [중단 지점에서 재개 — `True/False`, `str`, `dict`, `{id: 응답}` map 모두 가능],
  [_Approval_ 패턴],
  [`resume=True/False`],
  [critical action 승인/거부 + `Command(goto=...)`],
  [_Review & Edit_ 패턴],
  [`resume="edited text"`],
  [LLM 출력 검토·수정],
  [_Tool Interrupt_ 패턴],
  [`resume={"action": "approve", ...}`],
  [tool 함수 내부 interrupt, 부분 편집 가능],
  [_Input Validation_ 패턴],
  [루프 안 `interrupt()`],
  [유효한 값까지 재요청],
  [_Multiple Interrupts_ 패턴],
  [`resume={interrupt_id: 응답}`],
  [병렬 노드 동시 interrupt],
  [`get_state_history()`],
  [Graph],
  [체크포인트 이력 (최신순)],
  [_Replay_],
  [`invoke(None, prev.config)`],
  [그 시점부터 재실행 — LLM 호출은 다시 발생],
  [_Fork_],
  [`update_state(prev.config, values=..., as_node=...)` → `invoke(None, fork_config)`],
  [새 branch 생성 — 원본 thread 유지],
  [`update_state()`],
  [Graph],
  [외부에서 상태 수정 — reducer 있으면 병합, 없으면 덮어쓰기],
  [`invoke(..., version="v2")`],
  [LangGraph 1.1+],
  [`GraphOutput.value` / `.interrupts` 분기],
)

_핵심 규칙_:
- `interrupt()`를 try/except로 감싸지 말 것 (인터럽트 예외를 잡아버림)
- interrupt 호출 순서를 일관되게 유지 — 노드 내부 분기에 따라 reorder/skip 금지
- side effect는 interrupt 이후 또는 별도 노드에 둘 것 (재실행 시 중복 방지)
