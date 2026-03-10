// Auto-generated from 12_frontend_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "프론트엔드 스트리밍")

사용자가 에이전트의 응답을 수 초간 기다리게 하는 것은 좋은 경험이 아닙니다. 토큰이 생성되는 즉시 화면에 표시하면 체감 응답 시간이 극적으로 줄어듭니다. 이 장에서는 백엔드의 LangGraph 스트리밍 API부터 프론트엔드의 React `useStream` 훅까지, 실시간 스트리밍을 구현하는 전체 파이프라인을 학습합니다.

스트리밍이 중요한 이유는 단순히 UX를 넘어서, 에이전트의 _투명성_에 있습니다. 에이전트가 어떤 도구를 호출하고 있는지, 어떤 단계를 실행 중인지를 실시간으로 보여주면 사용자의 신뢰가 높아집니다. LangGraph SDK는 `StreamEvent` 프로토콜을 통해 토큰 스트리밍뿐 아니라 도구 호출 시작/완료, 노드 전환 등의 내부 이벤트도 세밀하게 전달할 수 있습니다.

#learning-header()
LLM 응답을 실시간으로 스트리밍하여 사용자에게 전달하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- LangChain SDK의 스트리밍 기초(`.stream()`, `.astream_events()`)를 이해한다
- `useStream` React 훅의 구조와 사용법을 안다
- `StreamEvent` 프로토콜을 이해한다
- Python SDK로 실시간 스트리밍을 소비하는 방법을 익힌다
- 에이전트 상태 실시간 표시 패턴을 안다

== 12.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-4.1",
)

print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 12.2 Python SDK 스트리밍 기초

`.stream()` 메서드는 모델 응답을 토큰 단위로 실시간 전달합니다. 사용자는 전체 응답이 완성되기 전에 부분 결과를 볼 수 있습니다. 내부적으로 `.stream()`은 LLM API의 스트리밍 응답을 파이썬 제너레이터로 감싸서, `for chunk in model.stream(...)` 형태로 각 토큰 청크를 순회할 수 있게 합니다.

#align(center)[#image("../../assets/diagrams/png/frontend_streaming_flow.png", width: 86%, height: 96mm, fit: "contain")]

이 그림처럼 프론트엔드 스트리밍은 단순히 _토큰을 받는 기능_ 이 아니라, 스레드 재개, 상태 동기화, 커스텀 이벤트 수신까지 포함하는 _세션 프로토콜_ 에 가깝습니다.

`.stream()`이 최종 출력만 토큰 단위로 전달한다면, `.astream_events()`는 에이전트 실행의 _모든 내부 이벤트_를 제공합니다.

== 12.3 astream_events()

`.astream_events()`는 비동기 방식으로 _모든 내부 이벤트_를 스트리밍합니다. 모델 호출, 도구 실행, 체인 단계 등을 세밀하게 추적할 수 있습니다. 각 이벤트는 `event`(이벤트 타입), `data`(이벤트 데이터), `metadata`(실행 컨텍스트) 필드를 포함하는 딕셔너리입니다.

=== 주요 이벤트 타입

#align(center)[#image("../../assets/diagrams/png/frontend_streaming_events.png", width: 68%, height: 122mm, fit: "contain")]

이 다이어그램은 _사용자 입력 → `useStream` → LangGraph 서버 → 에이전트 런타임 → 이벤트 반환_ 의 왕복 흐름을 보여줍니다. 실무에서는 토큰 자체보다도 `on_tool_start`, `on_tool_end` 같은 _상태 이벤트_ 가 중요합니다. 사용자는 "지금 답을 쓰는 중인지", "검색 도구를 실행 중인지"를 구분해 볼 수 있어야 체감 대기 시간이 크게 줄어듭니다.

#tip-box[_이벤트 읽는 법_: *start 계열*은 UI 상태 전환, *stream 계열*은 점진적 렌더링, *end 계열*은 메시지 확정 저장에 연결하면 구현이 깔끔합니다.]

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[이벤트],
  text(weight: "bold")[설명],
  [`on_chat_model_stream`],
  [모델 토큰 스트리밍],
  [`on_chat_model_start`],
  [모델 호출 시작],
  [`on_chat_model_end`],
  [모델 호출 완료],
  [`on_tool_start`],
  [도구 실행 시작],
  [`on_tool_end`],
  [도구 실행 완료],
)

#code-block(`````python
import asyncio

