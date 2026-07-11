// Auto-generated from 03_models_and_messages.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Models and the Message System")

Learn how to configure different LLM models in LangChain v1 and structure conversations with message types.


== Learning Objectives

- Understand the LangChain v1 model initialization methods (`init_chat_model`, `ChatOpenAI`)
- Learn the three call patterns: `invoke()`, `stream()`, and `batch()`
- Understand message types such as `SystemMessage`, `HumanMessage`, `AIMessage`, and `ToolMessage`
- Learn how to construct multimodal messages (image input)


== 3.1 Environment Setup

Load API keys from `.env` and initialize the model through OpenAI.


#code-block(`````python
import os
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI

load_dotenv(override=True)

# Initialize the model with OpenAI
model = ChatOpenAI(
    model="gpt-5.4",
)

print("Model initialized:", model.model_name)
`````)

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: pass config={"callbacks": [langfuse_handler]} to invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 3.2 Comparing Model Providers

LangChain v1 can initialize models from many providers through the unified `init_chat_model()` API.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Provider],
  text(weight: "bold")[Model String Format],
  text(weight: "bold")[Required Package],
  text(weight: "bold")[Environment Variable],
  [OpenAI],
  [`"openai:gpt-5"`],
  [`langchain-openai`],
  [`OPENAI_API_KEY`],
  [Anthropic],
  [`"anthropic:claude-sonnet-4-6"`],
  [`langchain-anthropic`],
  [`ANTHROPIC_API_KEY`],
  [Google],
  [`"google:gemini-2.0-flash"`],
  [`langchain-google-genai`],
  [`GOOGLE_API_KEY`],
  [AWS Bedrock],
  [`"bedrock:anthropic.claude-v3"`],
  [`langchain-aws`],
  [AWS credentials],
  [Azure],
  [`"azure:gpt-4o"`],
  [`langchain-openai`],
  [`AZURE_OPENAI_API_KEY`],
  [Ollama],
  [`"ollama:llama3"`],
  [`langchain-ollama`],
  [(local runtime)],
)

#note-box[_Note:_ When using OpenAI, you can set `base_url` and `api_key` directly on `ChatOpenAI` to connect to OpenAI-style services such as vLLM, LM Studio, or Ollama.]


== 3.3 Using `init_chat_model()`

`init_chat_model()` is the unified model initialization helper introduced in LangChain v1.
If the provider-specific package is installed, you can create a model with a single string.

When you are using OpenAI directly, `ChatOpenAI` is usually the more straightforward option.


#code-block(`````python
from langchain.chat_models import init_chat_model

# init_chat_model with OpenAI
model_direct = init_chat_model(
    model="openai:gpt-5.4",
    temperature=0,
)

response = model_direct.invoke("Hello! What is 2+2?", config=lf_config)
print("Model response:", response.content)
`````)

== 3.4 `invoke()`, `stream()`, and `batch()` Patterns

Every LangChain v1 model supports three calling patterns:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Method],
  text(weight: "bold")[Description],
  text(weight: "bold")[Return Type],
  [`invoke()`],
  [One response for one input],
  [`AIMessage`],
  [`stream()`],
  [Token-by-token streaming response],
  [`Iterator[AIMessageChunk]`],
  [`batch()`],
  [Handles multiple inputs at the same time],
  [`List[AIMessage]`],
)


#code-block(`````python
# invoke: single call
response = model.invoke("Explain what LangChain is in one sentence.", config=lf_config)
print("invoke result:", response.content)
`````)

#code-block(`````python
# stream: token-level streaming
print("stream result:", end=" ")
for chunk in model.stream("Count from 1 to 5.", config=lf_config):
    print(chunk.content, end="", flush=True)
print()
`````)

#code-block(`````python
# batch: process multiple inputs at once
responses = model.batch([
    "What is Python?",
    "What is JavaScript?",
    "What is Rust?",
], config=lf_config)
for i, resp in enumerate(responses):
    print(f"Response {i+1}: {resp.content[:100]}...")
`````)

== 3.5 Message Types

LangChain v1's message system clearly separates the roles inside a conversation:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Message Type],
  text(weight: "bold")[Role],
  text(weight: "bold")[Description],
  [`SystemMessage`],
  [System],
  [A system prompt that defines how the model should behave],
  [`HumanMessage`],
  [User],
  [A message entered by the user],
  [`AIMessage`],
  [AI],
  [A response generated by the model],
  [`ToolMessage`],
  [Tool],
  [A message that passes a tool result back to the model],
)

If you build a list of messages and pass it into `model.invoke()`, you can preserve the conversation context across turns.


#code-block(`````python
from langchain.messages import SystemMessage, HumanMessage, AIMessage, ToolMessage

messages = [
    SystemMessage(content="You are a translation assistant. Translate into Korean."),
    HumanMessage(content="Hello, how are you?"),
]

response = model.invoke(messages, config=lf_config)
print("Translation result:", response.content)
print(f"Message type: {type(response).__name__}")
`````)

#code-block(`````python
# Conversation history — combine multiple message types to build context
conversation = [
    SystemMessage(content="You are a math tutor. Answer concisely."),
    HumanMessage(content="What is a prime number?"),
    AIMessage(content="A prime number is a natural number greater than 1 that has no positive divisors other than 1 and itself."),
    HumanMessage(content="Give me five examples."),
]

response = model.invoke(conversation, config=lf_config)
print("Response:", response.content)
`````)

== 3.6 Multimodal Messages (Image Input)

In LangChain v1, you can send text and images together in the `content` of a `HumanMessage`.
Images can be passed as URLs or as base64-encoded content, and this works only with models that support vision input.

#code-block(`````python
content = [
    {"type": "text", "text": "Description text"},
    {"type": "image_url", "image_url": {"url": "IMAGE_URL"}},
]
`````)


#code-block(`````python
# Example multimodal message structure (requires model support to run)
from langchain.messages import HumanMessage

multimodal_msg = HumanMessage(
    content=[
        {"type": "text", "text": "What do you see in this image?"},
        {
            "type": "image_url",
            "image_url": {"url": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Camponotus_flavomarginatus_ant.jpg/320px-Camponotus_flavomarginatus_ant.jpg"},
        },
    ]
)

# Run with a multimodal-capable model
try:
    response = model.invoke([multimodal_msg], config=lf_config)
    print("Multimodal response:", response.content)
except Exception as e:
    print(f"Model does not support multimodal input: {e}")
    print("  -> Multimodal input is supported by vision-capable models such as GPT-4o and Claude.")
`````)

== 3.7 Summary

Here is a summary of the main ideas from this notebook.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [`init_chat_model()`],
  [Initializes models through a unified provider string],
  [`ChatOpenAI(base_url=...)`],
  [Uses OpenAI or another custom endpoint],
  [`invoke()`],
  [Single input → single response],
  [`stream()`],
  [Token-level streaming response],
  [`batch()`],
  [Handles multiple inputs at once],
  [`SystemMessage`],
  [Sets system instructions],
  [`HumanMessage`],
  [Represents user input],
  [`AIMessage`],
  [Represents an AI response (for conversation history)],
  [`ToolMessage`],
  [Carries tool execution results],
  [Multimodal message],
  [Sends text and images together in `content`],
)

=== Next Steps
→ _#link("./04_tools_and_structured_output.ipynb")[04_tools_and_structured_output.ipynb]_: Learn about tools and structured output.
