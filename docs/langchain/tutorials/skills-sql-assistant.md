# SQL Assistant with Progressive Disclosure

This tutorial covers building a SQL assistant that uses the skills pattern to progressively disclose information on demand. Instead of loading all database schema information into the prompt upfront, the agent loads schema details only when needed, keeping the context window efficient.

## Overview

The skills pattern implements progressive disclosure:

- **Small context** (<1K tokens): Include directly in the system prompt
- **Medium context** (1--10K tokens): Load on demand via the `load_skill` tool
- **Large context** (>10K tokens): Load on demand with pagination

A **skill** is a structured unit of knowledge:

```python
{
    "name": "orders_table_schema",
    "description": "Schema and usage guide for the orders table",
    "content": "CREATE TABLE orders (...) -- Full schema, relationships, and query examples"
}
```

## Prerequisites

```bash
pip install langchain langchain-openai langchain-community sqlalchemy
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Step 1: Define Skills

Each skill represents a chunk of domain knowledge that can be loaded on demand.

```python
skills = [
    {
        "name": "database_overview",
        "description": "High-level overview of all tables and their relationships",
        "content": (
            "The database contains 8 tables:\n"
            "- customers: Customer profiles and contact info\n"
            "- orders: Order records linked to customers\n"
            "- order_items: Line items within each order\n"
            "- products: Product catalog with pricing\n"
            "- categories: Product categories\n"
            "- suppliers: Supplier information\n"
            "- inventory: Current stock levels\n"
            "- shipping: Shipment tracking records\n\n"
            "Key relationships:\n"
            "- orders.customer_id -> customers.id\n"
            "- order_items.order_id -> orders.id\n"
            "- order_items.product_id -> products.id\n"
            "- products.category_id -> categories.id\n"
            "- products.supplier_id -> suppliers.id\n"
            "- inventory.product_id -> products.id\n"
            "- shipping.order_id -> orders.id"
        ),
    },
    {
        "name": "customers_schema",
        "description": "Full schema, indexes, and query patterns for the customers table",
        "content": (
            "CREATE TABLE customers (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    name VARCHAR(100) NOT NULL,\n"
            "    email VARCHAR(255) UNIQUE NOT NULL,\n"
            "    phone VARCHAR(20),\n"
            "    address TEXT,\n"
            "    city VARCHAR(50),\n"
            "    state VARCHAR(2),\n"
            "    zip VARCHAR(10),\n"
            "    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n"
            "    lifetime_value DECIMAL(10,2) DEFAULT 0\n"
            ");\n\n"
            "Indexes: idx_customers_email, idx_customers_state\n\n"
            "Common query patterns:\n"
            "- Find customer by email: WHERE email = ?\n"
            "- Customers by region: WHERE state = ?\n"
            "- High-value customers: ORDER BY lifetime_value DESC LIMIT ?\n"
            "- Customer with orders: JOIN orders ON orders.customer_id = customers.id"
        ),
    },
    {
        "name": "orders_schema",
        "description": "Full schema, indexes, and query patterns for orders and order_items tables",
        "content": (
            "CREATE TABLE orders (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    customer_id INTEGER NOT NULL REFERENCES customers(id),\n"
            "    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,\n"
            "    status VARCHAR(20) DEFAULT 'pending',\n"
            "    total DECIMAL(10,2),\n"
            "    shipping_address TEXT\n"
            ");\n\n"
            "CREATE TABLE order_items (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    order_id INTEGER NOT NULL REFERENCES orders(id),\n"
            "    product_id INTEGER NOT NULL REFERENCES products(id),\n"
            "    quantity INTEGER NOT NULL,\n"
            "    unit_price DECIMAL(10,2) NOT NULL\n"
            ");\n\n"
            "Indexes: idx_orders_customer, idx_orders_date, idx_items_order, idx_items_product\n\n"
            "Common patterns:\n"
            "- Revenue by period: SUM(total) GROUP BY DATE_TRUNC('month', order_date)\n"
            "- Order with items: JOIN order_items ON order_items.order_id = orders.id\n"
            "- Order status: WHERE status IN ('pending', 'shipped', 'delivered')"
        ),
    },
    {
        "name": "products_schema",
        "description": "Full schema for products, categories, and suppliers tables",
        "content": (
            "CREATE TABLE products (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    name VARCHAR(200) NOT NULL,\n"
            "    category_id INTEGER REFERENCES categories(id),\n"
            "    supplier_id INTEGER REFERENCES suppliers(id),\n"
            "    price DECIMAL(10,2) NOT NULL,\n"
            "    cost DECIMAL(10,2),\n"
            "    description TEXT\n"
            ");\n\n"
            "CREATE TABLE categories (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    name VARCHAR(100) NOT NULL,\n"
            "    parent_id INTEGER REFERENCES categories(id)\n"
            ");\n\n"
            "CREATE TABLE suppliers (\n"
            "    id INTEGER PRIMARY KEY,\n"
            "    name VARCHAR(200) NOT NULL,\n"
            "    contact_email VARCHAR(255),\n"
            "    lead_time_days INTEGER\n"
            ");\n\n"
            "Common patterns:\n"
            "- Product margin: (price - cost) / price AS margin\n"
            "- Products by category: JOIN categories ON products.category_id = categories.id\n"
            "- Category hierarchy: Self-join on categories.parent_id"
        ),
    },
    {
        "name": "query_best_practices",
        "description": "SQL best practices, optimization tips, and common pitfalls for this database",
        "content": (
            "Best Practices:\n"
            "1. Always use LIMIT for exploratory queries (default: 10)\n"
            "2. Use indexed columns in WHERE clauses for performance\n"
            "3. Prefer COUNT(*) over COUNT(column) unless NULLs matter\n"
            "4. Use DATE_TRUNC for time-based aggregations\n"
            "5. Avoid SELECT * -- specify needed columns\n\n"
            "Common Pitfalls:\n"
            "- Division by zero in margin calculations: use NULLIF(denominator, 0)\n"
            "- Timezone issues: all timestamps are UTC\n"
            "- The 'total' column in orders may be NULL for draft orders\n"
            "- Category hierarchy is max 3 levels deep\n\n"
            "Performance Notes:\n"
            "- orders table has ~1M rows, use date filters\n"
            "- order_items has ~5M rows, always filter by order_id\n"
            "- Full-text search on product descriptions uses pg_trgm"
        ),
    },
]
```

## Step 2: Create the load_skill Tool

The `load_skill` tool allows the agent to load a specific skill's content into its context on demand.

```python
from langchain_core.tools import tool

