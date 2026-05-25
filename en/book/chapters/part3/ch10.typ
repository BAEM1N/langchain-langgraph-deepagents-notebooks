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

_Key Features (7):_
+ _Real-time Visualization_ --- every step the agent takes (prompts, tool calls, results, final output) is rendered live.
+ _Interactive Testing_ --- drive different inputs and inspect intermediate states directly in the UI.
+ _Hot-reloading_ --- edits to prompts or tool signatures are reflected immediately without restarting the server.
+ _Trace Inspection_ --- execution traces include prompts, tool arguments, return values, token counts, and latency.
+ _Exception Capture_ --- exceptions are captured together with surrounding state for debugging context.
+ _Thread Replay_ --- re-run conversation threads from any step to validate changes without restarting.
+ _Optional Tracing_ --- set `LANGSMITH_TRACING=false` to keep run data on the local machine.

_How to use:_
#code-block(`````bash
$ langgraph dev
# Open https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
# Safari users append --tunnel
`````)

== 10.4 Agent Chat UI

Agent Chat UI is a Next.js chat interface for LangChain agents. It integrates directly with agents built using `create_agent` and connects to either a `langgraph dev` server or a deployed server.

_Install --- npx (recommended):_
#code-block(`````bash
$ npx create-agent-chat-app --project-name my-chat-ui
$ cd my-chat-ui
$ pnpm install
$ pnpm dev
`````)

_Hosted version:_ visit #link("https://agentchat.vercel.app")[agentchat.vercel.app] and enter your agent's deployment URL or local server address.

_Connection info:_
- _Graph ID_ --- the key in the `graphs` section of `langgraph.json`
- _Deployment URL_ --- the agent server URL (use `http://localhost:2024` for local)
- _LangSmith API key_ --- optional (not required when using a local server)

_Features:_
- Real-time streaming chat
- Tool call / result rendering
- Time-travel debugging, state forking
- Human-in-the-loop interrupt handling
- Generative UI support

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

_1. LangSmith Cloud (managed):_

Connect a GitHub repository in LangSmith Deployments and the platform deploys automatically (around 15 minutes):

+ Push your application code to a GitHub repository (public or private)
+ In LangSmith, open _Deployments_ and click _"+ New Deployment"_
+ For private repos, connect your GitHub account, then select and submit the repository
+ After deployment, open Studio from the deployment page and copy the API URL from Deployment details

_2. Self-hosted Docker:_
#code-block(`````bash
$ langgraph build -t my-agent
$ docker run -p 2024:2024 my-agent
`````)

_3. Calling the deployed API (Python SDK):_

Pass the deployment URL and your LangSmith API key to the same SDK used locally.

#code-block(`````python
from langgraph_sdk import get_sync_client

client = get_sync_client(url="your-deployment-url", api_key="your-langsmith-api-key")

for chunk in client.runs.stream(
    None,                                              # thread_id=None creates a stateless run
    "agent",                                           # graph name in langgraph.json
    input={"messages": [{"role": "human", "content": "What is LangGraph?"}]},
    stream_mode="updates",
):
    print(f"Receiving new event of type: {chunk.event}...")
    print(chunk.data)
`````)

_REST call:_ deployed servers authenticate via the `X-Api-Key` header.

#code-block(`````bash
curl -s --request POST \
    --url <DEPLOYMENT_URL>/runs/stream \
    --header 'Content-Type: application/json' \
    --header "X-Api-Key: <LANGSMITH API KEY>" \
    --data '{"assistant_id": "agent", "input": {"messages": [{"role": "human", "content": "What is LangGraph?"}]}, "stream_mode": "updates"}'
`````)

== 10.8 Observability — LangSmith Tracing

_Settings (`.env`):_
#code-block(`````bash
LANGSMITH_TRACING=true
LANGSMITH_API_KEY=lsv2-...
LANGSMITH_PROJECT=my-agent-project   # optional, defaults to "default"
`````)

`LANGSMITH_TRACING` and `LANGSMITH_API_KEY` are required; `LANGSMITH_PROJECT` is optional.

_Automatically tracked items:_
- Each node execution time
- LLM input/output, token usage
- Tool calls and results
- State changes
- Errors and retries

=== Selective tracing --- `tracing_context`

Use the `langsmith.tracing_context` context manager to toggle tracing for specific operations and to attach project / tags / metadata dynamically.

#code-block(`````python
import langsmith as ls

# Only this call is traced
with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "Send a test email"}]})

# Dynamic project + tags + metadata
with ls.tracing_context(
    project_name="email-agent-test",
    enabled=True,
    tags=["production", "email-assistant", "v1.0"],
    metadata={"user_id": "user_123", "session_id": "session_456"},
):
    agent.invoke({"messages": [{"role": "user", "content": "Send a welcome email"}]})
`````)

You can also pass tags and metadata through the `config` argument of `invoke()`:

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "Send a welcome email"}]},
    config={
        "tags": ["production", "email-assistant", "v1.0"],
        "metadata": {"user_id": "user_123", "session_id": "session_456"},
    },
)
`````)

=== Data privacy --- `LangChainTracer` + `with_config`

To avoid leaking sensitive data into traces, wire an anonymized `Client` into a `LangChainTracer` and attach it to the compiled graph via `.with_config({"callbacks": [tracer]})`.

#code-block(`````python
from langchain_core.tracers.langchain import LangChainTracer
from langgraph.graph import StateGraph, MessagesState
from langsmith import Client
from langsmith.anonymizer import create_anonymizer

anonymizer = create_anonymizer([
    {"pattern": r"\b\d{3}-?\d{2}-?\d{4}\b", "replace": "<ssn>"},
])

tracer_client = Client(anonymizer=anonymizer)
tracer = LangChainTracer(client=tracer_client)

graph = (
    StateGraph(MessagesState)
    # .add_node(...).add_edge(...)
    .compile()
    .with_config({"callbacks": [tracer]})
)
`````)

This pattern masks identifiable patterns (e.g., SSNs) just before sending traces to LangSmith.

== 10.9 Pregel Runtime Overview

- _Pregel_ is the internal execution engine of LangGraph
- Both Graph API and Functional API run on Pregel
- Key concepts: _superstep_, _Channel_, _Checkpoint_
- _superstep_: Unit in which nodes of the same level are executed in parallel
- Generally no need to use it directly (Graph/Functional API abstracts it)

_LangGraph Execution Model:_
[Super-step 1] Node A, Node B (parallel)
↓ State update
[Super-step 2] Node C (based on the results of A and B)
↓ State update
[Super-step 3] Node D
↓
END
#code-block(`````python
*Each superstep:*
1. Parallel execution of relevant nodes
2. Update state (apply reducer)
3. Save checkpoint
4. Next superstep decision
`````)

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
  [Pregel superstep Execution Model → Deeper in #link("13_api_guide_and_pregel.ipynb")[Chapter 13]],
)

=== Next Steps
→ Proceed to _#link("11_local_server.ipynb")[11. Local Server]_!
→ Skip to _#link("../04_deepagents/01_introduction.ipynb")[Deep Agents track]_
