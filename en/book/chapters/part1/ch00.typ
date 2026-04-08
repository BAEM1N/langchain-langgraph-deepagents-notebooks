// Auto-generated from 00_setup.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(0, "Environment Setup", subtitle: "Before You Start")

This series is in the order _LangChain → LangGraph → Deep Agents_
This is an introductory course to quickly experience only the core of AI agent.

== Learning Objectives

- Learn how to safely manage API keys with the `.env` file.
- Initialize the LLM model with `ChatOpenAI`
- Check normal operation by sending a simple question to the model

== 0.1 API key settings

Copy `.env.example` to `.env` in the project root and enter the following keys:

#code-block(`````python
OPENAI_API_KEY=sk-...
TAVILY_API_KEY=tvly-...   # Optional
`````)

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Key],
  text(weight: "bold")[Purpose],
  text(weight: "bold")[Provider],
  [`OPENAI_API_KEY`],
  [LLM calls (required)],
  [https://platform.openai.com/api-keys],
  [`TAVILY_API_KEY`],
  [Web Search tool (optional)],
  [https://tavily.com],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)

assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY is not set!"
print("✓ API key loaded")
`````)

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Set the key in .env, or uncomment it below and enter it yourself.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: Automatically activated when LANGSMITH_TRACING=true (no code modification required)
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON \u2014 project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: Pass config={"callbacks": [langfuse_handler]} when calling invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON \u2014 {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 0.2 Model initialization

`ChatOpenAI` is a LangChain class that wraps an OpenAI-compatible LLM.
This `model` object will be used repeatedly in subsequent Note books.

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")
print("✓ Model setup complete:", model.model_name)
`````)

== 0.3 Smoke Test

Send a brief message to the model to see if it responds normally.

#code-block(`````python
response = model.invoke("hello! Please answer in one sentence.", config=lf_config)
print("✓ Model response:", response.content)
`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [Environment Variables],
  [Load file `.env` into `load_dotenv()`],
  [model],
  [`ChatOpenAI(model="gpt-4.1")`],
  [test],
  [`model.invoke("...")` → Check response],
)

=== Next Steps
→ _#link("./01_llm_basics.ipynb")[01_llm_basics.ipynb]_: Learn the basics of LLM — messages, prompts, streaming.
