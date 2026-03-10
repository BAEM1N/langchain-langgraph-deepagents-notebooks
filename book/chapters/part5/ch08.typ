// Auto-generated from 08_voice_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "보이스 에이전트", subtitle: "STT/Agent/TTS 파이프라인")

이전 장까지의 에이전트는 모두 텍스트 인터페이스를 사용했습니다. 이 장에서는 인간에게 가장 자연스러운 소통 수단인 _음성_으로 에이전트와 상호작용하는 방법을 다룹니다. 음성 입력을 텍스트로 변환(STT)하고, LangChain 에이전트가 처리한 뒤, 텍스트를 음성으로 합성(TTS)하여 실시간으로 돌려주는 보이스 에이전트를 구축합니다.

이 아키텍처는 _Sandwich 패턴_ (STT → Agent → TTS)으로, 각 계층이 스트리밍으로 연결되어 sub-700ms 레이턴시를 목표로 합니다. 스트리밍이 핵심입니다 — 각 레이어가 이전 레이어의 완전한 출력을 기다리지 않고, 부분 결과가 생성되는 즉시 다음 레이어로 전달합니다. WebSocket 기반의 양방향 실시간 통신으로 이를 구현합니다.

보이스 에이전트는 텍스트 기반 에이전트와 동일한 추론 능력을 유지하면서 _음성이라는 가장 자연스러운 인터페이스_를 제공합니다. 이전 장까지의 에이전트와 근본적으로 다른 점은 _실시간성_에 대한 요구입니다. 텍스트 채팅에서는 몇 초의 지연이 허용되지만, 음성 대화에서 700ms 이상의 침묵은 사용자에게 "끊어진 대화"로 느껴집니다.

=== 핵심 설계 원칙

Sandwich 아키텍처의 핵심은 _스트리밍 체이닝_입니다. 각 레이어가 이전 레이어의 완전한 출력을 기다리지 않고, 부분 결과가 생성되는 즉시 다음 레이어로 전달합니다:

- _STT_: 부분 전사(partial transcript)를 실시간으로 생성하고, 발화 완료(end-of-speech) 감지 시 최종 전사를 emit
- _Agent_: `astream()`을 통해 토큰 단위로 응답을 스트리밍 — 전체 응답 생성 완료를 기다리지 않음
- _TTS_: WebSocket 기반으로 텍스트 청크가 도착하는 즉시 오디오 합성 시작

이 구조 덕분에 전체 파이프라인의 지연 시간은 각 단계의 합이 아닌, _각 단계의 첫 출력까지의 시간 합_으로 줄어듭니다.

#learning-header()
이 노트북을 완료하면 다음을 수행할 수 있습니다:

+ _Sandwich 아키텍처_ — STT -\> Agent -\> TTS 파이프라인의 구조와 데이터 흐름을 설명할 수 있다
+ _아키텍처 비교_ — Sandwich 방식과 Speech-to-Speech(S2S) 방식의 장단점을 비교할 수 있다
+ _STT 단계_ — AssemblyAI 실시간 전사의 Producer-Consumer 패턴을 이해할 수 있다
+ _에이전트 단계_ — LangChain `create_agent`로 스트리밍 응답을 생성하는 에이전트를 구축할 수 있다
+ _TTS 단계_ — Cartesia WebSocket 기반 스트리밍 음성 합성의 동작 원리를 이해할 수 있다
+ _RunnableGenerator_ — 비동기 제너레이터 체이닝으로 파이프라인을 조합할 수 있다
+ _성능 최적화_ — 레이턴시 목표 달성을 위한 각 단계별 최적화 기법을 이해할 수 있다

#note-box[_참고_: STT(AssemblyAI)와 TTS(Cartesia)는 외부 유료 서비스입니다. 해당 셀은 개념 설명용 마크다운으로 제공되며, _에이전트 생성 부분만 실제 실행 가능한 코드_입니다.]

== 8.1 환경 설정

보이스 에이전트에 필요한 패키지와 각 역할입니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[패키지],
  text(weight: "bold")[역할],
  [`langchain`, `langchain-openai`],
  [에이전트 생성 및 LLM 연결],
  [`assemblyai`],
  [실시간 음성-텍스트 변환 (STT)],
  [`cartesia`],
  [저지연 텍스트-음성 합성 (TTS)],
  [`websockets`],
  [실시간 양방향 통신 서버],
  [`pyaudio`],
  [마이크 오디오 캡처 (선택)],
)

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 8.2 보이스 에이전트 아키텍처 개요

