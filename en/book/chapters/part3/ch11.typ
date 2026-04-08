// Auto-generated from 11_local_server.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(11, "Local Server")

== Learning Objectives

- `langgraph dev` Know how to run a development server with CLI
- LangGraph Visually debug in conjunction with Studio
- Create `langgraph.json` configuration file
- Call local server with Python SDK
- Understand the deployment preparation process

== 11.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
`````)

== 11.2 LangGraph CLI installation

LangGraph To run a local server, you must first install the CLI.
The `langgraph-cli[inmem]` package includes an in-memory mode and is suitable for development/testing.

#code-block(`````python
# LangGraph CLI installation command
print("=== Install with pip (Python >= 3.11) ===")
print('  $ pip install -U "langgraph-cli[inmem]"')
print()
print("=== Install with uv ===")
print('  $ uv add "langgraph-cli[inmem]"')
print()
print("Check after installation:")
print("  $ langgraph --version")
`````)

== 11.3 Project creation

You can create a project template with the `langgraph new` command of the LangGraph CLI.
If you do not specify a template, an interactive menu is displayed.

#code-block(`````python
# Project creation command
print("=== Create a new project with template ===")
print("  $ langgraph new my-agent --template new-langgraph-project-python")
print()
print("=== Create an interactive menu ===")
print("  $ langgraph new my-agent")
print()
print("=== Install dependencies after creation ===")
print("# use pip")
print("  $ cd my-agent && pip install -e .")
print()
print("# use uv")
print("  $ cd my-agent && uv sync")
print()
print("=== Generated file structure ===")
print("  my-agent/")
print("├── langgraph.json # Graph settings")
print("├── .env.example # Environment Variables template")
print("├── pyproject.toml # Dependency definition")
print("  └── src/")
print("└── agent.py # agent code")
`````)

== 11.4 langgraph.json settings

`langgraph.json` is the core configuration file for the LangGraph project.
Specifies graph definition location, dependencies, Environment Variables files, etc.

#code-block(`````python
import json

# langgraph.json configuration example
config = {
    "dependencies": ["."],
    "graphs": {
        "agent": "./src/agent.py:graph"
    },
    "env": ".env"
}

print("langgraph.json example:")
print(json.dumps(config, indent=2))
print()
print("Main fields:")
print('dependencies: list of package paths to install')
print('graphs: graph name → module:variable mapping')
print('env: Environment Variables file path')
`````)

== 11.5 Running the development server

Run the local development server with the `langgraph dev` command.
`$ langgraph dev`
#code-block(`````python
**Expected output:**
Ready!
- API: http://127.0.0.1:2024
- Docs: http://127.0.0.1:2024/docs
- Studio: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
`````)
#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[URL],
  text(weight: "bold")[Use],
  [`http://127.0.0.1:2024`],
  [API endpoint],
  [`http://127.0.0.1:2024/docs`],
  [API Documentation (Swagger)],
  [`https://smith.langchain.com/studio/...`],
  [LangGraph Studio Interface],
)

#tip-box[_Safari users:_ Use the `langgraph dev --tunnel` flag to establish a secure connection to the localhost server.]

== 11.6 LangGraph Studio integration

LangGraph Studio is a visual debugging tool provided automatically when you run `langgraph dev`.

_Main Features:_

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Features],
  text(weight: "bold")[Description],
  [Graph visualization],
  [Identify node and edge structures at a glance],
  [Real-time tracking],
  [Observe the execution process of each node in real time],
  [state Inspection],
  [Check/edit the state(state) value of each step],
  [interactive testing],
  [Test graph execution by changing input],
)

Studio is browser-based, so no separate installation is required.
If you are using a custom server address, simply change the `baseUrl` parameter in the Studio URL.

== 11.7 Python SDK — Asynchronous client

Asynchronous clients are created with `langgraph_sdk.get_client()`.
It operates based on `asyncio` and can efficiently process streaming responses.

#code-block(`````python
# Asynchronous client usage pattern (used when the server is running)
print("""from langgraph_sdk import get_client
import asyncio

client = get_client(url="http://localhost:2024")

async def main():
    async for chunk in client.runs.stream(
        None,
        "agent",
        input={
            "messages": [{
                "role": "human",
                "content": "What is LangGraph?",
            }],
        },
    ):
        print(f"Event type: {chunk.event}...")
        print(chunk.data)

asyncio.run(main())
""")
print("# The above code is used when the langgraph dev server is running.")
`````)

== 11.8 Python SDK — Synchronous client

Synchronous clients are created with `langgraph_sdk.get_sync_client()`.
It is suitable for simple scripts or tests that do not require asynchrony.

#code-block(`````python
# Synchronous client usage pattern (used when the server is running)
print("""from langgraph_sdk import get_sync_client

client = get_sync_client(url="http://localhost:2024")

for chunk in client.runs.stream(
    None,
    "agent",
    input={
        "messages": [{
            "role": "human",
            "content": "What is LangGraph?",
        }],
    },
    stream_mode="messages-tuple",
):
    print(f"Event: {chunk.event}...")
    print(chunk.data)
""")
print("# The above code is used when the langgraph dev server is running.")
`````)

== 11.9 REST API call

LangGraph The local server provides a REST API.
It can be called directly with `curl` or with an HTTP client.
curl -s --request POST \
--url "http://localhost:2024/runs/stream" \
--header 'Content-Type: application/json' \
--data '{
"assistant_id": "agent",
"input": {
"messages": [{
"role": "human",
"content": "What is LangGraph?"
}]
},
"stream_mode": "messages-tuple"
}'
#code-block(`````python
API documentation can be found at `http://localhost:2024/docs`.
`````)

== 11.10 Deployment Readiness Checklist

Once local development is complete, prepare for production deployment.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Description],
  text(weight: "bold")[OK],
  [`langgraph.json`],
  [Graph path·dependency·Environment Variables setup complete],
  [☐],
  [`.env` file],
  [API key, etc. Environment Variables settings],
  [☐],
  [Dependency cleanup],
  [`pyproject.toml` or `requirements.txt` cleanup],
  [☐],
  [local test],
  [Normal locally with `langgraph dev` Smoke Test],
  [☐],
  [Check Studio],
  [LangGraph Check graph structure in Studio],
  [☐],
  [SDK Testing],
  [Test calls with Python SDK or REST API],
  [☐],
  [persistent storage],
  [Setting checkpointer (e.g. PostgresSaver) for production],
  [☐],
  [observability],
  [LangSmith or Langfuse tracing settings],
  [☐],
)

== 11.11 Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Concepts],
  [Install CLI],
  [`pip install "langgraph-cli[inmem]"` or `uv add`],
  [Create project],
  [Create template-based project with `langgraph new`],
  [langgraph.json],
  [Configuration file defining graph paths, dependencies, Environment Variables],
  [Studio],
  [`langgraph dev` Visual debugging provided automatically at run time tool],
  [SDK asynchronous],
  [Asynchronous call streaming with `get_client()`],
  [SDK synchronization],
  [Synchronous call to streaming with `get_sync_client()`],
  [REST API],
  [Direct call to `/runs/stream` endpoint with `curl`],
)

=== Next Steps
→ Proceed to _#link("12_durable_execution.ipynb")[12. Durable Execution]_!

#line(length: 100%, stroke: 0.5pt + luma(200))
_References:_
- #link("../docs/langgraph/02-local-server.md")[Run a Local Server]
