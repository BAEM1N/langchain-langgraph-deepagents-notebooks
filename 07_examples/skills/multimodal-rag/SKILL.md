# Multimodal PDF RAG Skill

공개 강의 PDF/PPTX-export PDF를 슬라이드 단위로 인덱싱하는 예제용 규칙.

## 워크플로

1. **PDF 확보**: 공개 URL을 캐시에 다운로드하고 PDF 헤더를 검증한다.
2. **슬라이드 단위 추출**: PyMuPDF4LLM `to_markdown(page_chunks=True)`로 1페이지 = 1 `Document`를 만든다.
3. **이미지 보강**: `write_images=True`로 추출 이미지를 저장하고, PyMuPDF 렌더링으로 슬라이드 대표 이미지를 만든다.
4. **표 보강**: Markdown 표 블록을 분리해 `metadata.table_count`와 본문 섹션에 넣는다.
5. **LLM 이미지 설명**: 비전 지원 `ChatOpenAI`로 슬라이드/이미지를 한국어 설명으로 변환해 검색 텍스트에 합친다.
6. **LangChain v1 RAG**: `InMemoryVectorStore` + `@tool(response_format="content_and_artifact")` + `create_agent()`를 사용한다.

## 안전 규칙

- 원본 공개 PDF는 저장소에 커밋하지 않고 `.cache/` 아래에 런타임 캐시로 둔다.
- 이미지 설명은 슬라이드 텍스트와 이미지를 근거로 작성하고, 보이지 않는 정보는 추측하지 않는다.
- 검색 답변에는 슬라이드 번호를 반드시 포함한다.
