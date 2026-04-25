# 02. Embeddings — 임베딩 모델 통합

검색(RAG) 품질을 좌우하는 임베딩 벡터 생성기. 공급자별 차원 수·컨텍스트·비용·로컬 가능 여부가 다르다.

## 커버리지 체크리스트

| # | 공급자 | 주요 클래스 | 패키지 | 상태 |
|---|--------|------------|--------|------|
| 01 | OpenAI / Azure | `OpenAIEmbeddings`, `AzureOpenAIEmbeddings` | `langchain-openai` | ⬜ |
| 02 | Google | `GoogleGenerativeAIEmbeddings` | `langchain-google-genai` | ⬜ |
| 03 | Cohere | `CohereEmbeddings` | `langchain-cohere` | ⬜ |
| 04 | Voyage AI | `VoyageAIEmbeddings` | `langchain-voyageai` | ⬜ |
| 05 | Ollama (로컬) | `OllamaEmbeddings` | `langchain-ollama` | ⬜ |
| 06 | HuggingFace / Sentence Transformers | `HuggingFaceEmbeddings` | `langchain-huggingface` | ⬜ |

## 학습 포인트

- **차원 수** 선택: OpenAI `text-embedding-3-large`(3072) vs `-small`(1536) vs Voyage(1024) — vector store 스키마 고정
- **다국어 성능**: Cohere `embed-multilingual-v3`, Voyage `voyage-3`는 한국어 강함
- **로컬**: Ollama + `nomic-embed-text` / HuggingFace `BAAI/bge-m3`로 완전 오프라인
- **Rerank**: Cohere/Voyage rerank 모델은 `05_retrievers`에서 다룸
- **Fake**: `FakeEmbeddings`로 유닛 테스트
