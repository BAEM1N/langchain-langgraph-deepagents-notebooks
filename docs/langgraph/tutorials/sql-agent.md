# Custom SQL Agent with LangGraph

## Overview

Build a custom SQL agent using LangGraph's StateGraph for deeper control than built-in agents. The agent lists tables, fetches schemas, generates queries, validates them, and executes with human review.

## Key Components

### Tools (SQLDatabaseToolkit)

| Tool | Description |
|---|---|
| `sql_db_query` | Execute SQL queries |
| `sql_db_schema` | Get table schemas and sample rows |
| `sql_db_list_tables` | List available tables |
| `sql_db_query_checker` | Validate queries before execution |

### Graph Nodes

```python
def list_tables(state): ...      # List available tables
def get_schema(state): ...       # Fetch relevant schemas
def generate_query(state): ...   # LLM generates SQL
def check_query(state): ...      # LLM validates SQL
```

Each node receives and returns the shared `State` object, appending messages to the conversation history as the agent progresses through its workflow.

### Human-in-the-Loop

Uses `interrupt()` to pause before query execution:

```python
from langgraph.types import interrupt

response = interrupt([request])  # accept, edit, or respond
```

Resume with `Command(resume=...)`.

The interrupt mechanism gives a human operator the opportunity to review the generated SQL query before it is executed against the database. The operator can:

- **Accept** the query as-is
- **Edit** the query and resume with the corrected version
- **Respond** with feedback so the agent can regenerate

### Database Setup

```python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("sqlite:///Chinook.db")
```

You can substitute any supported database URI (PostgreSQL, MySQL, etc.) in place of the SQLite connection string.

### State Definition

```python
from typing import Annotated
from typing_extensions import TypedDict
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]
```

### Building the Graph

```python
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode, tools_condition

builder = StateGraph(State)

builder.add_node("list_tables", list_tables)
builder.add_node("get_schema", get_schema)
builder.add_node("generate_query", generate_query)
builder.add_node("check_query", check_query)
builder.add_node("execute_query", execute_query)

builder.add_edge(START, "list_tables")
builder.add_edge("list_tables", "get_schema")
builder.add_edge("get_schema", "generate_query")
builder.add_edge("generate_query", "check_query")
builder.add_conditional_edges("check_query", tools_condition)
builder.add_edge("execute_query", END)

graph = builder.compile()
```

## Workflow

```
START -> list_tables -> get_schema -> generate_query -> check_query -> [tools_condition] -> execute/END
```

| Step | Purpose |
|---|---|
| `list_tables` | Discover available tables in the database |
| `get_schema` | Retrieve DDL and sample rows for relevant tables |
| `generate_query` | LLM produces a SQL query based on the user question and schema |
| `check_query` | LLM validates correctness and safety of the generated query |
| `tools_condition` | Routes to execution or back to generation if the query is invalid |
| `execute` | Runs the validated query and returns results |

## Running the Agent

```python
config = {"configurable": {"thread_id": "1"}}

for event in graph.stream(
    {"messages": [("user", "Which country has the most customers?")]},
    config,
    stream_mode="values",
):
    event["messages"][-1].pretty_print()
```

---

**참고:** https://docs.langchain.com/oss/python/langgraph/sql-agent
