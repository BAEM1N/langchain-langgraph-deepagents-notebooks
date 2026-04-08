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
    model="gpt-4.1",
)

from langchain.agents import create_agent
from langchain.tools import tool

print("Environment ready.")
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


== 9.3 Conditional Edges

Branch to different paths based on state. With `add_conditional_edges`, the next node can be selected dynamically at runtime.

In the example below, the input text is classified first and then routed to a different handler depending on its category.


== 9.4 Integrating an Agent into a Workflow

Use an agent created with `create_agent` as a node inside a `StateGraph`. This makes it possible to connect multiple agents in a pipeline and handle more complex tasks.

The example below connects a research agent and a writing agent in sequence.


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

