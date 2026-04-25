// Auto-generated from 01_rag_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(1, "RAG Agent", subtitle: "Vector Search-Based Question Answering")

== Learning Objectives

- Build a vector search pipeline with `InMemoryVectorStore`
- Define a retrieval tool with the `content_and_artifact` return pattern
- Create and query a RAG agent with `create_deep_agent`
- Apply v1 middleware (`ModelCallLimitMiddleware`, `ToolRetryMiddleware`)
- Use the _Skills system_ to progressively disclose RAG domain knowledge


== Overview

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Details],
  [_Framework_],
  [LangChain + Deep Agents],
  [_Core components_],
  [`InMemoryVectorStore`, `OpenAIEmbeddings`, `RecursiveCharacterTextSplitter`],
  [_Agent pattern_],
  [`content_and_artifact` tool → `create_deep_agent`],
  [_Backend_],
  [`FilesystemBackend(root_dir=".", virtual_mode=True)`],
  [_Skill_],
  [`skills/rag-agent/SKILL.md` — progressive disclosure of RAG domain knowledge],
)


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

== Step 1: Create Sample Documents

The first step in a RAG pipeline is preparing the documents you want to search. In a real system, you would load documents from PDFs, web pages, or databases. Here, for learning purposes, we create `Document` objects directly.


#code-block(`````python
from langchain_core.documents import Document

docs = [
    Document(page_content="LangChain is a framework for building LLM applications. It supports tools, chains, and agents.", metadata={"source": "langchain"}),
    Document(page_content="LangGraph is a framework for building stateful workflows. It provides a Graph API and a Functional API.", metadata={"source": "langgraph"}),
    Document(page_content="Deep Agents is an all-in-one agent SDK. It creates agents with create_deep_agent and supports backends and subagents.", metadata={"source": "deepagents"}),
    Document(page_content="RAG stands for retrieval-augmented generation. It injects external knowledge into an LLM to produce more accurate answers.", metadata={"source": "rag"}),
    Document(page_content="A vector store is a database that stores embeddings and performs similarity search. FAISS and Chroma are common examples.", metadata={"source": "vectorstore"}),
    Document(page_content="An agent is a system in which an LLM uses tools to perform tasks autonomously. ReAct is a representative pattern.", metadata={"source": "agent"}),
]
print(f"Created {len(docs)} documents")

`````)

== Step 2: Split the Text

Split larger documents into chunks that are easier to retrieve. `RecursiveCharacterTextSplitter` tries to split at natural boundaries such as paragraphs, sentences, and then words.


#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=200, chunk_overlap=50
)
splits = splitter.split_documents(docs)
print(f"Split result: {len(splits)} chunks")

`````)

== Step 3: Build the Vector Store

Convert the text into vectors with an OpenAI embedding model and store them in `InMemoryVectorStore`. In production, you would typically use a persistent store such as FAISS or Chroma.


#code-block(`````python
from langchain_openai import OpenAIEmbeddings
from langchain_core.vectorstores import InMemoryVectorStore

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = InMemoryVectorStore.from_documents(splits, embeddings)
print(f"Vector store ready — embedded {len(splits)} documents")

`````)

== Step 4: Define a Retrieval Tool (`content_and_artifact`)

The `response_format="content_and_artifact"` pattern makes the tool return two things:
- _content_: a text summary shown to the agent
- _artifact_: the full `Document` objects for downstream processing

This pattern helps save context tokens while still preserving access to the original data.


#code-block(`````python
from langchain.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search for relevant documents in the vector store."""
    results = vectorstore.similarity_search(query, k=3)
    content = "\n\n".join(d.page_content for d in results)
    return content, results

`````)

== Step 5: Test the Retrieval Tool by Itself

Before connecting the tool to the agent, verify that it behaves correctly.


#code-block(`````python
result = retrieve.invoke({"query": "What is an agent?"})
print(result)

`````)

== Step 6: Create the RAG Agent (with v1 Middleware)

Load the prompt from the prompt module. The flow tries LangSmith Hub → Langfuse → a local default prompt.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Middleware],
  text(weight: "bold")[Role],
  [`ModelCallLimitMiddleware`],
  [Prevents infinite loops by limiting the number of model calls],
  [`ToolRetryMiddleware`],
  [Automatically retries failed retrieval tool calls],
)


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langchain.agents.middleware import (
    ModelCallLimitMiddleware,
    ToolRetryMiddleware,
)
from prompts import RAG_AGENT_PROMPT

agent = create_deep_agent(
    model=model,
    tools=[retrieve],
    system_prompt=RAG_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    middleware=[
        ModelCallLimitMiddleware(run_limit=10),
        ToolRetryMiddleware(max_retries=2),
    ],
)

`````)

== Step 7: Run a Simple Query and a Comparison Query

Use a simple query (single retrieval) and a comparison-style query (multiple retrieval steps) to verify that the RAG agent works as expected.


== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Point],
  [_Vector store_],
  [`InMemoryVectorStore.from_documents()` — embedding-based similarity search],
  [_Retrieval tool_],
  [`\@tool(response_format="content_and_artifact")` — summary + original artifact separation],
  [_Agent_],
  [`create_deep_agent(model, tools=[retrieve], backend=..., skills=["/skills/"])`],
  [_Skill_],
  [`skills/rag-agent/SKILL.md` — saves tokens through progressive disclosure],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/langchain/24-retrieval.md`
- #link("https://python.langchain.com/docs/tutorials/rag/")[LangChain RAG Tutorial]
- `docs/deepagents/10-skills.md`

_Next Step:_ → #link("./02_sql_agent.ipynb")[02_sql_agent.ipynb]: Build a SQL agent.

