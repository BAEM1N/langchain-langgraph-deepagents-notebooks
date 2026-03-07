# Multi-Source Knowledge Base Router

This tutorial covers building a router that classifies incoming queries and routes them to specialized knowledge base agents in parallel. The router pattern uses structured output for classification, the Send API for parallel dispatch, and a reducer to aggregate results.

## Architecture

```
                    [Router]
                  /    |     \
          [GitHub]  [Notion]  [Slack]
              \       |       /
               [Result Reducer]
                     |
                 [Response]
```

| Component | Role |
|-----------|------|
| **Router** | Classifies the query and determines which sources to consult |
| **Specialized Agents** | GitHub, Notion, Slack agents with source-specific retrieval |
| **Send API** | Dispatches queries to multiple agents in parallel |
| **Reducer** | Aggregates results from all agents into a unified response |

## Prerequisites

```bash
pip install langchain langchain-openai
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Step 1: Define the Classification Schema

Use structured output to classify queries into one or more knowledge sources.

```python
from pydantic import BaseModel, Field
from typing import Literal

class QueryClassification(BaseModel):
    """Classification of a user query into knowledge base sources."""

    sources: list[Literal["github", "notion", "slack"]] = Field(
        description="Which knowledge sources are relevant to this query. "
                    "Select all that apply."
    )
    reasoning: str = Field(
        description="Brief explanation of why these sources were selected."
    )
    sub_queries: dict[str, str] = Field(
        description="Source-specific sub-queries optimized for each selected source. "
                    "Keys are source names, values are the optimized query strings."
    )
```

### Classification Examples

| User Query | Sources | Reasoning |
|-----------|---------|-----------|
| "How do I deploy the auth service?" | `["github", "notion"]` | Deployment code in GitHub, procedures in Notion |
| "What did the team decide about the new API?" | `["slack", "notion"]` | Discussions in Slack, decisions documented in Notion |
| "Show me the PR for the login fix" | `["github"]` | Pull requests are only in GitHub |
| "What's the onboarding process and where's the starter repo?" | `["github", "notion", "slack"]` | Repo in GitHub, process in Notion, context in Slack |

## Step 2: Build the Router

The router uses the LLM with structured output to classify the query.

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o")
classifier = llm.with_structured_output(QueryClassification)

def route_query(state):
    """Classify the query and determine routing."""
    user_message = state["messages"][-1].content

    classification = classifier.invoke(
        f"Classify this query and generate source-specific sub-queries:\n\n{user_message}"
    )

    return {
        "classification": classification,
        "sources": classification.sources,
        "sub_queries": classification.sub_queries,
    }
```

## Step 3: Define Specialized Agents

Each source has its own agent with domain-specific tools and retrieval logic.

### GitHub Agent

```python
from langchain_core.tools import tool

@tool
def search_github_code(query: str, repo: str = None) -> str:
    """Search for code across GitHub repositories.

    Args:
        query: Code search query.
        repo: Optional repository to limit search to.
    """
    results = github_client.search_code(query, repo=repo)
    return format_code_results(results)

@tool
def search_github_issues(query: str, state: str = "all") -> str:
    """Search GitHub issues and pull requests.

    Args:
        query: Issue search query.
        state: Filter by state (open, closed, all).
    """
    results = github_client.search_issues(query, state=state)
    return format_issue_results(results)

github_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[search_github_code, search_github_issues],
    system_prompt=(
        "You are a GitHub knowledge base agent. Search code repositories, "
        "issues, and pull requests to answer the user's query. "
        "Return relevant code snippets, issue summaries, and links."
    ),
    name="github_agent",
)
```

### Notion Agent

```python
@tool
def search_notion_pages(query: str) -> str:
    """Search Notion workspace for relevant pages and documents.

    Args:
        query: Search query for Notion pages.
    """
    results = notion_client.search(query=query)
    return format_notion_results(results)

@tool
def read_notion_page(page_id: str) -> str:
    """Read the full content of a Notion page.

    Args:
        page_id: The Notion page ID.
    """
    content = notion_client.get_page_content(page_id)
    return content

notion_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[search_notion_pages, read_notion_page],
    system_prompt=(
        "You are a Notion knowledge base agent. Search the workspace for "
        "documentation, meeting notes, and project pages. Return relevant "
        "content and page links."
    ),
    name="notion_agent",
)
```

### Slack Agent

