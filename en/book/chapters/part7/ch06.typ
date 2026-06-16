// Auto-generated from 06_multimodal_pdf_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "Multimodal PDF RAG", subtitle: "PyMuPDF4LLM + v1 Content Blocks")

== Learning Objectives

- Convert PDF slides into a _one slide = one Document_ structure with PyMuPDF4LLM
- Extract _images and tables_ from each slide and merge them into RAG search text
- Send slide images to a vision-capable LLM through _multimodal content blocks_
- Enable LangChain v1 `output_version="v1"` serialization and inspect standard content blocks (`TextContentBlock` / `ImageContentBlock`)
- Implement question answering with `create_agent()` and a `content_and_artifact` retrieval tool


== Overview

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Details],
  [_Target document_],
  [Public Stanford CS224N 2026 Lecture 5: Attention and Transformers PDF],
  [_Extraction tool_],
  [`pymupdf4llm.to_markdown(page_chunks=True, write_images=True)`],
  [_Document unit_],
  [One PDF page/slide → one LangChain `Document`],
  [_Multimodal enrichment_],
  [Extracted image paths + rendered slide PNG + LLM-generated image descriptions],
  [_Content blocks_],
  [Multimodal messages with `{"type":"text", ...}` + `{"type":"image_url", ...}`],
  [_Response serialization_],
  [`ChatOpenAI(..., output_version="v1")` — standard `TextContentBlock` / `ImageContentBlock` format],
  [_RAG structure_],
  [`OpenAIEmbeddings` → `InMemoryVectorStore` → `\@tool` → `create_agent()`],
  [_Skill_],
  [`skills/multimodal-rag/SKILL.md` — slide-based multimodal RAG rules],
)


#code-block(`````python
# [6-1] : Environment setup
from dotenv import load_dotenv
import os
import pymupdf4llm

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "Set OPENAI_API_KEY in .env"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

# output_version="v1" serializes responses as standard content blocks
# (TextContentBlock / ImageContentBlock / ReasoningContentBlock, and more).
# Setting LC_OUTPUT_VERSION="v1" in the environment has the same effect.
model = ChatOpenAI(model="gpt-5.4", output_version="v1")
vision_model = model  # gpt-5.4 supports vision inputs
print("Model ready — output_version=v1")

`````)

== LangChain v1 Multimodal Content Blocks

`HumanMessage.content` accepts three practical forms.

+ _string_ — simple text such as `"What limitation does self-attention have in Transformers?"`
+ _dict list_ — OpenAI-compatible multimodal content such as `[{"type":"text", ...}, {"type":"image_url", ...}]`
+ _standard content blocks_ — LangChain's type-safe representations such as `TextContentBlock`, `ImageContentBlock`, `AudioContentBlock`, and `FileContentBlock`

When sending slide images to a vision model, form 2 is the most direct. The helper `multimodal_pdf_rag.describe_image_with_llm` uses it internally.

#code-block(`````python
message = [
    {"type": "text", "text": "Explain this slide in English."},
    {"type": "image_url", "image_url": {"url": "data:image/png;base64,...."}},
]
response = vision_model.invoke([{"role": "user", "content": message}])
`````)

With `output_version="v1"`, `response.content` is serialized into standard content blocks so downstream systems can consume `TextContentBlock` / `ImageContentBlock` safely across providers (`docs/langchain/05-messages.md`).


== 1) Download the Public PDF

This example uses public Stanford CS224N lecture slides. The source PDF and generated images are runtime cache artifacts under `en/07_examples/.cache/`; they are not committed to the repository.


#code-block(`````python
import sys
from pathlib import Path

root = Path.cwd()
candidates = [root, root / "en" / "07_examples", root.parent / "en" / "07_examples"]
for candidate in candidates:
    if (candidate / "multimodal_pdf_rag.py").exists():
        sys.path.insert(0, str(candidate))
        break

`````)

#code-block(`````python
from multimodal_pdf_rag import (
    DEFAULT_PAGES, DEFAULT_SOURCE_URL, add_llm_image_descriptions,
    build_vectorstore, download_pdf, extract_pdf_metadata,
    extract_slide_documents, extract_slide_metadata, format_pdf_metadata,
    format_slide_metadata, format_sources, make_slide_search_tool,
    metadata_as_json,
)

`````)

#code-block(`````python
pdf_path = download_pdf(DEFAULT_SOURCE_URL)
selected_pages = DEFAULT_PAGES
if os.environ.get("FAST_MULTIMODAL_RAG_TEST"):
    selected_pages = [19, 51, 58]
print(f"PDF: {pdf_path}")
print(f"Target slides (0-based): {selected_pages}")

`````)

== 2) Extract PDF File Metadata

Start by extracting PDF-level metadata such as title, author, creation date, page count, file size, and page dimensions. These fields are useful for corpus provenance and future filtering rules.


#code-block(`````python
pdf_metadata = extract_pdf_metadata(pdf_path, source_url=DEFAULT_SOURCE_URL)
print(format_pdf_metadata(pdf_metadata))
print(metadata_as_json({"pages_sample": pdf_metadata["pages"][:2]}))

`````)

== 3) Create Slide-Level Documents

`page_chunks=True` returns page-level Markdown, while `write_images=True` saves image regions from each slide as PNG files. At the same time, PyMuPDF renders each whole slide as a representative image.

#note-box[To process all 70 slides, set `pages=None`. The notebook defaults to a focused slide subset to reduce runtime and API cost.]


#code-block(`````python
documents = extract_slide_documents(
    pdf_path,
    source_url=DEFAULT_SOURCE_URL,
    pages=selected_pages,
)
print(f"Documents created: {len(documents)}")
print(format_sources(documents))

