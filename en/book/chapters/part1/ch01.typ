// Auto-generated from 01_llm_basics.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "LLM Basics", subtitle: "Messages, Prompts, and Streaming")

Before building agents, learn the basics of how to communicate with an LLM.


== Learning Objectives

- Understand the roles of messages (`system`, `human`, `ai`)
- Control model behavior with system messages
- Receive real-time responses with `model.stream()`


== 1.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
print("✓ Model ready")

`````)

== 1.2 The Three Roles of Messages

An LLM takes a _list of messages_ as input. Each message has a role and is made up of three core pieces of information: role, content, and metadata.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Role],
  text(weight: "bold")[Class],
  text(weight: "bold")[Description],
  [`system`],
  [`SystemMessage`],
  [Sets behavioral instructions for the model. It defines the model's initial behavior through persona, tone, rules, and similar guidance.],
  [`human`],
  [`HumanMessage`],
  [Represents the user's input. It can include multimodal content such as images, audio, and files in addition to text.],
  [`ai`],
  [`AIMessage`],
  [Represents the model's reply. Besides text, it can include properties such as `tool_calls` and `usage_metadata`.],
)

There is also `ToolMessage`, which passes tool execution results back to the model. A `ToolMessage` must include the tool result content, the tool call ID, and the tool name.


== 1.3 Controlling Behavior with a System Message

If you change the `SystemMessage`, you can get very different answers to the same question.
That is the core idea behind _prompt engineering_.


== 1.4 Dictionary Format

You can also pass messages as dictionaries instead of message objects. LangChain supports three input formats for messages:

+ _String_: Best for a simple text prompt, for example `model.invoke("Hello")`
+ _Message objects_: A typed list of instances such as `SystemMessage` and `HumanMessage`
+ _Dictionary_: The same `{"role": ..., "content": ...}` structure used by the OpenAI Chat Completions API

All three formats return the same kind of result, so you can choose the one that best fits your situation. The dictionary format is especially useful when migrating existing OpenAI code to LangChain.


== 1.5 Streaming

If you use `model.stream()`, tokens are printed as they are generated in real time.
This can make the application feel much faster to the user.

LangChain models provide three main call styles:
- *`invoke()`*: A synchronous call that returns the full response at once
- *`stream()`*: Returns `AIMessageChunk` objects token by token for real-time output
- *`batch()`*: Handles multiple requests at once for better throughput

During streaming, each `AIMessageChunk` is progressively combined into the final message, and token usage can also be tracked incrementally.


== 1.6 Batch Calls

With `model.batch()`, you can send several questions at once. This is more efficient than repeatedly calling `invoke()` one request at a time.


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Concept],
  text(weight: "bold")[Description],
  [`SystemMessage`],
  [Sets the model's persona and rules],
  [`HumanMessage`],
  [Represents user input],
  [`model.invoke()`],
  [Synchronous call (full response)],
  [`model.stream()`],
  [Real-time output at the token level],
  [`model.batch()`],
  [Processes multiple requests at once],
)

=== Next Steps
→ _#link("./02_langchain_basics_en.ipynb")[02_langchain_basics_en.ipynb]_: Build an agent with tools in LangChain.

