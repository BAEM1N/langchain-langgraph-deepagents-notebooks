# 06. Text Splitters — 분할 전략

RAG 품질의 80%는 분할에서 결정된다. 문서 특성별로 다른 분할기를 써야 한다.

## 커버리지 체크리스트

| # | 주제 | 주요 클래스 | 패키지 | 상태 |
|---|------|-------------|--------|------|
| 01 | Character / Recursive | `CharacterTextSplitter` · `RecursiveCharacterTextSplitter` · `TokenTextSplitter` | `langchain-text-splitters` | ⬜ |
| 02 | Markdown / Code 언어별 | `MarkdownHeaderTextSplitter` · `RecursiveCharacterTextSplitter.from_language(Language.PYTHON)` · `HTMLHeaderTextSplitter` · `LatexTextSplitter` | `langchain-text-splitters` | ⬜ |
| 03 | Semantic splitter | `SemanticChunker` | `langchain-experimental` | ⬜ |

## 학습 포인트

- **chunk_size / chunk_overlap**: 토큰 기준 계산 (임베딩 모델의 max 토큰에 맞춰)
- **구조 보존**: Markdown/HTML은 헤더 기반으로 나눠야 metadata 풍부
- **코드 분할**: 함수·클래스 경계를 지키는 `Language.PYTHON|JS|GO|…` 30+ 지원
- **Semantic chunker**: 인접 문장 임베딩 유사도로 의미 경계 탐지 (비용↑ 품질↑)
