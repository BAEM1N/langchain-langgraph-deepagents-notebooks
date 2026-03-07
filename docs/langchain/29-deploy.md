# LangSmith Deployment Documentation

## Overview

LangSmith provides managed hosting for LangChain agents in production. The platform is specifically designed for "stateful, long-running agents" that require persistent state and background execution, distinguishing it from traditional stateless web application hosting.

## Requirements

- GitHub account
- LangSmith account (free signup available)

## Deployment Process

### Step 1: Repository Setup
Your application code must be hosted on GitHub (public or private repositories supported). Ensure LangGraph compatibility by following the local server setup guide, then push your code to the repository.

### Step 2: LangSmith Deployment
1. Log into LangSmith and navigate to Deployments
2. Click "+ New Deployment"
3. Connect your GitHub account if needed
4. Select your repository and submit (approximately 15 minutes to complete)
5. Monitor progress in the Deployment details view

### Step 3: Test in Studio
Once deployed, select your deployment and click the **Studio** button to view your graph visualization.

### Step 4: Retrieve API URL
In Deployment details, copy your API URL to the clipboard.

### Step 5: API Testing

**Python approach:**
```python
pip install langgraph-sdk
from langgraph_sdk import get_sync_client
client = get_sync_client(url="your-deployment-url", api_key="your-langsmith-api-key")
```

**REST API approach:**
```bash
curl --request POST --url <DEPLOYMENT_URL>/runs/stream \
  --header "X-Api-Key: <LANGSMITH API KEY>"
```

## Additional Resources

LangSmith offers self-hosted and hybrid deployment options. See the Platform setup overview for details.
