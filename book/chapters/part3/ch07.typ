// Auto-generated from 07_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(7, "스트리밍", subtitle: "실시간으로 에이전트 실행 관찰")

6장에서 체크포인터와 메모리를 통해 에이전트의 _상태 저장_을 다루었다면, 이 장에서는 에이전트의 _실행 과정을 실시간으로 관찰_하는 스트리밍을 다룹니다. 에이전트가 여러 단계를 거쳐 결과를 생성할 때, 최종 응답이 완성될 때까지 사용자를 기다리게 하면 UX가 크게 저하됩니다. 스트리밍을 통해 중간 과정을 실시간으로 보여주면 사용자는 에이전트가 "생각하고 있다"는 느낌을 받으며, 개발자는 에이전트의 내부 동작을 디버깅할 수 있습니다.

`LangGraph`는 `values`, `updates`, `messages`, `custom`, `debug` 등 5가지 스트리밍 모드를 제공합니다. 각 모드는 서로 다른 수준의 세밀함(granularity)으로 정보를 전달합니다. `values`는 전체 상태 스냅샷을, `updates`는 각 노드의 변경 사항만을, `messages`는 LLM 토큰 하나하나를 전달합니다. 동기 환경에서는 `graph.stream()`, 비동기 환경에서는 `graph.astream()`을 사용하며, `stream_mode=["updates", "messages"]`처럼 여러 모드를 리스트로 전달하여 동시에 사용할 수도 있습니다. 이 장에서는 각 모드의 특성과 적합한 사용 시나리오를 실습을 통해 비교합니다.

#learning-header()
LangGraph의 다양한 스트리밍 모드를 이해하고 활용합니다.

- `values`, `updates`, `messages`, `custom`, `debug` 다섯 가지 모드의 차이와 출력 형태를 이해합니다
- 각 스트리밍 모드의 적절한 사용 사례를 파악합니다 (디버깅, 채팅 UI, 진행률 보고 등)
- `stream_mode`에 리스트를 전달하여 여러 모드를 동시에 사용하는 방법을 익힙니다
- 서브그래프 스트리밍과 태그 기반 필터링 기법을 이해합니다

== 7.1 환경 설정

== 7.2 스트리밍 모드 비교

LangGraph는 다양한 스트리밍 모드를 제공합니다. 각 모드는 서로 다른 수준의 세밀함(granularity)으로 정보를 실시간으로 전달합니다. 아래 표에서 각 모드의 특성과 주요 용도를 한눈에 비교할 수 있습니다. 실무에서는 용도에 맞는 모드를 선택하거나, 여러 모드를 조합하여 사용합니다.

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

이제 각 스트리밍 모드를 하나씩 살펴보며, 출력 형태와 적합한 사용 시나리오를 확인합시다.

== 7.3 stream_mode="values" --- 전체 상태 스냅샷

`values` 모드는 각 노드 실행 후 _전체 상태(state)_를 반환합니다. 그래프가 어떻게 진행되는지 전체적인 흐름을 추적할 때 유용합니다. 매 이벤트마다 전체 상태 딕셔너리가 전달되므로 데이터 양이 많을 수 있지만, 각 시점의 완전한 스냅샷을 얻을 수 있다는 장점이 있습니다. 특히 디버깅 시 "이 노드 실행 후 상태가 정확히 어떤 모습인지" 확인하고 싶을 때 가장 적합합니다.

#tip-box[`values` 모드는 매 단계마다 _전체 상태_를 반환하므로, 상태에 긴 메시지 이력이 쌓이면 네트워크 트래픽이 커질 수 있습니다. 프로덕션 환경에서는 `updates` 모드로 변경 사항만 받는 것이 더 효율적입니다. `values` 모드는 주로 개발 중 디버깅 용도로 활용하세요.]

`values` 모드가 전체 상태를 보여주었다면, `updates` 모드는 각 노드가 _변경한 부분만_ 추출하여 보여줍니다.

== 7.4 stream_mode="updates" — 노드별 업데이트

