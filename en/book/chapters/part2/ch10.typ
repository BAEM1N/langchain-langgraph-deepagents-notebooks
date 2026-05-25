// Auto-generated from 10_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(10, "Production")


== Learning Objectives

Learn how to test, deploy, and monitor agents.

This notebook covers:
- Local development and debugging with LangSmith Studio
- Deterministic agent testing with `GenericFakeChatModel`
- Trajectory-based tests for validating tool call order
- Web-based interaction with Agent Chat UI
- Deployment with LangGraph Platform or your own server
- Observability with LangSmith


== 10.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("Environment ready.")
`````)

== 10.2 LangSmith Studio

Develop and debug agents locally.

To use Studio, you need:
- a `langgraph.json` config file
- a local dev server started with `langgraph dev` (default `http://127.0.0.1:2024`)
- the hosted Studio UI at `https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024`

Studio is a powerful tool for visualizing agent execution flow and debugging each step.

=== Studio Key Features

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Feature],
  text(weight: "bold")[Description],
  [_Hot-reloading_],
  [Edit prompts and tool code and see the change applied without restarting the server],
  [_Full execution trace inspection_],
  [Inspect every node, model call, and tool invocation in a single trace tree],
  [_Thread replay_],
  [Re-run saved threads from any checkpoint to compare branches and behaviors],
  [_Exception capture_],
  [Capture the state and surrounding context at the moment an exception is raised],
)


#code-block(`````python
# Example langgraph.json configuration
import json

langgraph_config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./agent.py:agent"
    },
    "env": ".env"
}

print("Example langgraph.json configuration:")
print(json.dumps(langgraph_config, indent=2))
print("\nHow to run:")
print("  $ langgraph dev  # local dev server: http://127.0.0.1:2024")
print("  → Studio UI: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024")
`````)

== 10.3 Agent Testing

Agent testing has three layers: _Unit_, _Integration_, and _Evals_.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Layer],
  text(weight: "bold")[Goal],
  text(weight: "bold")[Tools],
  [_Unit_],
  [Validate agent logic deterministically (tool choice, branching, exit conditions)],
  [`GenericFakeChatModel`, `pytest`],
  [_Integration_],
  [Run the full workflow against real LLMs and tools to confirm end-to-end behavior],
  [`langgraph dev`, real server environments],
  [_Evals_],
  [Evaluate agent trajectories with deterministic matching or LLM-as-judge evaluators],
  [`agentevals`, LangSmith Evaluations],
)

=== 10.3.1 Unit — `GenericFakeChatModel`

With `GenericFakeChatModel`, you can test an agent deterministically without making real API calls.

Benefits of this approach:
- No API cost during tests
- Always returns the same result, which is ideal for CI/CD pipelines
- Lets you validate the agent's logic independently (tool calls, branching, and so on)


#code-block(`````python
from langchain_core.language_models import GenericFakeChatModel
from langchain.messages import AIMessage
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def get_capital(country: str) -> str:
    """Returns the capital of a country."""
    capitals = {"Korea": "Seoul", "Japan": "Tokyo", "France": "Paris"}
    return capitals.get(country, "Unknown")

# Deterministic test with a fake model
fake_model = GenericFakeChatModel(
    messages=iter([
        AIMessage(content="The capital of South Korea is Seoul.")
    ])
)

# Test agent
test_agent = create_agent(
    model=fake_model,
    tools=[get_capital],
    system_prompt="You are a geography expert.",
)

