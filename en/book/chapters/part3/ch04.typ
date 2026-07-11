// Auto-generated from 04_workflows.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "workflow Pattern", subtitle: "5 core patterns")

== Learning Objectives

Understand Prompt Chaining, Parallelization, Routing, Orchestrator-Worker, and Evaluator-Optimizer patterns.

== 4.1 Environment Setup

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

== 4.2 Prompt Chaining — Sequential LLM calls

- The output of each step becomes the input of Next Steps
- Purpose: Translation → Verification → Proofreading, Analysis → Summary → Formatting

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

class ChainState(TypedDict):
    topic: str
    draft: str
    improved: str

def generate_draft(state: ChainState) -> dict:
    response = model.invoke(f"Write one factual sentence about the following topic: {state['topic']}", config=lf_config)
    return {"draft": response.content}

def improve_draft(state: ChainState) -> dict:
    response = model.invoke(f"Improve the following text so it sounds more engaging: {state['draft']}", config=lf_config)
    return {"improved": response.content}

builder = StateGraph(ChainState)
builder.add_node("draft", generate_draft)
builder.add_node("improve", improve_draft)
builder.add_edge(START, "draft")
builder.add_edge("draft", "improve")
builder.add_edge("improve", END)

chain = builder.compile()
result = chain.invoke({"topic": "Python programming"}, config=lf_config)
print(f"Draft: {result['draft']}")
print(f"Improved: {result['improved']}")
`````)

== 4.3 Parallelization — Simultaneous execution of independent `\@task`

#code-block(`````python
from typing import Annotated, TypedDict
import operator


class ParallelState(TypedDict):
    text: str
    analyses: Annotated[list[str], operator.add]


def analyze_tone(state: ParallelState) -> dict:
    r = model.invoke(
        f"Describe the tone of the following text in one sentence: {state['text']}",
        config=lf_config
    )
    return {
        "analyses": [f"Tone: {r.content}"]
    }


def analyze_complexity(state: ParallelState) -> dict:
    r = model.invoke(
        f"Evaluate the complexity of the following text in one sentence: {state['text']}",
        config=lf_config
    )
    return {
        "analyses": [f"Complexity: {r.content}"]
    }


def synthesize(state: ParallelState) -> dict:
    return {
        "analyses": [
            f"Combined summary: {len(state['analyses'])} analyses completed"
        ]
    }


builder = StateGraph(ParallelState)

builder.add_node("tone", analyze_tone)
builder.add_node("complexity", analyze_complexity)
builder.add_node("synthesize", synthesize)

# Parallel branch from START to two analysis nodes
builder.add_edge(START, "tone")
builder.add_edge(START, "complexity")

# Composite after completing two nodes
builder.add_edge("tone", "synthesize")
builder.add_edge("complexity", "synthesize")
builder.add_edge("synthesize", END)

parallel_graph = builder.compile()

result = parallel_graph.invoke(
    {
        "text": "LangGraph enables the powerful agent workflow.",
        "analyses": []
    },
    config=lf_config
)

for a in result["analyses"]:
    print(f"  {a}")
`````)

== 4.4 Routing — Classification-based branching

#image("../../assets/images/conditional_routing.png")

#code-block(`````python
from pydantic import BaseModel, Field
from typing import Literal, TypedDict


class Classification(BaseModel):
    category: Literal["technical", "business", "casual"]


class RouteState(TypedDict):
    question: str
    category: str
    answer: str


def classify(state: RouteState) -> dict:
    structured = model.with_structured_output(Classification)
    result = structured.invoke(
        f"Classify the following question: {state['question']}",
        config=lf_config
    )
    return {"category": result.category}


def handle_technical(state: RouteState) -> dict:
    r = model.invoke(
        f"Answer as a technical expert: {state['question']}",
        config=lf_config
    )
    return {"answer": r.content}


def handle_business(state: RouteState) -> dict:
    r = model.invoke(
        f"Answer as a business advisor: {state['question']}",
        config=lf_config
    )
    return {"answer": r.content}


def handle_casual(state: RouteState) -> dict:
    r = model.invoke(
        f"Answer casually: {state['question']}",
        config=lf_config
    )
    return {"answer": r.content}


def route(state: RouteState) -> str:
    return state["category"]


builder = StateGraph(RouteState)

builder.add_node("classify", classify)
builder.add_node("technical", handle_technical)
builder.add_node("business", handle_business)
builder.add_node("casual", handle_casual)

