# 01. Chat Models — 공급자별 통합

OpenAI / Anthropic 외에도 LangChain은 25+ chat 모델 공급자와 1:1 통합을 제공한다.
각 노트북은 동일한 `create_agent(...)` 인터페이스를 기준으로 공급자 특화 옵션(함수 호출, tool schema, 스트리밍 지원도 등)을 비교한다.

## 커버리지 체크리스트

| # | 공급자 | 주요 클래스 | 패키지 | 상태 |
|---|--------|------------|--------|------|
| 01 | OpenAI / Azure OpenAI | `ChatOpenAI`, `AzureChatOpenAI` | `langchain-openai` | ⬜ |
| 02 | Anthropic | `ChatAnthropic` | `langchain-anthropic` | ⬜ |
| 03 | Google (Gemini + Vertex AI) | `ChatGoogleGenerativeAI` | `langchain-google-genai` (4.0.0, 통합 SDK) | ⬜ |
| 04 | Ollama (로컬) | `ChatOllama` | `langchain-ollama` | ⬜ |
| 05 | AWS Bedrock / Amazon Nova | `ChatBedrock`, `ChatAmazonNova` | `langchain-aws` | ⬜ |
| 06 | Groq | `ChatGroq` | `langchain-groq` | ⬜ |
| 07 | Mistral AI | `ChatMistralAI` | `langchain-mistralai` | ⬜ |
| 08 | Cohere | `ChatCohere` | `langchain-cohere` | ⬜ |
| 09 | Routers & 기타 | `ChatOpenRouter` · `ChatLiteLLM` · `ChatTogether` · `ChatFireworks` · `ChatDeepSeek` · `ChatXAI` · `ChatPerplexity` | 각 공급자 | ⬜ |

## 학습 포인트

- **`init_chat_model()` 헬퍼**: `init_chat_model("openai:gpt-4.1")` 형태의 provider prefix 문자열로 모델 교체
- **`.profile` 속성 (1.1+)**: `max_input_tokens`, `tool_calling`, `reasoning_output` 등 공급자별 실제 능력치
- **Responses API (OpenAI)**: `use_responses_api=True, store=False, include=["reasoning.encrypted_content"]` 데이터 보존 옵션
- **Tool calling 호환성**: 공급자별 지원 범위 차이 (예: Ollama는 일부 모델만)
- **로컬 vs 관리형**: Ollama/Llama.cpp는 로컬, 그 외는 관리형 API
