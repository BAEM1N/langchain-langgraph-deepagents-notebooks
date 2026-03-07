# Build a RAG Agent

This tutorial covers two approaches to Retrieval-Augmented Generation (RAG) using LangChain: the **RAG Agent** pattern for multi-step retrieval and the **RAG Chain** pattern for single-pass retrieval. Choose the approach that best fits your use case.

## Overview

| Approach | Architecture | When to Use |
|----------|-------------|-------------|
| **RAG Agent** | Agent with retriever tool, multi-step reasoning | Complex queries requiring multiple searches, query reformulation, or combining results from different searches |
| **RAG Chain** | Middleware-injected context, single LLM call | Straightforward Q&A, predictable latency, lower cost |

## Prerequisites

```bash
pip install langchain langchain-openai langchain-community beautifulsoup4 chromadb
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Shared Setup: Building the Vector Store

Both approaches use the same document ingestion pipeline.

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

# Load documents from the web
loader = WebBaseLoader("https://docs.example.com/guide")
docs = loader.load()

# Split into chunks
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
)
splits = text_splitter.split_documents(docs)

# Create vector store
embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
vector_store = InMemoryVectorStore.from_documents(
    documents=splits,
    embedding=embeddings,
)
```

---

## Approach 1: RAG Agent

The RAG Agent treats the retriever as a tool that the agent can invoke one or more times. This enables multi-step reasoning: the agent can search, evaluate results, reformulate queries, and search again.

### Define the Retriever Tool

Use the `@tool` decorator with `response_format="content_and_artifact"` to return both a text summary and the raw documents as an artifact.

```python
from langchain_core.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search the knowledge base for information relevant to the query.

    Args:
        query: The search query to find relevant documents.

    Returns:
        A summary of retrieved documents and the raw document objects.
    """
    retrieved_docs = vector_store.similarity_search(query, k=4)
    serialized = "\n\n".join(
        f"Source: {doc.metadata.get('source', 'unknown')}\n"
        f"Content: {doc.page_content}"
        for doc in retrieved_docs
    )
    return serialized, retrieved_docs
```

The `response_format="content_and_artifact"` setting separates the tool output into:

- **Content**: A string representation passed to the model for reasoning
- **Artifact**: The raw document objects, available programmatically but not sent to the model

### Create the Agent

```python
from langchain.agents import create_agent

system_prompt = """You are a research assistant with access to a knowledge base.
Use the retrieve tool to search for relevant information before answering questions.
If your first search does not return sufficient information, try reformulating the query
and searching again. Always cite your sources."""

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[retrieve],
    system_prompt=system_prompt,
)
```

### Run the Agent

```python
response = agent.invoke(
    {"messages": [{"role": "user", "content": "What are the best practices for error handling?"}]}
)

print(response["messages"][-1].content)
```

### Multi-Step Retrieval

The agent can execute multiple retrieval steps automatically:

1. **Initial search** -- The agent formulates a query based on the user's question
2. **Evaluate results** -- The agent assesses whether the retrieved documents sufficiently answer the question
3. **Reformulate and re-search** -- If results are insufficient, the agent modifies the query and searches again
4. **Synthesize** -- The agent combines information from all retrieved documents into a final answer

---

## Approach 2: RAG Chain

The RAG Chain uses the `@dynamic_prompt` middleware to inject retrieved context directly into the system prompt before the LLM call. This produces a single LLM call with lower latency and more predictable costs.

### Define the Dynamic Prompt

```python
from langchain.middleware import dynamic_prompt

@dynamic_prompt
def rag_prompt(state, config):
    """Retrieve relevant documents and inject them into the system prompt."""
    # Get the latest user message
    user_message = state["messages"][-1].content

    # Retrieve relevant documents
    retrieved_docs = vector_store.similarity_search(user_message, k=4)
    context = "\n\n".join(doc.page_content for doc in retrieved_docs)

    # Return the augmented system prompt
    return (
        "You are a helpful assistant. Answer the user's question based on "
        "the following context. If the context does not contain relevant "
        "information, say so.\n\n"
        f"Context:\n{context}"
    )
```

### Create the Chain

```python
from langchain.agents import create_agent

chain = create_agent(
    model="claude-sonnet-4-6",
    middleware=[rag_prompt],
)
```

### Run the Chain

```python
response = chain.invoke(
    {"messages": [{"role": "user", "content": "What are the best practices for error handling?"}]}
)

print(response["messages"][-1].content)
```

---

## Comparing the Two Approaches

| Feature | RAG Agent | RAG Chain |
|---------|-----------|-----------|
| **LLM Calls** | Multiple (agent decides) | Single |
| **Retrieval Steps** | One or more, agent-controlled | Exactly one, middleware-controlled |
| **Query Reformulation** | Automatic when results are poor | Not supported |
| **Latency** | Higher (multiple round trips) | Lower (single pass) |
| **Cost** | Higher (more tokens) | Lower (fewer tokens) |
| **Transparency** | Agent reasoning visible in messages | Context injection is implicit |
| **Use Case** | Complex research questions | Straightforward Q&A |

## Advanced: Combining Both Approaches

You can use `@dynamic_prompt` to inject baseline context while also providing a retriever tool for deeper searches.

```python
@dynamic_prompt
def baseline_context(state, config):
    """Inject frequently-needed context into every request."""
    return (
        "You are a product support assistant for Acme Corp.\n\n"
        "Product catalog summary: ...\n"
        "Use the retrieve tool for detailed technical questions."
    )

agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[retrieve],
    middleware=[baseline_context],
)
```

## Full Example: RAG Agent

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_core.tools import tool
from langchain.agents import create_agent

# Ingest
loader = WebBaseLoader("https://docs.example.com/guide")
docs = loader.load()
splits = RecursiveCharacterTextSplitter(
    chunk_size=1000, chunk_overlap=200
).split_documents(docs)
vector_store = InMemoryVectorStore.from_documents(
    splits, OpenAIEmbeddings(model="text-embedding-3-large")
)

# Tool
@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search the knowledge base for relevant information."""
    docs = vector_store.similarity_search(query, k=4)
    serialized = "\n\n".join(
        f"Source: {d.metadata.get('source', 'unknown')}\nContent: {d.page_content}"
        for d in docs
    )
    return serialized, docs

# Agent
agent = create_agent(
    model="claude-sonnet-4-6",
    tools=[retrieve],
    system_prompt="You are a research assistant. Use retrieve to search before answering.",
)

# Run
response = agent.invoke(
    {"messages": [{"role": "user", "content": "Explain the authentication flow"}]}
)
print(response["messages"][-1].content)
```