async def stream_events_demo():
    """astream_events()로 이벤트 스트리밍 예시"""
    print("이벤트 스트리밍:")
    print("-" * 40)
    async for event in model.astream_events(
        "파이썬의 장점 2가지",
        version="v2",
    ):
        kind = event["event"]
        if kind == "on_chat_model_stream":
            content = event["data"]["chunk"].content
            if content:
                print(content, end="", flush=True)
        elif kind == "on_chat_model_start":
            print(f"[모델 호출 시작]")
        elif kind == "on_chat_model_end":
            print(f"\n[모델 호출 완료]")

await stream_events_demo()
`````)
#output-block(`````
이벤트 스트리밍:
----------------------------------------
[모델 호출 시작]

파
이
썬
의
 장
점
 두
 가지
는
 다음
과
 같습니다
.


1
.
 **
코
드
가
 간
결
하고
 읽
기
... (truncated)
`````)

백엔드의 스트리밍 API를 살펴보았으니, 이제 프론트엔드에서 이 스트림을 소비하는 방법을 알아보겠습니다. `useStream` React 훅은 백엔드의 복잡한 스트리밍 프로토콜을 추상화하여, 프론트엔드 개발자가 몇 줄의 코드로 실시간 채팅 UI를 구축할 수 있게 합니다.

== 12.4 useStream React 훅

`useStream`은 LangGraph SDK(`@langchain/langgraph-sdk/react`)에서 제공하는 React 훅으로, LangGraph 서버와의 스트리밍 통신을 간편하게 처리합니다. 이 훅은 스레드 생성, 메시지 전송, 스트림 수신, 에러 처리를 모두 내부적으로 관리합니다.

#note-box[_이벤트 타입별 사용 기준_
- `on_chat_model_stream` — 사용자에게 바로 보여 줄 텍스트 토큰
- `on_tool_start` / `on_tool_end` — 로딩 스피너, 단계 표시, 로그 패널
- 커스텀 이벤트 — 진행률, 분석 중간 결과, 멀티에이전트 상태 같은 앱 전용 UI]

=== 기본 사용법

#code-block(`````tsx
import { useStream } from "@langchain/langgraph-sdk/react";

function Chat() {
  const stream = useStream({
    assistantId: "agent",
    apiUrl: "http://localhost:2024",
  });

  const handleSubmit = (message: string) => {
    stream.submit({
      messages: [{ content: message, type: "human" }],
    });
  };

  return (
    <div>
      {stream.messages.map((message, idx) => (
        <div key={message.id ?? idx}>
          {message.type}: {message.content}
        </div>
      ))}
      {stream.isLoading && <div>Loading...</div>}
      {stream.error && <div>Error: {stream.error.message}</div>}
    </div>
  );
}
`````)

=== 주요 반환값

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[속성],
  text(weight: "bold")[타입],
  text(weight: "bold")[설명],
  [`messages`],
  [`Message[]`],
  [현재 스레드의 전체 메시지],
  [`isLoading`],
  [`boolean`],
  [스트림 진행 여부],
  [`error`],
  [`Error \\],
  [null`],
  [에러 객체],
  [`interrupt`],
  [`Interrupt`],
  [중단 요청 (HITL)],
  [`submit()`],
  [`function`],
  [메시지 전송],
  [`stop()`],
  [`function`],
  [스트림 중단],
)

== 12.5 useStream 설정 옵션

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[필수],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`assistantId`],
  [O],
  [—],
  [에이전트 식별자 (배포 대시보드에서 확인)],
  [`apiUrl`],
  [—],
  [`localhost:2024`],
  [에이전트 서버 URL],
  [`apiKey`],
  [—],
  [—],
  [배포된 에이전트 인증 토큰],
  [`threadId`],
  [—],
  [—],
  [기존 대화 스레드에 연결],
  [`onThreadId`],
  [—],
  [—],
  [스레드 생성 시 콜백],
  [`reconnectOnMount`],
  [—],
  [`false`],
  [컴포넌트 마운트 시 진행 중 스트림 재연결],
  [`onCustomEvent`],
  [—],
  [—],
  [커스텀 이벤트 핸들러],
  [`onUpdateEvent`],
  [—],
  [—],
  [상태 업데이트 핸들러],
  [`onMetadataEvent`],
  [—],
  [—],
  [메타데이터 이벤트 핸들러],
  [`messagesKey`],
  [—],
  [`"messages"`],
  [메시지를 담는 상태 키],
  [`throttle`],
  [—],
  [`true`],
  [상태 업데이트 배치 처리],
  [`initialValues`],
  [—],
  [—],
  [캐시된 초기 상태],
)

== 12.6 스레드 관리와 재연결

=== 스레드 ID 관리

`threadId`를 관리하면 대화를 지속하거나 이전 대화를 불러올 수 있습니다.

#code-block(`````tsx
const [threadId, setThreadId] = useState<string | null>(null);

const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  threadId,
  onThreadId: setThreadId,
});

