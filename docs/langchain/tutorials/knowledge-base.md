# Build a Semantic Search Engine

This tutorial covers building a semantic search engine using LangChain's document processing and vector store abstractions. You will learn how to load documents, split them into chunks, generate embeddings, store them in a vector store, and perform semantic search queries.

## Overview

A semantic search engine goes beyond keyword matching by understanding the meaning of queries and documents. The pipeline consists of four stages:

1. **Document Loading** -- Ingest documents from various sources
2. **Text Splitting** -- Break documents into manageable chunks
3. **Embedding** -- Convert text chunks into vector representations
4. **Vector Storage and Retrieval** -- Store vectors and query them by similarity

## Prerequisites

```bash
pip install langchain langchain-openai langchain-community pypdf chromadb faiss-cpu
```

```bash
export OPENAI_API_KEY="your-openai-key"
```

## Document Loaders

Document loaders read raw content from various sources and return `Document` objects with `page_content` and `metadata` fields.

### PyPDFLoader

Load PDF files with page-level granularity.

```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("path/to/document.pdf")
pages = loader.load()

# Each page is a Document with metadata including page number
for page in pages:
    print(f"Page {page.metadata['page']}: {page.page_content[:100]}...")
```

### Other Loaders

| Loader | Source | Install |
|--------|--------|---------|
| `PyPDFLoader` | PDF files | `pypdf` |
| `TextLoader` | Plain text files | Built-in |
| `CSVLoader` | CSV files | Built-in |
| `DirectoryLoader` | Directories of files | Built-in |
| `WebBaseLoader` | Web pages | `beautifulsoup4` |
| `UnstructuredLoader` | Multiple formats | `unstructured` |
| `NotionDBLoader` | Notion databases | `notion-client` |

## Text Splitters

Text splitters break large documents into smaller chunks suitable for embedding and retrieval. Chunk size and overlap are the two critical parameters.

### RecursiveCharacterTextSplitter

The recommended default splitter. It recursively splits on a hierarchy of separators (`\n\n`, `\n`, ` `, `""`) to keep semantically related text together.

```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    length_function=len,
    add_start_index=True,
)

documents = text_splitter.split_documents(pages)
print(f"Split {len(pages)} pages into {len(documents)} chunks")
```

### Choosing Chunk Size and Overlap

| Parameter | Description | Guidance |
|-----------|-------------|----------|
| `chunk_size` | Maximum number of characters per chunk | 500--2000 for most use cases. Smaller chunks yield more precise retrieval; larger chunks preserve more context. |
| `chunk_overlap` | Number of characters shared between adjacent chunks | Typically 10--20% of `chunk_size`. Prevents information loss at chunk boundaries. |

### Other Splitters

| Splitter | Best For |
|----------|----------|
| `RecursiveCharacterTextSplitter` | General-purpose text |
| `MarkdownHeaderTextSplitter` | Markdown documents |
| `HTMLHeaderTextSplitter` | HTML documents |
| `TokenTextSplitter` | Token-budget-aware splitting |
| `CodeTextSplitter` | Source code (language-aware) |

## Embeddings

Embedding models convert text into dense vector representations that capture semantic meaning. Similar texts produce vectors that are close together in the embedding space.

### OpenAI Embeddings

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
```

### Available Embedding Models

| Provider | Model | Dimensions | Notes |
|----------|-------|------------|-------|
| OpenAI | `text-embedding-3-large` | 3072 | Highest quality OpenAI embedding |
| OpenAI | `text-embedding-3-small` | 1536 | Good balance of quality and cost |
| Cohere | `embed-english-v3.0` | 1024 | Strong multilingual support |
| HuggingFace | Various | Varies | Open-source, self-hosted |
| Google | `text-embedding-004` | 768 | Vertex AI |

### Generating Embeddings Directly

```python
# Embed a single query
query_vector = embeddings.embed_query("What is machine learning?")

# Embed multiple documents
doc_vectors = embeddings.embed_documents([
    "Machine learning is a subset of AI.",
    "Deep learning uses neural networks.",
])
```

## Vector Stores

Vector stores index and search document embeddings. LangChain provides a unified interface across many backends.

### InMemoryVectorStore

Suitable for development, testing, and small datasets.

```python
from langchain_core.vectorstores import InMemoryVectorStore