`updates` 모드는 각 노드가 _반환한 업데이트 값만_ 전달합니다. 출력 형태는 `{노드_이름: 반환값}` 딕셔너리입니다. 전체 상태 대신 변경 사항만 전달하므로 데이터 양이 적고, "어떤 노드가 어떤 변경을 만들었는지" 명확히 파악할 수 있습니다. 프로덕션 환경에서 에이전트의 진행 상황을 모니터링하거나, UI에 "검색 중...", "분석 중..." 같은 단계별 상태를 표시할 때 가장 적합한 모드입니다.

`values`와 `updates`가 노드 단위의 스트리밍이었다면, `messages` 모드는 한 단계 더 세밀하게 _토큰 단위_로 스트리밍합니다.

== 7.5 stream_mode="messages" — 토큰 단위 스트리밍

`messages` 모드는 LLM이 생성하는 _토큰을 실시간으로_ 전달합니다. 각 이벤트는 `(message_chunk, metadata)` 튜플 형태로, `message_chunk`에는 생성된 토큰이, `metadata`에는 어떤 노드(`langgraph_node`)에서 생성되었는지 등의 정보가 포함됩니다. ChatGPT나 Claude 같은 채팅 UI에서 글자가 하나씩 나타나는 _타이핑 효과_를 구현할 때 가장 적합한 모드입니다.

`metadata`의 `tags`나 `langgraph_node` 필드를 사용하면, 특정 LLM 호출이나 특정 노드에서 생성된 토큰만 선택적으로 필터링할 수도 있습니다. 예를 들어, 여러 LLM 호출이 있는 그래프에서 최종 응답 노드의 토큰만 사용자에게 보여주고, 중간 추론 노드의 토큰은 무시하는 등의 제어가 가능합니다.

#warning-box[`messages` 모드는 LangChain의 LLM 통합(예: `ChatOpenAI`)을 사용해야 동작합니다. 직접 OpenAI API를 호출하거나 LangChain을 사용하지 않는 LLM을 쓰는 경우에는 `messages` 모드 대신 `custom` 모드에서 `get_stream_writer()`를 사용하여 수동으로 토큰을 스트리밍해야 합니다.]

지금까지 각 모드를 개별적으로 살펴보았습니다. 하지만 실무에서는 하나의 모드만으로는 부족한 경우가 많습니다.

== 7.6 여러 스트리밍 모드 동시 사용

예를 들어, 채팅 UI에서 토큰을 실시간으로 보여주면서(`messages`) 동시에 노드별 진행 상황(`updates`)도 추적하고 싶을 수 있습니다. `stream_mode`에 리스트를 전달하면 여러 모드를 _동시에_ 사용할 수 있습니다. 반환되는 이벤트는 `(mode, data)` 튜플 형태이므로, 첫 번째 원소인 `mode` 문자열로 어떤 모드에서 온 이벤트인지 구분하여 처리할 수 있습니다.

이 기능은 복합적인 모니터링 시나리오에서 매우 유용합니다. 예를 들어, 프론트엔드에서는 `messages` 이벤트로 타이핑 효과를 구현하고, 동시에 `updates` 이벤트로 사이드바에 "검색 도구 실행 중..."과 같은 진행 상황을 표시할 수 있습니다.

#tip-box[복수 모드 사용 시, 이벤트를 모드별로 분기 처리하는 패턴이 일반적입니다: `for mode, data in graph.stream(..., stream_mode=["updates", "messages"]):`에서 `if mode == "messages":` 로 분기합니다.]

마지막으로, 가장 유연한 스트리밍 모드인 `custom`을 살펴봅시다. 앞의 네 가지 모드가 LangGraph가 _자동으로_ 생성하는 이벤트를 전달하는 반면, `custom` 모드는 개발자가 _직접_ 원하는 데이터를 스트리밍합니다.

== 7.7 stream_mode="custom" — 사용자 정의 스트리밍

`custom` 모드는 노드 내부에서 _임의의 데이터를 직접 스트리밍_할 수 있게 해줍니다. `langgraph.config`의 `get_stream_writer()`를 호출하면 `writer` 함수를 얻을 수 있고, 이 함수에 딕셔너리, 문자열 등 직렬화 가능한 데이터를 전달하면 그래프 실행 중 실시간으로 클라이언트에 전송됩니다.

