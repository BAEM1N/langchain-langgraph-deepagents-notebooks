# LangGraph Application Structure Documentation

## Overview
A LangGraph application requires multiple components: one or more graphs, a `langgraph.json` configuration file, a dependency specification file, and an optional `.env` file.

## Key Components

**Four essential elements:**
1. A configuration file (`langgraph.json`) specifying dependencies, graphs, and environment variables
2. Graph implementations containing application logic
3. A dependency file (requirements.txt or pyproject.toml)
4. Environment variable specifications

## Typical Directory Layout

**Python with requirements.txt:**
```
my-app/
├── my_agent/
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── tools.py
│   │   ├── nodes.py
│   │   └── state.py
│   ├── __init__.py
│   └── agent.py
├── .env
├── requirements.txt
└── langgraph.json
```

**Python with pyproject.toml:**
Same structure but substitutes `pyproject.toml` for `requirements.txt`.

## Configuration File Details

The `langgraph.json` file specifies deployment settings in JSON format. A sample configuration:

```json
{
  "dependencies": ["langchain_openai", "./your_package"],
  "graphs": {
    "my_agent": "./your_package/your_file.py:agent"
  },
  "env": "./.env"
}
```

This example demonstrates:
- Custom local packages alongside third-party dependencies
- Single graph loaded from specified file path
- Environment variables sourced from `.env`

## Dependencies Management

Applications typically require:
- A dependency file listing Python packages
- A `dependencies` key in the configuration referencing required packages
- Optional `dockerfile_lines` for system libraries or binaries

## Graphs Configuration

Use the `graphs` key to identify available graphs, specifying unique names paired with file paths to compiled graphs or graph-generating functions.

## Environment Variables

Local development uses the `env` key in configuration; production deployments typically manage variables within the hosting environment.
