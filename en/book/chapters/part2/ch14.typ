// Auto-generated from 14_semantic_search.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(14, "Semantic Search", subtitle: "Build retrieval before RAG")

In this chapter you build the retrieval layer as a testable system in its own right. The goal is to understand documents, chunks, embeddings, vector stores, and retrieval evaluation before adding a generative model.

_Learning goals_
- Explain why semantic search is the foundation of most RAG applications.
- Turn source documents into chunks and searchable vectors.
- Evaluate retrieval quality before introducing an answer generator.


== 14.1 Environment setup

Start with a small, deterministic setup. The notebook avoids external services so you can focus on the retrieval contract rather than API behavior.


#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv(override=True)
`````)

#code-block(`````python
from langchain_core.documents import Document
from langchain_core.embeddings import DeterministicFakeEmbedding
from langchain_core.vectorstores import InMemoryVectorStore
from langchain_text_splitters import RecursiveCharacterTextSplitter
`````)

== 14.2 Build a small document collection

A retrieval system is only as clear as the corpus it searches. We begin with a tiny document set so every search result can be inspected by eye.


#code-block(`````python
raw_docs = [
    Document(page_content="LangChain agents combine models, tools, and middleware.", metadata={"source": "langchain"}),
    Document(page_content="LangGraph persists state with checkpointers and stores.", metadata={"source": "langgraph"}),
    Document(page_content="Deep Agents include planning, files, subagents, and skills.", metadata={"source": "deepagents"}),
]
len(raw_docs)
`````)

== 14.3 Split into chunks

Chunking determines what the retriever can actually return. Here you compare compact text units instead of treating whole documents as one undifferentiated blob.


#code-block(`````python
splitter = RecursiveCharacterTextSplitter(chunk_size=60, chunk_overlap=10)
chunks = splitter.split_documents(raw_docs)

[(doc.metadata["source"], doc.page_content) for doc in chunks]
`````)

== 14.4 Embeddings and vector store

Embeddings convert text into a similarity space. The vector store then gives us a simple interface for ranking chunks by semantic closeness.


#code-block(`````python
embedding = DeterministicFakeEmbedding(size=64)
vectorstore = InMemoryVectorStore(embedding=embedding)
vectorstore.add_documents(chunks)

retriever = vectorstore.as_retriever(search_kwargs={"k": 2})
`````)

== 14.5 Run retrieval

Retrieval should be observable before it becomes part of a larger RAG chain. Inspect the returned chunks and scores as the system’s first quality signal.


#code-block(`````python
query = "Which framework uses checkpointers?"
results = retriever.invoke(query)

for idx, doc in enumerate(results, 1):
    print(idx, doc.metadata["source"], "=>", doc.page_content)
`````)

== 14.6 Mini retrieval evaluation

A small evaluation table is enough to catch many retrieval mistakes. The point is to define expected evidence before asking a model to write an answer.


#code-block(`````python
test_cases = [
    ("state checkpoint memory", "langgraph"),
    ("agent middleware tools", "langchain"),
    ("skills and subagents", "deepagents"),
]

for question, expected in test_cases:
    hits = retriever.invoke(question)
    sources = [doc.metadata["source"] for doc in hits]
    print(question, "=>", sources, "PASS", expected in sources)
`````)

== 14.7 Checklist before RAG

Before adding generation, check the retrieval layer for coverage, chunk quality, and debuggability. A weak retriever usually produces a weak RAG system.


#line(length: 100%, stroke: 0.5pt + luma(200))

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Content],
  [_Covered_],
  [semantic search, chunking, embeddings, vector stores, retrievers, and retrieval-only evaluation],
  [_Core idea_],
  [Start from a small deterministic contract before adding model calls or external services.],
  [_Next step_],
  [Follow the linked course notebooks and official reference notes listed in this chapter.],
)

== Reference docs

- #link("../../docs/langchain/retrieval.md")[`retrieval.md`]
- #link("../../docs/langchain/rag.md")[`rag.md`]
- #link("../../docs/langchain/knowledge-base.md")[`knowledge-base.md`]
