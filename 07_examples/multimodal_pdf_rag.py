"""PyMuPDF4LLM 기반 슬라이드 단위 멀티모달 RAG 유틸리티.

Stanford CS224N 공개 PDF 슬라이드를 예제로 사용하되, 같은 구조의
강의 PDF/PPTX-export PDF에도 그대로 적용할 수 있도록 함수 단위로 나눴다.
"""

from __future__ import annotations

import base64
import json
import mimetypes
import re
import shutil
from pathlib import Path
from typing import Iterable
from urllib.request import Request, urlopen

import pymupdf
import pymupdf4llm
from langchain_core.documents import Document
from langchain_core.tools import tool


DEFAULT_SOURCE_URL = (
    "https://web.stanford.edu/class/cs224n/slides_w26/"
    "cs224n-2026-lecture05-transformers.pdf"
)
DEFAULT_WORK_DIR = Path(__file__).resolve().parent / ".cache" / "06_multimodal_pdf_rag"
DEFAULT_PAGES = [0, 1, 19, 21, 23, 39, 42, 51, 52, 56, 58, 62, 64, 66]
IMAGE_REF_RE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
TABLE_SEPARATOR_RE = re.compile(
    r"^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$"
)


def download_pdf(url: str = DEFAULT_SOURCE_URL, work_dir: Path | str = DEFAULT_WORK_DIR) -> Path:
    """공개 PDF를 캐시에 내려받고 PDF 헤더를 검증한다."""

    work_dir = Path(work_dir)
    work_dir.mkdir(parents=True, exist_ok=True)
    pdf_path = work_dir / Path(url).name
    if pdf_path.exists() and pdf_path.read_bytes()[:4] == b"%PDF":
        return pdf_path
    request = Request(url, headers={"User-Agent": "agent-notebooks/1.0"})
    with urlopen(request, timeout=60) as response:
        data = response.read()
    if data[:4] != b"%PDF":
        raise ValueError(f"다운로드 결과가 PDF가 아닙니다: {url}")
    pdf_path.write_bytes(data)
    return pdf_path


def extract_pdf_metadata(
    pdf_path: Path | str,
    *,
    source_url: str | None = DEFAULT_SOURCE_URL,
) -> dict:
    """PDF 파일 수준 메타데이터를 JSON 직렬화 가능한 dict로 추출한다."""

    pdf_path = Path(pdf_path)
    with pymupdf.open(str(pdf_path)) as pdf:
        pages = [_page_metadata(page, index) for index, page in enumerate(pdf)]
        metadata = dict(pdf.metadata or {})
        toc = pdf.get_toc(simple=True)
    metadata.update(
        {
            "source_url": source_url,
            "file_name": pdf_path.name,
            "file_size_bytes": pdf_path.stat().st_size,
            "page_count": len(pages),
            "toc_count": len(toc),
            "pages": pages,
        }
    )
    return _json_safe(metadata)


def _page_metadata(page, index: int) -> dict:
    rect = page.rect
    return {
        "page_index": index,
        "slide": index + 1,
        "width": round(rect.width, 2),
        "height": round(rect.height, 2),
        "rotation": page.rotation,
    }


def format_pdf_metadata(metadata: dict) -> str:
    """PDF 파일 수준 메타데이터를 Markdown 표로 만든다."""

    fields = ["file_name", "title", "author", "producer", "creationDate", "page_count", "toc_count"]
    rows = ["| key | value |", "|---|---|"]
    for field in fields:
        rows.append(f"| {field} | {str(metadata.get(field, ''))[:120]} |")
    return "\n".join(rows)


def extract_slide_metadata(documents: list[Document]) -> list[dict]:
    """LangChain Document 목록에서 슬라이드별 검색 메타데이터만 추출한다."""

    rows = []
    for doc in documents:
        meta = doc.metadata
        rows.append(
            {
                "slide": meta.get("slide"),
                "title": meta.get("first_heading", ""),
                "tables": meta.get("table_count", 0),
                "pictures": meta.get("picture_count", 0),
                "images": meta.get("extracted_image_count", 0),
                "layout_classes": ", ".join(meta.get("layout_classes", [])),
                "markdown_chars": meta.get("markdown_chars", 0),
            }
        )
    return rows


def format_slide_metadata(rows: list[dict]) -> str:
    """슬라이드별 메타데이터를 Markdown 표로 만든다."""

    header = "| slide | tables | pictures | images | chars | title |"
    lines = [header, "|---:|---:|---:|---:|---:|---|"]
    for row in rows:
        title = str(row.get("title", "")).replace("|", "\\|")[:80]
        lines.append(
            f"| {row['slide']} | {row['tables']} | {row['pictures']} | "
            f"{row['images']} | {row['markdown_chars']} | {title} |"
        )
    return "\n".join(lines)


