// Auto-generated from 07_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "스트리밍", subtitle: "실시간으로 에이전트 실행 관찰")

== 학습 목표
LangGraph의 다양한 스트리밍 모드를 이해하고 활용합니다.

- `values`, `updates`, `messages`, `custom`, `debug` 모드의 차이를 이해합니다
- 각 스트리밍 모드의 적절한 사용 사례를 파악합니다
- 여러 스트리밍 모드를 동시에 사용하는 방법을 익힙니다

== 7.1 환경 설정

== 7.2 스트리밍 모드 비교

LangGraph는 다양한 스트리밍 모드를 제공합니다. 각 모드는 서로 다른 수준의 정보를 실시간으로 전달합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[용도],
  [`values`],
  [각 단계의 전체 상태],
  [디버깅, 상태 추적],
  [`updates`],
  [각 노드가 반환한 업데이트만],
  [진행 상황 표시],
  [`messages`],
  [메시지 토큰 단위],
  [채팅 UI],
  [`custom`],
  [사용자 정의 이벤트],
  [커스텀 진행률],
  [`debug`],
  [전체 디버그 정보],
  [개발 중 디버깅],
)

== 7.3 stream_mode="values" — 전체 상태 스냅샷

`values` 모드는 각 노드 실행 후 _전체 상태_를 반환합니다. 그래프가 어떻게 진행되는지 전체 흐름을 추적할 때 유용합니다.

== 7.4 stream_mode="updates" — 노드별 업데이트

`updates` 모드는 각 노드가 _반환한 업데이트 값만_ 전달합니다. 어떤 노드가 어떤 변경을 만들었는지 정확히 파악할 수 있습니다.

== 7.5 stream_mode="messages" — 토큰 단위 스트리밍

`messages` 모드는 LLM이 생성하는 _토큰을 실시간으로_ 전달합니다. 채팅 UI에서 타이핑 효과를 구현할 때 가장 적합합니다.

== 7.6 여러 스트리밍 모드 동시 사용

`stream_mode`에 리스트를 전달하면 여러 모드를 _동시에_ 사용할 수 있습니다. 반환되는 이벤트는 `(mode, data)` 튜플 형태입니다.

== 7.7 stream_mode="custom" — 사용자 정의 스트리밍

`custom` 모드는 노드 내부에서 _임의의 데이터를 직접 스트리밍_할 수 있게 합니다.

`langgraph.config`의 `get_stream_writer()`를 호출하면 `writer` 함수를 얻을 수 있고, 이 함수에 딕셔너리 등의 데이터를 전달하면 그래프 실행 중 실시간으로 클라이언트에 전송됩니다.

_활용 사례:_
- 긴 작업의 _진행률(progress)_ 보고
- LangChain을 사용하지 않는 외부 LLM의 _청크 단위 스트리밍_
- 노드 내부의 _중간 결과_를 즉시 전달

#tip-box[`stream_mode="custom"`으로 그래프를 스트리밍하면 `writer()`로 전송한 데이터만 수신됩니다.]

== 7.8 version="v2" — 타입-안전 통일 스트림 (LangGraph 1.1+)

`version="v2"`를 opt-in하면 **모든 청크가 `StreamPart` dict**로 통일됩니다. v1은 모드/서브그래프 조합에 따라 dict/tuple이 섞여 호출 측 분기 코드가 복잡했습니다.

=== StreamPart 구조

#code-block(`````python
{
    "type": "values" | "updates" | "messages" | "custom" | ...,
    "ns":   (),    # 서브그래프 namespace 튜플
    "data": ...,   # 모드별 payload
}
`````)

=== 이점

- _타입 안전성_: `langgraph.types`의 `UpdatesStreamPart`, `CustomStreamPart` 등으로 편집기가 `data`를 자동 내로잉
- _일관된 분기 코드_: 항상 `chunk["type"]`으로 분기 → v1처럼 tuple vs dict 판별 불필요
- _Pydantic / dataclass 자동 강제_: `stream_mode="values"`에서 state가 선언된 타입으로 coerce
- _후방 호환_: v1 동작 유지, v2는 순수 opt-in

=== v1 → v2 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[측면],
  text(weight: "bold")[v1 (기본)],
  text(weight: "bold")[v2 (opt-in)],
  [반환 형태],
  [모드/서브그래프 조합에 따라 dict/tuple 혼재],
  [항상 `StreamPart` dict],
  [모드 식별],
  [tuple 첫 원소(다중모드) / 암묵적],
  [`chunk["type"]` 명시 필드],
  [namespace],
  [`subgraphs=True` 시에만 tuple 첫 원소],
  [항상 `chunk["ns"]`],
  [타입 추론],
  [제한적],
  [TypedDict로 자동 내로잉],
  [Pydantic/dataclass state],
  [유지 (dict)],
  [values 모드에서 자동 인스턴스화],
)

=== 마이그레이션 전략

+ 새 코드는 **`version="v2"` 기본값**으로 작성
+ 기존 v1 호출부는 _그대로 두어도 무방_ (v1은 계속 동작)
+ 타입 안전성이 필요한 핫패스 / 신기능부터 점진 마이그레이션
+ Pydantic state 쓰는 그래프는 자동 강제 덕분에 이득이 가장 큼

== 7.9 `nostream` 태그 — 백그라운드 LLM을 messages 스트림에서 제외

같은 그래프 안에서 _사용자에게 보여줄 응답 모델_과 _내부 보조 모델_(라우팅·요약·툴 결정 등)이 함께 호출되면, 두 모델의 토큰이 모두 `messages` 스트림에 흘러들어 UI가 노이즈를 받습니다.

해결책: 내부 모델에 **`nostream` 태그**를 부여하면 `stream_mode="messages"` 출력에서 자동으로 제외됩니다.

#code-block(`````python
from langchain_anthropic import ChatAnthropic

