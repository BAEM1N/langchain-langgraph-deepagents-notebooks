// Auto-generated from 06_multimodal_pdf_rag.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "멀티모달 PDF RAG", subtitle: "PyMuPDF4LLM + v1 content blocks")

== 학습 목표
#learning-objectives([PyMuPDF4LLM 으로 PDF 슬라이드를 _1장 = 1 Document_ 구조로 변환한다], [슬라이드 내 _이미지와 표_ 를 추출하고 RAG 검색 텍스트에 합친다], [비전 지원 LLM 에 _멀티모달 content blocks_ 로 이미지를 전달해 설명을 생성한다], [LangChain v1 의 `output_version="v1"` 직렬화 옵션을 켜서 표준 content blocks (`TextContentBlock` / `ImageContentBlock`) 로 응답을 받는다], [`create_agent()` 와 `content_and_artifact` 검색 도구로 질의응답을 구현한다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_대상 문서_],
  [Stanford CS224N 2026 Lecture 5: Attention and Transformers 공개 PDF],
  [_추출 도구_],
  [`pymupdf4llm.to_markdown(page_chunks=True, write_images=True)`],
  [_문서 단위_],
  [PDF 1페이지/슬라이드 → LangChain `Document` 1개],
  [_멀티모달 보강_],
  [추출 이미지 경로 + 슬라이드 렌더링 PNG + LLM 이미지 설명],
  [_Content blocks_],
  [`{"type":"text", ...}` + `{"type":"image_url", ...}` 의 멀티모달 메시지],
  [_응답 직렬화_],
  [`ChatOpenAI(..., output_version="v1")` — `TextContentBlock` / `ImageContentBlock` 표준 형식],
  [_RAG 구조_],
  [`OpenAIEmbeddings` → `InMemoryVectorStore` → `\@tool` → `create_agent()`],
  [_스킬_],
  [`skills/multimodal-rag/SKILL.md` — 슬라이드 기반 멀티모달 RAG 규칙],
)

#code-block(`````python
# [6-1] : 환경 설정
from dotenv import load_dotenv
import os
import pymupdf4llm

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"
`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

# output_version="v1" — 응답이 표준 content blocks 형식으로 직렬화됨
# (TextContentBlock / ImageContentBlock / ReasoningContentBlock 등)
# 환경 변수 LC_OUTPUT_VERSION="v1" 로도 동일 효과를 줄 수 있음.
model = ChatOpenAI(model="gpt-5.4", output_version="v1")
vision_model = model  # gpt-5.4 는 비전 지원
print("모델 준비 완료 — output_version=v1")
`````)

== LangChain v1 멀티모달 content blocks

`HumanMessage.content` 는 세 가지 형식을 받습니다.

+ _string_ — `"Transformer 의 self-attention 한계는?"` 처럼 단순 텍스트
+ _dict list_ — OpenAI 호환 멀티모달 형식: `[{"type":"text", ...}, {"type":"image_url", ...}]`
+ _표준 content blocks_ — `TextContentBlock`, `ImageContentBlock`, `AudioContentBlock`, `FileContentBlock` 등 LangChain 의 타입세이프 표현

비전 모델에 슬라이드 이미지를 보낼 때는 형식 2 (`multimodal_pdf_rag.describe_image_with_llm` 가 내부에서 사용) 가 가장 직관적입니다.

#code-block(`````python
message = [
    {"type": "text", "text": "이 슬라이드를 한국어로 설명하세요."},
    {"type": "image_url", "image_url": {"url": "data:image/png;base64,...."}},
]
response = vision_model.invoke([{"role": "user", "content": message}])
`````)

응답을 받을 때 `output_version="v1"` 을 켜 두면 `response.content` 가 자동으로 표준 content blocks 로 직렬화되어, 외부 시스템이 `TextContentBlock` / `ImageContentBlock` 을 타입세이프하게 소비할 수 있습니다 (`docs/langchain/05-messages.md`).

== 1) 공개 PDF 다운로드

이 예제는 Stanford CS224N의 공개 PDF 슬라이드를 사용합니다. 원본 PDF와 생성 이미지는 저장소에 커밋하지 않고 `07_examples/.cache/` 아래 런타임 캐시에 둡니다.

#code-block(`````python
import sys
from pathlib import Path

root = Path.cwd()
if (root / "07_examples").exists():
    sys.path.append(str(root / "07_examples"))
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
print(f"대상 슬라이드(0-based): {selected_pages}")
`````)

== 2) PDF 파일 메타데이터 추출

PDF 자체의 제목, 작성자, 생성일, 페이지 수, 파일 크기, 페이지 크기 같은 메타데이터를 먼저 추출합니다. 이 값은 전체 코퍼스의 출처 추적과 필터링 조건으로 사용할 수 있습니다.

#code-block(`````python
pdf_metadata = extract_pdf_metadata(pdf_path, source_url=DEFAULT_SOURCE_URL)
print(format_pdf_metadata(pdf_metadata))
print(metadata_as_json({"pages_sample": pdf_metadata["pages"][:2]}))
`````)

== 3) 슬라이드 단위 Document 생성

`page_chunks=True`로 페이지별 Markdown을 받고, `write_images=True`로 슬라이드 안의 그림 영역을 PNG로 저장합니다. 동시에 PyMuPDF로 각 슬라이드 전체를 대표 이미지로 렌더링합니다.

#note-box[전체 70장을 처리하려면 `pages=None`으로 바꾸면 됩니다. 노트북 기본값은 실행 시간과 비용을 줄이기 위해 핵심 슬라이드만 선택합니다.]

#code-block(`````python
documents = extract_slide_documents(
    pdf_path,
    source_url=DEFAULT_SOURCE_URL,
    pages=selected_pages,
)
print(f"생성된 Document 수: {len(documents)}")
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