print("GenericFakeChatModel test:")
print("  → Tests agent behavior with deterministic responses")
print("  → Can be tested in CI/CD without live API calls")
`````)

=== 10.3.2 Evals — Trajectory matching with `agentevals`

Validate the order in which the agent calls tools. A trajectory test checks whether the agent uses tools in the expected order and whether the final response matches your expectation.

The `agentevals` package offers four trajectory-match modes.

#code-block(`````bash
pip install agentevals
`````)

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Mode],
  text(weight: "bold")[Matching rule],
  [`strict`],
  [Tool calls must match the reference exactly in kind and order],
  [`unordered`],
  [Same set of tool calls; order is ignored],
  [`subset`],
  [The observed trajectory is a subset of the reference (no extra calls allowed)],
  [`superset`],
  [The observed trajectory is a superset of the reference (must contain the required calls)],
)

LLM-as-judge evaluators allow grading trajectories against natural-language criteria as well.


#code-block(`````python
# Example trajectory test
def test_agent_trajectory():
    """Tests whether the agent calls tools in the expected order."""
    result = test_agent.invoke(
        {"messages": [{"role": "user", "content": "What is the capital of South Korea?"}]}
    )
    
    messages = result["messages"]
    
    # Check: verify that messages exist
    assert len(messages) > 0, "The agent did not respond"
    
    # Check: verify that the last message is an AI response
    last_msg = messages[-1]
    assert hasattr(last_msg, 'content'), "The last message does not contain content"
    
    print("✓ Trajectory test passed")
    print(f"  Message count: {len(messages)}")
    print(f"  Final response: {last_msg.content[:100]}")

try:
    test_agent_trajectory()
except Exception as e:
    print(f"Testing note: {e}")
`````)

== 10.5 Agent Chat UI

This is a web UI for talking to your agent. It connects to a LangGraph server so you can test the agent directly in the browser. Either scaffold a new project with `create-agent-chat-app` or clone the official repository (`langchain-ai/agent-chat-ui`). Point the UI at your local LangGraph server (`http://127.0.0.1:2024`).

Key features:
- Real-time streaming chat
- Tool call visualization
- Conversation branching
- Human-in-the-loop approval

Pick one of the two install paths:

#code-block(`````bash
# Option A — scaffold (recommended)
npx create-agent-chat-app --project-name my-chat-ui

# Option B — clone the official repository
git clone https://github.com/langchain-ai/agent-chat-ui.git
cd agent-chat-ui && pnpm install && pnpm dev
`````)

#code-block(`````bash
# Start the LangGraph server in another shell
langgraph dev   # http://127.0.0.1:2024
`````)

The UI asks for three values on first launch.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Field],
  text(weight: "bold")[Value],
  [_Deployment URL_],
  [`http://127.0.0.1:2024` for local; the deployment URL for managed agents],
  [_Graph ID_],
  [The `graphs` key from `langgraph.json` (for example, `agent`)],
  [_LangSmith API key_],
  [Required for managed deployments; can be skipped for the local dev server],
)

== 10.6 Deployment

You can deploy an agent through LangGraph Platform (managed) or your own server. Choose the option that best fits your production environment.

=== 10.6.1 LangGraph Platform deploy workflow

LangGraph Platform deployments now go through GitHub integration. The old single-command `langgraph deploy` flow is no longer recommended.

1. Push the agent code (including `langgraph.json`) to a GitHub repository.
2. Open the LangSmith console → _Deployments_ → _+ New Deployment_.
3. Select the repository, branch, and `langgraph.json` path.
4. Enter environment variables (`OPENAI_API_KEY`, etc.).
5. Click _Deploy_, watch the build log, and pick up the issued Deployment URL.

#warning-box[The `langgraph deploy` CLI flow from older guides is _deprecated_. Use the GitHub-based flow in the LangSmith console for new deployments.]


#code-block(`````python
print("Deployment options:")
print("=" * 50)

