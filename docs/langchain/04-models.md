# LangChain Models

## Overview

Large Language Models are AI systems capable of interpreting and generating text. Beyond text generation, many models support tool calling, structured output, multimodality, and reasoning capabilities.

## Key Capabilities

Models in LangChain support:

- **Tool Calling**: Execute external tools like database queries or API calls
- **Structured Output**: Constrain responses to defined formats
- **Multimodality**: Process images, audio, and video
- **Reasoning**: Multi-step problem solving

## Initialization

The `init_chat_model` function provides the simplest way to get started:

```python
from langchain.chat_models import init_chat_model

model = init_chat_model("gpt-5.2")
response = model.invoke("Why do parrots talk?")
```

Supported providers include OpenAI, Anthropic, Google Gemini, Azure, AWS Bedrock, and HuggingFace.

## Core Parameters

Standard configuration options include:

- **model**: Model identifier
- **api_key**: Authentication credentials
- **temperature**: Controls randomness (0=deterministic, higher=creative)
- **max_tokens**: Limits response length
- **timeout**: Maximum wait time in seconds
- **max_retries**: Automatic retry attempts (default: 6)

## Invocation Methods

### Invoke

Single synchronous call returning complete response:

```python
response = model.invoke("Your question here")
```

### Stream

Real-time output generation:

```python
for chunk in model.stream("Your question here"):
    print(chunk.text, end="", flush=True)
```

### Batch

Process multiple requests efficiently:

```python
responses = model.batch(["Question 1", "Question 2", "Question 3"])
```

## Tool Calling

Bind tools to enable external function execution:

```python
from langchain.tools import tool

@tool
def get_weather(location: str) -> str:
    """Get weather at a location."""
    return f"Sunny in {location}."

model_with_tools = model.bind_tools([get_weather])
response = model_with_tools.invoke("What's the weather in Boston?")
```

Models can make parallel tool calls when appropriate.

## Structured Output

Enforce response formats using Pydantic, TypedDict, or JSON Schema:

```python
from pydantic import BaseModel, Field

class Movie(BaseModel):
    title: str
    year: int
    director: str

model_with_structure = model.with_structured_output(Movie)
response = model_with_structure.invoke("Tell me about Inception")
```

## Advanced Features

### Multimodal Processing

Models can process and return images, audio, and video content through content blocks.

### Reasoning

Some models surface multi-step reasoning processes:

```python
for chunk in model.stream("Complex question"):
    reasoning = [b for b in chunk.content_blocks if b["type"] == "reasoning"]
```

### Model Profiles

**Since langchain 1.1**: 모든 chat model이 `.profile` 속성으로 capability dict를 노출한다. 데이터는 오픈소스 [models.dev](https://models.dev) 프로젝트에서 가져오고 LangChain 고유 필드가 추가된다.

```python
from langchain.chat_models import init_chat_model

model = init_chat_model("openai:gpt-5")
model.profile
# {
#   "max_input_tokens": 400000,
#   "image_inputs": True,
#   "reasoning_output": True,
#   "tool_calling": True,
#   ...
# }
```

주요 용도:

- **동적 컨텍스트 관리** — `SummarizationMiddleware`가 `fraction` trigger를 `.profile["max_input_tokens"]` 기준으로 자동 계산
- **구조화 출력 전략 자동 선택** — `ProviderStrategy` vs `ToolStrategy`를 `.profile`로 추론
- **입력 게이팅** — `image_inputs: False`이면 이미지 메시지 사전 차단

profile 데이터가 없는 모델(private / 커스텀)은 수동 지정 가능:

```python
custom_profile = {"max_input_tokens": 100_000, "tool_calling": True}
model = init_chat_model("my-private-model", profile=custom_profile)
```

### Prompt Caching

Providers offer caching to reduce costs and latency on repeated token processing.

### Rate Limiting

Control request rates to manage API limits:

```python
from langchain_core.rate_limiters import InMemoryRateLimiter

rate_limiter = InMemoryRateLimiter(requests_per_second=0.1)
model = init_chat_model("gpt-5", rate_limiter=rate_limiter)
```

### Token Usage Tracking

Monitor token consumption across models using callbacks or context managers.

### Configurable Models

Create runtime-configurable models that switch providers or parameters:

```python
model = init_chat_model(temperature=0)
model.invoke("question", config={"configurable": {"model": "claude-sonnet-4-6"}})
```

## Message Format

Conversations use message dictionaries or LangChain message objects with roles (system, user, assistant).

## Additional Resources

- Full integration documentation at `/oss/python/integrations/chat`
- Reference guide: `init_chat_model` function documentation
- Support for local models via Ollama
- OpenAI-compatible API support with custom base URLs
