// Auto-generated from 02_graph_api.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "Graph API Basics", subtitle: "Creating workflow with StateGraph")

== Learning Objectives

Understand StateGraph, nodes, edges, conditional branches, and state reducers.

== 2.1 Environment Setup

Load the LLM model and required modules.

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4")
`````)

#code-block(`````python
# Observability settings (optional) - LangSmith or Langfuse
# Keep secrets in .env or environment variables; never paste API keys into notebooks.
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

== 2.2 StateGraph basic structure

The basic flow using StateGraph is as follows:

+ Create a graph builder with `StateGraph(State)` — `state_schema`
+ `add_node()` — Node (function) registration
+ `add_edge()` — Connections between nodes
+ `compile()` — Create an executable graph
+ `invoke()` — Graph execution

#code-block(`````python
StateGraph(State) → add_node() → add_edge() → compile() → invoke()
`````)

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict


class State(TypedDict):
    text: str
    word_count: int


def count_words(state: State) -> dict:
    words = state["text"].split()
    return {
        "word_count": len(words)
    }


builder = StateGraph(State)

builder.add_node("counter", count_words)

builder.add_edge(START, "counter")
builder.add_edge("counter", END)

graph = builder.compile()


result = graph.invoke(
    {
        "text": "LangGraph is a powerful framework for building agent."
    },
    config=lf_config
)

print(f"Text: {result['text']}")
print(f"Word count: {result['word_count']}")
`````)

== 2.3 state Reducer

Specifies the state update method with `Annotated`.

=== What is a reducer?

- The reducer determines _how_ the fields in state are updated.
- No reducer: simple override
- `operator.add`: Accumulate (append) list items
- Reducers can also be defined as custom functions.

#code-block(`````python
from typing import Annotated, TypedDict
import operator

class AccState(TypedDict):
    items: Annotated[list[str], operator.add]  # list append via reducer
    count: int  # default: override


def step_a(state: AccState) -> dict:
    return {
        "items": ["from_a"],
        "count": 1
    }


def step_b(state: AccState) -> dict:
    return {
        "items": ["from_b"],
        "count": 2
    }


builder = StateGraph(AccState)

builder.add_node("a", step_a)
builder.add_node("b", step_b)

builder.add_edge(START, "a")
builder.add_edge("a", "b")
builder.add_edge("b", END)

graph = builder.compile()

result = graph.invoke(
    {
        "items": [],
        "count": 0
    },
    config=lf_config
)

print(f"items (reducer=add): {result['items']}")
# ["from_a", "from_b"]

print(f"count (override): {result['count']}")
# 2
`````)

== 2.4 Conditional Edge

Branch to another node according to state.

- `add_conditional_edges(source, routing_function)` — The return value of the routing function is the next node name.
- Routing functions can be visualized using the `Literal` type hint.

#code-block(`````python
START → classify → [route] → weather → END
                           → math    → END
                           → general → END
`````)

#code-block(`````python
from typing import Literal

class RouterState(TypedDict):
    query: str
    category: str
    result: str

def classify(state: RouterState) -> dict:
    q = state["query"].lower()
    if "weather" in q or "weather" in q:
        return {"category": "weather"}
    elif "math" in q or "calculate" in q or "calculate" in q:
        return {"category": "math"}
    return {"category": "general"}

def handle_weather(state: RouterState) -> dict:
    return {"result": f"[Weather] Checking weather for: {state['query']}"}

def handle_math(state: RouterState) -> dict:
    return {"result": f"[Math] Calculating: {state['query']}"}

def handle_general(state: RouterState) -> dict:
    return {"result": f"[General] Processing: {state['query']}"}

def route(state: RouterState) -> Literal["weather", "math", "general"]:
    return state["category"]

builder = StateGraph(RouterState)
builder.add_node("classify", classify)
builder.add_node("weather", handle_weather)
builder.add_node("math", handle_math)
builder.add_node("general", handle_general)

builder.add_edge(START, "classify")
builder.add_conditional_edges("classify", route)
builder.add_edge("weather", END)
builder.add_edge("math", END)
builder.add_edge("general", END)

graph = builder.compile()

for query in ["What's the weather like today?", "Calculate 2+2", "tell me a joke"]:
    result = graph.invoke({"query": query}, config=lf_config)
    print(f"  {query} -> {result['result']}")
`````)

== 2.5 Message-based state

Use `MessagesState` as appropriate for LLM agent.

- `MessagesState` is a predefined state that includes `messages: Annotated[list[AnyMessage], add_messages]`
- `add_messages` Reducer automatically accumulates the message list
- Naturally add LLM responses to message history

#code-block(`````python
from langgraph.graph import MessagesState
from langchain.messages import HumanMessage, SystemMessage

def chatbot(state: MessagesState) -> dict:
    response = model.invoke(state["messages"], config=lf_config)
    return {"messages": [response]}

builder = StateGraph(MessagesState)
builder.add_node("chatbot", chatbot)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

graph = builder.compile()

result = graph.invoke({"messages": [HumanMessage(content="How much is 2+2?")]}, config=lf_config)
print("response:", result["messages"][-1].content)
`````)

== 2.6 Input/Output Schema

Separate the graph's input and output from its internal state.

- `StateGraph(InternalState, input_schema=InputSchema, output_schema=OutputSchema)`
- Input schema: Includes only data received from external sources
- Output schema: Includes only data exported externally
- Internal state: Includes fields for intermediate processing (not exposed to the outside)

#code-block(`````python
from typing import TypedDict

class InputSchema(TypedDict):
    question: str


class OutputSchema(TypedDict):
    answer: str


class InternalState(TypedDict):
    question: str
    answer: str
    intermediate: str  # internal only


def process(state: InternalState) -> dict:
    return {
        "intermediate": state["question"].upper()
    }


def answer(state: InternalState) -> dict:
    return {
        "answer": f"Answer for '{state['intermediate']}': 42"
    }


builder = StateGraph(
    InternalState,
    input_schema=InputSchema,
    output_schema=OutputSchema
)

builder.add_node("process", process)
builder.add_node("answer", answer)

builder.add_edge(START, "process")
builder.add_edge("process", "answer")
builder.add_edge("answer", END)

graph = builder.compile()

result = graph.invoke(
    {
        "question": "meaning of life"
    },
    config=lf_config
)

print("output of power:", result)

# intermediate fields are not included in the output
`````)

== 2.7 Summary

We summarize what we learned in this Note book.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[concept],
  text(weight: "bold")[Description],
  [_StateGraph_],
  [`state_schema` based graph builder],
  [_Node_],
  [Processing units defined as Python functions],
  [_Edge_],
  [Fixed connection between nodes (`add_edge`)],
  [_Conditional Edge_],
  [state based dynamic branch (`add_conditional_edges`)],
  [_Reducer_],
  [Define state accumulation method with `Annotated` + `operator.add`],
  [_MessagesState_],
  [Predefined state for LLM dialog],
  [_Input/Output Schema_],
  [Separation of internal state and external input/output],
)

=== Next Steps
→ _#link("./03_functional_api.ipynb")[03_functional_api.ipynb]_: Learn Functional API.
