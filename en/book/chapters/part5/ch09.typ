// Auto-generated from 09_production.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Production deployment", subtitle: "- testing, observability, deployment")

We cover the entire pipeline for deploying agents into production. We ensure quality through unit testing and LangSmith evaluation, secure observability through tracing, and deploy to the LangGraph Platform.

#code-block(`````python
Development -> Testing (unit + evaluation) -> Observability (tracing) -> Deployment (LangGraph Platform)
`````)

=== Why do you need an agent-specific production pipeline?

Agents have different characteristics than traditional software:

- _Non-deterministic execution_: Same input can produce different tool calling orders and different responses.
- _Statefull_: A long-running process that manages conversation history and checkpoints.
- _Multiple components_: Multiple systems such as LLM, tool, memory, checkpointer, etc. are linked

Therefore, beyond simple unit testing, agent-specific quality assurance techniques such as _trajectory evaluation_, _LLM-as-Judge_, and _trace-based monitoring_ are needed.

== Learning Objectives

After completing this notebook, you will be able to:

+ _Unit Test_ -- You can write deterministic tests by mocking the LLM response with `GenericFakeChatModel`
+ _LangSmith Evaluation_ -- Create datasets, define evaluators, and perform automated agent evaluation.
+ _Trace Analysis_ -- LangSmith tracing allows you to track latency, token usage, and errors.
+ _LangGraph Studio_ -- You can analyze the agent execution flow with visual debugging tool
+ _Deployment Options_ -- Understand the differences between LangGraph Platform, self-host, and cloud deployment
+ _langgraph.json_ -- You can configure the deployment configuration file and execute deployment commands.

== 9.1 Environment Setup

Install the packages required for testing, observability, and deployment.

== 9.2 Production Pipeline Overview

Due to the non-deterministic nature of agents, traditional software testing alone cannot ensure quality.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[steps],
  text(weight: "bold")[Purpose],
  text(weight: "bold")[tool],
  [_Development_],
  [Agent implementation and local testing],
  [LangGraph, LangGraph Studio],
  [_Test_],
  [Unit Testing + LLM Based Assessment],
  [pytest, agentevals, LangSmith],
  [_observability_],
  [Tracing, Metrics, Error Tracking],
  [LangSmith Tracing],
  [_Distribution_],
  [Deploying a Production Environment],
  [LangGraph Platform],
)

=== Testing Strategy

Agent testing requires a combination of two approaches:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Type],
  text(weight: "bold")[Features],
  text(weight: "bold")[Suitable for],
  [_Unit Test_],
  [Perform isolated deterministic tests by mocking the LLM response with `GenericFakeChatModel`. Fast execution without API calls],
  [Individual tool, parser, prompt formatting, state transition logic],
  [_Integration Test_],
  [Verification of collaboration between components with actual network calls. Analysis of agent behavior patterns by trajectory evaluation of `agentevals`],
  [Total agent flow, tool calling sequence, final response quality],
)

Because agent systems operate by chaining multiple components, integration testing generally requires a higher proportion. Unit tests verify the correctness of individual components, and integration tests evaluate the quality of the overall flow.

== 9.3 Agent testing -- LangSmith evaluation

The `agentevals` package provides a dedicated evaluator for agent trajectories. Trajectory refers to all the steps (tool calling, intermediate reasoning, decision making) that the agent takes to reach the final response.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[strategy],
  text(weight: "bold")[Description],
  text(weight: "bold")[Advantages],
  text(weight: "bold")[Disadvantages],
  [_Trajectory Match_],
  [Step-by-step comparison with expected sequence. Matching the agent's actual trajectory with a predefined reference trajectory],
  [Accurate verification, reproducible],
  [Requires specific expectations, low flexibility],
  [_LLM-as-Judge_],
  [LLM qualitatively evaluates trajectories based on rubrics (evaluation criteria). tool Automatic judgment of appropriateness of use, accuracy of response, etc.],
  [Flexible evaluation, response to complex scenarios],
  [Additional LLM costs, indeterminacy of the assessment itself],
)

=== Trajectory Match Mode

You can adjust your agent's tool calling ordering expectations in four levels:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[mode],
  text(weight: "bold")[Description],
  text(weight: "bold")[When to use],
  [`strict`],
  [The message and tool calling order must be exactly the same as the reference to pass],
  [Workflows where order is important (e.g. Authentication -\\\> Lookup -\\\> Update)],
  [`unordered`],
  [If the same tool are called, they pass regardless of the order. When there are multiple independent tool calling],
  [`subset`],
  [Agent only calls reference tool (no additional tool calling)],
  [When you want to prevent unnecessary tool calling],
  [`superset`],
  [Agent contains at least reference tool (additional calls allowed)],
  [When you want to ensure only the core tool calling],
)

#code-block(`````python
try:
    from langsmith import Client

    ls_client = Client()

    dataset = ls_client.create_dataset("agent-eval-v1")
    ls_client.create_examples(
        inputs=[{"query": "What is LangGraph?"}],
        outputs=[{"expected": "Framework for Agents"}],
        dataset_id=dataset.id,
    )
    print("Dataset created:", dataset.name)