vector_store = InMemoryVectorStore.from_documents(
    documents=documents,
    embedding=embeddings,
)
```

### Chroma

Open-source embedding database with persistence support.

```python
from langchain_chroma import Chroma

vector_store = Chroma.from_documents(
    documents=documents,
    embedding=embeddings,
    persist_directory="./chroma_db",
)
```

### FAISS

Facebook AI Similarity Search, optimized for fast nearest-neighbor lookups.

```python
from langchain_community.vectorstores import FAISS

vector_store = FAISS.from_documents(
    documents=documents,
    embedding=embeddings,
)

# Save and load from disk
vector_store.save_local("faiss_index")
vector_store = FAISS.load_local("faiss_index", embeddings)
```

### Other Vector Stores

| Vector Store | Type | Best For |
|--------------|------|----------|
| `InMemoryVectorStore` | In-process | Development, small datasets |
| `Chroma` | Embedded / Client-server | Prototyping, medium datasets |
| `FAISS` | In-process | High-performance local search |
| `Pinecone` | Managed cloud | Production, scalable |
| `PGVector` | PostgreSQL extension | Existing PostgreSQL infrastructure |
| `Weaviate` | Cloud / Self-hosted | Hybrid search (vector + keyword) |
| `Qdrant` | Cloud / Self-hosted | Filtering and payload support |
| `Milvus` | Cloud / Self-hosted | Large-scale vector search |

## Querying the Vector Store

### Similarity Search

Return the most semantically similar documents to a query.

```python
results = vector_store.similarity_search(
    query="How does photosynthesis work?",
    k=4,
)

for doc in results:
    print(f"Content: {doc.page_content[:200]}")
    print(f"Metadata: {doc.metadata}")
    print("---")
```

### Similarity Search with Scores

Return documents along with their similarity scores.

```python
results_with_scores = vector_store.similarity_search_with_score(
    query="How does photosynthesis work?",
    k=4,
)

for doc, score in results_with_scores:
    print(f"Score: {score:.4f}")
    print(f"Content: {doc.page_content[:200]}")
    print("---")
```

## Using as a Retriever

Convert the vector store into a LangChain `Retriever` for use in chains and agents.

```python
retriever = vector_store.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 6},
)

docs = retriever.invoke("What is photosynthesis?")
```

### Search Types

| Search Type | Description | Parameters |
|-------------|-------------|------------|
| `"similarity"` | Standard nearest-neighbor search | `k`: number of results |
| `"mmr"` | Maximal Marginal Relevance -- balances relevance with diversity to reduce redundancy | `k`, `fetch_k`, `lambda_mult` |
| `"similarity_score_threshold"` | Only return documents above a minimum similarity score | `k`, `score_threshold` |

### MMR (Maximal Marginal Relevance)

MMR reduces redundancy by penalizing documents that are similar to already-selected results.

```python
retriever = vector_store.as_retriever(
    search_type="mmr",
    search_kwargs={
        "k": 6,
        "fetch_k": 20,       # Fetch 20 candidates, return top 6 diverse
        "lambda_mult": 0.5,  # 0 = max diversity, 1 = max relevance
    },
)
```

### Score Threshold

Only return documents that meet a minimum similarity threshold.

```python
retriever = vector_store.as_retriever(
    search_type="similarity_score_threshold",
    search_kwargs={
        "k": 6,
        "score_threshold": 0.8,
    },
)
```

## Full Example

```python
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_chroma import Chroma

# 1. Load documents
loader = PyPDFLoader("research_paper.pdf")
pages = loader.load()

# 2. Split into chunks
splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
)
chunks = splitter.split_documents(pages)

# 3. Create embeddings and store
embeddings = OpenAIEmbeddings(model="text-embedding-3-large")
vector_store = Chroma.from_documents(
    documents=chunks,
    embedding=embeddings,
    persist_directory="./search_index",
)

# 4. Query
results = vector_store.similarity_search("key findings", k=5)
for doc in results:
    print(doc.page_content)

# 5. Use as retriever
retriever = vector_store.as_retriever(
    search_type="mmr",
    search_kwargs={"k": 4, "fetch_k": 10},
)
docs = retriever.invoke("What methodology was used?")
```
