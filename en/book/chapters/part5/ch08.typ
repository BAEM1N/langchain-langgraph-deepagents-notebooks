// Auto-generated from 08_voice_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Voice Agent", subtitle: "STT/Agent/TTS Pipeline")

We build a voice agent that converts voice input to text (STT), processes it by the LangChain agent, and then synthesizes text into speech (TTS) and returns it in real-time.

This architecture is a _Sandwich pattern_ (STT -\> Agent -\> TTS), where each layer is connected by streaming, targeting sub-700ms latency.

=== Core design principles

The core of the Sandwich architecture is _Streaming Chaining_. Rather than waiting for the complete output of the previous layer, each layer passes partial results to the next layer as soon as they are produced:

- _STT_: Generates partial transcripts in real-time and emits final transcripts when detecting end-of-speech.
- _Agent_: Streams the response token by token through `astream()` — does not wait for the entire response generation to complete.
- _TTS_: Start audio synthesis as soon as a text chunk arrives based on WebSocket

Thanks to this structure, the latency of the entire pipeline is reduced to _the sum of the time until the first output of each stage_, rather than the sum of each stage.

== Learning Objectives

After completing this notebook, you will be able to:

+ _Sandwich Architecture_ — Can explain the structure and data flow of STT -\> Agent -\> TTS pipeline
+ _Architecture Comparison_ — You can compare the pros and cons of the Sandwich method and the Speech-to-Speech (S2S) method.
+ _STT Step_ — You can understand the Producer-Consumer pattern of AssemblyAI real-time transcription.
+ _Agent Phase_ — You can build an agent that generates streaming responses with LangChain `create_agent`
+ _TTS Step_ — Understand the operating principle of Cartesia WebSocket-based streaming voice synthesis.
+ _RunnableGenerator_ — Pipelines can be combined with asynchronous generator chaining.
+ _Performance Optimization_ — Understand optimization techniques at each stage to achieve latency goals.

#note-box[_Note_: STT (AssemblyAI) and TTS (Cartesia) are external paid services. The cells are provided as markdown to illustrate the concept, _only the agent creation part is the actual executable code_.]

== 8.1 Environment Setup

These are the packages and each role required for a voice agent:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[package],
  text(weight: "bold")[Role],
  [`langchain`, `langchain-openai`],
  [Create Agent and Connect LLM],
  [`assemblyai`],
  [Real-time speech-to-text (STT)],
  [`cartesia`],
  [Low-latency text-to-speech synthesis (TTS)],
  [`websockets`],
  [Real-time two-way communication server],
  [`pyaudio`],
  [Microphone audio capture (optional)],
)

#code-block(`````python
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv()

model = ChatOpenAI(model="gpt-4.1")
`````)

== 8.2 Voice Agent Architecture Overview

The voice agent consists of a 3-layer pipeline:

#code-block(`````python
Audio In -> [STT: AssemblyAI] -> Text -> [Agent: LangChain] -> Text -> [TTS: Cartesia] -> Audio Out
`````)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Layer],
  text(weight: "bold")[Provider],
  text(weight: "bold")[Role],
  [_STT_],
  [AssemblyAI],
  [User Converts speech into text],
  [_Agent_],
  [LangChain],
  [Processes the text query and generates a response],
  [_TTS_],
  [Cartesia],
  [Converts the agent's text response into speech],
)

Each layer is connected through _streaming_, so partial results can be forwarded immediately without waiting for the previous step to finish completely:

+ _STT_ — streams partial transcriptions (emits a final transcript when the utterance is complete)
+ _Agent_ — streams responses token by token (`astream()`)
+ _TTS_ — Start speech synthesis before the entire response is complete (WebSocket-based)

=== Why Streaming Matters

When processing synchronously without streaming, Next Steps does not start until each step is completely finished. For example, if the agent takes 3 seconds to generate a 200 token response, TTS will only start after 3 seconds. In streaming, on the other hand, TTS begins synthesizing speech _as soon as the agent's first token appears_, so the user already starts hearing speech while the agent is still generating a response.

== 8.3 Architecture comparison table

Compare two approaches to building voice agents.

=== Sandwich architecture (STT -\\> Agent -\\> TTS)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Advantages_],
  [Each component can be replaced independently, easy to use text-based tool, convenient for debugging (intermediate text logging)],
  [_Disadvantages_],
  [Latency accumulation and loss of non-verbal information such as emotion/intonation due to 3-step serial processing],
  [_Suitable for_],
  [tool calling Complex agents with many, when multilingual support is required],
)

=== Speech-to-Speech (S2S)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Advantages_],
  [Low latency, preservation of voice characteristics (emotion, stress), natural conversation],
  [_Disadvantages_],
  [tool calling Difficulty in integration, limited model selection, difficulty in debugging],
  [_Suitable for_],
  [Simple conversational interface, when emotion recognition is important],
)

#note-box[In this notebook, we focus on the _tool calling-enabled Sandwich architecture_.]

== 8.4 STT Step -- AssemblyAI Real-Time Transcription

#tip-box[_This cell requires an AssemblyAI API key._ Reference code to understand the concept.]

AssemblyAI's `RealtimeTranscriber` operates with the _Producer-Consumer pattern_:

- _Producer_: Send audio chunks captured from the microphone to WebSocket
- _Consumer_: Receives partial and final transcription results as a callback.

Since both operations take place _simultaneously_, you can receive a transcription of the previous utterance even while your voice is being transmitted.

=== Two types of transcription results

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[class],
  text(weight: "bold")[Description],
  [_Partial_],
  [`RealtimeTranscript`],
  [Temporary transcription of words still being uttered. Updated in real-time as the user speaks],
  [_Final_],
  [`RealtimeFinalTranscript`],
  [Confirmation transcription after the end of utterance (endpointing) is detected. Pass only this result to the agent],
)

AssemblyAI's built-in Voice Activity Detection (VAD) automatically detects when an utterance has ended, eliminating the need for separate silence detection logic.

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

=== Capturing Microphone Audio

PCM 16-bit, 16kHz Capture mono audio and send it to the transcriber in real time:

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

== 8.5 Agent Phase -- Utilizing LangChain Agent

The agent stage is the core of the pipeline. An agent created with `create_agent` takes text input, performs inference with tool calling, and streams a text response.

The key to system prompts for voice agents is to elicit concise, conversational responses. For voice output, unlike text, long responses can be burdensome to the user, so users are instructed to generate short responses of no more than 1 to 2 sentences.

=== The role of asynchronous streaming

The agent's `astream()` method yields a response token as soon as it is generated. Why this is especially important for voice agents:

- _TTS Early Start_: Speech synthesis is possible from the first token without waiting for the entire response to be completed.
- _Reduced perceived lag_: Users start hearing the agent’s response sooner.
- _Pipeline efficiency_: Agent and TTS run simultaneously, reducing total processing time

#code-block(`````python
from langchain.agents import create_agent