print("""
# Option 1: LangGraph Platform (managed) — GitHub integration
#   → Use LangSmith Deployments → + New Deployment
#   (legacy `langgraph deploy` CLI pattern is deprecated)


# Option 2: self-hosted Docker deployment
`$ langgraph build -t my-agent`
`$ docker run -p 2024:2024 my-agent`


# Option 3: wrap with FastAPI/Flask
from fastapi import FastAPI

app = FastAPI()


@app.post("/chat")
async def chat(message: str):
    result = agent.invoke(
        {
            "messages": [
                {
                    "role": "user",
                    "content": message
                }
            ]
        }
    )

    return {
        "response": result["messages"][-1].content
    }
""")
`````)

=== 10.6.2 Calling a deployed agent — `langgraph-sdk`

Use the Python SDK or REST to call a deployed agent.

#code-block(`````bash
pip install langgraph-sdk
`````)

#code-block(`````python
from langgraph_sdk import get_sync_client

client = get_sync_client(url="http://127.0.0.1:2024")

for chunk in client.runs.stream(
    None,  # threadless run
    "agent",  # graph ID
    input={"messages": [{"role": "user", "content": "hi"}]},
    stream_mode="updates",
):
    print(chunk)
`````)

Or call the REST API directly:

#code-block(`````bash
curl -X POST http://127.0.0.1:2024/runs/stream \
  -H "Content-Type: application/json" \
  --data '{
    "assistant_id": "agent",
    "input": {"messages": [{"role": "user", "content": "hi"}]},
    "stream_mode": "updates"
  }'
`````)

== 10.7 Observability

Use LangSmith to trace agent behavior. When tracing is enabled, every step of agent execution is recorded and can be analyzed.

=== 10.7.1 Environment variables

#code-block(`````bash
# Current (recommended)
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY="lsv2_..."
export LANGSMITH_PROJECT="my-agent"   # defaults to `default` if unset
`````)


LangSmith lets you inspect:
- The complete execution flow of each agent call
- Model input/output, tool calls, and token usage
- Latency, errors, and cost tracking

=== 10.7.2 Selective tracing with `tracing_context`

Use `tracing_context` to enable or disable tracing for a specific block in code.

#code-block(`````python
import langsmith as ls

with ls.tracing_context(enabled=True):
    agent.invoke({"messages": [{"role": "user", "content": "hi"}]})
`````)

=== 10.7.3 Tags and metadata via `config`

Attach tags and metadata at call time to make trace search and filtering easier.

#code-block(`````python
agent.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    config={
        "tags": ["production", "v1.0"],
        "metadata": {"user_id": "123", "session_id": "456"},
    },
)
`````)


== 10.8 Production Checklist

Before deploying an agent to production, review the following checklist.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Tool],
  text(weight: "bold")[Status],
  [Unit tests],
  [`GenericFakeChatModel`, `pytest`],
  [],
  [Trajectory tests],
  [Custom validation functions],
  [],
  [Observability],
  [LangSmith tracing],
  [],
  [Error handling],
  [`try/except`, retry logic],
  [],
  [Security],
  [API key management, input validation, guardrails],
  [],
  [Deployment environment],
  [Docker, LangGraph Platform],
  [],
  [Monitoring],
  [LangSmith dashboards, alert configuration],
  [],
  [Documentation],
  [API docs, agent behavior notes],
  [],
)


== 10.9 Summary

This notebook covered:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Idea],
  [_LangSmith Studio_],
  [Use `langgraph dev` to debug agents visually on your local machine],
  [_Agent testing_],
  [Run deterministic tests with `GenericFakeChatModel` and no API calls],
  [_Trajectory tests_],
  [Validate tool call order and final responses],
  [_Agent Chat UI_],
  [Talk to agents in the browser and visualize tool usage],
  [_Deployment_],
  [Deploy with LangGraph Platform, Docker, FastAPI, and related options],
  [_Observability_],
  [Use LangSmith to track execution flow, token usage, and cost],
)

This completes the LangChain v1 agent track. You covered the full lifecycle of agent development, from basic concepts to production deployment.

=== Next Steps
→ Continue to _#link("./11_mcp.ipynb")[11_mcp.ipynb]_
→ Or jump to the _#link("../03_langgraph/01_introduction.ipynb")[LangGraph intermediate track]_