except Exception as e:
    print(f"LangSmith not configured (skipped): {e}")
    ls_client = None
    dataset = None
`````)

#code-block(`````python
try:
    from agentevals.trajectory import create_trajectory_llm_as_judge

    evaluator = create_trajectory_llm_as_judge(
        rubric=(
            "Did the agent use the appropriate tool?"
            "Was your final answer correct?"
        ),
    )
    print("Evaluator created:", type(evaluator).__name__)
except ImportError:
    print("agentevals not installed. Installation: pip install agentevals")
    evaluator = None
except Exception as e:
    print(f"Evaluator creation skipped (LLM API key required): {e}")
    evaluator = None
`````)

== 9.4 Unit test patterns

`GenericFakeChatModel` allows you to write deterministic tests by mocking LLM responses without making API calls. It takes a response iterator and returns one for each call.

=== Why mocking?

When I call the actual LLM API from my agent tests, I run into the following issues:
- _Non-deterministic results_: It is difficult to reproduce the test because the same input may result in a different response each time.
- _Cost_: API cost incurred each time a test is run
- _Speed_: Network delay slows down testing
- _Availability_: Test fails in case of API failure

`GenericFakeChatModel` returns predefined responses in sequence, allowing you to write tests that are _deterministic, fast, and free_. Streaming patterns are also supported, so `astream()`-based code can also be tested.

=== State persistence testing

`InMemorySaver` checkpointer allows you to test state-dependent behavior across multiple conversation turns. Specify `thread_id` to verify the cumulative state of multiple calls while maintaining the same conversation context.

#code-block(`````python
def search_tool(query: str) -> str:
    """Search for information on the web."""
    return f"Search result: {query}"

def test_search_tool():
    """Tests whether search tool returns the expected format."""
    result = search_tool("test query")
    assert isinstance(result, str) and len(result) > 0
    print("Passed: test_search_tool")

test_search_tool()
`````)

=== HTTP request recording/playback

To reduce API costs in CI/CD, you can record and replay HTTP requests with `vcrpy` and `pytest-recording`. Record the actual API call (save it as a cassette file) on the first run, and play the recorded response on subsequent runs to test without network calls.

Advantages of this approach:
- _First run_: Verifies integration with actual API (roles as integration test)
- _Run after_: Quick and conclusive testing with recorded responses (acts as a unit test)
- _CI/CD_: Tests can be run without an API key

#code-block(`````python
import pytest

@pytest.fixture(scope="module")
def vcr_config():
    return {"record_mode": "once"}

@pytest.mark.vcr()
def test_agent_with_recorded_responses():
    result = agent.invoke("What is LangGraph?")
    assert "framework" in result.lower()
`````)

== 9.5 observability -- LangSmith Tracing

LangSmith tracing records _every step_ of an agent's execution. A trace is a complete record of an agent's execution, from initial user input to the final response, including all model calls, tool usage, and decision points.

=== Information recorded in traces

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [_Input/Output_],
  [Input data and output results of each step],
  [_Model Call_],
  [Prompts, responses, model parameters],
  [_tool calling_],
  [Called tool, arguments, return value],
  [_Latency_],
  [Time required for each stage],
  [_Token Usage_],
  [Number of input/output tokens],
  [_Error_],
  [Failed Steps and Error Messages],
)

=== How to activate

Just set two environment variables and you'll get automatic tracing _without any additional code_:

#code-block(`````bash
export LANGSMITH_TRACING=true
export LANGSMITH_API_KEY=<your-api-key>
`````)

`create_agent` agents automatically send execution data to LangSmith when the relevant environment variables are configured. All LangChain components (LLMs, chains, tools, etc.) include built-in instrumentation, so no extra code changes are required.

=== Selective Tracing

`tracing_context` allows you to selectively trace only specific code blocks. This allows you to intensively monitor only the parts that require debugging or separate traces by project.

== 9.6 Trace analysis

Monitor the quality of your production agents by analyzing traces in the LangSmith dashboard.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[metrics],
  text(weight: "bold")[Description],
  text(weight: "bold")[Confirmation Points],
  [_Latency_],
  [Time required for each stage],
  [Identify bottleneck section (which node is the slowest)],
  [_Token Usage_],
  [Number of input/output tokens],
  [Cost optimization (adjust prompt length, remove unnecessary context)],
  [_Error Rate_],
  [Failed Execution Rate],
  [Stability monitoring (failure rate for specific tool, LLM timeouts, etc.)],
  [_Tool Call Frequency_],
  [Call frequency by tool],
  [Agent behavior pattern analysis (identifying excessive tool calling and unused tool)],
)

=== Utilizing tags and metadata

You can classify and filter traces by adding custom tags and metadata with the `config` parameter or `tracing_context`. Examples of useful tags/metadata in a production environment:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Tags/Metadata],
  text(weight: "bold")[Use],
  [_Version tag_ (`v2.1`)],
  [A/B testing, performance comparison by version],
  [_Experimental Tag_ (`experiment-A`)],
  [Experiment tracking, including prompt changes],
  [_User Tier_ (`premium`)],
  [Quality monitoring by user group],
  [_Region_ (`kr`)],
  [Latency analysis by region],
)

=== Project Management

Projects can be set up in two ways:
- _static_: Specify the default project with the `LANGSMITH_PROJECT` environment variable.
- _Dynamic_: Separate project by code block with `tracing_context(project_name=...)`

#code-block(`````python
try:
    from langsmith import tracing_context

    with tracing_context(
        project_name="production-agent",
        tags=["v2.1", "experiment-A"],
        metadata={"user_tier": "premium", "region": "kr"},
    ):
        print("Tagged tracing enabled")