def search_tool(query: str) -> str:
    """Search the web for the latest information."""
    return f"Search result: {query}"

def calendar_tool(action: str, details: str) -> str:
    """Manage calendar events."""
    return f"Calendar {action}: {details}"
`````)

#code-block(`````python
agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calendar_tool],
    system_prompt=(
        "You are a useful voice assistant."
        "Keep your responses brief and conversational."
    ),
)
`````)

=== Generate asynchronous streaming response

`astream()` yields the agent's response token as soon as it is generated. Allows the TTS stage to start speech synthesis without waiting for the entire response to complete.

LangChain's streaming offers two main methods:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[method],
  text(weight: "bold")[Description],
  [`astream()`],
  [Stream the output for each step of agent execution. Contains messages, tool calling results, etc.],
  [`astream_events()`],
  [More granular event-level streaming. Provide detailed events such as individual tokens, LLM start/end, etc.],
)

The voice agent receives message chunks as `astream()`, extracts `content` from each chunk, and passes it to TTS.

#code-block(`````python
async def stream_agent_response(user_text: str):
    """Stream agent response tokens one by one."""
    async for chunk in agent.astream(
        {"messages": [{"role": "user",
                        "content": user_text}]}
    ):
        if "messages" in chunk:
            for msg in chunk["messages"]:
                if hasattr(msg, "content") and msg.content:
                    yield msg.content
`````)

== 8.6 TTS Steps -- Cartesia Streaming Speech Synthesis

#tip-box[_This cell requires a Cartesia API key._ Reference code to understand the concept.]

Cartesia provides WebSocket-based low-latency TTS. It takes a text stream from an agent and generates audio chunks for each partial text on the fly.

=== How Cartesia TTS works

+ _WebSocket connection_: Maintain a persistent connection by opening a WebSocket session with the `AsyncCartesia` client.
+ _Send text chunks_: Send text in units of tokens/sentences generated by the agent.
+ _Receive Audio Chunk_: Receive PCM audio bytes immediately for each text chunk
+ _Client Delivery_: Stream the received audio bytes to the client via WebSocket.

Because it is based on WebSocket, two-way real-time communication is possible without HTTP request/response overhead. The `sonic-2` model provides both natural speech and low latency.

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

== 8.7 Pipeline Combination -- RunnableGenerator

LangChain's `RunnableGenerator` allows you to integrate asynchronous generators into your _Runnable pipeline_. This allows the entire data flow of STT output -\> Agent processing -\> TTS input to be organized into one pipeline.

=== What is RunnableGenerator?

`RunnableGenerator` wraps an asynchronous generator function into LangChain's `Runnable` interface. If you do this:

- Chaining with other Runnables is possible using the `|` (pipe) operator.
- Standard methods such as LangChain’s `batch()` and `stream()` can be used.
- Suitable for patterns that receive an input stream and generate a converted output stream.

#code-block(`````python
from langchain_core.runnables import RunnableGenerator