// threadId를 URL 파라미터나 localStorage에 저장하여 지속성 확보
`````)

=== 페이지 새로고침 후 재연결

`reconnectOnMount`를 활성화하면 페이지 새로고침 후에도 진행 중이던 스트림에 자동 재연결됩니다.

#code-block(`````tsx
const stream = useStream({
  apiUrl: "http://localhost:2024",
  assistantId: "agent",
  reconnectOnMount: true, // sessionStorage 사용
});

// 커스텀 스토리지 사용
const stream = useStream({
  reconnectOnMount: () => window.localStorage,
});
`````)

== 12.7 브랜칭과 메시지 편집

브랜칭을 사용하면 대화 히스토리의 특정 지점에서 _대체 경로_를 만들 수 있습니다. 이 기능의 기반은 LangGraph의 _체크포인트_ 시스템입니다. 매 단계마다 상태가 자동으로 저장되므로, 이전 체크포인트로 돌아가 새로운 입력으로 분기를 생성할 수 있습니다. 메시지를 편집하거나 AI 응답을 재생성할 때 유용합니다.

#code-block(`````tsx
{stream.messages.map((message) => {
  const meta = stream.getMessagesMetadata(message);
  const parentCheckpoint = meta?.firstSeenState?.parent_checkpoint;

  return (
    <div key={message.id}>
      {message.content}

      {/* 사용자 메시지 편집 */}
      {message.type === "human" && (
        <button onClick={() => {
          const newContent = prompt("Edit:", message.content);
          if (newContent) {
            stream.submit(
              { messages: [{ type: "human", content: newContent }] },
              { checkpoint: parentCheckpoint }
            );
          }
        }}>
          Edit
        </button>
      )}

      {/* AI 응답 재생성 */}
      {message.type === "ai" && (
        <button onClick={() =>
          stream.submit(undefined, { checkpoint: parentCheckpoint })
        }>
          Regenerate
        </button>
      )}
    </div>
  );
})}
`````)

핵심: `checkpoint` 파라미터로 특정 시점의 상태로 돌아가 새로운 분기를 생성합니다.

== 12.8 커스텀 스트리밍 이벤트

LangGraph의 기본 이벤트(토큰 스트리밍, 도구 호출 등) 외에도, 에이전트에서 _커스텀 데이터_를 클라이언트로 스트리밍할 수 있습니다. 도구 실행 중 진행률 표시, 중간 분석 결과 전달, 단계별 상태 업데이트 등 애플리케이션 고유의 데이터를 실시간으로 전달할 때 유용합니다. 서버 측에서는 `config.writer()` 패턴을 사용하고, 클라이언트 측에서는 `onCustomEvent` 콜백으로 수신합니다.

#code-block(`````python
# 커스텀 스트리밍 이벤트 — Python writer 패턴
print("커스텀 스트리밍 이벤트 패턴 (Python 서버 측):")
print("=" * 50)
print("""
from langchain.tools import tool
from langchain.agents.types import ToolRuntime

@tool
async def analyze_data(
    data_source: str, *, config: ToolRuntime
) -> str:
    \"\"\"데이터를 분석합니다.\"\"\"
    if config.writer:
        # 진행 상황을 클라이언트에 스트리밍
        config.writer({
            "type": "progress",
            "message": "데이터 로딩 중...",
            "progress": 25,
        })
        # ... 처리 ...
        config.writer({
            "type": "progress",
            "message": "분석 완료!",
            "progress": 100,
        })
    return '{"result": "분석 완료"}'
""")
print("클라이언트(React) 측: onCustomEvent 콜백으로 수신")
print('  onCustomEvent: (data) => setProgress(data.progress)')
`````)
#output-block(`````
커스텀 스트리밍 이벤트 패턴 (Python 서버 측):
==================================================

from langchain.tools import tool
from langchain.agents.types import ToolRuntime