보이스 에이전트는 3-레이어 파이프라인으로 구성됩니다:

#align(center)[#image("../../assets/diagrams/png/voice_streaming_pipeline.png", width: 92%, height: 82mm, fit: "contain")]

이 파이프라인은 세 단계가 _겹쳐서_ 실행될 때 비로소 자연스럽게 동작합니다. STT가 문장을 완전히 마치기 전에도 부분 전사를 넘기고, Agent는 첫 토큰이 나오자마자 TTS로 전달하여 전체 체감 지연을 줄입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[레이어],
  text(weight: "bold")[제공자],
  text(weight: "bold")[역할],
  [_STT_],
  [AssemblyAI],
  [사용자 음성을 텍스트로 변환],
  [_Agent_],
  [LangChain],
  [텍스트 쿼리를 처리하고 응답 생성],
  [_TTS_],
  [Cartesia],
  [에이전트의 텍스트 응답을 음성으로 변환],
)

각 레이어가 _스트리밍_으로 연결되어, 이전 단계의 완전한 출력을 기다리지 않고 부분 결과를 즉시 다음 단계로 전달합니다:

+ _STT_ — 부분 전사 결과를 스트리밍 (발화 완료 감지 시 최종 전사)
+ _Agent_ — 토큰 단위 스트리밍 응답 생성 (`astream()`)
+ _TTS_ — 전체 응답 완료 전에 음성 합성 시작 (WebSocket 기반)

=== 스트리밍이 중요한 이유

스트리밍 없이 동기적으로 처리하면, 각 단계가 완전히 끝나야 다음 단계가 시작됩니다. 예를 들어 에이전트가 200 토큰 응답을 생성하는 데 3초가 걸린다면, TTS는 3초 후에야 시작됩니다. 반면 스트리밍에서는 에이전트의 _첫 토큰이 나오는 즉시_ TTS가 음성 합성을 시작하므로, 사용자는 에이전트가 아직 응답을 생성하는 동안에도 이미 음성을 듣기 시작합니다.

== 8.3 아키텍처 비교표

음성 에이전트를 구축하는 두 가지 접근법을 비교합니다.

=== Sandwich 아키텍처 (STT -\\> Agent -\\> TTS)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_장점_],
  [각 컴포넌트 독립 교체 가능, 텍스트 기반 도구 활용 용이, 디버깅 편리 (중간 텍스트 로깅)],
  [_단점_],
  [3단계 직렬 처리로 레이턴시 누적, 감정/억양 등 비언어 정보 손실],
  [_적합 상황_],
  [도구 호출이 많은 복잡한 에이전트, 다국어 지원 필요 시],
)

=== Speech-to-Speech (S2S)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_장점_],
  [낮은 레이턴시, 음성 특성(감정, 강세) 보존, 자연스러운 대화],
  [_단점_],
  [도구 호출 통합 어려움, 모델 선택지 제한, 디버깅 어려움],
  [_적합 상황_],
  [단순 대화형 인터페이스, 감정 인식이 중요한 경우],
)

#note-box[이 노트북에서는 _도구 호출이 가능한 Sandwich 아키텍처_에 집중합니다.]

아키텍처의 전체 구조를 이해했으니, 각 레이어를 하나씩 구현합니다. 첫 번째는 사용자 음성을 텍스트로 변환하는 STT 단계입니다. 이 단계의 성능이 전체 파이프라인의 시작점을 결정합니다.

== 8.4 STT 단계 -- AssemblyAI 실시간 전사

#tip-box[_이 셀은 AssemblyAI API 키가 필요합니다._ 개념 이해를 위한 참조 코드입니다.]

AssemblyAI의 `RealtimeTranscriber`는 _Producer-Consumer 패턴_으로 동작합니다:

- _Producer_: 마이크에서 캡처한 오디오 청크를 WebSocket으로 전송
- _Consumer_: 부분 전사(partial) 및 최종 전사(final) 결과를 콜백으로 수신

두 작업이 _동시에_ 진행되므로, 음성 전송 중에도 이전 발화의 전사 결과를 받을 수 있습니다.

=== 전사 결과의 두 가지 유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[유형],
  text(weight: "bold")[클래스],
  text(weight: "bold")[설명],
  [_Partial_],
  [`RealtimeTranscript`],
  [아직 발화 중인 단어들의 임시 전사. 사용자가 말하는 동안 실시간으로 업데이트됨],
  [_Final_],
  [`RealtimeFinalTranscript`],
  [발화 종료(엔드포인팅)가 감지된 후의 확정 전사. 이 결과만 에이전트로 전달],
)

