// Auto-generated from 05_agentic_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Agentic RAG", subtitle: "- Built directly with LangGraph")

We implement Retrieval-Augmented Generation (RAG) in three ways: LangChain RAG Agent, LangChain RAG Chain, and a custom RAG based on LangGraph StateGraph. Covers in-depth patterns such as document relevance evaluation, query rewriting, and conditional routing.

== Learning Objectives

- Understand the overall structure of the RAG pipeline (Indexing -\> Search -\> Generation)
- Chunk the document with `RecursiveCharacterTextSplitter`
- Build a vector store with `InMemoryVectorStore`
- Implement RAG Agent with LangChain `create_agent` + `@tool`
- Implement RAG Chain (single LLM call) with `@dynamic_prompt` middleware
- Build a custom RAG agent with LangGraph `StateGraph`
- `GradeDocuments` Evaluate document relevance with structured output
- Implement query rewriting and conditional routing

== 5.1 Environment Setup

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

llm = ChatOpenAI(model="gpt-4.1")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("Environment ready.")
`````)

== 5.2 RAG Overview

Retrieval-Augmented Generation (RAG) is a pattern that improves the accuracy of LLM responses by retrieving external knowledge. LLM has two key limitations:
- _Finite context_: the entire corpus cannot be processed at once.
- _Static Knowledge_: Training data becomes outdated over time.

RAG overcomes this limitation by bringing in relevant external information at query time.

=== Pipeline: Indexing -\\> Search -\\> Generate

#code-block(`````python
[Documents] -> Text Splitter -> [Chunks] -> Embeddings -> [Vector Store]
                                                      |
[Question] -> Embedding -> similarity_search -> [Relevant Chunks] -> LLM -> [Answer]
`````)

=== 5 Core Components

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Components],
  text(weight: "bold")[Role],
  [_Document Loaders_],
  [Collect data from external sources (Google Drive, Notion, etc.) into a standard Document object],
  [_Text Splitters_],
  [Split large documents into chunks that fit into the context window],
  [_Embedding Models_],
  [Convert text into vectors where semantically similar content is grouped close together],
  [_Vector Stores_],
  [A specialized database that stores embeddings and performs similarity searches],
  [_Retrievers_],
  [Return related documents based on unstructured queries],
)

=== Three RAG architectures

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Approach],
  text(weight: "bold")[Architecture],
  text(weight: "bold")[LLM Call],
  text(weight: "bold")[Flexibility],
  text(weight: "bold")[Suitable for],
  [_2-Step RAG_ ​​],
  [Created immediately after search],
  [single],
  [low],
  [FAQ, Doc Bot (fast and predictable)],
  [_Agentic RAG_ ​​],
  [Agent decides when/how to search],
  [Multiple],
  [High],
  [Complex research, multiple tool approaches],
  [_Hybrid RAG_ ​​],
  [Query strengthening + search verification + answer quality check],
  [Multiple],
  [High],
  [When repeated purification is required],
)

=== Agent vs Chain approach (LangChain implementation)

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Approach],
  text(weight: "bold")[Architecture],
  text(weight: "bold")[LLM Call],
  text(weight: "bold")[Suitable for],
  [_RAG Agent_],
  [agent + retriever tool],
  [Multiple],
  [Complex queries, query reorganization required],
  [_RAG Chain_],
  [Middleware Injection Context],
  [single],
  [Simple Q&A, Predictable Costs],
  [_LangGraph Custom_],
  [StateGraph + Custom Node],
  [Multiple],
  [Fine-grained control such as relevance evaluation and rewriting],
)

== 5.3 Document loading & chunking

=== Document Loaders
The document loader reads raw content from various sources and returns it as a `Document` object with fields `page_content` and `metadata`.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[loader],
  text(weight: "bold")[Source],
  text(weight: "bold")[package],
  [`PyPDFLoader`],
  [PDF file],
  [`pypdf`],
  [`TextLoader`],
  [text file],
  [built],
  [`CSVLoader`],
  [CSV file],
  [built],
  [`WebBaseLoader`],
  [web page],
  [`beautifulsoup4`],
  [`DirectoryLoader`],
  [Files in directory],
  [built],
)

=== Text Splitting
`RecursiveCharacterTextSplitter` maintains semantic relevance by recursively splitting it in the order `\n\n` -\> `\n` -\> ` ` -\> `""`. Recommended as the most general purpose splitter.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[parameters],
  text(weight: "bold")[Description],
  text(weight: "bold")[Recommended value],
  [`chunk_size`],
  [Chunk maximum number of characters],
  [500-2000 (small for precise search, large for context preservation)],
  [`chunk_overlap`],
  [Number of adjacent chunks shared characters],
  [10-20% of chunk_size (to avoid loss of boundary information)],
)

=== Other dividers

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[divider],
  text(weight: "bold")[Suitable for],
  [`MarkdownHeaderTextSplitter`],
  [Markdown document],
  [`HTMLHeaderTextSplitter`],
  [HTML document],
  [`TokenTextSplitter`],
  [Token Budget Based Split],
  [`CodeTextSplitter`],
  [Source code (language recognition)],
)

#code-block(`````python
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