except Exception as e:
    print(f"LangSmith tracing unavailable: {e}")
`````)

== 9.7 LangGraph Studio -- Visual Debugging

LangGraph Studio is a free tool that allows you to _visually_ debug an agent's execution flow. Optimized for developing and testing agents on your local machine.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[Description],
  [_Graph visualization_],
  [Check the agent's node/edge structure in real-time. Highlight the currently running node],
  [_Step by step_],
  [Debugging by inspecting the input and output data of each node. Prompt, tool calling, check results step by step],
  [_Status Check_],
  [Visually explore the overall state of your agents. Includes message history and checkpoint data],
  [_Live Streaming_],
  [Observe the agent execution process in real-time. Token/latency metrics provided],
)

=== Setting up a local development server

To use Studio, start your local development server with the LangGraph CLI:

You can access the Studio UI from 
== LangGraph CLI installation (Python 3.11+ required)
pip install --upgrade "langgraph-cli[inmem]"

== Start the development server
langgraph dev
#code-block(`````python

When the server starts, open `https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024`.

### Information available in Studio

- Prompt sent to agent
- Each tool calling and its results
- Final output
- Intermediate state (can be inspected and modified)
- Token usage and latency metrics
`````)

== 9.8 Deployment Options

Agents are _long-running processes that maintain state_, so they require a different approach than regular web app hosting. Traditional stateless web application hosting (e.g. Vercel, Heroku) is not suitable for persistent state management, background execution, and checkpointing of agents.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Options],
  text(weight: "bold")[Description],
  text(weight: "bold")[Suitable for],
  [_LangGraph Cloud_],
  [LangSmith Managed Hosting. Automatic build/deployment with just a GitHub connection],
  [Rapid prototyping, small teams],
  [_Self-Hosted_],
  [Run as Docker containers on your own infrastructure],
  [Data Sovereignty, Enterprise, Regulatory Environment],
  [_Hybrid_],
  [Cloud Management + Own Runtime],
  [Convenience of management + data control],
)

=== Deployment Requirements

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  [_GitHub repository_],
  [Code hosting (supports both public and private)],
  [_LangSmith Account_],
  [Free to join (smith.langchain.com)],
  [_langgraph.json_],
  [Deployment configuration file defining dependencies, graphs, and environment variables],
)

=== LangGraph Cloud deployment process

+ Log in to LangSmith and go to the Deployments page.
+ Click “+ New Deployment”
+ Connect your GitHub account (for private repositories)
+ Select the repository and submit (takes about 15 minutes)
+ After deployment is complete, copy the API URL and use it on the client.

== 9.9 langgraph.json settings

`langgraph.json` is the core configuration file for your deployment. Define dependencies, graph entry points, and environment variables. This file must be located in the project root for LangGraph CLI and Cloud deployment to operate properly.

#code-block(`````python
import json

langgraph_config = {
    "dependencies": ["."],
    "graphs": {"agent": "./src/agent.py:graph"},
    "env": ".env",
}
print(json.dumps(langgraph_config, indent=2))
`````)

=== Setting item details

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Type],
  text(weight: "bold")[Description],
  [`dependencies`],
  [`list[str]`],
  [Python package dependencies. `.` references `pyproject.toml` in the current directory],
  [`graphs`],
  [`dict`],
  [Mapping graph names and module paths. `"module_path:variable_name"` format],
  [`env`],
  [`str`],
  [Environment variable file path (`.env` format). Contains sensitive information such as API keys],
)

=== Graph entry point

The value of the `graphs` field is in the format `"./path/file.py:variable_name"`. The variable must be a `CompiledGraph` instance. Both LangGraph's Graph API (`StateGraph`) and Functional API (`@entrypoint`) are available.

==== Graph API example

#code-block(`````python
# src/agent.py
from langgraph.prebuilt import create_react_agent

