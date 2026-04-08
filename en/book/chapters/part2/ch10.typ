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
    model="gpt-4.1",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("Environment ready.")
`````)

== 10.2 LangSmith Studio

Develop and debug agents locally.

To use Studio, you need:
- a `langgraph.json` config file
- a local server started with `langgraph dev`
- interactive testing through the Studio UI

Studio is a powerful tool for visualizing agent execution flow and debugging each step.


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
print("  $ langgraph dev")
print("  → Open the Studio UI at http://localhost:2024")
`````)

== 10.3 Agent Testing

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

== 10.4 Trajectory-Based Testing

Validate the order in which the agent calls tools. A trajectory test checks whether the agent uses tools in the expected order and whether the final response matches your expectation.


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

This is a web UI for talking to your agent. It connects to a LangGraph server so you can test the agent directly in the browser.

Key features:
- Real-time streaming chat
- Tool call visualization
- Conversation branching
- Human-in-the-loop approval


#code-block(`````python
print("Agent Chat UI setup:")
print("=" * 50)
print("""
# 1. Install Agent Chat UI
`$ npx @anthropic-ai/agent-chat-ui`

# 2. Start the LangGraph server
`$ langgraph dev`

# 3. Connect the UI to http://localhost:2024
#    -> Talk to the agent in a web browser
""")
print("Key features:")
print("  - Real-time streaming chat")
print("  - Tool-call visualization")
print("  - Conversation branching")
print("  - Human-in-the-loop approval")
`````)

== 10.6 Deployment

You can deploy an agent through LangGraph Platform (managed) or your own server. Choose the option that best fits your production environment.


#code-block(`````python
print("Deployment options:")
print("=" * 50)

print("""
# Option 1: LangGraph Platform (managed)
`$ langgraph deploy`


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

== 10.7 Observability

Use LangSmith to trace agent behavior. When tracing is enabled, every step of agent execution is recorded and can be analyzed.

LangSmith lets you inspect:
- The complete execution flow of each agent call
- Model input/output, tool calls, and token usage
- Latency, errors, and cost tracking


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