@tool
async def analyze_data(
    data_source: str, *, config: ToolRuntime
) -> str:
    """데이터를 분석합니다."""
    if config.writer:
        # 진행 상황을 클라이언트에 스트리밍
        config.writer({
            "type": "progress",
            "message": "데이터 로딩 중...",
            "progress": 25,
        })
        # ... 처리 ...
        config.writer({
            "type": "progress",
            "message": "분석 완료!",
            "progress": 100,
        })
    return '{"result": "분석 완료"}'

클라이언트(React) 측: onCustomEvent 콜백으로 수신
  onCustomEvent: (data) => setProgress(data.progress)
`````)

== 12.9 멀티 에이전트 스트리밍

8장에서 학습한 멀티 에이전트 패턴과 스트리밍을 결합하면, 여러 에이전트가 협업하는 과정을 사용자에게 실시간으로 보여줄 수 있습니다. 여러 에이전트가 협업하는 환경에서는 각 에이전트의 메시지를 _구분하여 표시_해야 합니다. 메타데이터의 `langgraph_node`를 사용하여 메시지 출처를 식별합니다.

#tip-box[멀티 에이전트 스트리밍에서는 각 에이전트에 고유한 색상과 레이블을 부여하여 시각적으로 구분하는 것이 좋습니다. 사용자가 "지금 리서치 에이전트가 검색 중"인지 "작성 에이전트가 글을 쓰는 중"인지 한눈에 파악할 수 있으면 에이전트 시스템에 대한 신뢰도가 크게 높아집니다.]

#code-block(`````tsx
// 노드별 설정
const NODE_CONFIG: Record<string, { label: string; color: string }> = {
  researcher: { label: "Research Agent", color: "blue" },
  writer:     { label: "Writing Agent",  color: "green" },
  reviewer:   { label: "Review Agent",   color: "purple" },
};

// 메시지 렌더링
function AgentMessage({ message, stream }) {
  const metadata = stream.getMessagesMetadata?.(message);
  const nodeName = metadata?.streamMetadata?.langgraph_node;
  const config = NODE_CONFIG[nodeName];

  return (
    <div className={`bg-${config?.color}-950/30 p-4 rounded-lg`}>
      <div className={`text-${config?.color}-400 text-sm font-bold`}>
        {config?.label ?? "Agent"}
      </div>
      <div>{message.content}</div>
    </div>
  );
}
`````)

=== 이벤트 콜백 정리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[콜백],
  text(weight: "bold")[용도],
  text(weight: "bold")[스트림 모드],
  [`onUpdateEvent`],
  [그래프 단계 후 상태 업데이트],
  [`updates`],
  [`onCustomEvent`],
  [에이전트의 커스텀 이벤트],
  [`custom`],
  [`onMetadataEvent`],
  [실행 및 스레드 메타데이터],
  [`metadata`],
  [`onError`],
  [에러 처리],
  [—],
  [`onFinish`],
  [스트림 완료],
  [—],
)

#chapter-summary-header()

이 노트북에서 배운 내용:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_SDK 스트리밍_],
  [`.stream()`으로 토큰 단위 실시간 응답을 받습니다],
  [_astream_events_],
  [비동기 이벤트 스트리밍으로 모델/도구 호출을 세밀하게 추적합니다],
  [_useStream_],
  [React 훅으로 LangGraph 서버와 스트리밍 통신을 간편하게 처리합니다],
  [_스레드 관리_],
  [`threadId`와 `reconnectOnMount`로 대화 지속성을 확보합니다],
  [_브랜칭_],
  [`checkpoint` 기반으로 대화의 대체 경로를 생성합니다],
  [_커스텀 이벤트_],
  [`writer` 패턴으로 진행 상황 등 커스텀 데이터를 스트리밍합니다],
  [_멀티에이전트_],
  [`langgraph_node` 메타데이터로 에이전트별 메시지를 구분 표시합니다],
)

스트리밍을 통해 에이전트의 실행 과정을 사용자에게 투명하게 전달하는 방법을 배웠습니다. 그러나 에이전트가 사용자에게 직접 노출되는 만큼, 안전하지 않은 입력이나 부적절한 출력에 대한 방어가 필수적입니다. 다음 장에서는 에이전트의 입출력 경계에 _가드레일_을 설치하여 PII 유출, 프롬프트 인젝션, 위험한 도구 실행 등을 방지하는 방법을 학습합니다.

#references-box[
- #link("../docs/langchain/08-streaming.md")[Streaming]
- #link("../docs/langchain/28-ui.md")[UI (Agent Chat UI & useStream)]
]
#chapter-end()
