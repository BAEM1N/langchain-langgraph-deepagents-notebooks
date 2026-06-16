# 08. Integrations — LangChain 생태계 통합 카탈로그

`08_integration/`은 LangChain, LangGraph, Deep Agents를 외부 provider, database, vector store, sandbox, observability 도구와 연결하는 **통합 실습 카탈로그**입니다. Core curriculum이 “에이전트를 어떻게 설계하나”에 집중한다면, 이 폴더는 “어떤 외부 시스템과 어떻게 연결하나”를 다룹니다.

> 실행 정책: 이 폴더는 provider별 API key, 로컬 서비스, 유료 cloud sandbox가 섞여 있어 기본 `01~07` gpt-4.1 live harness에서 의도적으로 제외됩니다.

---

## 폴더 규칙

- 서브폴더: `NN_topic/`
- 노트북: `NN_name.ipynb`
- 각 서브폴더는 자체 `README.md`나 노트북 제목으로 coverage를 설명합니다.
- 실행 전 필요한 provider key, local server, Docker/service dependency를 먼저 확인합니다.

---

## 카테고리 현황 — 69 notebooks

| # | 카테고리 | 노트북 수 | 주요 내용 | 상태 |
|---|---|---:|---|---|
| 01 | [Chat Models](./01_chat_models/) | 9 | OpenAI, Anthropic, Google, Ollama, Bedrock, Groq, Mistral, Cohere, routers | ✅ |
| 02 | [Embeddings](./02_embeddings/) | 6 | OpenAI, Google, Cohere, Voyage, Ollama, HuggingFace | ✅ |
| 03 | [Vector Stores](./03_vectorstores/) | 8 | InMemory/FAISS, Chroma, PGVector, Pinecone, Qdrant, Weaviate, Milvus, Elasticsearch | ✅ |
| 04 | [Document Loaders](./04_document_loaders/) | 5 | PDF, web, cloud storage, productivity, structured/code sources | ✅ |
| 05 | [Retrievers](./05_retrievers/) | 5 | BM25+ensemble, MultiVector, SelfQuery, web, vendor-managed retrievers | ✅ |
| 06 | [Text Splitters](./06_text_splitters/) | 3 | Character/Recursive, Markdown/HTML/Code, semantic splitting | ✅ |
| 07 | [Tools](./07_tools/) | 6 | search, code execution, SQL, Playwright, productivity, knowledge tools | ✅ |
| 08 | [Checkpointers](./08_checkpointers/) | 4 | InMemory, SQLite, Postgres, CosmosDB | ✅ |
| 09 | [Stores](./09_stores/) | 2 | InMemoryStore, PostgresStore | ✅ |
| 10 | [Sandboxes](./10_sandboxes/) | 3 | Modal, Daytona, Runloop | ✅ |
| 11 | [Provider Middleware](./11_provider_middleware/) | 7 | Anthropic patterns, Bedrock prompt caching, OpenAI moderation | ✅ |
| 12 | [Observability](./12_observability/) | 2 | Langfuse, OpenTelemetry | ✅ |
| 13 | [Providers](./13_providers/) | 9 | Anthropic, OpenAI, Google, AWS, Microsoft, Groq, HuggingFace, NVIDIA, Ollama | ✅ |

---

## 실행 전 체크리스트

| 통합 유형 | 확인할 것 |
|---|---|
| Cloud provider | API key, region, billing, rate limit |
| Vector DB | Docker/local server 또는 managed endpoint |
| SQL/DB | connection string, sample DB, write 권한 제한 |
| Browser/tooling | Playwright browser install, sandbox 권한 |
| Sandbox | 유료 cloud runtime 비용, secrets 전달 방식 |
| Observability | tracing key, project name, PII masking 정책 |

---

## 기본 harness에서 제외되는 이유

`local/notebook_execution_01_07_gpt41/run_notebooks.py`는 다음 범위만 기본 검증합니다.

- `01_beginner/`~`07_examples/`
- `en/01_beginner/`~`en/07_examples/`

`08_integration/`은 다음 이유로 별도 검증 대상입니다.

1. provider별 secret이 필요합니다.
2. Postgres, Elasticsearch, browser, sandbox 등 로컬/외부 runtime이 필요할 수 있습니다.
3. Modal/Daytona/Runloop 같은 cloud sandbox는 비용이 발생할 수 있습니다.
4. 동일 노트북이라도 계정/region/quota에 따라 결과가 달라질 수 있습니다.

---

## 관련 문서

- [`../docs/MODEL_PROVIDERS.md`](../docs/MODEL_PROVIDERS.md)
- [`../docs/OBSERVABILITY.md`](../docs/OBSERVABILITY.md)
- [`../docs/skills/langchain-dependencies.md`](../docs/skills/langchain-dependencies.md)
- [`../docs/verification/2026-06-17-tutorial-gap-analysis.md`](../docs/verification/2026-06-17-tutorial-gap-analysis.md)
