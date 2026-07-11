// Auto-generated from 09_custom_workflow_and_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(9, "Custom Workflows and RAG")


== Learning Objectives

Build a custom workflow with LangGraph `StateGraph` and implement the RAG pattern.

This notebook covers:
- The basic structure of `StateGraph` (nodes, edges, state)
- Branching with conditional edges
- Integrating `create_agent` as a workflow node
- Implementing the RAG (Retrieval-Augmented Generation) pattern


== 9.1 Environment Setup


#code-block(`````python
from dotenv import load_dotenv
import os
load_dotenv(override=True)

from langchain_openai import ChatOpenAI

model = ChatOpenAI(
    model="gpt-5.4",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("Environment ready.")
`````)

#code-block(`````python
# Optional observability setup: LangSmith or Langfuse
# Set the keys in .env, or uncomment the lines below to enter them manually.
# os.environ["LANGFUSE_SECRET_KEY"] = "sk-lf-..."
# os.environ["LANGFUSE_PUBLIC_KEY"] = "pk-lf-..."
# os.environ["LANGFUSE_HOST"] = "https://lf.ddok.ai"
import os

# LangSmith: automatically enabled when LANGSMITH_TRACING=true
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    os.environ.setdefault("LANGCHAIN_TRACING_V2", "true")
    os.environ.setdefault("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    os.environ.setdefault("LANGCHAIN_PROJECT", os.environ.get("LANGSMITH_PROJECT", "default"))
    print(f"LangSmith tracing ON — project: {os.environ['LANGCHAIN_PROJECT']}")

# Langfuse: pass config={"callbacks": [langfuse_handler]} to invoke/stream
langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")

# Langfuse config: pass to invoke/stream/batch calls
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

== 9.2 `StateGraph` Basics

Let's look at the core building blocks of LangGraph.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Concept],
  text(weight: "bold")[Description],
  [_Node_],
  [A unit of work. It can be a function or an agent],
  [_Edge_],
  [A connection between nodes that defines execution flow],
  [_State_],
  [Shared data passed between nodes, usually defined with `TypedDict`],
)

`StateGraph` combines these three parts so you can build complex workflows.


#code-block(`````python
from langgraph.graph import StateGraph, START, END
from typing import TypedDict


# Define state
class WorkflowState(TypedDict):
    input: str
    processed: str
    output: str


# Define node functions
def preprocess(state: WorkflowState) -> dict:
    """
    Preprocessing: clean up the input text.
    """
    return {
        "processed": state["input"].strip().lower()
    }


def analyze(state: WorkflowState) -> dict:
    """
    Analysis: analyze the processed text.
    """
    text = state["processed"]
    word_count = len(text.split())

    return {
        "output": f"Analysis complete: '{text}' contains {word_count} words."
    }


# Build the graph
builder = StateGraph(WorkflowState)

builder.add_node("preprocess", preprocess)
builder.add_node("analyze", analyze)

builder.add_edge(START, "preprocess")
builder.add_edge("preprocess", "analyze")
builder.add_edge("analyze", END)

graph = builder.compile()


# Execute
result = graph.invoke(
    {
        "input": "  Hello World from LangGraph!  "
    },
    config=lf_config
)

print("Input:", result["input"])
print("Preprocessed:", result["processed"])
print("Output:", result["output"])
`````)

== 9.3 Conditional Edges

Branch to different paths based on state. With `add_conditional_edges`, the next node can be selected dynamically at runtime.

In the example below, the input text is classified first and then routed to a different handler depending on its category.


#code-block(`````python
class RouterState(TypedDict):
    input: str
    category: str
    output: str

def classify(state: RouterState) -> dict:
    """Classifies the input."""
    text = state["input"].lower()
    if any(w in text for w in ["calculate", "math", "sum"]):
        return {"category": "math"}
    elif any(w in text for w in ["translate", "language"]):
        return {"category": "language"}
    return {"category": "general"}

def handle_math(state: RouterState) -> dict:
    return {"output": f"[Math handler] Processing: {state['input']}"}

def handle_language(state: RouterState) -> dict:
    return {"output": f"[Language handler] Processing: {state['input']}"}

def handle_general(state: RouterState) -> dict:
    return {"output": f"[General handler] Processing: {state['input']}"}

def route(state: RouterState) -> str:
    """Route based on the classification result"""
    return state["category"]

builder = StateGraph(RouterState)
builder.add_node("classify", classify)
builder.add_node("math", handle_math)
builder.add_node("language", handle_language)
builder.add_node("general", handle_general)

builder.add_edge(START, "classify")
builder.add_conditional_edges("classify", route, {
    "math": "math",
    "language": "language",
    "general": "general",
})
builder.add_edge("math", END)
builder.add_edge("language", END)
builder.add_edge("general", END)

graph = builder.compile()

# Test
for query in ["Calculate 2+2", "Translate 'hello' into Korean", "What is AI?"]:
    result = graph.invoke({"input": query}, config=lf_config)
    print(f"  {query} → {result['output']}")
`````)

== 9.4 Integrating an Agent into a Workflow

Use an agent created with `create_agent` as a node inside a `StateGraph`. This makes it possible to connect multiple agents in a pipeline and handle more complex tasks.

The example below connects a research agent and a writing agent in sequence.


#code-block(`````python
from langgraph.graph import MessagesState

@tool
def web_search(query: str) -> str:
    """Searches for information on the web."""
    return f"'{query}'search result for"

# Use an agent as a node
research_agent = create_agent(
    model=model,
    tools=[web_search],
    system_prompt="You are a research assistant. Search for information and provide concise answers.",
    name="researcher",
)

@tool
def format_report(content: str) -> str:
    """Converts content into a structured report format."""
    return f"## Report\n\n{content}"

writer_agent = create_agent(
    model=model,
    tools=[format_report],
    system_prompt="You are a technical writer. Turn the research results into a clean report.",
    name="writer",
)

# Research -> writing pipeline
builder = StateGraph(MessagesState)
builder.add_node(research_agent)
builder.add_node(writer_agent)
builder.add_edge(START, "researcher")
builder.add_edge("researcher", "writer")
builder.add_edge("writer", END)

pipeline = builder.compile()

result = pipeline.invoke(
    {"messages": [{"role": "user", "content": "Research the main features of LangChain v1."}]},
    config=lf_config,
)
print("Pipeline result:", result["messages"][-1].content[:300])
`````)

== 9.5 Overview of RAG (Retrieval-Augmented Generation)

RAG is a pattern that strengthens LLM answers by retrieving external knowledge. There are three major approaches:

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Pattern],
  text(weight: "bold")[Description],
  text(weight: "bold")[Characteristic],
  [_Basic 2-step_],
  [Retrieve → generate],
  [Simple and fast],
  [_Agentic RAG_],
  [An agent repeatedly calls retrieval tools],
  [Flexible and accurate],
  [_Hybrid_],
  [Combines keyword and semantic search],
  [Higher retrieval quality],
)

- _Basic 2-step_: retrieve documents, then pass them as context to the LLM for answer generation
- _Agentic RAG_: the agent calls retrieval tools repeatedly until it has enough information to answer


== 9.6 A Simple RAG Implementation

Split text into chunks and implement RAG with simple keyword-based retrieval. Even without a vector store, you can still understand the core idea behind RAG.


#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Sample documents
documents = [
    "LangChain is a framework for building applications with large language models. It provides tools for prompt engineering, memory management, and agent creation.",
    "LangGraph is a low-level orchestration framework for building stateful agents. It uses a graph-based approach with nodes and edges.",
    "Middleware in LangChain v1 allows you to intercept and modify agent behavior at every step. You can add logging, guardrails, and custom logic.",
    "Multi-agent systems in LangChain support five patterns: subagents, handoffs, skills, router, and custom workflows.",
    "RAG (Retrieval-Augmented Generation) combines information retrieval with text generation to provide grounded, factual responses.",
]

# Split text
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=200,
    chunk_overlap=50,
)

chunks = []
for doc in documents:
    chunks.extend(text_splitter.split_text(doc))

print(f"Original documents: {len(documents)}")
print(f"Split chunks: {len(chunks)}")
for i, chunk in enumerate(chunks):
    print(f"  [{i}] {chunk[:80]}...")
`````)