SKILL_MAP = {skill["name"]: skill for skill in skills}

@tool
def load_skill(skill_name: str) -> str:
    """Load detailed information about a specific database skill.

    Use this tool when you need detailed schema information, query patterns,
    or best practices for a specific part of the database. Check the available
    skills listed in your instructions before calling.

    Args:
        skill_name: Name of the skill to load.
    """
    skill = SKILL_MAP.get(skill_name)
    if skill is None:
        available = ", ".join(SKILL_MAP.keys())
        return f"Skill '{skill_name}' not found. Available skills: {available}"
    return f"## {skill['name']}\n\n{skill['content']}"
```

## Step 3: Create the Skill Middleware

`SkillMiddleware` injects skill descriptions (names and descriptions only, not content) into the system prompt so the agent knows what is available to load.

```python
from langchain.middleware import wrap_model_call

@wrap_model_call
def skill_middleware(state, config, next_fn):
    """Inject skill descriptions into the system prompt."""
    skill_descriptions = "\n".join(
        f"- **{skill['name']}**: {skill['description']}"
        for skill in skills
    )

    skill_section = (
        "\n\n## Available Skills\n"
        "Use the `load_skill` tool to load detailed information for any of these:\n\n"
        f"{skill_descriptions}\n\n"
        "Load a skill before writing queries that involve those tables."
    )

    # Append skill listing to the system prompt
    current_prompt = config.get("system_prompt", "")
    config["system_prompt"] = current_prompt + skill_section

    return next_fn(state, config)