internal_model = ChatAnthropic(model_name="claude-haiku-4-5-20251001").with_config(
    {"tags": ["nostream"]}
)
# internal_model의 토큰은 messages 스트림에 노출되지 않는다
`````)

`disable_streaming=True` / `streaming=False`로 모델 자체의 스트리밍을 끄는 것과는 다릅니다 — `nostream`은 _그래프 스트림에서만_ 가립니다.

== 7.10 태그 / 마지막 청크 감지 — `chunk_position == "last"`

`messages` 모드 청크에는 메시지 자체뿐 아니라 풍부한 메타데이터가 함께 옵니다.

- `metadata["tags"]` — 모델 호출에 부여한 태그 리스트 → `["joke"]`, `["poem"]`처럼 모델별 필터링
- `metadata["langgraph_node"]` — 어떤 노드가 호출한 토큰인지
- `metadata["chunk_position"]` — `"first"` / 중간(없음) / `"last"` 중 하나. **`"last"`**가 들어오면 해당 메시지의 스트리밍이 끝났음을 의미해 UI에서 cursor 정리·전송 확정에 사용

#code-block(`````python
joke_model = init_chat_model(model="gpt-5.4-mini", tags=["joke"])
poem_model = init_chat_model(model="gpt-5.4-mini", tags=["poem"])

async for chunk in graph.astream(
    {"topic": "cats"},
    stream_mode="messages",
    version="v2",
):
    if chunk["type"] != "messages":
        continue
    msg, meta = chunk["data"]

    # 1) 태그로 모델 분기
    if meta.get("tags") != ["joke"]:
        continue

    # 2) 토큰 출력
    if msg.content:
        print(msg.content, end="", flush=True)

    # 3) 마지막 청크에서 마무리 처리
    if meta.get("chunk_position") == "last":
        print("  <-- joke 모델 완료")
`````)

== 7.11 `GraphOutput` — `invoke(..., version="v2")`의 반환 타입

`stream()`뿐 아니라 `invoke()`에도 `version="v2"`를 줄 수 있습니다. 이때 반환값은 dict가 아니라 **`GraphOutput`** 객체입니다.

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
  [그래프 최종 state (Pydantic / dataclass면 자동 인스턴스화)],
  [`.interrupts`],
  [`tuple[Interrupt, ...]`],
  [실행 중 발생한 interrupt들. 없으면 빈 튜플],
)

→ `if result.interrupts:` 한 줄로 "최종 결과 vs interrupt 대기" 분기 가능.
→ `result["key"]` 같은 dict 스타일 접근도 여전히 동작 (deprecated 경로).

== 7.12 Event Streaming v3 — projection 기반 앱 스트림

LangGraph 1.2의 `stream_events(..., version="v3")`는 raw `stream_mode` 위에 projection 계층을 얹습니다. `stream_mode`는 런타임 이벤트를 직접 파싱할 때 좋고, v3 event streaming은 앱 코드가 `stream.messages`, `stream.values`, `stream.subgraphs`, `stream.output`처럼 목적별 핸들을 소비할 때 좋습니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[필요],
  text(weight: "bold")[권장 API],
  [노드별 raw update 확인],
  [`graph.stream(..., stream_mode="updates")`],
  [custom event 직접 처리],
  [`graph.stream(..., stream_mode="custom")`],
  [UI에서 메시지·상태·서브그래프를 분리 표시],
  [`graph.stream_events(..., version="v3")`],
  [typed projection 확장],
  [`StreamTransformer`, `StreamChannel`],
)

#code-block(`````python
# Event Streaming v3 패턴 — 로컬 설치 버전과 무관하게 안전하게 예시를 출력합니다.
from importlib.metadata import version

print("설치된 langgraph:", version("langgraph"))
print("필요 버전: langgraph>=1.2.0")

example = r'''
# 1) 기본 사용
stream = graph.stream_events(
    {"messages": [{"role": "user", "content": "42 * 17은?"}]},
    version="v3",
)

for message in stream.messages:
    for token in message.text:
        print(token, end="", flush=True)

for snapshot in stream.values:
    print(snapshot)

final_state = stream.output

# 2) interrupt 이후 재개 — checkpointer + thread_id 필요
from langgraph.types import Command

stream = graph.stream_events(input_data, version="v3")
for message in stream.messages:
    print(message.text)

if stream.interrupted:
    print(stream.interrupts)
    stream = graph.stream_events(
        Command(resume={"decisions": [{"type": "approve"}]}),
        version="v3",
    )
'''
print(example)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[설명],
  [`values` / `updates`],
  [각 단계의 전체 상태 / 변경분만],
  [`messages`],
  [LLM 토큰 + metadata (`tags`, `langgraph_node`, `chunk_position`)],
  [`custom`],
  [`get_stream_writer()`로 임의 데이터 전송],
  [`debug`],
  [전체 실행 트레이스],
  [여러 모드 동시],
  [v1: `(mode, data)` 튜플 / v2: `chunk["type"]`],
  [**`version="v2"`**],
  [`StreamPart` dict (`type` / `ns` / `data`) 통일, Pydantic state 자동 강제],
  [**`invoke(..., version="v2")`**],
  [`GraphOutput` 반환 — `.value` / `.interrupts`],
  [**`nostream` 태그**],
  [내부 보조 LLM을 messages 스트림에서 제외],
  [**`chunk_position == "last"`**],
  [메시지 스트리밍 종료 시점 감지],
  [**`stream_events(..., version="v3")`**],
  [projection 기반 — `stream.messages` / `stream.values` / `stream.output`, interrupt 재개 지원],
)