raw_docs = [
    Document(page_content="LangGraph is a state-based multi-actor with LLM"
        "A framework for building applications.",
        metadata={"source": "langgraph-docs"}),
    Document(page_content="Agents use tool to communicate with external systems."
        "Interact. The ReAct pattern alternates between reasoning and action.",
        metadata={"source": "agent-guide"}),
]
print(f"Loaded {len(raw_docs)} documents.")
`````)

#code-block(`````python
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000, chunk_overlap=200,
)
splits = text_splitter.split_documents(raw_docs)

for i, doc in enumerate(splits):
    print(f"Chunk {i}: {doc.page_content[:60]}...")
print(f"Total chunks: {len(splits)}")
`````)

== 5.4 Building a vector store

Vector Store is a specialized database that indexes embeddings and performs similarity searches. `InMemoryVectorStore` is suitable for development/testing.

=== Comparison of major vector stores

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Vector Store],
  text(weight: "bold")[Type],
  text(weight: "bold")[Suitable for],
  [`InMemoryVectorStore`],
  [In-process],
  [Development, small dataset],
  [`Chroma`],
  [Embedded/Client-Server],
  [Prototyping, medium-scale datasets],
  [`FAISS`],
  [In-process],
  [High performance local search],
  [`Pinecone`],
  [Managed Cloud],
  [Production, Scalability],
  [`PGVector`],
  [PostgreSQL extensions],
  [Leverage existing PostgreSQL infrastructure],
)

=== Search type

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Search type],
  text(weight: "bold")[Description],
  [`"similarity"`],
  [Standard nearest neighbor search],
  [`"mmr"`],
  [Maximal Marginal Relevance -- Balancing relevance and diversity (reducing duplication)],
  [`"similarity_score_threshold"`],
  [Return only documents with minimum similarity score or higher],
)

#code-block(`````python
from langchain_core.vectorstores import InMemoryVectorStore

vector_store = InMemoryVectorStore.from_documents(
    documents=splits, embedding=embeddings,
)
test_results = vector_store.similarity_search("LangGraph", k=2)
for doc in test_results:
    print(f"  [{doc.metadata['source']}] {doc.page_content[:80]}")
print(f"Vector store ready with {len(splits)} documents.")
`````)

== 5.5 Search tool Definition

Using `response_format="content_and_artifact"` splits the tool output into two parts:
- _Content_: String expression passed to the model (used for inference)
- _Artifact_: The original Document object (accessible programmatically, but not sent to the model)

This separation allows you to use readable text for the model and the original object with metadata for subsequent processing.

#code-block(`````python
from langchain_core.tools import tool

@tool(response_format="content_and_artifact")
def retrieve(query: str):
    """Search our knowledge base for related articles."""
    docs = vector_store.similarity_search(query, k=4)
    serialized = "\n\n".join(
        f"Source: {d.metadata.get('source', '?')}\n{d.page_content}"
        for d in docs
    )
    return serialized, docs