AssemblyAI의 내장 VAD(Voice Activity Detection)가 발화 종료 시점을 자동으로 감지하므로, 별도의 무음 감지 로직이 필요하지 않습니다.

#code-block(`````python
import assemblyai as aai

aai.settings.api_key = "your-assemblyai-key"

transcriber = aai.RealtimeTranscriber(
    sample_rate=16000,
    encoding=aai.AudioEncoding.pcm_s16le,
    on_data=on_transcription_data,
    on_error=on_transcription_error,
)

def on_transcription_data(transcript: aai.RealtimeTranscript):
    if isinstance(transcript, aai.RealtimeFinalTranscript):
        process_user_input(transcript.text)

def on_transcription_error(error: aai.RealtimeError):
    print(f"Transcription error: {error}")

transcriber.connect()
`````)

=== 마이크 오디오 캡처

PCM 16-bit, 16kHz 단일 채널 오디오를 캡처하여 실시간으로 전사기에 전송합니다:

#code-block(`````python
import pyaudio

audio = pyaudio.PyAudio()
stream = audio.open(
    format=pyaudio.paInt16,
    channels=1, rate=16000,
    input=True, frames_per_buffer=1024,
)

while True:
    data = stream.read(1024)
    transcriber.stream(data)
`````)

STT 단계에서 텍스트가 생성되면, 이제 에이전트가 이 텍스트를 처리하여 응답을 생성합니다. 에이전트 단계는 Sandwich 아키텍처의 중심부이며, 기존 텍스트 기반 에이전트를 _그대로_ 재사용할 수 있다는 것이 핵심 장점입니다.

== 8.5 에이전트 단계 -- LangChain 에이전트 활용

파이프라인의 핵심인 에이전트 단계입니다.

#warning-box[보이스 에이전트의 시스템 프롬프트에서 _응답 길이 제한_은 매우 중요합니다. 텍스트 채팅과 달리 음성에서는 긴 응답이 사용자에게 큰 부담입니다. "1~2문장으로 간결하게", "목록 대신 핵심만", "마크다운 서식 사용 금지" 등의 지시를 반드시 포함하세요. 또한 괄호, URL, 특수문자 등 _음성으로 자연스럽게 읽을 수 없는 표현_을 피하도록 지시해야 합니다.] `create_agent`로 생성한 에이전트는 텍스트 입력을 받아 도구 호출과 추론을 수행한 뒤 텍스트 응답을 스트리밍합니다.

보이스 에이전트용 시스템 프롬프트의 핵심은 _간결하고 대화체인 응답_을 유도하는 것입니다. 음성 출력은 텍스트와 달리 긴 응답이 사용자에게 부담이 되므로, 1~2문장 이내의 짧은 응답을 생성하도록 지시합니다.

=== 비동기 스트리밍의 역할

에이전트의 `astream()` 메서드는 응답 토큰을 생성되는 즉시 yield합니다. 이것이 보이스 에이전트에서 특히 중요한 이유:

- _TTS 조기 시작_: 전체 응답 완료를 기다리지 않고 첫 토큰부터 음성 합성 가능
- _체감 지연 감소_: 사용자가 에이전트의 응답을 더 빨리 듣기 시작
- _파이프라인 효율성_: Agent와 TTS가 동시에 실행되어 총 처리 시간 단축

#code-block(`````python
from langchain.agents import create_agent

def search_tool(query: str) -> str:
    """웹에서 최신 정보를 검색합니다."""
    return f"검색 결과: {query}"

def calendar_tool(action: str, details: str) -> str:
    """캘린더 이벤트를 관리합니다."""
    return f"캘린더 {action}: {details}"
