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

== 3.2 \@task — Asynchronous unit of work

- Checkpointing is possible by wrapping it with the `@task` decorator.
- Returns Future object immediately when called, waits with `.result()`

== 3.3 Parallel `\@task` execution

Running multiple `@task` simultaneously.

== 3.4 previous — short-term memory (accessing previous execution results)

== 3.5 entrypoint.final — Separate return and checkpoint saved values

== 3.6 Determinism Requirements

Non-deterministic operations must be wrapped in `@task`.

== 3.7 LLM agent (Functional API)

Implementing ReAct agent with while loop

== 3.8 \@task retry and caching

`@task` accepts the same policy objects as `add_node()`. `RetryPolicy` configures auto-retry, and `CachePolicy` caches results by input hash. Caching requires attaching `cache=InMemoryCache()` on the entrypoint and `cache_policy` on the task — the two are configured separately.

#code-block(`````python
from langgraph.cache.memory import InMemoryCache
from langgraph.types import RetryPolicy, CachePolicy

@task(retry_policy=RetryPolicy(max_attempts=3, retry_on=ValueError))
def fetch_data(url: str) -> dict: ...

@task(cache_policy=CachePolicy(ttl=120))
def slow_compute(x: int) -> int:
    time.sleep(1)
    return x * 2

@entrypoint(cache=InMemoryCache())
def main(inputs: dict) -> dict[str, int]:
    a = slow_compute(inputs["a"]).result()
    b = slow_compute(inputs["b"]).result()
    return {"a": a, "b": b}
`````)

== 3.9 Structured interrupt and Command(resume=)

`interrupt()` pauses the workflow for human review. Pass a structured dict payload so callers get rich context, and resume with `Command(resume=...)`.

#code-block(`````python
from langgraph.types import Command, interrupt

@task
def review(input_query: str):
    human_review = interrupt({
        "question": "Approve this result?",
        "tool_call": {"name": "send_email", "args": {...}},
    })
    return human_review

config = {"configurable": {"thread_id": "review-1"}}
workflow.invoke("draft", config=config)
workflow.invoke(Command(resume={"approved": True}), config=config)
`````)

== 3.10 \@entrypoint injected parameters

Beyond `previous`, `@entrypoint` auto-injects runtime dependencies by parameter name.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Parameter],
  text(weight: "bold")[Role],
  [`previous`],
  [Last checkpoint's saved value (short-term memory)],
  [`store`],
  [`BaseStore` instance for long-term memory],
  [`writer`],
  [`StreamWriter` for custom streaming (async + Python < 3.11)],
  [`config`],
  [`RunnableConfig` — `thread_id`, metadata, configurable values],
)

#code-block(`````python
from langgraph.types import StreamWriter

@entrypoint(checkpointer=checkpointer, store=store)
def workflow(
    inputs: dict,
    *,
    previous=None,
    store=None,
    writer: StreamWriter = None,
    config=None,
):
    writer({"phase": "start"})
    user_id = config["configurable"]["user_id"]
    memory = store.get(("users", user_id), "profile")
    ...
`````)

== 3.11 Summary

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
