# 13. Providers — 공급자 패키지 카탈로그

공식 `docs.langchain.com/oss/python/integrations/providers/` 에 있는 공급자별 종합 진입점에 대응한다. 한 공급자(예: Anthropic) 가 제공하는 chat · embedding · retriever · middleware 등 모든 integration 을 한 눈에 본다.

기능별 분류는 `01_chat_models/` ~ `12_observability/` 에서 다룬다 — 여기는 **공급자 관점 오버뷰**.

## 커버리지 체크리스트

| # | 공급자 | 패키지 | 주요 integration | 상태 |
|---|-------|-------|------|------|
| 01 | Anthropic | `langchain-anthropic` | ChatAnthropic · prompt caching · Claude native tools (bash/text editor/memory/file search) | ⬜ |
| 02 | OpenAI / Azure | `langchain-openai` | ChatOpenAI · Embeddings · Moderation · Azure OpenAI · DALL-E | ⬜ |
| 03 | Google | `langchain-google-genai` · `langchain-google-community` | Gemini · Vertex AI · GCS loader · Drive loader · Vertex AI Search | ⬜ |
| 04 | AWS | `langchain-aws` | Bedrock · Bedrock prompt caching · Kendra · Knowledge Bases · S3 · DynamoDB · Neptune | ⬜ |
| 05 | Microsoft / Azure | `langchain-microsoft` · `langchain-azure-ai` | Azure OpenAI · Azure AI Search · Cosmos DB · Blob Storage | ⬜ |
| 06 | Groq | `langchain-groq` | ChatGroq (Llama · Mixtral 고속 추론) | ⬜ |
| 07 | Hugging Face | `langchain-huggingface` | ChatHuggingFace · HuggingFaceEmbeddings · Transformers · TGI | ⬜ |
| 08 | NVIDIA | `langchain-nvidia-ai-endpoints` | ChatNVIDIA · NVIDIA NIM · reranker · embedding | ⬜ |
| 09 | Ollama | `langchain-ollama` | ChatOllama · OllamaEmbeddings (로컬 모델) | ⬜ |

## 언제 기능별 카테고리 vs. 공급자 카테고리?

- **기능별** (`01_chat_models/`): "채팅 모델을 쓰고 싶은데 어떤 공급자가 있나?"
- **공급자별** (여기): "Anthropic 패키지 하나로 무엇까지 할 수 있나?"

## 참고

- 공식 overview: https://docs.langchain.com/oss/python/integrations/providers/overview
- 전체 공급자 목록: https://docs.langchain.com/oss/python/integrations/providers/all_providers
