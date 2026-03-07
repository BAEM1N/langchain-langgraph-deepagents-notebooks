# Complete Documentation: Run a Local Server

## Overview
This guide demonstrates deploying a LangGraph application on your local machine.

## Prerequisites
- LangSmith API key (free signup available at https://smith.langchain.com/settings)

## Installation Steps

### 1. Install LangGraph CLI
Using pip (Python >= 3.11 required):
```bash
pip install -U "langgraph-cli[inmem]"
```

Or using uv:
```bash
uv add "langgraph-cli[inmem]"
```

### 2. Create Application
Generate a new project from the official template:
```shell
langgraph new path/to/your/app --template new-langgraph-project-python
```

The `langgraph new` command without a template argument presents an interactive menu of available options.

### 3. Install Dependencies
Navigate to your project and install packages in editable mode:

With pip:
```bash
cd path/to/your/app
pip install -e .
```

With uv:
```bash
cd path/to/your/app
uv sync
```

### 4. Configure Environment
Create a `.env` file from `.env.example` in your project root and add your credentials:
```bash
LANGSMITH_API_KEY=lsv2...
```

### 5. Launch Server
Start the development server:
```shell
langgraph dev
```

Expected output includes:
- API endpoint: http://127.0.0.1:2024
- Studio interface: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
- API documentation: http://127.0.0.1:2024/docs

The in-memory mode suits development and testing. Production deployments require persistent storage backends.

### 6. Test in Studio
Access the visual interface via the provided Studio URL. For custom servers, modify the `baseUrl` parameter accordingly.

**Safari Users:** Apply the `--tunnel` flag to establish secure connections to localhost servers.

### 7. API Testing

**Python SDK (Async):**
```python
from langgraph_sdk import get_client
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
```

**Python SDK (Sync):**
```python
from langgraph_sdk import get_sync_client

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
```

**REST API:**
```bash
curl -s --request POST \
    --url "http://localhost:2024/runs/stream" \
    --header 'Content-Type: application/json' \
    --data "{
        \"assistant_id\": \"agent\",
        \"input\": {
            \"messages\": [{
                \"role\": \"human\",
                \"content\": \"What is LangGraph?\"
            }]
        },
        \"stream_mode\": \"messages-tuple\"
    }"
```

## Next Steps
- Explore deployment options via LangSmith
- Review foundational LangSmith concepts
- Consult SDK API Reference documentation
