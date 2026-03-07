# LangSmith Deployment Guide - Complete Content

## Overview
This documentation covers deploying agents to **LangSmith Cloud**, a managed hosting platform specifically designed for stateful, long-running agents rather than traditional stateless web applications.

## Prerequisites
- GitHub account
- LangSmith account (free signup available)

## Deployment Steps

### 1. Repository Setup
Your application code must reside in a GitHub repository (public or private supported). Ensure your app follows the LangGraph-compatible local server setup before pushing code.

### 2. Deploy to LangSmith
- Log into LangSmith and navigate to Deployments
- Click "+ New Deployment"
- Connect GitHub account if needed for private repositories
- Select your repository and submit (approximately 15 minutes for completion)

### 3. Test in Studio
- View deployment details
- Click the Studio button to display your graph

### 4. Retrieve API URL
- In Deployment details, copy the API URL to clipboard

### 5. API Testing

**Python SDK approach:**
```python
from langgraph_sdk import get_sync_client
client = get_sync_client(url="your-deployment-url", api_key="your-api-key")
for chunk in client.runs.stream(None, "agent", input={"messages": [...]}, stream_mode="updates"):
    print(chunk.data)
```

**REST API approach:**
```bash
curl -s --request POST --url <DEPLOYMENT_URL>/runs/stream \
  --header 'Content-Type: application/json' \
  --header "X-Api-Key: <LANGSMITH_API_KEY>" \
  --data '{"assistant_id": "agent", "input": {...}, "stream_mode": "updates"}'
```
