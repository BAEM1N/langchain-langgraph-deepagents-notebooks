# 04. Document Loaders — 소스별 적재

원본 데이터를 `Document(page_content=..., metadata=...)` 형태로 표준화한다.

## 커버리지 체크리스트

| # | 유형 | 대표 로더 | 패키지 | 상태 |
|---|------|----------|--------|------|
| 01 | PDF | `PyPDFLoader` · `PyMuPDFLoader` · `PyMuPDF4LLMLoader` · `PDFPlumberLoader` · `PDFMinerLoader` · `PyPDFDirectoryLoader` | `langchain-community` | ⬜ |
| 02 | Web crawl | `WebBaseLoader` · `RecursiveURLLoader` · `SitemapLoader` · `FirecrawlLoader` · `SpiderLoader` | `langchain-community` | ⬜ |
| 03 | Cloud storage | `S3FileLoader` · `S3DirectoryLoader` · `AzureBlobStorageLoader` · `GCSFileLoader` · `GCSDirectoryLoader` · `GoogleDriveLoader` | `langchain-community` / 공급자 패키지 | ⬜ |
| 04 | Productivity | `NotionDirectoryLoader` · `SlackDirectoryLoader` · `GithubFileLoader` · `ConfluenceLoader` · `FigmaFileLoader` | `langchain-community` | ⬜ |
| 05 | Structured / code | `CSVLoader` · `JSONLoader` · `BSHTMLLoader` · `DoclingLoader` · `GitLoader` · `UnstructuredFileLoader` | `langchain-community` | ⬜ |

## 학습 포인트

- **`load()` vs `lazy_load()`**: 대량 문서는 제너레이터 버전
- **Metadata 설계**: `source`, `page`, `section`, `author` 등 RAG 필터링 기반
- **파싱 품질**: PDF는 로더마다 표·이미지 추출 방식 다름 — `PyMuPDF4LLMLoader`가 LLM 친화적 마크다운 출력
- **Docling**: IBM 오픈소스, 테이블·레이아웃 이해 뛰어남
- **Rate limit / 인증**: 클라우드·productivity 로더는 OAuth 흐름 주의
