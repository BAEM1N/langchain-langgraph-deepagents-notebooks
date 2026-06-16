// Auto-generated from 12_frontend_streaming.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(12, "프론트엔드 스트리밍")

== 학습 목표
LLM 응답을 실시간으로 스트리밍하여 사용자에게 전달하는 방법을 알아봅니다.

이 노트북에서 다루는 내용:
- LangChain SDK의 스트리밍 기초(`.stream()`, `.astream_events()`)를 이해한다
- `useStream` React 훅의 구조와 사용법을 안다
- `StreamEvent` 프로토콜을 이해한다
- Python SDK로 실시간 스트리밍을 소비하는 방법을 익힌다
- 에이전트 상태 실시간 표시 패턴을 안다
- Headless Tools와 Custom Stream Channels로 UI 확장 지점을 구분한다

== 12.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

print("환경 준비 완료.")
`````)

== 12.2 Python SDK 스트리밍 기초

`.stream()` 메서드는 모델 응답을 토큰 단위로 실시간 전달합니다. 전체 응답이 완성되기 전에 부분 결과를 볼 수 있습니다.

== 12.3 astream_events()

`.astream_events()`는 비동기 방식으로 _모든 내부 이벤트_를 스트리밍합니다. 모델 호출, 도구 실행, 체인 단계 등을 세밀하게 추적할 수 있습니다.

=== 주요 이벤트 타입

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

== 12.4 Event Streaming v3 — LangChain 1.3+

LangChain 1.3부터 agent 실행에는 `stream_events(..., version="v3")`를 우선 검토합니다. 기존 `.stream()`은 토큰을 직접 받는 저수준 API이고, v3 event streaming은 _메시지, 도구 호출, 상태, 최종 출력_을 projection 단위로 나누어 UI 코드가 덜 복잡해집니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Projection],
  text(weight: "bold")[의미],
  text(weight: "bold")[UI 매핑],
  [`stream.messages`],
  [모델 메시지와 토큰 delta],
  [채팅 버블],
  [`stream.tool_calls`],
  [도구 시작·출력·완료·오류],
  [도구 타임라인],
  [`stream.values`],
  [agent state snapshot],
  [디버그 패널],
  [`stream.output`],
  [최종 state],
  [저장/후처리],
)

이 API는 LangGraph의 v3 event streaming 위에 올라가므로 LangGraph/Deep Agents와 같은 UI 패턴을 공유합니다.

#code-block(`````python
# Event Streaming v3 패턴 — 설치 버전이 낮아도 안전하게 읽을 수 있는 예시 출력
from importlib.metadata import version

print("설치된 langchain:", version("langchain"))
print("필요 버전: langchain>=1.3.0")

example = r'''
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """도시 날씨를 조회합니다."""
    return f"{city}: 맑음"

agent = create_agent(model="openai:gpt-5.4", tools=[get_weather])
stream = agent.stream_events(
    {"messages": [{"role": "user", "content": "서울 날씨 알려줘"}]},
    version="v3",
)

for message in stream.messages:
    for token in message.text:
        print(token, end="", flush=True)

final_state = stream.output
'''
print(example)
`````)

== 12.5 useStream React 훅

`useStream`은 LangGraph SDK에서 제공하는 React 훅으로, LangGraph 서버와의 스트리밍 통신을 간편하게 처리합니다.

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

== 12.6 useStream 설정 옵션

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

== 12.7 스레드 관리와 재연결

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

== 12.8 브랜칭과 메시지 편집

브랜칭을 쓰면 대화 히스토리의 특정 지점에서 _대체 경로_를 만들 수 있습니다. 메시지를 편집하거나 AI 응답을 재생성할 때 유용합니다.

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

== 12.9 커스텀 스트리밍 이벤트

에이전트에서 _커스텀 데이터_를 클라이언트로 스트리밍할 수 있습니다. 진행 상황, 중간 결과 등을 실시간으로 전달할 때 유용합니다.

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

== 12.10 멀티 에이전트 스트리밍

여러 에이전트가 협업하는 환경에서는 각 에이전트의 메시지를 _구분하여 표시_해야 합니다. 메타데이터의 `langgraph_node`로 메시지 출처를 식별합니다.

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

== 12.11 Headless Tools와 Custom Stream Channels

최신 LangChain/LangGraph UI 문서는 프론트엔드 확장을 두 축으로 나눕니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[언제 쓰나],
  text(weight: "bold")[프론트엔드 연결],
  [_Headless Tools_],
  [서버에는 tool schema만 두고, 실제 실행은 브라우저/디바이스 API에서 해야 할 때],
  [`useStream({ tools: [...] })`, `stream.toolCalls`],
  [_Custom Stream Channels_],
  [모델 토큰이 아닌 별도 진행률·상태·차트 데이터를 흘려보낼 때],
  [`useExtension`, `useChannel`],
)

Headless tool은 “도구 실행을 서버가 아니라 클라이언트에서 하게 할까”의 문제입니다. 서버 tool은 `interrupt()`로 실행을 프론트엔드에 넘기고, 브라우저 구현은 같은 tool 이름과 schema를 mirror한 뒤 `.implement(...)`로 붙입니다.

#code-block(`````tsx
const stream = useStream<AgentState>({
  apiUrl: AGENT_URL,
  assistantId: "headless_tools",
  tools: [memoryPut, memoryGet, geolocationGet],
});
`````)

Custom channel은 “기본 메시지 스트림 밖의 데이터를 어디로 보낼까”의 문제입니다. 최신값만 필요하면 `useExtension("channel-name")`, 로그/히스토리가 필요하면 `useChannel(stream, ["custom:channel-name"])`로 분리합니다.

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
  [_Event Streaming v3_],
  [`stream_events(..., version="v3")`로 메시지·도구·상태 projection을 분리합니다],
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
  [_Headless Tools_],
  [`useStream({ tools })`로 브라우저 구현을 연결하고 `stream.toolCalls`로 상태를 표시합니다],
  [_Custom Channels_],
  [`useChannel`로 진행률·차트 등 별도 스트림을 수신합니다],
)


#references-box[
- #link("../docs/langchain/08-streaming.md")[Streaming] — useStream 정식 문서
- #link("../docs/langchain/28-ui.md")[UI (Agent Chat UI & useStream)]
- #link("../docs/langchain/28-ui.md")[Headless Tools / Custom Stream Channels]
- #link("../docs/langchain/08-streaming.md")[LangChain Event Streaming v3]
]
#chapter-end()
