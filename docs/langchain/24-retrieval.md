# Retrieval-Augmented Generation (RAG) Documentation

## Overview

The documentation explains how LLMs face two key constraints: "Finite context" preventing them from processing entire corpora simultaneously, and "Static knowledge" where training data becomes outdated. Retrieval solves these limitations by fetching relevant external information at query time.

## Core Concept

**Retrieval-Augmented Generation (RAG)** enhances LLM responses by integrating context-specific information during generation. Rather than relying solely on training data, RAG systems dynamically incorporate external knowledge sources.

## Building a Knowledge Base

A knowledge base serves as a repository of documents or structured data. LangChain offers document loaders and vector stores for creating custom knowledge bases. However, existing systems like SQL databases or CRM platforms can be integrated directly as agent tools or as context sources without rebuilding.

## Key Building Blocks

The documentation identifies five essential components:

1. **Document loaders** ingest data from external sources (Google Drive, Slack, Notion) as standardized Document objects
2. **Text splitters** break large documents into retrievable chunks fitting within context windows
3. **Embedding models** convert text into numerical vectors where semantically similar content clusters together
4. **Vector stores** are specialized databases for storing and searching embeddings
5. **Retrievers** return relevant documents based on unstructured queries

## RAG Architectures

The documentation presents three implementation approaches:

### 2-Step RAG
Retrieval always precedes generation in a straightforward, predictable workflow. This suits FAQs and documentation bots requiring "fast" latency with "high" control but "low" flexibility.

### Agentic RAG
An LLM-powered agent independently decides when and how to retrieve information during reasoning. This approach offers "high" flexibility and "variable" latency, ideal for research assistants accessing multiple tools.

### Hybrid RAG
Combines both approaches with validation steps including query enhancement, retrieval validation, and answer quality checks. It supports iterative refinement between retrieval and generation stages.

## Code Example: Agentic RAG

The documentation provides an extended example implementing Agentic RAG for documentation queries, featuring a `fetch_documentation` tool that retrieves and converts web content while enforcing domain whitelisting and system prompts guiding agent behavior.
