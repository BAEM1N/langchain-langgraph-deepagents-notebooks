# 05. Retrievers — 검색 전략 통합

벡터 유사도 외에도 키워드(BM25), 구조적 검색, 웹 검색, 벤더 관리형 검색까지 조합 가능하다.

## 커버리지 체크리스트

| # | 주제 | 클래스 | 패키지 | 상태 |
|---|------|--------|--------|------|
| 01 | BM25 + Ensemble | `BM25Retriever` · `EnsembleRetriever` | `langchain-community` · `langchain` | ⬜ |
| 02 | Multi-Vector / Parent-Document | `MultiVectorRetriever` · `ParentDocumentRetriever` | `langchain` | ⬜ |
| 03 | Self-Query | `SelfQueryRetriever` | `langchain` | ⬜ |
| 04 | Web / Knowledge | `TavilySearchAPIRetriever` · `WikipediaRetriever` · `ArxivRetriever` · `PubMedRetriever` | `langchain-community` | ⬜ |
| 05 | Vendor-managed | `AmazonKnowledgeBasesRetriever` · `AzureAISearchRetriever` · `VertexAISearchRetriever` · `ElasticsearchRetriever` | 공급자 패키지 | ⬜ |

## 학습 포인트

- **Ensemble 가중치**: BM25 0.3 + dense 0.7 같은 조합이 일반 RAG에 강함
- **Multi-Vector**: 원본 문서 하나당 N개 벡터(요약·가설 질문·핵심 발췌) 저장
- **Parent-Document**: 작은 청크로 검색 → 큰 원본 문단을 LLM에 전달
- **Self-Query**: 자연어 질의에서 metadata filter 자동 추출 (vector store DSL로 변환)
- **Rerank 레이어**: Cohere `rerank-3` / Voyage rerank 을 retriever 뒤에 붙여 품질 향상