`````)

== 5.6 LangChain RAG Agent -- `create_agent` + `\@tool`

Simplest way: register the retriever as tool and call the agent when needed.

=== Multi-step search flow
RAG Agent can automatically run multiple discovery steps:
+ _Initial Search_ -- Create a query based on user questions
+ _Result evaluation_ -- Determine whether the retrieved documents are sufficient for the question
+ _Reorganize and re-search_ -- If there are not enough results, modify the query and re-search
+ _Consolidation_ -- Combine all search results to create final answer

This approach is suitable for complex research questions, but multiple LLM calls increase costs and delays.

== 5.7 LangChain RAG Chain -- `\@dynamic_prompt` Middleware

Implement RAG with a single LLM call. `@dynamic_prompt` retrieves the document before the LLM call and automatically injects it into the system prompt. Because it is a middleware method, it operates in a _single pass_ without an agent loop.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[RAG Agent],
  text(weight: "bold")[RAG Chain],
  [Number of LLM calls],
  [Multiple (agent decision)],
  [single],
  [Number of searches],
  [More than once (agent control)],
  [Exactly once (middleware control)],
  [Query Reconstruction],
  [automatic],
  [Not supported],
  [delay],
  [High (multiple round trips)],
  [Low (single pass)],
  [cost],
  [High (more tokens)],
  [Low (fewer tokens)],
  [Transparency],
  [Agent inference exposes message],
  [Context injection is implicit],
)

_Advanced usage_: You can also combine both approaches by injecting the default context with `@dynamic_prompt` while simultaneously providing a retriever tool.

#code-block(`````python
from langchain.agents.middleware import dynamic_prompt

@dynamic_prompt
def rag_prompt(request):
    """It retrieves the document and injects it into the system prompt."""
    user_msg = request.state["messages"][-1].content
    docs = vector_store.similarity_search(user_msg, k=4)
    ctx = "\n\n".join(d.page_content for d in docs)
    return f"Answer based on the following context:\n\n{ctx}"
`````)

== 5.8 LangGraph Custom RAG -- Building StateGraph

Build your own RAG agent that allows detailed control with LangGraph `StateGraph`. The key advantage of this approach is that conditional routing allows fine-grained flow control, such as evaluating the relevance of search results and rewriting queries if they are irrelevant.

=== Architecture

The custom RAG graph follows this high-level flow:

- `generate_query_or_respond` decides whether the model should search or answer directly.
- If a tool call is made, `retrieve` runs the search.
- `grade_documents` evaluates whether the retrieved documents are relevant.
- If the documents are relevant, `generate_answer` produces the final answer.
- If the documents are not relevant, `rewrite_question` rewrites the query and loops back to `generate_query_or_respond`.

#note-box[Because `rewrite_question` can loop back to `generate_query_or_respond`, it is a good idea to add a retry counter to state so the graph cannot loop forever.]

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Node],
  text(weight: "bold")[Role],
  [`generate_query_or_respond`],
  [Entry node. Decides whether to search or answer directly.],
  [`retrieve`],
  [Runs retrieval through a `ToolNode`.],
  [`grade_documents`],
  [Evaluates document relevance with structured output (`GradeDocuments`).],
  [`rewrite_question`],
  [Rewrites the query into something more specific when the results are not relevant.],
  [`generate_answer`],
  [Generates the final answer from relevant documents.],
)

#code-block(`````python

### Role of Each Node

| Node | Role |
|---|---|
| `generate_query_or_respond` | Entry node. Decides whether to search or answer directly. |
| `retrieve` | `ToolNode`runs retrieval through |
| `grade_documents` | Evaluates document relevance through structured output (`GradeDocuments`). |
| `rewrite_question` | rewrite the query when results are not relevant |
| `generate_answer` | Generates the final answer from relevant documents. |

### Preventing Infinite Loops
`rewrite_question` -> `generate_query_or_respond` because a loop can occur, `retry_count` to State. Recommended.
`````)

#code-block(`````python
from langgraph.graph import MessagesState

class AgentState(MessagesState):
    """Custom RAG agent status."""
    relevance: str  # "relevant" or "not_relevant"