이 모드의 핵심 가치는 _LangGraph의 기본 이벤트로는 표현할 수 없는 정보_를 전달할 수 있다는 점입니다. 다음과 같은 시나리오에서 특히 유용합니다:

_활용 사례:_
- 긴 작업의 _진행률(progress)_ 보고: `writer({"progress": 0.5, "step": "데이터 분석 중"})` 형태로 중간 상태를 전달
- LangChain을 사용하지 않는 외부 LLM의 _청크 단위 스트리밍_: 직접 OpenAI API나 Anthropic API를 호출할 때, 각 청크를 `writer()`로 전달하면 `messages` 모드 없이도 토큰 스트리밍을 구현할 수 있습니다
- 노드 내부의 _중간 결과_를 즉시 전달: 예를 들어, 검색 도구가 10개의 결과를 순차적으로 찾을 때, 각 결과를 발견 즉시 전달

#tip-box[`stream_mode="custom"`으로 그래프를 스트리밍하면 `writer()`로 전송한 데이터_만_ 수신됩니다. 상태 업데이트나 메시지 토큰은 포함되지 않습니다. 다른 모드의 이벤트도 함께 받으려면 `stream_mode=["custom", "updates"]`처럼 복수 모드를 사용하세요.]

#warning-box[Python 3.10 이하에서 비동기 함수(`async def`) 안에서 `get_stream_writer()`를 사용하면 컨텍스트 전파 문제가 발생할 수 있습니다. 이 경우, 노드 함수의 파라미터에 `writer: StreamWriter`를 직접 선언하여 LangGraph가 주입하도록 하세요: `async def my_node(state: State, writer: StreamWriter):`.]

== 7.8 nostream 태그 --- 내부 LLM 호출을 messages 스트림에서 제외

하나의 그래프에서 사용자에게 보여줄 응답 모델과, 내부 평가·라우팅용 보조 모델을 함께 사용하는 경우가 흔합니다. 이때 보조 모델의 토큰까지 `messages` 스트림에 흘러나가면 UI가 어지러워집니다. 해결책은 보조 모델 호출에 `nostream` 태그를 부여하는 것입니다.

#code-block(`````python
from langchain_anthropic import ChatAnthropic

# 보조 모델 — messages 스트림에 노출되지 않음
internal_model = ChatAnthropic(model_name="claude-haiku-4-5-20251001").with_config(
    {"tags": ["nostream"]}
)
`````)

`tags=["nostream"]`이 부여된 모델은 `stream_mode="messages"`에서 자동으로 필터링됩니다. 사용자용 응답 모델만 그대로 두면, UI에는 최종 답변 토큰만 노출됩니다.

== 7.9 chunk_position --- 메시지의 마지막 청크 감지

`messages` 모드의 metadata에는 `chunk_position` 필드가 함께 전달됩니다. `chunk_position == "last"`인 시점에 메시지 한 건이 완결됩니다. 토큰 단위 UI 업데이트는 계속 진행하다가, last 청크에서만 DB 저장이나 후처리 트리거를 걸 수 있습니다.

#code-block(`````python
for msg, metadata in graph.stream(inputs, stream_mode="messages"):
    if metadata.get("chunk_position") == "last":
        # 메시지 종료 시점 — 저장/로깅/후처리
        save_final_message(msg, node=metadata["langgraph_node"])
        continue
    print(msg.content, end="", flush=True)
`````)

`metadata`에서 자주 활용하는 키는 다음 세 가지입니다.

- `tags` --- 모델/체인에 부여한 태그. 예: `["joke"]`, `["nostream"]`
- `langgraph_node` --- 현재 토큰을 생성한 노드 이름
- `chunk_position` --- `"first"`, `"middle"`, `"last"` 중 하나

== 7.10 invoke v2 --- GraphOutput 반환 타입

`invoke()`를 `version="v2"`로 호출하면 결과가 `GraphOutput`으로 감싸여 반환됩니다. 기존 dict 접근(`result["key"]`)도 동작하지만 deprecated 경로이므로, 새 코드는 `.value` / `.interrupts`를 사용합니다.

#code-block(`````python
from langgraph.types import GraphOutput