```

## Step 4: Add the SQL Query Tool

```python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("postgresql://user:pass@localhost:5432/company")

@tool
def execute_sql(query: str) -> str:
    """Execute a SQL query against the database and return results.

    Args:
        query: The SQL query to execute. Must be a SELECT statement.
    """
    if not query.strip().upper().startswith("SELECT"):
        return "Error: Only SELECT queries are allowed."
    try:
        result = db.run(query)
        return result
    except Exception as e:
        return f"Query error: {str(e)}"
```

## Step 5: Create the Agent

```python
from langchain.agents import create_agent

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[load_skill, execute_sql],
    system_prompt=(
        "You are a SQL assistant for a company database. You help users write "
        "and execute SQL queries to answer their questions.\n\n"
        "Workflow:\n"
        "1. Understand the user's question\n"
        "2. Load the relevant skills to understand the schema\n"
        "3. Write a SQL query based on the loaded schema\n"
        "4. Execute the query\n"
        "5. Interpret and present the results\n\n"
        "Always load the relevant schema skill before writing a query. "
        "If unsure which tables are needed, load database_overview first."
    ),
    middleware=[skill_middleware],
)
```

## Step 6: Run the Agent

```python
response = agent.invoke(
    {"messages": [{"role": "user", "content": "What are the top 10 customers by total spend this year?"}]}
)

print(response["messages"][-1].content)
```

## Execution Flow

```
User: "What are the top 10 customers by total spend this year?"

Agent thinks: "I need the customers and orders schemas."

Agent -> load_skill("customers_schema")
      <- Full schema with columns, indexes, and query patterns

Agent -> load_skill("orders_schema")
      <- Full schema including the 'total' column and date patterns

Agent -> execute_sql("""
    SELECT c.name, SUM(o.total) as total_spend
    FROM customers c
    JOIN orders o ON o.customer_id = c.id
    WHERE o.order_date >= '2026-01-01'
    AND o.total IS NOT NULL
    GROUP BY c.id, c.name
    ORDER BY total_spend DESC
    LIMIT 10
""")
      <- Results table

Agent: "Here are the top 10 customers by total spend in 2026:
        1. Acme Corp - $125,430.00
        2. ..."
```

## Size Guidance

The progressive disclosure pattern follows these guidelines for deciding what goes where:

| Size | Strategy | Example |
|------|----------|---------|
| **<1K tokens** | Include directly in the system prompt | Table names, high-level relationships |
| **1--10K tokens** | Load on demand via `load_skill` | Full table schemas, query patterns, best practices |
| **>10K tokens** | Load on demand with pagination | Large reference tables, historical query logs |

### Implementing Pagination for Large Skills

For skills with content larger than 10K tokens, implement pagination:

```python
@tool
def load_skill_page(skill_name: str, page: int = 1, page_size: int = 50) -> str:
    """Load a page of content from a large skill.

    Args:
        skill_name: Name of the skill.
        page: Page number (1-indexed).
        page_size: Number of items per page.
    """
    skill = SKILL_MAP.get(skill_name)
    if skill is None:
        return f"Skill '{skill_name}' not found."

    lines = skill["content"].split("\n")
    start = (page - 1) * page_size
    end = start + page_size
    total_pages = (len(lines) + page_size - 1) // page_size

    page_content = "\n".join(lines[start:end])
    return (
        f"## {skill_name} (Page {page}/{total_pages})\n\n"
        f"{page_content}\n\n"
        f"{'Use load_skill_page with page=' + str(page + 1) + ' for more.' if page < total_pages else 'End of content.'}"
    )
```

## Benefits of Progressive Disclosure

| Benefit | Description |
|---------|-------------|
| **Token efficiency** | Only load what is needed for the current query |
| **Scalability** | Supports databases with hundreds of tables |
| **Accuracy** | Agent gets detailed schema info exactly when it needs it |
| **Adaptability** | Skills can be updated independently without changing the prompt |
| **Cost reduction** | Fewer input tokens per request means lower API costs |
