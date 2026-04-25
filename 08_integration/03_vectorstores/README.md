# 03. Vector Stores — 벡터 DB 통합

100+ 벡터 스토어가 공식 통합된다. 아래는 한국 환경에서 실제로 자주 쓰는 조합.

## 커버리지 체크리스트

| # | 스토어 | 클래스 | 패키지 | 특징 | 상태 |
|---|--------|--------|--------|------|------|
| 01 | In-Memory / FAISS | `InMemoryVectorStore`, `FAISS` | `langchain-core`, `langchain-community` | 로컬 개발·테스트 | ⬜ |
| 02 | Chroma | `Chroma` | `langchain-chroma` | 로컬 ~ 소규모 배포 | ⬜ |
| 03 | PGVector | `PGVectorStore`, `PGVector` | `langchain-postgres` | 기존 Postgres에 애드온 | ⬜ |
| 04 | Pinecone | `PineconeVectorStore` | `langchain-pinecone` | 관리형 serverless | ⬜ |
| 05 | Qdrant | `QdrantVectorStore` | `langchain-qdrant` | Rust 기반, 로컬·클라우드 | ⬜ |
| 06 | Weaviate | `WeaviateVectorStore` | `langchain-weaviate` | hybrid search 내장 | ⬜ |
| 07 | Milvus | `Milvus` | `langchain-milvus` | 대규모 프로덕션 | ⬜ |
| 08 | Elasticsearch | `ElasticsearchStore` | `langchain-elasticsearch` | 기존 ES 스택 재사용 | ⬜ |

## 학습 포인트

- **add_documents / similarity_search / as_retriever**: 모든 구현에서 공통
- **Metadata filter**: 구현별 DSL이 다름 (Pinecone · Qdrant · Weaviate 하이브리드 조건)
- **Hybrid search**: Weaviate·Qdrant·Elasticsearch는 BM25 + dense 혼합 지원
- **Persistence**: Chroma `persist_directory`, FAISS `save_local`, 나머지는 네트워크 DB
- **Index management**: 차원 수 변경 불가 — 임베딩 모델 교체 시 재인덱싱

## 관련

- `05_retrievers/` — retriever 레이어 (BM25, multi-vector, parent-doc)
- `05_advanced/05_agentic_rag.ipynb` — retriever + agent 통합 예