result = graph.invoke(inputs, version="v2")
assert isinstance(result, GraphOutput)

result.value         # 최종 state (dict / Pydantic / dataclass)
result.interrupts    # tuple[Interrupt, ...] — interrupt 없으면 빈 튜플

if result.interrupts:
    payload = result.interrupts[0].value
    print("HITL 응답 대기:", payload)
`````)

`interrupts` 필드 덕분에 별도 분기 없이 "이번 invoke가 정상 종료인지, interrupt로 멈췄는지"를 한 줄로 판별할 수 있습니다.

== 7.11 stream_events v3 --- projection 기반 재개

LangGraph 1.2+에서는 raw `stream_mode` 위에 _event streaming projection_ 레이어가 추가되었습니다. `graph.stream_events(..., version="v3")`는 하나의 run stream 객체를 반환하며, 호출자는 `stream.messages` / `stream.values` / `stream.subgraphs` / `stream.output` 같은 projection만 독립적으로 소비합니다. interrupt로 멈춘 뒤 동일 API로 재개할 수 있다는 점이 v2 raw streaming과의 가장 큰 차이입니다.

#code-block(`````python
from langgraph.types import Command

stream = graph.stream_events(
    {"messages": [{"role": "user", "content": "보안 점검 시작"}]},
    version="v3",
)

for message in stream.messages:
    for token in message.text:
        print(token, end="", flush=True)

if stream.interrupted:
    print("\n승인 요청:", stream.interrupts)
    stream = graph.stream_events(
        Command(resume={"decisions": [{"type": "approve"}]}),
        version="v3",
    )
    for message in stream.messages:
        for token in message.text:
            print(token, end="", flush=True)

final_state = stream.output  # 최종 state 단일 접근점
`````)

#tip-box[v2 raw streaming은 디버깅·custom 모드 직접 처리에, v3 `stream_events`는 애플리케이션/UI 코드와 typed projection 소비에 적합합니다. 두 API는 공존하므로, 같은 그래프를 디버깅용 v2와 서비스용 v3로 동시에 운영해도 무방합니다.]

이 장에서 LangGraph의 5가지 스트리밍 모드를 모두 살펴보았습니다. `values`는 전체 상태 스냅샷, `updates`는 노드별 변경 사항, `messages`는 LLM 토큰, `custom`은 사용자 정의 데이터, `debug`는 내부 실행 상세를 제공합니다. 각 모드는 서로 다른 수준의 정보를 제공하므로, 용도에 맞게 선택하거나 조합하는 것이 중요합니다.

#chapter-summary-header()

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스트리밍 모드],
  text(weight: "bold")[설명],
  text(weight: "bold")[용도],
  [`values`],
  [각 단계 후 전체 상태 반환],
  [디버깅, 상태 추적],
  [`updates`],
  [노드가 변경한 부분만 반환],
  [진행 상황 모니터링],
  [`messages`],
  [LLM 토큰 실시간 스트리밍],
  [채팅 UI 구현],
  [여러 모드 동시],
  [리스트로 전달 → `(mode, data)` 튜플 수신],
  [복합 모니터링],
  [`custom`],
  [`get_stream_writer()`로 임의 데이터 전송],
  [진행률 보고, 외부 LLM],
  [`debug`],
  [노드 실행의 전체 디버그 정보 (입력, 출력, 메타데이터)],
  [개발 중 상세 디버깅],
)

#next-step-box[다음 장에서는 에이전트 실행을 중간에 _멈추고_ 사람의 입력을 받아 _재개_하는 인터럽트와 타임 트래블을 다룹니다. 스트리밍으로 실행 과정을 관찰하는 것에서 한 걸음 더 나아가, 실행 흐름 자체를 _제어_하는 방법을 배웁니다.]

#chapter-end()
