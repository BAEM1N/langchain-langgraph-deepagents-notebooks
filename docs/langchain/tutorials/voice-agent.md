# Voice Agent

This tutorial covers building a voice-enabled agent using a Speech-to-Text (STT), Agent, Text-to-Speech (TTS) sandwich architecture. The pipeline converts spoken input to text, processes it through a LangChain agent, and streams synthesized speech back to the user in real time.

## Architecture

The voice agent follows a three-layer pipeline:

```
Audio In -> [STT] -> Text -> [Agent] -> Text -> [TTS] -> Audio Out
```

| Layer | Provider | Role |
|-------|----------|------|
| **STT** | AssemblyAI | Convert user speech to text |
| **Agent** | LangChain | Process the text query and generate a response |
| **TTS** | Cartesia | Convert the agent's text response to speech |

### Latency Target

The system targets sub-700ms latency from end-of-speech to first audio output. This is achieved through:

- Streaming transcription (STT delivers partial results)
- Streaming agent output (tokens stream as they are generated)
- Streaming synthesis (TTS begins speaking before the full response is ready)

## Prerequisites

```bash
pip install langchain langchain-openai assemblyai cartesia websockets
```

```bash
export OPENAI_API_KEY="your-openai-key"
export ASSEMBLYAI_API_KEY="your-assemblyai-key"
export CARTESIA_API_KEY="your-cartesia-key"
```

## Step 1: Speech-to-Text with AssemblyAI

AssemblyAI provides real-time transcription via WebSocket. Configure it to stream partial transcripts and emit final results.

```python
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
        # Final transcript -- send to agent
        process_user_input(transcript.text)

def on_transcription_error(error: aai.RealtimeError):
    print(f"Transcription error: {error}")

# Connect and start streaming audio
transcriber.connect()
```

### Streaming Audio from Microphone

```python
import pyaudio

audio = pyaudio.PyAudio()
stream = audio.open(
    format=pyaudio.paInt16,
    channels=1,
    rate=16000,
    input=True,
    frames_per_buffer=1024,
)

while True:
    data = stream.read(1024)
    transcriber.stream(data)
```

## Step 2: Agent Processing

The LangChain agent processes the transcribed text and generates a response. Use async generators to stream agent output token-by-token.

```python
from langchain.agents import create_agent
from langchain_openai import ChatOpenAI

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[search_tool, calendar_tool],
    system_prompt="You are a helpful voice assistant. Keep responses concise and conversational.",
)
```

### Async Generator for Streaming Output

Use an async generator to yield agent response tokens as they are produced. This enables the TTS layer to begin synthesis before the full response is complete.

```python
from langchain_core.runnables import RunnableGenerator

async def stream_agent_response(user_text: str):
    """Stream the agent's response token by token."""
    async for chunk in agent.astream(
        {"messages": [{"role": "user", "content": user_text}]}
    ):
        if "messages" in chunk:
            for message in chunk["messages"]:
                if hasattr(message, "content") and message.content:
                    yield message.content
```

### RunnableGenerator

Wrap the async generator in a `RunnableGenerator` to integrate it into LangChain's runnable pipeline.

```python
from langchain_core.runnables import RunnableGenerator

async def transform_input(input_stream):
    """Transform streamed input into agent queries."""
    async for text in input_stream:
        async for token in stream_agent_response(text):
            yield token

agent_runnable = RunnableGenerator(transform_input)
```

## Step 3: Text-to-Speech with Cartesia

Cartesia provides low-latency streaming TTS via WebSocket. Feed agent output tokens directly into the TTS stream.

```python
import cartesia
import asyncio

cartesia_client = cartesia.AsyncCartesia(api_key="your-cartesia-key")

async def text_to_speech_stream(text_stream):
    """Convert a stream of text chunks into audio using Cartesia."""
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
            yield audio["audio"]  # Raw PCM bytes

    await ws.close()
```

## Step 4: WebSocket Server for Real-Time Communication

Use WebSockets to handle bidirectional audio streaming with the client.

```python
import websockets
import json

async def handle_client(websocket):
    """Handle a single voice agent session."""
    # Start transcriber
    transcriber = create_transcriber()
    transcriber.connect()

    async def receive_audio():
        """Receive audio from client and forward to STT."""
        async for message in websocket:
            if isinstance(message, bytes):
                transcriber.stream(message)

    async def send_audio():
        """Process transcriptions and stream TTS audio back."""
        async for transcript in transcription_queue:
            text_stream = stream_agent_response(transcript)
            async for audio_chunk in text_to_speech_stream(text_stream):
                await websocket.send(audio_chunk)

    # Run both directions concurrently
    await asyncio.gather(receive_audio(), send_audio())

async def main():
    async with websockets.serve(handle_client, "0.0.0.0", 8765):
        print("Voice agent server running on ws://0.0.0.0:8765")
        await asyncio.Future()  # Run forever

asyncio.run(main())
```

## Putting It All Together

```python
import asyncio
import assemblyai as aai
import cartesia
from langchain.agents import create_agent

# Initialize components
agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[search_tool],
    system_prompt="You are a concise voice assistant.",
)

cartesia_client = cartesia.AsyncCartesia(api_key="your-cartesia-key")

async def voice_pipeline(audio_input_stream):
    """Complete voice agent pipeline: STT -> Agent -> TTS."""
    transcript_queue = asyncio.Queue()

    # STT: Audio -> Text
    def on_final_transcript(transcript):
        if isinstance(transcript, aai.RealtimeFinalTranscript):
            transcript_queue.put_nowait(transcript.text)

    transcriber = aai.RealtimeTranscriber(
        sample_rate=16000,
        on_data=on_final_transcript,
    )
    transcriber.connect()

    # Process audio input
    async for audio_chunk in audio_input_stream:
        transcriber.stream(audio_chunk)

        # Check for completed transcription
        if not transcript_queue.empty():
            user_text = await transcript_queue.get()
            print(f"User said: {user_text}")

            # Agent: Text -> Response Text
            text_stream = stream_agent_response(user_text)

            # TTS: Response Text -> Audio
            async for audio_bytes in text_to_speech_stream(text_stream):
                yield audio_bytes  # Stream audio back to client
```

## Performance Optimization

| Technique | Impact | Implementation |
|-----------|--------|----------------|
| Streaming STT | Reduces wait for full transcription | Use `RealtimeTranscriber` with partial results |
| Streaming agent output | Enables TTS to start before full response | Use `astream()` instead of `ainvoke()` |
| Streaming TTS | Reduces time to first audio | Use WebSocket-based synthesis |
| Connection pooling | Eliminates connection setup latency | Reuse WebSocket connections across requests |
| Voice Activity Detection | Prevents processing silence | AssemblyAI's built-in endpointing |
| Response caching | Instant responses for common queries | Cache frequent agent responses |

## Latency Breakdown

| Stage | Target | Description |
|-------|--------|-------------|
| STT finalization | ~200ms | Time from end-of-speech to final transcript |
| Agent first token | ~300ms | Time to generate the first response token |
| TTS first audio | ~150ms | Time from first text token to first audio chunk |
| **Total** | **<700ms** | **End-of-speech to first audio output** |
