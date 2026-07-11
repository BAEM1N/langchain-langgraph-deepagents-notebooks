// Auto-generated from 08_interrupts_and_time_travel.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(8, "Interrupts and Time Travel", subtitle: "Execute interrupt, Acknowledge, Rewind")

== Learning Objectives

Execute with `interrupt()`, interrupt, and resume with `Command(resume=...)`. Time travel back to the previous state.

- Human-in-the-loop pattern can be implemented
- Interrupt can also be used in Functional API
- You can perform time travel using checkpoint history.
- state can be modified externally with `update_state()`

== 8.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-5.4")
print("Model is ready")
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

== 8.2 interrupt() — executes interrupt and waits for human input

- `interrupt(value)`: Save the current state to the checkpoint and execute interrupt
- `Command(resume=value)`: Passes the value at interrupt point and resume

This pattern is used to obtain human approval or input additional information before performing sensitive tasks.

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver
from typing import TypedDict


class ReviewState(TypedDict):
    document: str
    approved: bool
    final_result: str


def draft_document(state: ReviewState) -> dict:
    return {
        "document": f"Draft: important document about {state.get('document', 'the topic')}"
    }


def human_review(state: ReviewState) -> dict:
    # wait for human approval
    decision = interrupt(
        {
            "document": state["document"],
            "question": "Would you like to approve this document? (yes/no)"
        }
    )

    return {
        "approved": decision == "yes"
    }


def finalize(state: ReviewState) -> dict:
    if state["approved"]:
        return {
            "final_result": f"Approved: {state['document']}"
        }

    return {
        "final_result": f"Rejected: {state['document']}"
    }


builder = StateGraph(ReviewState)

builder.add_node("draft", draft_document)
builder.add_node("review", human_review)
builder.add_node("finalize", finalize)

builder.add_edge(START, "draft")
builder.add_edge("draft", "review")
builder.add_edge("review", "finalize")
builder.add_edge("finalize", END)

graph = builder.compile(
    checkpointer=InMemorySaver()
)

config = {
    "configurable": {
        "thread_id": "review-1"
    }
}

# Step 1: Run → interrupt in review node
result = graph.invoke(
    {
        "document": "AI safety"
    },
    {**config, **lf_config}
)

print("Step 1 - interrupt in review")

state = graph.get_state(config)

print(f"  Next node: {state.next}")
print(f"  Interrupt value: {state.tasks}")
`````)

== 8.3 Command(resume=...) — interrupt executes resume

Using `Command(resume=value)` causes execution to resume at the point where `interrupt()` is called. The value passed to `resume` becomes the return value of `interrupt()`.

#code-block(`````python
from typing import TypedDict
from langgraph.types import interrupt, Command

class ApprovalState(TypedDict):
    topic: str
    document: str
    final_result: str


def create_draft(state: ApprovalState) -> dict:
    return {
        "document": f"Draft: important document about {state.get('document', 'the topic')}"
    }


def review_document(state: ApprovalState) -> dict:
    decision = interrupt({"document": state["document"], "action": "review"})

    if decision == "approve":
        return {
            "final_result": f"Approved: {state['document']}"
        }

    return {
        "final_result": f"Rejected: {state['document']}"
    }

`````)

== 8.4 Interrupt in Functional API

You can also use `interrupt()` in the Functional API (`@entrypoint`, `@task`).

#code-block(`````python
from langgraph.graph import StateGraph, START, END

builder = StateGraph(ApprovalState)
builder.add_node("create_draft", create_draft)
builder.add_node("review_document", review_document)
builder.add_edge(START, "create_draft")
builder.add_edge("create_draft", "review_document")
builder.add_edge("review_document", END)

graph = builder.compile()

result = graph.invoke({"topic": "LangGraph", "document": "LangGraph overview"}, config=lf_config)
print(f"  Interrupt value: {result}")

`````)

== 8.5 Time Travel — Go back to a previous checkpoint

The checkpoint system in LangGraph stores all executions of state. You can view previous checkpoints with `get_state_history()` and go back to a specific point in time.

#code-block(`````python
# Resume with approval
print(f"Step 2 - resumed after approval")

`````)

== 8.6 update_state() — Time travel + state fix

`update_state()` allows you to directly modify the state of a graph from the outside. This is useful for debugging, testing, or when manual intervention is required.

#code-block(`````python
def suggest(topic: str) -> str:
    response = model.invoke(f"Write a one-sentence suggestion about the following topic: {topic}", config=lf_config)
    return response.content

`````)

== 8.7 Input validation — one interrupt per node invocation

A resumed node starts again from its first line. Call `interrupt()` once, store an invalid-answer prompt in state, and let a conditional edge route back. A `while True` loop around multiple interrupt calls replays prior iterations and causes exponential re-execution.

#code-block(`````python
class FormState(TypedDict):
    age: int | None
    pending_question: str | None

def collect_age(state: FormState) -> dict:
    question = state.get("pending_question") or "Enter a positive age."
    answer = interrupt(question)
    if isinstance(answer, int) and answer > 0:
        return {"age": answer, "pending_question": None}
    return {"pending_question": f"'{answer}' is invalid. Enter a positive integer."}

`````)

#code-block(`````python
def route_age(state: FormState) -> str:
    return END if state.get("age") is not None else "collect_age"

builder = StateGraph(FormState)
builder.add_node("collect_age", collect_age)
builder.add_edge(START, "collect_age")
builder.add_conditional_edges("collect_age", route_age)
age_graph = builder.compile(checkpointer=InMemorySaver())

`````)

#code-block(`````python
config = {"configurable": {"thread_id": "validation-en"}}
result = age_graph.invoke({"age": None, "pending_question": None}, config, version="v2")
print(result.interrupts[0].value)
result = age_graph.invoke(Command(resume=-5), config, version="v2")
print(result.interrupts[0].value)
result = age_graph.invoke(Command(resume=30), config, version="v2")
print(result.value["age"])

`````)

== 8.8 Summary

Summary of the key functions in this notebook.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[API],
  text(weight: "bold")[Description],
  [`interrupt(value)`],
  [Both sides],
  [run interrupt, pass value],
  [`Command(resume=value)`],
  [Both sides],
  [resume at point interrupt],
  [Input validation],
  [`add_conditional_edges()`],
  [one interrupt per node invocation],
  [`get_state_history()`],
  [Graph],
  [Checkpoint history inquiry],
  [`update_state()`],
  [Graph],
  [Modify state externally],
)

_interrupts and time travel_ are key features in production AI applications:
- _interrupt_: Get human approval before sensitive operations
- _Time Travel_: You can go back to the previous state and explore different routes
- _update_state_: You can adjust the execution flow by modifying state externally.

=== Next Steps
→ _#link("./09_subgraphs.ipynb")[09_subgraphs.ipynb]_: Learn subgraphs.
