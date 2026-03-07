# Custom RAG Agent with LangGraph

This tutorial covers building a retrieval-augmented generation (RAG) agent using LangGraph's `StateGraph`. The agent implements a custom control flow that includes query generation, document retrieval, relevance grading, question rewriting, and answer generation with conditional routing between steps.

## Architecture

```
           [generate_query_or_respond]
                /              \
          (tool call)       (no tool call)
              |                  |
         [retrieve]           [END]
              |
      [grade_documents]
         /          \
   (relevant)    (not relevant)
       |              |
  [generate_answer]  [rewrite_question]
       |              |
     [END]     [generate_query_or_respond]
```

## Prerequisites

```bash
pip install langgraph langchain langchain-openai chromadb
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Step 1: Build the Vector Store

```python
from langchain_community.document_loaders import WebBaseLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

# Load and split documents
loader = WebBaseLoader("https://docs.example.com/guide")
docs = loader.load()

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
)
splits = text_splitter.split_documents(docs)

# Create vector store
embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
vector_store = InMemoryVectorStore.from_documents(splits, embeddings)
retriever = vector_store.as_retriever(search_kwargs={"k": 4})
```

## Step 2: Define the Retriever Tool

```python
from langchain_core.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Retrieve documents from the knowledge base relevant to the query.

    Args:
        query: The search query.
    """
    docs = retriever.invoke(query)
    serialized = "\n\n".join(
        f"Source: {doc.metadata.get('source', 'unknown')}\n{doc.page_content}"
        for doc in docs
    )
    return serialized, docs
```

## Step 3: Define the State

```python
from langgraph.graph import MessagesState

class AgentState(MessagesState):
    """State for the RAG agent."""
    pass
```

## Step 4: Define the Grading Schema

Use structured output to grade the relevance of retrieved documents.

```python
from pydantic import BaseModel, Field
from typing import Literal

class GradeDocuments(BaseModel):
    """Binary relevance score for a retrieved document."""

    relevance: Literal["relevant", "not_relevant"] = Field(
        description="Whether the document is relevant to the question. "
                    "'relevant' if the document contains information that helps "
                    "answer the question, 'not_relevant' otherwise."
    )
    reasoning: str = Field(
        description="Brief explanation of the relevance assessment."
    )
```

## Step 5: Define the Graph Nodes

### Node: generate_query_or_respond

This is the entry node. It either generates a retrieval query (by calling the retrieve tool) or responds directly if no retrieval is needed.

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o")
llm_with_tools = llm.bind_tools([retrieve])

def generate_query_or_respond(state: AgentState):
    """Decide whether to retrieve documents or respond directly."""
    system_message = (
        "You are a helpful assistant with access to a knowledge base. "
        "If the user's question can be answered from the knowledge base, "
        "use the retrieve tool to search for relevant documents. "
        "If the question is conversational or does not require retrieval, "
        "respond directly."
    )
    messages = [{"role": "system", "content": system_message}] + state["messages"]
    response = llm_with_tools.invoke(messages)
    return {"messages": [response]}
```

### Node: grade_documents

Grade each retrieved document for relevance to the original question. Filter out irrelevant documents.

```python
grader = llm.with_structured_output(GradeDocuments)

def grade_documents(state: AgentState):
    """Grade the relevance of retrieved documents."""
    messages = state["messages"]

    # Find the user's original question
    user_question = None
    for msg in messages:
        if msg.type == "human":
            user_question = msg.content

    # Find the tool response with retrieved documents
    tool_message = messages[-1]  # Most recent message should be the tool result
    retrieved_content = tool_message.content

    # Grade relevance
    grade = grader.invoke(
        f"Question: {user_question}\n\n"
        f"Retrieved documents:\n{retrieved_content}\n\n"
        f"Are these documents relevant to answering the question?"
    )

    return {"relevance": grade.relevance, "messages": messages}
```

### Node: rewrite_question

Rewrite the question to improve retrieval results when documents are not relevant.

```python
def rewrite_question(state: AgentState):
    """Rewrite the question to improve retrieval."""
    messages = state["messages"]

    # Find the original question
    user_question = None
    for msg in messages:
        if msg.type == "human":
            user_question = msg.content

    rewrite_prompt = (
        f"The following question did not retrieve relevant documents from the "
        f"knowledge base. Rewrite it to be more specific or use different terms "
        f"that might match the documents better.\n\n"
        f"Original question: {user_question}\n\n"
        f"Rewritten question:"
    )

    response = llm.invoke(rewrite_prompt)
    return {"messages": [{"role": "human", "content": response.content}]}
```

### Node: generate_answer

Generate a final answer using the relevant retrieved documents.

```python
def generate_answer(state: AgentState):
    """Generate an answer using retrieved documents."""
    messages = state["messages"]

    # Find the user's question and retrieved content
    user_question = None
    retrieved_content = None
    for msg in messages:
        if msg.type == "human":
            user_question = msg.content
        if msg.type == "tool":
            retrieved_content = msg.content

    answer_prompt = (
        f"Answer the following question using only the provided context. "
        f"If the context does not contain enough information, say so.\n\n"
        f"Context:\n{retrieved_content}\n\n"
        f"Question: {user_question}"
    )

    response = llm.invoke(answer_prompt)
    return {"messages": [{"role": "assistant", "content": response.content}]}
```

## Step 6: Define Conditional Edges

### tools_condition

Route based on whether the LLM decided to call the retrieve tool.

```python
from langgraph.prebuilt import tools_condition

# tools_condition checks if the last message has tool calls
# Returns "tools" if tool calls are present, END otherwise
```

### Relevance Routing

Route based on the document relevance grade.

```python
def relevance_router(state: AgentState):
    """Route based on document relevance."""
    relevance = state.get("relevance", "not_relevant")
    if relevance == "relevant":
        return "generate_answer"
    else:
        return "rewrite_question"
```

## Step 7: Build the Graph

```python
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode

graph = StateGraph(AgentState)

# Add nodes
graph.add_node("generate_query_or_respond", generate_query_or_respond)
graph.add_node("retrieve", ToolNode([retrieve]))
graph.add_node("grade_documents", grade_documents)
graph.add_node("rewrite_question", rewrite_question)
graph.add_node("generate_answer", generate_answer)

# Add edges
graph.add_edge(START, "generate_query_or_respond")
graph.add_conditional_edges(
    "generate_query_or_respond",
    tools_condition,
    {
        "tools": "retrieve",
        "__end__": END,
    },
)
graph.add_edge("retrieve", "grade_documents")
graph.add_conditional_edges(
    "grade_documents",
    relevance_router,
    {
        "generate_answer": "generate_answer",
        "rewrite_question": "rewrite_question",
    },
)
graph.add_edge("rewrite_question", "generate_query_or_respond")
graph.add_edge("generate_answer", END)

# Compile
app = graph.compile()
```

## Step 8: Run the Agent

```python
response = app.invoke(
    {"messages": [{"role": "user", "content": "How does the authentication system work?"}]}
)

# Print the final answer
print(response["messages"][-1].content)
```

### Streaming Execution

```python
for event in app.stream(
    {"messages": [{"role": "user", "content": "Explain the caching strategy"}]}
):
    for node_name, output in event.items():
        print(f"--- {node_name} ---")
        if "messages" in output:
            for msg in output["messages"]:
                print(msg.content[:200] if hasattr(msg, "content") else str(msg)[:200])
```

## Execution Trace

```
User: "How does the authentication system work?"

generate_query_or_respond:
  -> Decides to call retrieve("authentication system architecture")

retrieve:
  -> Returns 4 documents about authentication

grade_documents:
  -> GradeDocuments(relevance="relevant", reasoning="Documents describe auth flow")

generate_answer:
  -> Synthesizes answer from retrieved documents
  -> "The authentication system uses JWT tokens with..."

---

User: "What is the meaning of life?"

generate_query_or_respond:
  -> Decides to respond directly (no tool call)
  -> "That's a philosophical question outside the scope of this knowledge base..."
```

## Customization

### Adding a Maximum Retry Limit

Prevent infinite rewrite loops by tracking the number of retries.

```python
class AgentState(MessagesState):
    retry_count: int = 0

def rewrite_question(state: AgentState):
    retry_count = state.get("retry_count", 0)
    if retry_count >= 2:
        return {
            "messages": [{"role": "assistant", "content": "I couldn't find relevant information after multiple attempts."}],
        }
    # ... rewrite logic ...
    return {"messages": [...], "retry_count": retry_count + 1}
```

### Using Different Grading Strategies

| Strategy | Description |
|----------|-------------|
| **Binary** | Relevant / Not relevant (shown above) |
| **Scored** | 0--1 relevance score with a threshold |
| **Multi-aspect** | Grade on relevance, recency, and specificity separately |