`````)

#code-block(`````python
agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calendar_tool],
    system_prompt=(
        "당신은 유용한 음성 어시스턴트입니다. "
        "응답을 간결하고 대화체로 유지하세요."
    ),
)
`````)

=== 비동기 스트리밍 응답 생성

`astream()`은 에이전트의 응답 토큰을 생성되는 즉시 yield합니다. TTS 단계가 전체 응답 완료를 기다리지 않고 음성 합성을 시작할 수 있게 합니다.

LangChain의 스트리밍은 크게 두 가지 방식을 제공합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[메서드],
  text(weight: "bold")[설명],
  [`astream()`],
  [에이전트 실행의 각 스텝별 출력을 스트리밍. 메시지, 도구 호출 결과 등을 포함],
  [`astream_events()`],
  [더 세분화된 이벤트 단위 스트리밍. 개별 토큰, LLM 시작/종료 등 상세 이벤트 제공],
)

보이스 에이전트에서는 `astream()`으로 메시지 청크를 수신하고, 각 청크의 `content`를 추출하여 TTS로 전달합니다.

#code-block(`````python
async def stream_agent_response(user_text: str):
    """에이전트 응답 토큰을 하나씩 스트리밍합니다."""
    async for chunk in agent.astream(
        {"messages": [{"role": "user",
                        "content": user_text}]}
    ):
        if "messages" in chunk:
            for msg in chunk["messages"]:
                if hasattr(msg, "content") and msg.content:
                    yield msg.content
`````)

에이전트가 텍스트 응답을 스트리밍하면, 마지막 레이어인 TTS가 이를 음성으로 변환합니다. TTS 단계의 설계 목표는 _첫 오디오 출력까지의 시간을 최소화_하는 것입니다.

== 8.6 TTS 단계 -- Cartesia 스트리밍 음성 합성

#tip-box[_이 셀은 Cartesia API 키가 필요합니다._ 개념 이해를 위한 참조 코드입니다.]

Cartesia는 WebSocket 기반 저지연 TTS를 제공합니다. 에이전트의 텍스트 스트림을 받아 _부분 텍스트마다 즉시 오디오 청크를 생성_합니다.

=== Cartesia TTS의 동작 방식

+ _WebSocket 연결_: `AsyncCartesia` 클라이언트로 WebSocket 세션을 열어 지속적인 연결 유지
+ _텍스트 청크 전송_: 에이전트가 생성한 토큰/문장 단위로 텍스트를 전송
+ _오디오 청크 수신_: 각 텍스트 청크에 대해 즉시 PCM 오디오 바이트를 수신
+ _클라이언트 전달_: 수신된 오디오 바이트를 WebSocket으로 클라이언트에 스트리밍

WebSocket 기반이므로 HTTP 요청/응답 오버헤드 없이 양방향 실시간 통신이 가능합니다. `sonic-2` 모델은 자연스러운 음성과 낮은 지연 시간을 동시에 제공합니다.

#code-block(`````python
import cartesia

cartesia_client = cartesia.AsyncCartesia(
    api_key="your-cartesia-key"
)

async def text_to_speech_stream(text_stream):
    ws = await cartesia_client.tts.websocket()
    async for text_chunk in text_stream:
        audio_chunks = ws.send(
            model_id="sonic-2",
            transcript=text_chunk,
            voice_id="your-voice-id",
            stream=True,
            output_format={
                "container": "raw",
                "encoding": "pcm_s16le",
                "sample_rate": 24000,
            },
        )
        async for audio in audio_chunks:
            yield audio["audio"]
    await ws.close()
`````)

세 개의 레이어(STT, Agent, TTS)가 각각 완성되었습니다. 이제 이들을 하나의 스트리밍 파이프라인으로 연결하는 것이 남았습니다. 핵심 과제는 비동기 스트림 간의 _데이터 흐름을 자연스럽게 체이닝_하는 것입니다.

== 8.7 파이프라인 조합 -- RunnableGenerator

LangChain의 `RunnableGenerator`를 사용하면 비동기 제너레이터를 _Runnable 파이프라인_에 통합할 수 있습니다.

#tip-box[`RunnableGenerator`는 기존 비동기 제너레이터 함수를 LangChain 생태계에 통합하는 브릿지 역할을 합니다. STT나 TTS와 같이 LangChain 외부의 스트리밍 서비스를 에이전트 파이프라인에 연결할 때 특히 유용합니다. `|` 연산자로 체이닝이 가능해지므로, 복잡한 비동기 로직을 선언적으로 표현할 수 있습니다.] 이를 통해 STT 출력 -\> Agent 처리 -\> TTS 입력이라는 전체 데이터 흐름을 하나의 파이프라인으로 구성할 수 있습니다.

=== RunnableGenerator란?

`RunnableGenerator`는 비동기 제너레이터 함수를 LangChain의 `Runnable` 인터페이스로 래핑합니다. 이렇게 하면:

- `|` (파이프) 연산자로 다른 Runnable과 체이닝 가능
- LangChain의 `batch()`, `stream()` 등 표준 메서드 사용 가능
- 입력 스트림을 받아 변환된 출력 스트림을 생성하는 패턴에 적합

#code-block(`````python
from langchain_core.runnables import RunnableGenerator