def metadata_as_json(metadata: dict | list[dict], *, max_chars: int = 3000) -> str:
    """노트북 출력용으로 메타데이터를 보기 좋은 JSON 문자열로 변환한다."""

    text = json.dumps(_json_safe(metadata), ensure_ascii=False, indent=2)
    return text if len(text) <= max_chars else text[:max_chars] + "\n..."


def _json_safe(value):
    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}
    if isinstance(value, list | tuple):
        return [_json_safe(v) for v in value]
    if isinstance(value, Path):
        return str(value)
    return value


def _reset_dir(path: Path) -> Path:
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)
    return path


def _normalize_pages(pages: Iterable[int] | None, page_count: int) -> list[int]:
    selected = range(page_count) if pages is None else pages
    return sorted({p for p in selected if 0 <= int(p) < page_count})


def extract_markdown_tables(markdown: str) -> list[str]:
    """PyMuPDF4LLM이 만든 GFM 표 블록만 분리한다."""

    lines = markdown.splitlines()
    tables: list[str] = []
    i = 0
    while i < len(lines) - 1:
        if "|" in lines[i] and TABLE_SEPARATOR_RE.match(lines[i + 1] or ""):
            start = i
            i += 2
            while i < len(lines) and "|" in lines[i] and lines[i].strip():
                i += 1
            tables.append("\n".join(lines[start:i]))
        i += 1
    return tables


def _extract_image_paths(markdown: str, image_dir: Path) -> list[str]:
    refs = []
    for ref in IMAGE_REF_RE.findall(markdown):
        refs.append(str(_resolve_image_ref(ref.replace("%20", " "), image_dir)))
    return refs


def _resolve_image_ref(ref: str, image_dir: Path) -> Path:
    path = Path(ref)
    candidates = [
        path,
        Path.cwd() / path,
        Path(__file__).resolve().parent / path,
        image_dir / path.name,
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return path


def render_slide_thumbnails(
    pdf_path: Path | str,
    pages: Iterable[int],
    thumbnail_dir: Path | str,
    *,
    dpi: int = 110,
) -> dict[int, str]:
    """각 PDF 페이지를 슬라이드 대표 이미지로 렌더링한다."""

    thumbnail_dir = _reset_dir(Path(thumbnail_dir))
    zoom = dpi / 72
    rendered: dict[int, str] = {}
    with pymupdf.open(str(pdf_path)) as pdf:
        for page_index in pages:
            page = pdf[page_index]
            pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=False)
            out = thumbnail_dir / f"slide-{page_index + 1:03d}.png"
            pix.save(out)
            rendered[page_index + 1] = str(out)
    return rendered


def extract_slide_documents(
    pdf_path: Path | str,
    *,
    source_url: str = DEFAULT_SOURCE_URL,
    pages: Iterable[int] | None = DEFAULT_PAGES,
    work_dir: Path | str = DEFAULT_WORK_DIR,
) -> list[Document]:
    """PDF 한 페이지를 LangChain Document 한 개로 변환한다."""

    work_dir = Path(work_dir)
    image_dir = _reset_dir(work_dir / "extracted_images")
    with pymupdf.open(str(pdf_path)) as pdf:
        page_numbers = _normalize_pages(pages, pdf.page_count)
    chunks = pymupdf4llm.to_markdown(
        str(pdf_path),
        page_chunks=True,
        write_images=True,
        image_path=str(image_dir),
        image_format="png",
        pages=page_numbers,
        table_strategy="lines_strict",
        show_progress=False,
    )
    thumbs = render_slide_thumbnails(pdf_path, page_numbers, work_dir / "slide_thumbnails")
    return [_chunk_to_document(chunk, source_url, thumbs, image_dir) for chunk in chunks]


def _chunk_to_document(
    chunk: dict,
    source_url: str,
    thumbnails: dict[int, str],
    image_dir: Path,
) -> Document:
    metadata = dict(chunk.get("metadata", {}))
    slide_no = int(metadata.get("page_number", 0))
    markdown = chunk.get("text", "")
    tables = extract_markdown_tables(markdown)
    image_paths = _extract_image_paths(markdown, image_dir)
    page_boxes = chunk.get("page_boxes", [])
    first_heading = _first_content_line(markdown).replace("#", "").strip()
    content = _compose_page_content(slide_no, markdown, tables, [], image_paths)
    metadata.update(
        {
            "source": source_url,
            "slide": slide_no,
            "markdown": markdown,
            "tables": tables,
            "slide_image_path": thumbnails.get(slide_no),
            "extracted_image_paths": image_paths,
            "extracted_image_count": len(image_paths),
            "markdown_chars": len(markdown),
            "first_heading": first_heading,
            "table_count": len(tables),
            "picture_count": sum(1 for box in page_boxes if box.get("class") == "picture"),
            "layout_classes": sorted({box.get("class", "") for box in page_boxes}),
        }
    )
    return Document(page_content=content, metadata=metadata)