builder.add_edge(START, "classify")
builder.add_conditional_edges("classify", route)

builder.add_edge("technical", END)
builder.add_edge("business", END)
builder.add_edge("casual", END)

router = builder.compile()

result = router.invoke(
    {
        "question": "How does garbage collection work in Python?"
    },
    config=lf_config
)

print(f"Category: {result['category']}")
print(f"Answer: {result['answer'][:200]}")
`````)

== 4.5 Orchestrator-Worker — Create dynamic worker with Send()

#image("../../assets/images/orchestrator_worker.png")

#code-block(`````python
from langgraph.types import Send
from typing import Annotated, TypedDict
import operator


class OrchestratorState(TypedDict):
    topic: str
    sections: list[str]
    results: Annotated[list[str], operator.add]


class WorkerState(TypedDict):
    section: str


def plan_sections(state: OrchestratorState) -> dict:
    r = model.invoke(
        f"List three short section titles for an article about '{state['topic']}'. Put one per line with no numbering.",
        config=lf_config
    )

    sections = [
        s.strip()
        for s in r.content.strip().split("\n")
        if s.strip()
    ][:3]

    return {"sections": sections}


def assign_workers(state: OrchestratorState) -> list[Send]:
    return [
        Send("worker", {"section": s})
        for s in state["sections"]
    ]


def worker(state: WorkerState) -> dict:
    r = model.invoke(
        f"Write one sentence about the following section: {state['section']}",
        config=lf_config
    )

    return {
        "results": [
            f"## {state['section']}\n{r.content}"
        ]
    }


builder = StateGraph(OrchestratorState)

builder.add_node("plan", plan_sections)
builder.add_node("worker", worker)

builder.add_edge(START, "plan")

builder.add_conditional_edges(
    "plan",
    assign_workers,
    ["worker"]
)

builder.add_edge("worker", END)

orchestrator = builder.compile()

result = orchestrator.invoke(
    {
        "topic": "machine learning",
        "sections": [],
        "results": []
    },
    config=lf_config
)

for r in result["results"]:
    print(r)
    print()
`````)

== 4.6 Evaluator-Optimizer — Generate-evaluation iteration loop

#code-block(`````python
class EvalState(TypedDict):
    task: str
    draft: str
    feedback: str
    is_good: bool
    iterations: int

def generate(state: EvalState) -> dict:
    if state.get("feedback"):
        prompt = f"Improve the draft using the feedback below.\nOriginal: {state['draft']}\nFeedback: {state['feedback']}"
    else:
        prompt = f"Write a one-sentence slogan for the following task: {state['task']}"
    r = model.invoke(prompt, config=lf_config)
    return {"draft": r.content, "iterations": state.get("iterations", 0) + 1}

def evaluate(state: EvalState) -> dict:
    r = model.invoke(f"Rate this slogan from 1 to 10 and give brief feedback: '{state['draft']}'", config=lf_config)
    content = r.content
    is_good = any(f"{n}/10" in content for n in range(8, 11))
    return {"feedback": content, "is_good": is_good}

def should_retry(state: EvalState) -> str:
    if state["is_good"] or state["iterations"] >= 3:
        return END
    return "generate"

builder = StateGraph(EvalState)
builder.add_node("generate", generate)
builder.add_node("evaluate", evaluate)

builder.add_edge(START, "generate")
builder.add_edge("generate", "evaluate")
builder.add_conditional_edges("evaluate", should_retry, ["generate", END])

optimizer = builder.compile()
result = optimizer.invoke({"task": "Python learning platform"}, config=lf_config)
print(f"Final draft (after {result['iterations']} iterations): {result['draft']}")
`````)

== 4.7 Pattern comparison table

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[pattern],
  text(weight: "bold")[decisive],
  text(weight: "bold")[Parallel],
  text(weight: "bold")[repeat],
  text(weight: "bold")[suitable situation],
  [Prompt Chaining],
  [O],
  [X],
  [sequential],
  [Step-by-step conversion],
  [Parallelization],
  [O],
  [O],
  [X],
  [Independent Analysis],
  [Routing],
  [O],
  [X],
  [X],
  [Classification-based processing],
  [Orchestrator-Worker],
  [O],
  [O],
  [X],
  [Dynamic Subtasks],
  [Evaluator-Optimizer],
  [X],
  [X],
  [O],
  [Quality Improvement Loop],
)

=== Next Steps
→ _#link("./05_agents.ipynb")[05_agents.ipynb]_: Build ReAct agent.
