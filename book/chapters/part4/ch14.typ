// Source: docs/deepagents/15-streaming.md
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "스트리밍", subtitle: "subgraphs=True + v2 네임스페이스")

메인 에이전트는 물론 서브에이전트 내부 이벤트까지 실시간으로 UI에 노출하고, 커스텀 진행률 이벤트까지 방출하는 방법을 다룹니다. 장시간 실행 에이전트의 진행 상황을 사용자에게 보여주거나 서브에이전트 카드 UI를 만들 때 이 장을 씁니다.

#learning-header()
#learning-objectives(
  [`subgraphs=True`와 `version="v2"` 조합으로 서브에이전트 내부까지 관찰한다],
  [네임스페이스(`ns`) 튜플로 메인/서브 이벤트를 라우팅한다],
  [`updates` · `messages` · `custom` 세 모드를 동시에 구독한다],
  [`get_stream_writer`로 커스텀 진행률 이벤트를 방출한다],
  [서브에이전트 라이프사이클(Pending/Running/Complete) 3신호를 UI 카드에 매핑한다],
)

== 14.1 세 가지 핵심

Deep Agents 스트리밍의 핵심은 세 가지입니다.

- *`subgraphs=True` + `version="v2"`* — 서브에이전트 내부 이벤트까지 관찰
- *네임스페이스(`ns`)* — 이벤트가 어느 서브그래프에서 왔는지 튜플로 구분
- *Stream mode 조합* — `updates`(스텝), `messages`(토큰/도구), `custom`(커스텀 이벤트)

v2 포맷은 모든 청크를 `{"type", "ns", "data"}` 통일 구조로 돌려줍니다. v1의 중첩 튜플보다 라우팅이 단순합니다.

== 14.2 기본 사용: 서브에이전트 스트리밍 활성화

#code-block(`````python
for chunk in agent.stream(
    {"messages": [{"role": "user", "content": "Research quantum computing advances"}]},
    stream_mode="updates",
    subgraphs=True,
    version="v2",
):
    print(chunk)
`````)

`subgraphs=True`를 주지 않으면 서브에이전트 내부 동작은 슈퍼바이저 레벨에서 `task` 도구 호출 결과로만 보입니다. UI에서는 "블랙박스에서 뭔가 하다가 결과가 나오는" 경험이 됩니다.

== 14.3 네임스페이스로 이벤트 라우팅

모든 v2 청크는 `ns` 필드에 _튜플_을 담고 있으며, 이 튜플이 이벤트 발생 위치를 식별합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[튜플],
  text(weight: "bold")[의미],
  [`()`],
  [메인 에이전트 이벤트],
  [`("tools:abc123",)`],
  [메인 에이전트의 `task` 도구 호출로 스폰된 서브에이전트],
  [`("tools:abc123", "model_request:def456")`],
  [해당 서브에이전트 내부의 model request 노드],
)

서브에이전트 이벤트 여부 판정:

#code-block(`````python
is_subagent = any(segment.startswith("tools:") for segment in chunk["ns"])
`````)

메인 대화 패널과 서브에이전트 카드를 UI에서 나눌 때 이 판정이 기본 분기점입니다.

== 14.4 Stream mode: `updates`

노드 스텝 단위로 "지금 어느 단계를 실행 중인가"를 보여줍니다. 서브에이전트 라이프사이클 추적에 특히 유용합니다.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="updates",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "updates":
        for node_name, data in chunk["data"].items():
            print(f"Step: {node_name}")
`````)

== 14.5 Stream mode: `messages`

LLM 토큰을 조각 단위로 받습니다. 도구 호출이 발생하면 각 청크에 `tool_call_chunks`가 붙어 _도구 이름과 args가 스트리밍으로 쌓입니다_.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="messages",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "messages":
        token, metadata = chunk["data"]
        if token.tool_call_chunks:
            for tc in token.tool_call_chunks:
                print(f"Tool: {tc['name']}, Args: {tc.get('args')}")
        else:
            print(token.content, end="")
`````)

토큰 단위 출력과 도구 호출 조립을 같은 루프에서 처리할 수 있습니다.

== 14.6 커스텀 진행률 이벤트

도구 내부에서 스트리밍 작성자를 꺼내 임의 구조체를 방출합니다. 업로드 진행률, 처리 건수, 중간 상태 등을 UI에 내보낼 때 씁니다.

#code-block(`````python
from langchain.tools import tool
from langgraph.config import get_stream_writer