async def transform_input(input_stream):
    async for text in input_stream:
        async for token in stream_agent_response(text):
            yield token

agent_runnable = RunnableGenerator(transform_input)
`````)

=== 전체 파이프라인 연결 (개념 코드)

`asyncio.Queue`를 사용하여 STT의 최종 전사 결과를 에이전트로 전달하고, 에이전트의 스트리밍 응답을 TTS로 중계합니다. `Queue`는 비동기 Producer-Consumer 패턴의 핵심 구성 요소입니다.

#code-block(`````python
async def voice_pipeline(audio_input_stream):
    transcript_queue = asyncio.Queue()

    def on_final(transcript):
        if isinstance(transcript, aai.RealtimeFinalTranscript):
            transcript_queue.put_nowait(transcript.text)

    transcriber = aai.RealtimeTranscriber(
        sample_rate=16000, on_data=on_final
    )
    transcriber.connect()

    async for audio_chunk in audio_input_stream:
        transcriber.stream(audio_chunk)
        if not transcript_queue.empty():
            user_text = await transcript_queue.get()
            text_stream = stream_agent_response(user_text)
            async for audio in text_to_speech_stream(text_stream):
                yield audio
`````)

== 8.8 WebSocket 서버 -- 실시간 양방향 통신

#tip-box[_이 셀의 코드를 실행하면 서버가 시작됩니다._ 개념 이해를 위한 참조 코드입니다.]

WebSocket을 통해 클라이언트와 양방향 오디오 스트리밍을 처리합니다. `asyncio.gather`로 수신과 송신을 _동시 실행_합니다.

=== WebSocket을 사용하는 이유

보이스 에이전트는 양방향 실시간 통신이 필수입니다:

- _수신 (Receive)_: 클라이언트가 마이크 오디오를 서버로 지속적으로 전송
- _송신 (Send)_: 서버가 합성된 음성 오디오를 클라이언트로 지속적으로 전송

HTTP의 요청-응답 모델은 이런 양방향 스트리밍에 적합하지 않습니다. WebSocket은 단일 TCP 연결 위에서 양방향 데이터 흐름을 지원하며, `asyncio.gather`를 사용하면 수신과 송신이 서로를 블록하지 않고 동시에 실행됩니다.

#code-block(`````python
import websockets
import asyncio

async def handle_client(websocket):
    transcriber = create_transcriber()
    transcriber.connect()

    async def receive_audio():
        async for message in websocket:
            if isinstance(message, bytes):
                transcriber.stream(message)

    async def send_audio():
        async for transcript in transcription_queue:
            text_stream = stream_agent_response(transcript)
            async for audio in text_to_speech_stream(text_stream):
                await websocket.send(audio)

    await asyncio.gather(receive_audio(), send_audio())

async def main():
    async with websockets.serve(handle_client, "0.0.0.0", 8765):
        print("Voice agent server on ws://0.0.0.0:8765")
        await asyncio.Future()
