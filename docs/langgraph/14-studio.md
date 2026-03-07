# LangSmith Studio Documentation

## Overview

LangSmith Studio is a complimentary visual development environment designed for creating and testing LangChain agents locally. It enables developers to observe agent operations in real-time, including prompt delivery to models, tool invocations with results, and final outputs.

## Key Prerequisites

Before setup, users need:
- A LangSmith account (free signup available at smith.langchain.com)
- An API key generated from LangSmith
- Optional: `LANGSMITH_TRACING=false` in `.env` to prevent data transmission to external servers

## Setup Steps

### 1. Install LangGraph CLI
The tool requires Python 3.11+:
```
pip install --upgrade "langgraph-cli[inmem]"
```

### 2. Agent Preparation
Users can employ existing LangChain agents directly. A sample email agent demonstrates the pattern with the `create_agent` function.

### 3. Environment Configuration
Add your API credentials to a `.env` file:
```
LANGSMITH_API_KEY=lsv2...
```

### 4. LangGraph Configuration
Create `langgraph.json` specifying agent location and dependencies:
```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./src/agent.py:agent"
  },
  "env": ".env"
}
```

### 5. Dependency Installation
Install required packages via pip or uv package manager.

### 6. Launch Development Server
Execute `langgraph dev` to start the local server. The agent becomes accessible via API at `http://127.0.0.1:2024` and through Studio's web interface.

## Notable Features

The development environment supports hot-reloading, allowing immediate reflection of code modifications. Execution traces capture detailed metrics including prompts, tool arguments, and performance data. The interface facilitates iterative testing from any execution step.

## Additional Resources

Documentation references include guides for running applications, managing assistants and threads, optimizing prompts, and debugging traces within LangSmith.
