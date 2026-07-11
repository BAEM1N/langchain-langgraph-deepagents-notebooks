// Auto-generated from 03_functional_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(3, "Functional API", subtitle: "Creating workflow with @entrypoint and @task")

== Learning Objectives

Understand the `@entrypoint`, `@task` patterns and short-term memory of the Functional API.

== 3.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
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

== 3.2 \@task — Asynchronous unit of work

- Checkpointing is possible by wrapping it with the `@task` decorator.
- Returns Future object immediately when called, waits with `.result()`

#code-block(`````python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver


@task
def fetch_data(url: str) -> str:
    """This is a simulation of fetching data from a URL."""
    return f"Data fetched from {url}"


@task
def process_data(data: str) -> str:
    """Process the imported data."""
    return f"Processing complete: {data.upper()}"


@entrypoint(checkpointer=InMemorySaver())
def data_pipeline(url: str) -> str:
    raw = fetch_data(url).result()
    processed = process_data(raw).result()
    return processed


config = {
    "configurable": {
        "thread_id": "pipe-1"
    }
}

result = data_pipeline.invoke(
    "https://example.com/api",
    {**config, **lf_config}
)

print("Pipeline results:", result)
`````)

== 3.3 Parallel `\@task` execution

Running multiple `@task` simultaneously.

#code-block(`````python
from langgraph.func import entrypoint, task
from langgraph.checkpoint.memory import InMemorySaver


@task
def analyze_sentiment(text: str) -> str:
    return f"Sentiment ({text[:20]}...): positive"


@task
def extract_keywords(text: str) -> str:
    words = text.split()
    return f"Keywords: {', '.join(words[:3])}"


@task
def summarize(text: str) -> str:
    return f"Summary: {text[:50]}..."


@entrypoint(checkpointer=InMemorySaver())
def parallel_analysis(text: str) -> dict:
    # Start 3 `@task` in parallel
    sentiment_future = analyze_sentiment(text)
    keywords_future = extract_keywords(text)
    summary_future = summarize(text)

    # Collect results in order
    return {
        "sentiment": sentiment_future.result(),
        "keywords": keywords_future.result(),
        "summary": summary_future.result(),
    }


config = {
    "configurable": {
        "thread_id": "parallel-1"
    }
}

result = parallel_analysis.invoke(
    "LangGraph is a powerful framework for building agent based on state",
    {**config, **lf_config}
)

for k, v in result.items():
    print(f"  {k}: {v}")
`````)

== 3.4 previous — short-term memory (accessing previous execution results)

#code-block(`````python
@entrypoint(checkpointer=InMemorySaver())
def counter(increment: int, *, previous: int = 0) -> int:
    """Each call adds to the previous total."""
    new_total = (previous or 0) + increment
    return new_total

config = {"configurable": {"thread_id": "counter-1"}}
print("Call 1:", counter.invoke(5, {**config, **lf_config}))   # 5
print("Call 2:", counter.invoke(3, {**config, **lf_config}))   # 8
print("Call 3:", counter.invoke(10, {**config, **lf_config}))  # 18
`````)

== 3.5 entrypoint.final — Separate return and checkpoint saved values

#code-block(`````python
@entrypoint(checkpointer=InMemorySaver())
def smart_counter(number: int, *, previous: int = 0) -> entrypoint.final[str, int]:
    """Returns a formatted string, but stores the raw number for the next call."""
    new_total = (previous or 0) + number
    # value: value returned to the user
    # save: value saved as previous for next call
    return entrypoint.final(value=f"Current total: {new_total}", save=new_total)

config = {"configurable": {"thread_id": "smart-1"}}
print(smart_counter.invoke(10, {**config, **lf_config}))   # "Current total: 10"
print(smart_counter.invoke(5, {**config, **lf_config}))    # "Current total: 15"
`````)

== 3.6 Determinism Requirements

Non-deterministic operations must be wrapped in `@task`.

#code-block(`````python
import time

# CORRECT: wrapping non-deterministic tasks in @task
@task
def get_timestamp() -> float:
    return time.time()


@task
def call_llm(prompt: str) -> str:
    response = model.invoke(prompt, config=lf_config)
    return response.content


@entrypoint(checkpointer=InMemorySaver())
def deterministic_workflow(prompt: str) -> dict:
    ts = get_timestamp().result()  # Save to checkpoint, same value when re-executed
    answer = call_llm(prompt).result()

    return {
        "timestamp": ts,
        "answer": answer
    }


config = {
    "configurable": {
        "thread_id": "det-1"
    }
}

result = deterministic_workflow.invoke(
    "Please say hello in one word",
    {**config, **lf_config}
)

print(f"Timestamp: {result['timestamp']}")
print(f"Answer: {result['answer']}")
`````)

== 3.7 LLM agent (Functional API)

Implementing ReAct agent with while loop

#code-block(`````python
from langchain.tools import tool
from langchain.messages import HumanMessage, SystemMessage, ToolMessage
from langgraph.graph import add_messages

@tool
def add(a: int, b: int) -> int:
    """Add two numbers together."""
    return a + b

@tool
def multiply(a: int, b: int) -> int:
    """Multiply two numbers."""
    return a * b

tools = [add, multiply]
tools_by_name = {t.name: t for t in tools}
model_with_tools = model.bind_tools(tools)

@task
def call_model(messages: list) -> object:
    return model_with_tools.invoke(
        [SystemMessage(content="You are a math helper.")] + messages,
        config=lf_config,
)

@task
def call_tool(tool_call: dict) -> ToolMessage:
    tool_fn = tools_by_name[tool_call["name"]]
    result = tool_fn.invoke(tool_call["args"], config=lf_config)
    return ToolMessage(content=str(result), tool_call_id=tool_call["id"])

@entrypoint(checkpointer=InMemorySaver())
def agent(messages: list) -> list:
    llm_response = call_model(messages).result()

    while llm_response.tool_calls:
        tool_results = [call_tool(tc).result() for tc in llm_response.tool_calls]
        messages = add_messages(messages, [llm_response] + tool_results)
        llm_response = call_model(messages).result()

    return add_messages(messages, llm_response)

config = {"configurable": {"thread_id": "agent-1"}}
result = agent.invoke([HumanMessage(content="How much is 7 * 8 + 3?")], {**config, **lf_config})
print("agent Result:", result[-1].content)
`````)

== 3.8 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[Description],
  [`\@task`],
  [Asynchronous operations, checkpointing, parallel execution],
  [`\@entrypoint`],
  [workflow Entry point, execution management],
  [`.result()`],
  [Future Result Synchronous Waiting],
  [`previous`],
  [Access previous execution results (short-term memory)],
  [`entrypoint.final`],
  [Separate return value ≠ stored value],
)

=== Next Steps
→ _#link("./04_workflows.ipynb")[04_workflows.ipynb]_: Learn the workflow pattern.