```python
@tool
def search_slack_messages(query: str, channel: str = None) -> str:
    """Search Slack messages across channels.

    Args:
        query: Search query for Slack messages.
        channel: Optional channel to limit search to.
    """
    results = slack_client.search_messages(query=query, channel=channel)
    return format_slack_results(results)

@tool
def get_slack_thread(channel: str, thread_ts: str) -> str:
    """Get the full thread of a Slack conversation.

    Args:
        channel: The channel ID.
        thread_ts: The thread timestamp.
    """
    messages = slack_client.get_thread(channel=channel, ts=thread_ts)
    return format_thread(messages)

slack_agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[search_slack_messages, get_slack_thread],
    system_prompt=(
        "You are a Slack knowledge base agent. Search conversations, threads, "
        "and channel history to find relevant discussions and decisions."
    ),
    name="slack_agent",
)
```

## Step 4: Parallel Dispatch with Send API

Use the `Send` API to dispatch queries to multiple agents simultaneously.

```python
from langgraph.constants import Send

AGENT_MAP = {
    "github": github_agent,
    "notion": notion_agent,
    "slack": slack_agent,
}

def dispatch_to_agents(state):
    """Send sub-queries to the relevant agents in parallel."""
    classification = state["classification"]
    sends = []

    for source in classification.sources:
        sub_query = classification.sub_queries.get(source, state["messages"][-1].content)
        sends.append(
            Send(
                source,
                {
                    "messages": [{"role": "user", "content": sub_query}],
                    "source": source,
                },
            )
        )

    return sends
```

## Step 5: Aggregate Results

The reducer collects results from all agents and synthesizes a unified response.

```python
def reduce_results(state):
    """Aggregate results from all source agents into a final response."""
    agent_results = state.get("agent_results", [])

    # Format results by source
    formatted = "\n\n".join(
        f"### From {result['source'].title()}\n{result['content']}"
        for result in agent_results
    )

    # Use LLM to synthesize a unified answer
    synthesis_prompt = (
        "Synthesize the following information from multiple sources into a "
        "coherent, unified answer. Cite which source each piece of information "
        "came from.\n\n"
        f"{formatted}"
    )

    llm = ChatOpenAI(model="gpt-4o")
    response = llm.invoke(synthesis_prompt)

    return {
        "messages": [{"role": "assistant", "content": response.content}],
    }
```

## Step 6: Assemble the Graph

```python
from langgraph.graph import StateGraph, START, END

class RouterState(AgentState):
    classification: QueryClassification = None
    sources: list[str] = []
    sub_queries: dict[str, str] = {}
    agent_results: list[dict] = []

graph = StateGraph(RouterState)

# Add nodes
graph.add_node("router", route_query)
graph.add_node("github", github_agent)
graph.add_node("notion", notion_agent)
graph.add_node("slack", slack_agent)
graph.add_node("reducer", reduce_results)

# Add edges
graph.add_edge(START, "router")
graph.add_conditional_edges("router", dispatch_to_agents)
graph.add_edge("github", "reducer")
graph.add_edge("notion", "reducer")
graph.add_edge("slack", "reducer")
graph.add_edge("reducer", END)

app = graph.compile()
```

## Step 7: Run the Router

```python
response = app.invoke(
    {"messages": [{"role": "user", "content": "How do we deploy the payment service?"}]}
)

print(response["messages"][-1].content)
```

## Execution Flow

```
User: "How do we deploy the payment service?"

Router:
  Classification:
    sources: ["github", "notion"]
    sub_queries:
      github: "payment service deployment scripts CI/CD pipeline"
      notion: "payment service deployment process procedure runbook"

Parallel dispatch via Send API:
  GitHub Agent: Searches repos for deployment configs, CI/CD files
  Notion Agent: Searches docs for deployment runbooks, procedures

Reducer:
  Synthesizes: "To deploy the payment service:
  1. The deployment is managed via the CI/CD pipeline in the
     `payment-service` repo (GitHub: .github/workflows/deploy.yml)
  2. Follow the deployment runbook (Notion: 'Payment Service Ops')
  3. ..."
```

## Extending the Router

### Adding a New Source

1. Define source-specific tools
2. Create a specialized agent
3. Add the source to `QueryClassification.sources`
4. Add the agent node to the graph
5. Connect it to the reducer

### Custom Routing Logic

For more complex routing, replace the LLM classifier with a rule-based or hybrid approach:

```python
def custom_route(state):
    """Rule-based routing with LLM fallback."""
    query = state["messages"][-1].content.lower()

    # Rule-based shortcuts
    if "pull request" in query or "PR" in query or "commit" in query:
        return {"sources": ["github"], "sub_queries": {"github": query}}
    if "meeting notes" in query:
        return {"sources": ["notion"], "sub_queries": {"notion": query}}

    # Fall back to LLM classification
    return route_query(state)
```