def _compose_page_content(
    slide_no: int,
    markdown: str,
    tables: list[str],
    image_descriptions: list[str],
    image_paths: list[str],
) -> str:
    parts = [f"# Slide {slide_no}", markdown.strip()]
    if tables:
        parts.append("## Extracted tables\n" + "\n\n".join(tables))
    if image_paths:
        parts.append("## Extracted image files\n" + "\n".join(f"- {p}" for p in image_paths))
    if image_descriptions:
        parts.append("## LLM image descriptions\n" + "\n".join(image_descriptions))
    return "\n\n".join(part for part in parts if part)


def _image_to_data_url(image_path: str | Path) -> str:
    image_path = Path(image_path)
    mime = mimetypes.guess_type(image_path)[0] or "image/png"
    encoded = base64.b64encode(image_path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def _string_content(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(str(item.get("text", item)) if isinstance(item, dict) else str(item) for item in content)
    return str(content)


def describe_image_with_llm(model, image_path: str | Path, *, slide_text: str = "") -> str:
    """비전 지원 ChatModel로 이미지 설명을 생성한다."""

    prompt = (
        "강의 슬라이드 RAG 인덱싱용 이미지 설명을 한국어로 작성하세요. "
        "도표의 축, 화살표, 단계, 핵심 용어를 우선 설명하고 추측은 피하세요."
    )
    message = [
        {"type": "text", "text": f"{prompt}\n\n주변 슬라이드 텍스트:\n{slide_text[:1600]}"},
        {"type": "image_url", "image_url": {"url": _image_to_data_url(image_path)}},
    ]
    response = model.invoke([{"role": "user", "content": message}])
    return _string_content(response.content).strip()


def add_llm_image_descriptions(
    documents: list[Document],
    model,
    *,
    max_descriptions: int | None = None,
    include_extracted_images: bool = True,
) -> list[Document]:
    """각 슬라이드 대표 이미지와 추출 이미지를 설명해 Document 본문에 합친다."""

    used = 0
    for doc in documents:
        doc.metadata["image_descriptions"] = []
    for doc in documents:
        used += _caption_one(doc, doc.metadata.get("slide_image_path"), model, max_descriptions, used)
    if include_extracted_images:
        for doc in documents:
            for image_path in doc.metadata.get("extracted_image_paths", [])[:1]:
                used += _caption_one(doc, image_path, model, max_descriptions, used)
    for doc in documents:
        _refresh_page_content(doc)
    return documents


def _caption_one(doc: Document, image_path: str | None, model, limit: int | None, used: int) -> int:
    if limit is not None and used >= limit:
        return 0
    if not image_path or not Path(image_path).exists():
        return 0
    caption = describe_image_with_llm(model, image_path, slide_text=doc.page_content)
    doc.metadata["image_descriptions"].append(f"- `{Path(image_path).name}`: {caption}")
    return 1


def _refresh_page_content(doc: Document) -> None:
    doc.page_content = _compose_page_content(
        doc.metadata["slide"],
        doc.metadata.get("markdown", ""),
        doc.metadata.get("tables", []),
        doc.metadata.get("image_descriptions", []),
        doc.metadata.get("extracted_image_paths", []),
    )


def build_vectorstore(documents: list[Document], embeddings):
    """LangChain v1 InMemoryVectorStore를 생성한다."""

    from langchain_core.vectorstores import InMemoryVectorStore

    return InMemoryVectorStore.from_documents(documents, embedding=embeddings)


def make_slide_search_tool(vectorstore, *, k: int = 4):
    """검색 결과 본문과 원본 Document artifact를 함께 반환하는 도구를 만든다."""

    @tool(response_format="content_and_artifact")
    def search_slides(query: str):
        """Stanford Transformer 강의 슬라이드에서 관련 내용을 검색합니다."""
        docs = vectorstore.similarity_search(query, k=k)
        content = "\n\n".join(
            f"[slide {d.metadata.get('slide')}] {d.page_content[:1600]}" for d in docs
        )
        return content, docs

    return search_slides


def format_sources(documents: list[Document]) -> str:
    """검색된 슬라이드 출처와 이미지/표 메타데이터를 사람이 읽기 쉽게 정리한다."""

    rows = []
    for doc in documents:
        title = _first_content_line(doc.page_content)
        rows.append(
            "| {slide} | {tables} | {pictures} | {title} |".format(
                slide=doc.metadata.get("slide"),
                tables=doc.metadata.get("table_count", 0),
                pictures=doc.metadata.get("picture_count", 0),
                title=title[:80],
            )
        )
    return "\n".join(["| slide | tables | pictures | first line |", "|---:|---:|---:|---|", *rows])


def _first_content_line(text: str) -> str:
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("# Slide"):
            return line.replace("|", "\\|")
    return ""
