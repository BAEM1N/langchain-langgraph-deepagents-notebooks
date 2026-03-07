# SQL Agent

This tutorial walks through building an agent that can query SQL databases using natural language. The agent uses a ReAct reasoning loop to explore the database schema, construct queries, validate them, and return results -- with optional human-in-the-loop review before query execution.

## Overview

The SQL agent follows an 8-step process:

1. **Receive** the natural language question
2. **List tables** in the database
3. **Get schema** for relevant tables
4. **Generate** a SQL query
5. **Check** the query for correctness
6. **Review** (optional human-in-the-loop)
7. **Execute** the query
8. **Interpret** results and respond

## Prerequisites

```bash
pip install langchain langchain-openai langchain-community sqlalchemy
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Step 1: Connect to the Database

Use `SQLDatabase` to wrap your database connection. It provides introspection methods the agent needs to understand the schema.

```python
from langchain_community.utilities import SQLDatabase

# SQLite
db = SQLDatabase.from_uri("sqlite:///company.db")

# PostgreSQL
db = SQLDatabase.from_uri("postgresql://user:pass@localhost:5432/company")

# MySQL
db = SQLDatabase.from_uri("mysql+pymysql://user:pass@localhost:3306/company")

# Inspect what's available
print(db.get_usable_table_names())
print(db.get_table_info())
```

## Step 2: Create the Toolkit

`SQLDatabaseToolkit` generates a set of tools that the agent uses to interact with the database.

```python
from langchain_community.agent_toolkits import SQLDatabaseToolkit
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o")
toolkit = SQLDatabaseToolkit(db=db, llm=llm)
tools = toolkit.get_tools()
```

### Toolkit Tools

The toolkit provides four tools:

| Tool | Function | Description |
|------|----------|-------------|
| `sql_db_list_tables` | List available tables | Returns a comma-separated list of all table names in the database |
| `sql_db_schema` | Get table schema | Returns the CREATE TABLE statement and sample rows for specified tables |
| `sql_db_query` | Execute a query | Runs a SQL query and returns the results |
| `sql_db_query_checker` | Validate a query | Uses the LLM to check a query for common errors before execution |

```python
for tool in tools:
    print(f"{tool.name}: {tool.description[:80]}")
```

## Step 3: Define the System Prompt

Guide the agent's behavior with a system prompt that enforces the query construction workflow.

```python
system_prompt = """You are an agent designed to interact with a SQL database.

Given an input question, create a syntactically correct {dialect} query to run,
then look at the results of the query and return the answer.

Follow these steps:
1. First, list the available tables using sql_db_list_tables.
2. Then, get the schema for the relevant tables using sql_db_schema.
3. Write a query based on the schema. Use sql_db_query_checker to validate it.
4. Execute the validated query using sql_db_query.
5. Interpret the results and provide a clear answer.

Rules:
- Never query for all columns from a table. Only ask for relevant columns.
- Use LIMIT to avoid returning too many rows (default: 10).
- Order results to return the most relevant data.
- Never execute DML statements (INSERT, UPDATE, DELETE, DROP, etc.).
- If you get an error, rewrite the query and try again.
- Do NOT make up information that is not in the query results.
""".format(dialect=db.dialect)
```

## Step 4: Create the Agent

```python
from langchain.agents import create_agent

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=tools,
    system_prompt=system_prompt,
)
```

## Step 5: Run the Agent

```python
response = agent.invoke(
    {"messages": [{"role": "user", "content": "What are the top 5 customers by total order value?"}]}
)

print(response["messages"][-1].content)
```

## Step 6: Add Human-in-the-Loop

Use `HumanInTheLoopMiddleware` to require human approval before executing SQL queries. This is critical for production deployments.

```python
from langchain.middleware import HumanInTheLoopMiddleware

hitl = HumanInTheLoopMiddleware(
    tool_names=["sql_db_query"],  # Only intercept actual query execution
)

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=tools,
    system_prompt=system_prompt,
    middleware=[hitl],
)
```

### Handling Review Responses

When the agent attempts to call `sql_db_query`, execution pauses and waits for human review. The human can approve, edit, or reject the query.

```python
from langchain_core.commands import Command

# Run the agent (will pause at sql_db_query)
response = agent.invoke(
    {"messages": [{"role": "user", "content": "Show me revenue by quarter"}]}
)

# The response contains the proposed query for review
# Option 1: Approve the query as-is
result = agent.invoke(Command(resume="approve"))

# Option 2: Edit the query before execution
result = agent.invoke(Command(resume={
    "type": "edit",
    "args": {
        "query": "SELECT quarter, SUM(revenue) as total FROM sales GROUP BY quarter ORDER BY quarter"
    }
}))

# Option 3: Reject the query entirely
result = agent.invoke(Command(resume={
    "type": "reject",
    "reason": "This query would be too expensive to run on production"
}))
```

## Agent Execution Trace

A typical execution trace looks like this:

```
User: "What are the top 5 products by revenue last month?"

Agent -> sql_db_list_tables()
      <- "customers, orders, order_items, products, categories"

Agent -> sql_db_schema("orders, order_items, products")
      <- CREATE TABLE orders (id INT, customer_id INT, order_date DATE, ...)
         CREATE TABLE order_items (id INT, order_id INT, product_id INT, quantity INT, price DECIMAL, ...)
         CREATE TABLE products (id INT, name VARCHAR, category_id INT, ...)

Agent -> sql_db_query_checker("""
            SELECT p.name, SUM(oi.quantity * oi.price) as revenue
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            JOIN products p ON oi.product_id = p.id
            WHERE o.order_date >= DATE('now', '-1 month')
            GROUP BY p.name
            ORDER BY revenue DESC
            LIMIT 5
         """)
      <- "The query looks correct."

Agent -> sql_db_query(validated_query)
      <- [("Widget Pro", 45230.00), ("Gadget X", 38100.00), ...]

Agent: "The top 5 products by revenue last month are:
        1. Widget Pro - $45,230.00
        2. Gadget X - $38,100.00
        ..."
```

## Safety Considerations

| Concern | Mitigation |
|---------|------------|
| SQL injection | Toolkit uses parameterized queries where possible |
| DML execution | System prompt prohibits INSERT/UPDATE/DELETE; consider database-level read-only access |
| Data exposure | Use database views or restricted user permissions |
| Expensive queries | Add LIMIT directives in the prompt; use human-in-the-loop for production |
| Sensitive data | Use column-level permissions; exclude sensitive tables from `include_tables` |

### Restricting Available Tables

```python
db = SQLDatabase.from_uri(
    "sqlite:///company.db",
    include_tables=["products", "orders", "order_items"],  # Allowlist
    # exclude_tables=["users", "credentials"],             # Or blocklist
)
```

## Full Example

```python
from langchain_community.utilities import SQLDatabase
from langchain_community.agent_toolkits import SQLDatabaseToolkit
from langchain_openai import ChatOpenAI
from langchain.agents import create_agent
from langchain.middleware import HumanInTheLoopMiddleware

# Database
db = SQLDatabase.from_uri("sqlite:///company.db")

# Toolkit
llm = ChatOpenAI(model="gpt-4o")
toolkit = SQLDatabaseToolkit(db=db, llm=llm)
tools = toolkit.get_tools()

# Agent with HITL
agent = create_agent(
    model="claude-sonnet-4-6",
    tools=tools,
    system_prompt="You are a SQL expert. Follow the standard query workflow.",
    middleware=[HumanInTheLoopMiddleware(tool_names=["sql_db_query"])],
)

# Run
response = agent.invoke(
    {"messages": [{"role": "user", "content": "What is the average order value by month?"}]}
)
```