#code-block(`````python
# Simple keyword-based retrieval (without a vector store)
def simple_search(query: str, documents: list[str], top_k: int = 2) -> list[str]:
    """A simple keyword-based retrieval function."""
    scores = []
    query_words = set(query.lower().split())
    for doc in documents:
        doc_words = set(doc.lower().split())
        score = len(query_words & doc_words)
        scores.append((score, doc))
    scores.sort(reverse=True)
    return [doc for _, doc in scores[:top_k]]

# RAG tool
@tool
def retrieve_info(query: str) -> str:
    """Searches for relevant information in the knowledge base."""
    results = simple_search(query, chunks, top_k=3)
    return "\n\n".join(results)

# RAG agent
rag_agent = create_agent(
    model=model,
    tools=[retrieve_info],
    system_prompt="""You are a knowledgeable assistant. Always use the retrieve_info tool to search for information before answering. Base your answer on the retrieved information.""",
)

result = rag_agent.invoke(
    {"messages": [{"role": "user", "content": "What are LangChain's multi-agent patterns?"}]},
    config=lf_config,
)
print("RAG agent result:", result["messages"][-1].content)
`````)

== 9.7 FAISS Vector Store (Optional)

Similarity search with embeddings is far more accurate than keyword matching. The example below shows how to use a FAISS vector store.


#code-block(`````python
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS

# Create the embedding model
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

# Create the vector store
vectorstore = FAISS.from_texts(chunks, embeddings)

# Retrieve
results = vectorstore.similarity_search("LangChain agent patterns", k=3)
for doc in results:
    print(doc.page_content)
`````)

== 9.8 Summary

This notebook covered:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Topic],
  text(weight: "bold")[Key Idea],
  [_StateGraph basics_],
  [Build workflows from nodes, edges, and state],
  [_Conditional edges_],
  [Branch at runtime with `add_conditional_edges`],
  [_Agent integration_],
  [Use `create_agent` as a `StateGraph` node inside a pipeline],
  [_RAG pattern_],
  [Combine retrieval and generation for grounded answers],
  [_Vector store_],
  [Use FAISS or similar tools for embedding-based similarity search],
)

The next notebook shows how to deploy agents to production environments.

=== Next Steps
→ _#link("./10_production.ipynb")[10_production.ipynb]_: Learn about production deployment.