== 4) 슬라이드별 메타데이터와 표/이미지 확인

PyMuPDF4LLM은 표를 GitHub Flavored Markdown 형태로 본문에 넣습니다. 헬퍼 모듈은 Markdown 표 블록을 다시 분리해 `metadata["table_count"]`와 `## Extracted tables` 섹션에 보존합니다.

#code-block(`````python
table_docs = [doc for doc in documents if doc.metadata["table_count"] > 0]
print(f"표가 감지된 슬라이드: {[d.metadata['slide'] for d in table_docs]}")
if table_docs:
    print(table_docs[0].page_content[:1200])
`````)

== 5) LLM 기반 이미지 설명 생성

이미지 자체는 벡터 검색에 바로 들어가기 어렵습니다. 따라서 슬라이드 대표 이미지와 일부 추출 이미지를 비전 지원 LLM으로 설명하게 한 뒤, 그 설명을 Document 본문에 합칩니다.

#code-block(`````python
caption_limit = len(documents) + 4

documents = add_llm_image_descriptions(
    documents, vision_model,
    max_descriptions=caption_limit,
)
print(documents[0].metadata["image_descriptions"][0][:700])
`````)

=== v1 응답의 표준 content blocks 확인

`output_version="v1"` 을 켜 두면 비전 모델의 응답 메시지에서 `.content_blocks` 프로퍼티로 `TextContentBlock` 들을 꺼낼 수 있습니다. 이 표현은 provider 별 차이를 흡수하므로 후속 파이프라인(예: 캡션 캐싱, UI 렌더링) 이 안전하게 소비할 수 있습니다.

#code-block(`````python
from multimodal_pdf_rag import _image_to_data_url  # 데모용 헬퍼

sample_image = documents[0].metadata["slide_image_path"]
vision_msg = [
    {"type": "text", "text": "이 슬라이드의 핵심 메시지를 한 문장으로 요약하세요."},
    {"type": "image_url", "image_url": {"url": _image_to_data_url(sample_image)}},
]
resp = vision_model.invoke([{"role": "user", "content": vision_msg}])

# v1: .content_blocks 는 표준 content block 리스트 (TextContentBlock 등)
blocks = getattr(resp, "content_blocks", None)
print("block 개수:", len(blocks) if blocks else "n/a")
if blocks:
    for b in blocks:
        print(f"  type={b.get('type'):>15}  | preview={str(b)[:120]}")
print()
print("응답 미리보기:", str(resp.content)[:300])
`````)

== 6) 벡터 인덱스와 검색 도구 구성

LangChain v1 구조에 맞춰 `InMemoryVectorStore`를 만들고, `@tool(response_format="content_and_artifact")`로 검색 본문과 원본 Document artifact를 함께 반환합니다.

#code-block(`````python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = build_vectorstore(documents, embeddings)
search_slides = make_slide_search_tool(vectorstore, k=4)
print("벡터 인덱스와 검색 도구 준비 완료")
`````)

#code-block(`````python
query = "self-attention을 Transformer 블록으로 쓰려면 어떤 문제가 있나요?"
hits = vectorstore.similarity_search(query, k=3)
print(format_sources(hits))
print(hits[0].page_content[:1400])
`````)

== 7) LangChain v1 `create_agent()`로 질의응답

검색을 도구로 노출하면 에이전트가 질문에 맞춰 슬라이드를 검색하고, 텍스트·표·이미지 설명을 함께 근거로 답변합니다.

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

== 정리

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_슬라이드 단위 문서화_],
  [`page_chunks=True` 로 PDF 1페이지를 `Document` 1개로 구성],
  [_이미지 처리_],
  [`write_images=True` 추출 이미지 + PyMuPDF 슬라이드 렌더링 + LLM 설명],
  [_메타데이터 처리_],
  [PDF 파일 메타데이터 + 슬라이드별 표/이미지/레이아웃 메타데이터 추출],
  [_표 처리_],
  [Markdown 표 블록을 분리해 본문과 메타데이터에 보존],
  [_멀티모달 메시지_],
  [`{"type":"text", ...}` + `{"type":"image_url", ...}` content blocks 로 비전 모델 호출],
  [_v1 직렬화_],
  [`ChatOpenAI(..., output_version="v1")` → `.content_blocks` 로 `TextContentBlock` 접근],
  [_LangChain v1 구조_],
  [`InMemoryVectorStore` + `\@tool(content_and_artifact)` + `create_agent()`],
  [_확장 포인트_],
  [`pages=None` 으로 전체 PDF 처리, Chroma/FAISS 로 영속화, 캡션 캐시 추가],
)


#references-box[
- `docs/langchain/05-messages.md` — content blocks · `output_version="v1"`
- `docs/langchain/24-retrieval.md` — RAG 5 building blocks
- `07_examples/skills/multimodal-rag/SKILL.md`
- #link("https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/index.html")[PyMuPDF4LLM 공식 문서]
- #link("https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/api.html")[PyMuPDF4LLM API: `to_markdown`]
- #link("https://docs.langchain.com/oss/python/integrations/providers/pymupdf4llm/")[LangChain PyMuPDF4LLM integration]
- #link("https://web.stanford.edu/class/cs224n/slides_w26/cs224n-2026-lecture05-transformers.pdf")[Stanford CS224N 2026 Lecture 5 PDF]
_다음 단계:_ → #link("../08_integration/04_document_loaders/")[08_integration/04_document_loaders]에서 PDF·웹·구조화 문서 로더를 비교합니다.
]
#chapter-end()