@tool
def analyze_data(topic: str) -> str:
    """주제에 대한 데이터를 분석한다."""
    writer = get_stream_writer()
    writer({"status": "starting", "progress": 0})
    # ... 분석 작업 ...
    writer({"status": "complete", "progress": 100})
    return "done"
`````)

수신 측에서는 `stream_mode="custom"`을 구독합니다.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode="custom",
    subgraphs=True,
    version="v2",
):
    if chunk["type"] == "custom":
        print(chunk["data"])
`````)

== 14.7 다중 모드 동시 구독

리스트로 넘기면 루프 하나에서 세 종류 이벤트를 모두 받습니다.

#code-block(`````python
for chunk in agent.stream(
    {"messages": [...]},
    stream_mode=["updates", "messages", "custom"],
    subgraphs=True,
    version="v2",
):
    t = chunk["type"]
    if t == "updates":
        # 스텝 진행
        ...
    elif t == "messages":
        # 토큰 / 도구 호출
        ...
    elif t == "custom":
        # 진행률 / 커스텀 이벤트
        ...
`````)

프로덕션 UI에서는 보통 이 세 모드를 함께 구독해 각자의 패널에 분배합니다.

== 14.8 서브에이전트 라이프사이클 추적

메인 에이전트 관점에서 서브에이전트는 세 이벤트로 식별합니다.

+ *Pending* — 메인이 `name="task"`인 tool_call을 방출한 순간
+ *Running* — `("tools:<id>",)` 네임스페이스에서 첫 이벤트가 도착한 순간
+ *Complete* — 해당 `task` 호출의 ToolMessage가 메인 `tools` 노드에 돌아온 순간

UI 카드 상태를 이 세 신호에 매핑하면 "어떤 서브에이전트가 지금 탐색 중인지" 바로 보입니다.

== 14.9 v2 통합 포맷

모든 청크는 다음 세 필드를 가집니다.

#code-block(`````python
{
    "type": "updates" | "messages" | "custom",
    "ns": tuple,
    "data": Any,
}
`````)

v1의 중첩 튜플 포맷은 `type`마다 자료 구조가 달라 분기가 복잡했습니다. v2는 프런트엔드 라우팅을 `(type, ns prefix)` 하나로 단순화합니다.

== 14.10 프런트엔드 연동

React/Vue/Svelte/Angular는 `@langchain/react` 등의 `useStream` 훅으로 이 스트림을 자동 처리합니다. 서브에이전트 카드 렌더링, 재연결, 히스토리 로드까지 내장돼 있습니다.

#code-block(`````tsx
import { useStream } from "@langchain/react";

const stream = useStream<typeof agent>({
  apiUrl: "https://your-deployment.langsmith.dev",
  assistantId: "agent",
  reconnectOnMount: true,
  fetchStateHistory: true,
});

stream.submit(
  { messages: [{ type: "human", content: text }] },
  {
    streamSubgraphs: true,
    config: { recursionLimit: 10000 },
  },
);
`````)

== 14.11 주의사항

- *`subgraphs=True` 없으면 서브에이전트 내부는 보이지 않는다* — UI 진행 카드에 필수
- *`version="v2"`를 명시하라* — 레거시 포맷으로 떨어지면 네임스페이스 처리가 달라짐
- *커스텀 이벤트 스키마는 고정* — 도구마다 제각각 쓰면 UI 라우팅이 깨짐 (예: `{"status", "progress", "message"}` 공통 필드)
- *요약(summarization) 토큰은 노출 여부를 결정*해야 함 (`metadata.get("lc_source") == "summarization"`로 필터링)
- *재시도 이벤트도 스트리밍됨* — `ModelRetryMiddleware`가 붙어 있으면 실패-재시도 플로우가 그대로 보이므로 UI에서 집계

== 핵심 정리

- v2 포맷 + `subgraphs=True`가 서브에이전트 관찰의 입구
- `ns` 튜플 prefix로 메인/서브 이벤트를 라우팅
- `updates`/`messages`/`custom` 세 모드를 리스트로 동시 구독하는 것이 프로덕션 기본
- `get_stream_writer`로 도구에서 임의 진행률 이벤트 방출
- Pending/Running/Complete 3신호를 UI 카드 상태에 매핑