async def transform_input(input_stream):
    async for text in input_stream:
        async for token in stream_agent_response(text):
            yield token

agent_runnable = RunnableGenerator(transform_input)
`````)

=== Wiring the Full Pipeline (conceptual code)

Use `asyncio.Queue` to pass the final STT transcript to the agent and forward the agent's streaming response to TTS. `Queue` is a core building block in an async producer-consumer pattern.

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

== 8.8 WebSocket Server -- Real-time two-way communication

#tip-box[_Running the code in this cell will start the server._ This is reference code to help you understand the concept.]

Handles two-way audio streaming with clients via WebSockets. Receiving and sending are _executed_ simultaneously with `asyncio.gather`.

=== Why use WebSockets

Voice agents require two-way, real-time communication:

- _Receive_: Client continuously transmits microphone audio to the server
- _Send_: The server continuously transmits synthesized voice audio to the client.

HTTP's request-response model is not suitable for this kind of two-way streaming. WebSockets support two-way data flow over a single TCP connection, and with `asyncio.gather`, ingress and egress run concurrently without blocking each other.

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

== 8.9 Performance Target -- Sub-700ms Latency

A key performance metric for voice agents is Time to First Audio (TTFA). For a natural conversation experience, this metric should be less than 700ms.

=== Latency analysis

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[steps],
  text(weight: "bold")[target time],
  text(weight: "bold")[Description],
  [STT final transcription],
  [~200ms],
  [Detect end of utterance -\\\> final text (AssemblyAI built-in endpointing)],
  [Agent first token],
  [~300ms],
  [Enter text -\\\> Create first response token (TTFT: Time to First Token)],
  [TTS first audio],
  [~150ms],
  [First text token -\\\> first audio chunk (WebSocket based)],
  [_Total_],
  [_\\\<700ms_],
  [_End of speech -\\\> First audio output_],
)

=== Optimization techniques

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[technique],
  text(weight: "bold")[effect],
  text(weight: "bold")[Implementation method],
  [Streaming STT],
  [Eliminate full transcription wait],
  [`RealtimeTranscriber` + partial result],
  [Streaming Agent],
  [Start TTS before completing all responses],
  [Use `astream()` — instead of `ainvoke()`],
  [Streaming TTS],
  [Reduce time to first audio],
  [WebSocket-based synthesis],
  [Connection Pooling],
  [Eliminate connection setup delays],
  [WebSocket reuse (avoid creating new connection per request)],
  [VAD],
  [Prevent processing of silent sections],
  [AssemblyAI built-in endpointing],
  [response caching],
  [Immediate response to frequently asked questions],
  [Frequently Asked Questions Caching],
)

#tip-box[_Tip_: Agent's TTFT (Time to First Token) accounts for the largest proportion of overall latency. Short system prompts and lightweight model selection are key to latency optimization.]

== 8.10 Add tool to agent

The strength of the voice agent is that its Sandwich architecture allows it to leverage text-based tool. You can add a variety of tool features such as search, calendar management, weather lookup, and more.

This is the biggest difference from the S2S (Speech-to-Speech) method. The S2S model processes audio directly, making text-based tool calling difficult, but the Sandwich architecture allows agents to operate in text areas, so all existing LangChain tool can be used as is.

=== tool Design Tips

tool of voice agents _fast response_ is important. tool As the execution time increases, the latency of the entire pipeline increases:

- Designed mainly for light API calls
- Timeout setting required
- Apply caching if possible

#code-block(`````python
def weather_tool(city: str) -> str:
    """View the current weather in your city."""
    return f"{city} weather: 15°C, partly cloudy"

def reminder_tool(time: str, message: str) -> str:
    """Set reminders at specified times."""
    return f"{time}Reminder scheduled for {message}"
`````)

#code-block(`````python
voice_agent = create_agent(
    model="gpt-4.1",
    tools=[search_tool, calendar_tool,
           weather_tool, reminder_tool],
    system_prompt=(
        "You are a voice assistant."
        "Please keep your response concise and conversational in 1-2 sentences."
    ),
)
`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Takeaways],
  [_Sandwich Architecture_],
  [STT -\\\> Agent -\\\> TTS, each layer can be replaced independently, supports tool calling],
  [_STT (AssemblyAI)_],
  [`RealtimeTranscriber`, Producer-Consumer pattern, WebSocket streaming],
  [_Agent (LangChain)_],
  [`create_agent` + `astream()`, token-level streaming, tool integration],
  [_TTS (Cartesia)_],
  [WebSocket-based low-latency synthesis, instant audio conversion of partial text],
  [_Pipeline Combination_],
  [`RunnableGenerator`, asynchronous generator chaining],
  [_Performance Goals_],
  [Sub-700ms (STT ~200ms + Agent ~300ms + TTS ~150ms)],
  [_tool Expansion_],
  [Text-based tool can be applied to voice agents as is],
)

=== Next Steps
→ _#link("./09_production.ipynb")[09_production.ipynb]_: Learn production deployment.