`````)

#code-block(`````python
slide_metadata = extract_slide_metadata(documents)
print(format_slide_metadata(slide_metadata))
print(metadata_as_json(slide_metadata[:2]))

`````)

#code-block(`````python
from IPython.display import Image, display

sample_doc = documents[0]
display(Image(filename=sample_doc.metadata["slide_image_path"], width=480))
print(sample_doc.metadata["extracted_image_paths"][:2])

`````)

== 4) Inspect Slide Metadata, Tables, and Images

PyMuPDF4LLM inserts tables into the page body as GitHub Flavored Markdown. The helper module separates Markdown table blocks again and preserves them in both `metadata["table_count"]` and a `## Extracted tables` section.


#code-block(`````python
table_docs = [doc for doc in documents if doc.metadata["table_count"] > 0]
print(f"Slides with detected tables: {[d.metadata['slide'] for d in table_docs]}")
if table_docs:
    print(table_docs[0].page_content[:1200])

`````)

== 5) Generate LLM-Based Image Descriptions

Raw images are difficult to embed directly in a text vector index. Instead, we ask a vision-capable LLM to describe each rendered slide image and selected extracted images, then merge those descriptions back into the `Document` body.


#code-block(`````python
caption_limit = len(documents) + 4

documents = add_llm_image_descriptions(
    documents, vision_model,
    max_descriptions=caption_limit,
)
print(documents[0].metadata["image_descriptions"][0][:700])

`````)

=== Inspect Standard Content Blocks from v1 Responses

With `output_version="v1"`, the vision model response exposes `.content_blocks`, a provider-normalized list of `TextContentBlock` items. This representation is safer for downstream pipelines such as caption caching or UI rendering.


#code-block(`````python
from multimodal_pdf_rag import _image_to_data_url  # demo helper

sample_image = documents[0].metadata["slide_image_path"]
vision_msg = [
    {"type": "text", "text": "Summarize the main message of this slide in one sentence."},
    {"type": "image_url", "image_url": {"url": _image_to_data_url(sample_image)}},
]
resp = vision_model.invoke([{"role": "user", "content": vision_msg}])

# v1: .content_blocks is a list of standard content blocks such as TextContentBlock
blocks = getattr(resp, "content_blocks", None)
print("block count:", len(blocks) if blocks else "n/a")
if blocks:
    for b in blocks:
        print(f"  type={b.get('type'):>15}  | preview={str(b)[:120]}")
print()
print("Response preview:", str(resp.content)[:300])

`````)

== 6) Build a Vector Index and Retrieval Tool

Following the LangChain v1 structure, we create an `InMemoryVectorStore` and expose retrieval through `@tool(response_format="content_and_artifact")`, which returns both answer text and the original `Document` artifacts.


#code-block(`````python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = build_vectorstore(documents, embeddings)
search_slides = make_slide_search_tool(vectorstore, k=4)
print("Vector index and search tool ready")

`````)

#code-block(`````python
query = "What problem appears when using self-attention as a Transformer block?"
hits = vectorstore.similarity_search(query, k=3)
print(format_sources(hits))
print(hits[0].page_content[:1400])

`````)

== 7) Answer Questions with LangChain v1 `create_agent()`

Once retrieval is exposed as a tool, the agent can search slides for the question and answer with evidence from text, tables, and image descriptions.


#code-block(`````python
from langchain.agents import create_agent
from langchain.agents.middleware import ModelCallLimitMiddleware
from langgraph.checkpoint.memory import InMemorySaver
from prompts import MULTIMODAL_RAG_AGENT_PROMPT

`````)

#code-block(`````python
rag_agent = create_agent(
    model=model,
    tools=[search_slides],
    system_prompt=MULTIMODAL_RAG_AGENT_PROMPT,
    middleware=[ModelCallLimitMiddleware(run_limit=6)],
    checkpointer=InMemorySaver(),
)

`````)

== Summary

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Item],
  text(weight: "bold")[Key Point],
  [_Slide-level documents_],
  [`page_chunks=True` turns each PDF page into one `Document`],
  [_Image handling_],
  [`write_images=True` extracted images + PyMuPDF slide renderings + LLM descriptions],
  [_Metadata handling_],
  [Extract PDF-level metadata plus slide-level table/image/layout metadata],
  [_Table handling_],
  [Separate Markdown table blocks and preserve them in content and metadata],
  [_Multimodal messages_],
  [Call the vision model with `{"type":"text", ...}` + `{"type":"image_url", ...}` content blocks],
  [_v1 serialization_],
  [`ChatOpenAI(..., output_version="v1")` → access `TextContentBlock` through `.content_blocks`],
  [_LangChain v1 structure_],
  [`InMemoryVectorStore` + `\@tool(content_and_artifact)` + `create_agent()`],
  [_Extension points_],
  [Process the full PDF with `pages=None`, persist in Chroma/FAISS, and add a caption cache],
)

#line(length: 100%, stroke: 0.5pt + luma(200))

_References:_
- `docs/langchain/05-messages.md` — content blocks and `output_version="v1"`
- `docs/langchain/24-retrieval.md` — the five building blocks of RAG
- `07_examples/skills/multimodal-rag/SKILL.md`
- #link("https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/index.html")[PyMuPDF4LLM documentation]
- #link("https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/api.html")[PyMuPDF4LLM to_markdown API]
- #link("https://docs.langchain.com/oss/python/integrations/providers/pymupdf4llm/")[LangChain PyMuPDF4LLM integration]
- #link("https://web.stanford.edu/class/cs224n/slides_w26/cs224n-2026-lecture05-transformers.pdf")[Stanford CS224N 2026 Lecture 5 PDF]

_Next step:_ → #link("../08_integration/04_document_loaders/")[08_integration/04_document_loaders] compares PDF, web, and structured document loaders.
