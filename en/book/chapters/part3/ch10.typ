// Auto-generated from 10_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Production", subtitle: "testing, deployment, observability")

== Learning Objectives

LangGraph Learn how to test, deploy, and monitor your apps.

== 10.1 Environment Setup

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

== 10.2 App structure — langgraph.json

- `langgraph.json`: Graph definition, dependencies, Environment Variables settings
- `langgraph dev`: Run local development server

#code-block(`````python
import json

config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./agent.py:graph"
    },
    "env": ".env"
}
print("langgraph.json example:")
print(json.dumps(config, indent=2))
print()
print("Command:")
print("  $ pip install 'langgraph-cli[inmem]'")
print("$ langgraph dev  # starts the local server at http://localhost:2024")
`````)

== 10.3 LangGraph Studio — Visual Debugging tool

Studio is automatically provided when you run `langgraph dev`.

_Function:_
- Graph structure visualization
- Real-time execution tracking
- Check and modify state
- Interactive testing
- Checkpoint navigation (time travel)

_How to use:_

#code-block(`````bash
$ langgraph dev
# Open http://localhost:2024 in your browser
# Or connect remotely from LangSmith Studio
`````)

== 10.4 Agent Chat UI

Talk to agent using the chat interface:

#code-block(`````bash
$ npx @anthropic-ai/agent-chat-ui
`````)
_Function:_
- Real-time streaming chat
- tool calling Visualization
- Conversation branching
- Human-in-the-loop approved
- multi-agent Message classification

== 10.5 Test — Deterministic agent test

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict

# Graph to test
class TestState(TypedDict):
    input: str
    output: str


def process(state: TestState) -> dict:
    return {"output": state["input"].upper()}


builder = StateGraph(TestState)

builder.add_node("process", process)
builder.add_edge(START, "process")
builder.add_edge("process", END)

graph = builder.compile()


# Unit tests
def test_process():
    result = graph.invoke({"input": "hello"})

    assert result["output"] == "HELLO", f"Expected HELLO, got {result['output']}"

    print("  OK test_process")


def test_empty_input():
    result = graph.invoke({"input": ""})

    assert result["output"] == "", f"Expected an empty string, got {result['output']}"

    print("  OK test_empty_input")


print("Running tests:")

test_process()
test_empty_input()

print("All tests passed!")
`````)

== 10.6 LLM agent Test — Using GenericFakeChatModel

#code-block(`````python
from langchain_core.language_models import GenericFakeChatModel
from langchain.messages import AIMessage, HumanMessage, AnyMessage
from langgraph.graph import StateGraph, START, END, MessagesState

# Deterministic fake model
fake_model = GenericFakeChatModel(
    messages=iter(
        [
            AIMessage(content="The answer is 42."),
        ]
    )
)

def chatbot(state: MessagesState) -> dict:
    return {
        "messages": [fake_model.invoke(state["messages"])]
    }

builder = StateGraph(MessagesState)

builder.add_node("chatbot", chatbot)
builder.add_edge(START, "chatbot")
builder.add_edge("chatbot", END)

test_graph = builder.compile()

result = test_graph.invoke(
    {
        "messages": [HumanMessage(content="test")]
    }
)

assert "42" in result["messages"][-1].content

print("GenericFakeChatModel test passed!")
print(f"  Response: {result['messages'][-1].content}")
`````)

== 10.7 Deployment Options

_1. LangGraph Platform (managed):_
#code-block(`````bash
$ langgraph deploy
`````)

_2. Self-hosted Docker:_
#code-block(`````bash
$ langgraph build -t my-agent
$ docker run -p 2024:2024 my-agent
`````)
_3. LangGraph Cloud:_
- Automatic distribution linked to GitHub
- Managed by https://smith.langchain.com

== 10.8 observability — LangSmith Tracing

_Settings (`.env`):_

#code-block(`````python
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_TRACING=true
`````)
_Automatically tracked items:_
- Each node execution time
- LLM input/output, token usage
- tool calling and results
- state Change
- Errors and retries

#code-block(`````python
import os

tracing = os.environ.get("LANGSMITH_TRACING", "false")
api_key = os.environ.get("LANGSMITH_API_KEY", "")

print("Current state:")

print(f"  Tracing: {'enabled' if tracing == 'true' else 'disabled'}")
print(f"  API key: {'configured' if api_key else 'not set'}")
`````)

== 10.9 Pregel Runtime Overview

- _Pregel_ is the internal execution engine of LangGraph
- Both Graph API and Functional API run on Pregel
- Key concepts: _superstep_, _Channel_, _Checkpoint_
- _superstep_: Unit in which nodes of the same level are executed in parallel
- Generally no need to use it directly (Graph/Functional API abstracts it)

_LangGraph Execution Model:_

#code-block(`````python
[Super-step 1] Node A, Node B (parallel)
     ↓ State update
[Super-step 2] Node C (based on the results of A and B)
     ↓ State update
[Super-step 3] Node D
     ↓
END
`````)
_Each superstep:_
+ Parallel execution of relevant nodes
+ Update state (apply reducer)
+ Save checkpoint
+ Next superstep decision

== 10.10 Production Checklist

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[tool],
  text(weight: "bold")[Description],
  [unit testing],
  [pytest],
  [Test individual node functions],
  [Integration Testing],
  [GenericFakeChatModel],
  [Full flow without API calls],
  [persistence],
  [PostgreSaver],
  [Production checkpointer],
  [observability],
  [LangSmith],
  [Tracing, Monitoring],
  [Distribution],
  [langgraph deploy],
  [Managed Deployment],
  [UI],
  [Agent Chat UI],
  [User Interface],
)

== 10.11 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Concepts],
  [App Structure],
  [Set up project with `langgraph.json`],
  [Studio],
  [Visual debugging with `langgraph dev`],
  [test],
  [Deterministic Testing + GenericFakeChatModel],
  [Distribution],
  [Platform, Docker, Cloud options],
  [observability],
  [LangSmith Tracing],
  [runtime],
  [Pregel superstep Execution Model → Deeper in \#link("13_api_guide_and_pregel.ipynb")[Chapter 13]],
)

=== Next Steps
→ Proceed to _#link("11_local_server.ipynb")[11. Local Server]_!
→ Skip to _#link("../04_deepagents/01_introduction.ipynb")[Deep Agents track]_