`````)

== 8.9 성능 목표 -- Sub-700ms 레이턴시

보이스 에이전트의 핵심 성능 지표는 _발화 종료부터 첫 오디오 출력까지의 시간_(Time to First Audio, TTFA)입니다. 자연스러운 대화 경험을 위해 이 지표가 700ms 미만이어야 합니다.

=== 레이턴시 분석

#align(center)[#image("../../assets/diagrams/png/voice_latency_pipeline.png", width: 86%, height: 96mm, fit: "contain")]

_레이턴시 버짓 예시_: STT 180ms + Agent TTFT 320ms + TTS 첫 오디오 140ms = _약 640ms_ 입니다. 이때 핵심은 각 단계를 개별 최적화하는 것보다, 다음 단계가 이전 단계의 _완료_ 가 아니라 _첫 결과_ 를 받아 시작하도록 만드는 것입니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[단계],
  text(weight: "bold")[목표 시간],
  text(weight: "bold")[설명],
  [STT 최종 전사],
  [~200ms],
  [발화 종료 감지 -\\\> 최종 텍스트 (AssemblyAI 내장 엔드포인팅)],
  [Agent 첫 토큰],
  [~300ms],
  [텍스트 입력 -\\\> 첫 응답 토큰 생성 (TTFT: Time to First Token)],
  [TTS 첫 오디오],
  [~150ms],
  [첫 텍스트 토큰 -\\\> 첫 오디오 청크 (WebSocket 기반)],
  [_합계_],
  [_\\\<700ms_],
  [_발화 종료 -\\\> 첫 오디오 출력_],
)

=== 최적화 기법

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기법],
  text(weight: "bold")[효과],
  text(weight: "bold")[구현 방법],
  [스트리밍 STT],
  [전체 전사 대기 제거],
  [`RealtimeTranscriber` + 부분 결과],
  [스트리밍 Agent],
  [전체 응답 완료 전 TTS 시작],
  [`astream()` 사용 — `ainvoke()` 대신],
  [스트리밍 TTS],
  [첫 오디오까지 시간 단축],
  [WebSocket 기반 합성],
  [커넥션 풀링],
  [연결 설정 지연 제거],
  [WebSocket 재사용 (요청마다 새 연결 생성 방지)],
  [VAD],
  [무음 구간 처리 방지],
  [AssemblyAI 내장 엔드포인팅],
  [응답 캐싱],
  [빈번한 질문 즉시 응답],
  [자주 묻는 질문 캐싱],
)

#tip-box[_팁_: Agent의 TTFT(첫 토큰까지 시간)가 전체 레이턴시에서 가장 큰 비중을 차지합니다. 짧은 시스템 프롬프트와 경량 모델 선택이 레이턴시 최적화의 핵심입니다.]

== 8.10 에이전트에 도구 추가

보이스 에이전트의 강점은 Sandwich 아키텍처 덕분에 _텍스트 기반 도구를 그대로 활용_할 수 있다는 점입니다. 검색, 일정 관리, 날씨 조회 등 다양한 도구를 추가할 수 있습니다.

이것이 S2S(Speech-to-Speech) 방식과의 가장 큰 차별점입니다. S2S 모델은 오디오를 직접 처리하므로 텍스트 기반 도구 호출이 어렵지만, Sandwich 아키텍처는 에이전트가 텍스트 영역에서 동작하므로 기존의 모든 LangChain 도구를 그대로 사용할 수 있습니다.

=== 도구 설계 팁

음성 에이전트의 도구는 _빠른 응답_이 중요합니다. 도구 실행 시간이 길어지면 전체 파이프라인의 레이턴시가 증가하므로:

- 가벼운 API 호출 위주로 설계
- 타임아웃 설정 필수
- 가능하면 캐싱 적용

#code-block(`````python
def weather_tool(city: str) -> str:
    """도시의 현재 날씨를 조회합니다."""
    return f"{city} 날씨: 15도, 구름 조금"

def reminder_tool(time: str, message: str) -> str:
    """지정된 시간에 알림을 설정합니다."""
    return f"{time}에 알림 설정됨: {message}"
`````)

#code-block(`````python
voice_agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calendar_tool,
           weather_tool, reminder_tool],
    system_prompt=(
        "당신은 음성 어시스턴트입니다. "
        "1-2문장으로 간결하고 대화체로 응답하세요."
    ),
)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[주제],
  text(weight: "bold")[핵심 내용],
  [_Sandwich 아키텍처_],
  [STT -\\\> Agent -\\\> TTS, 각 레이어 독립 교체 가능, 도구 호출 지원],
  [_STT (AssemblyAI)_],
  [`RealtimeTranscriber`, Producer-Consumer 패턴, WebSocket 스트리밍],
  [_Agent (LangChain)_],
  [`create_agent` + `astream()`, 토큰 단위 스트리밍, 도구 통합],
  [_TTS (Cartesia)_],
  [WebSocket 기반 저지연 합성, 부분 텍스트 즉시 오디오 변환],
  [_파이프라인 조합_],
  [`RunnableGenerator`, 비동기 제너레이터 체이닝],
  [_성능 목표_],
  [Sub-700ms (STT ~200ms + Agent ~300ms + TTS ~150ms)],
  [_도구 확장_],
  [텍스트 기반 도구를 그대로 음성 에이전트에 적용 가능],
)

보이스 에이전트까지 구현할 수 있게 되었습니다. 지금까지 학습한 모든 에이전트 패턴을 실제 서비스로 배포하려면 테스트, 관측성, 배포 인프라가 필요합니다. 마지막 장에서는 에이전트를 프로덕션에 안전하게 배포하기 위한 전체 파이프라인을 다룹니다.