print(f"AgentState keys: {list(AgentState.__annotations__)}")
`````)

== 5.9 `generate_query_or_respond` node

This is the entry node. Determines whether LLM will call retrieve tool or respond directly.

== 5.10 `grade_documents` Node -- Evaluate relevance with structured output

The `GradeDocuments` schema allows LLM to evaluate document relevance. Receive a structured response as `with_structured_output`.

#code-block(`````python
from pydantic import BaseModel, Field
from typing import Literal

class GradeDocuments(BaseModel):
    """Binary relevance score of the retrieved document."""
    relevance: Literal["relevant", "not_relevant"] = Field(
        description="Whether the document is relevant."
    )
    reasoning: str = Field(description="A brief explanation.")

grader = llm.with_structured_output(GradeDocuments)
`````)

#code-block(`````python
def grade_documents(state: AgentState):
    """
    Evaluates the relevance of the retrieved documents.
    """

    msgs = state["messages"]

    user_q = next(
        (m.content for m in msgs if m.type == "human"),
        ""
    )

    tool_content = msgs[-1].content

    grade = grader.invoke(
        f"Question: {user_q}\nDocument:\n{tool_content}\n"
        f"Are these documents relevant?"
    )

    return {
        "relevance": grade.relevance,
        "messages": msgs
    }
`````)

== 5.11 `rewrite_question` node

When retrieved documents are irrelevant, rewrite the original question to be more specific to improve search quality.

== 5.12 `generate_answer` node

Once relevant documents are identified, the search results and the original question are combined to generate the final answer.

== 5.13 Graph assembly & execution

Register all nodes in `StateGraph` and connect them with conditional edges (`tools_condition`, `relevance_router`).

#code-block(`````python
from langgraph.graph import StateGraph, START, END
from langgraph.prebuilt import ToolNode, tools_condition

def relevance_router(state: AgentState):
    if state.get("relevance") == "relevant":
        return "generate_answer"
    return "rewrite_question"

graph = StateGraph(AgentState)
graph.add_node("gen_query", generate_query_or_respond)
`````)

#code-block(`````python
graph.add_node("retrieve", ToolNode([retrieve]))
graph.add_node("grade_documents", grade_documents)
graph.add_node("rewrite_question", rewrite_question)
graph.add_node("generate_answer", generate_answer)

graph.add_edge(START, "gen_query")
graph.add_conditional_edges(
    "gen_query", tools_condition,
    {"tools": "retrieve", "__end__": END},
)
`````)

#code-block(`````python
graph.add_edge("retrieve", "grade_documents")
graph.add_conditional_edges(
    "grade_documents", relevance_router,
    {"generate_answer": "generate_answer",
     "rewrite_question": "rewrite_question"},
)
graph.add_edge("rewrite_question", "gen_query")
graph.add_edge("generate_answer", END)

app = graph.compile()
print("Graph compilation successful.")
`````)

== Summary

=== Comparison of three RAG approaches

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Characteristics],
  text(weight: "bold")[RAG Agent],
  text(weight: "bold")[RAG Chain],
  text(weight: "bold")[LangGraph Custom],
  [Number of LLM calls],
  [Multiple],
  [single],
  [Multiple],
  [Number of searches],
  [agent decision],
  [Exactly 1 time],
  [Custom],
  [Query Reconstruction],
  [automatic],
  [Not supported],
  [explicit node],
  [Relevance Assessment],
  [implicit],
  [None],
  [`GradeDocuments`],
  [control level],
  [low],
  [low],
  [High],
  [Implementation Complexity],
  [low],
  [Lowest],
  [High],
)

=== Core LangGraph patterns

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[pattern],
  text(weight: "bold")[implementation],
  [conditional routing],
  [`add_conditional_edges` + `tools_condition`],
  [structured output],
  [`llm.with_structured_output(GradeDocuments)`],
  [tool node],
  [`ToolNode([retrieve])`],
  [loop control],
  [`rewrite_question` -\\\> `gen_query` cycle],
)

=== Next Steps
→ _#link("./06_sql_agent.ipynb")[06_sql_agent.ipynb]_: Creates a SQL agent.