graph = create_react_agent(
    model="claude-sonnet-4-6",
    tools=[search_tool],
    checkpointer=True,
)
`````)

==== Functional API Example

LangGraph's Functional API lets you add persistence, memory, and streaming to existing Python code with minimal changes. The `@entrypoint` decorator defines the start of the workflow, and the `@task` decorator marks an individual unit of work.

#code-block(`````python
# src/agent.py
from langgraph.func import entrypoint, task

@task
def process_query(query: str) -> str:
    return f"Processing complete: {query}"

@entrypoint(checkpointer=checkpointer)
def graph(inputs: dict) -> str:
    result = process_query(inputs["query"])
    return result.result()
`````)

Key features of Functional API:
- _Uses standard Python control flow_ (if/for, etc.) -- No explicit graph structure required
- _Function scope state management_ -- No need to declare a separate state or set up a reducer.
- _Task result checkpointing_ -- Automatically reuses previously completed task results when re-executed
- _Input/output JSON serialization required_ -- When using checkpointer, all data must be serializable

== 9.10 Deployment command

Build, local server, and cloud deployment commands using LangGraph CLI.

=== 1. Build Docker image

Create a Docker image based on the `langgraph.json` settings:

#code-block(`````bash
langgraph build -t my-agent:latest
`````)

=== 2. Run the local server

Run the agent locally for testing and connect it to the Studio UI for visual debugging:

#code-block(`````bash
# Production mode (Docker-based)
langgraph up --config langgraph.json

# Development mode (in-memory, quick start)
langgraph dev
`````)

=== 3. Cloud Deployment

LangSmith In the dashboard:
+ Deployments -\> "+ New Deployment"
+ GitHub Connect the repository
+ Select the repository and submit it (about 15 minutes)
+ Copy the API URL after deployment completes

=== Python SDKAccess the deployed agent from the Python SDK

`langgraph-sdk` allows you to communicate programmatically with the deployed agent. All functions, including streaming, thread management, and status inquiry, are controlled by the SDK.

#code-block(`````python
try:
    from langgraph_sdk import get_sync_client

    api_key = os.environ.get("LANGSMITH_API_KEY", "")
    if not api_key:
        print("LANGSMITH_API_KEY Not set. Skipping client connection.")
    else:
        client = get_sync_client(
            url="https://your-deployment.langsmith.com",
            api_key=api_key,
        )
        print("Client connected:", type(client).__name__)
except Exception as e:
    print(f"LangGraph SDK client unavailable: {e}")
`````)

=== Access via REST API

Deployed agents can also be accessed through REST API. This allows you to communicate with the agent in any programming language/framework:

#code-block(`````bash
curl --request POST \
  --url <DEPLOYMENT_URL>/runs/stream \
  --header 'Content-Type: application/json' \
  --header 'X-Api-Key: <LANGSMITH_API_KEY>' \
  --data '{
    "assistant_id": "agent",
    "input": {
      "messages": [
        {"role": "user", "content": "Hello!"}
      ]
    },
    "stream_mode": "updates"
  }'
`````)

Key endpoints:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Endpoint],
  text(weight: "bold")[Method],
  text(weight: "bold")[Description],
  [`/runs/stream`],
  [POST],
  [Streaming execution],
  [`/runs`],
  [POST],
  [Synchronous execution],
  [`/threads`],
  [POST],
  [Create a new thread],
  [`/threads/{id}/state`],
  [GET],
  [thread status query],
)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Takeaways],
  [_Testing Strategy_],
  [Unit test (`GenericFakeChatModel`) + integration test (`agentevals`) in parallel],
  [_LangSmith Evaluation_],
  [Trajectory Match (strict/unordered/subset/superset), LLM-as-Judge],
  [_observability_],
  [Automatic tracing with `LANGSMITH_TRACING=true` + `LANGSMITH_API_KEY`],
  [_Trace Analysis_],
  [Latency, Token Usage, Error Rate, Tool Call Frequency],
  [_LangGraph Studio_],
  [Visual graph debugging, step-by-step state inspection],
  [_Deployment Options_],
  [Cloud (Managed), Self-Hosted (Docker), Hybrid],
  [_langgraph.json_],
  [`dependencies`, `graphs`, `env` 3 core settings],
  [_Deployment Command_],
  [`langgraph build` -\\\> `langgraph up` -\\\> LangSmith Deploy],
)
