# 11. Provider Middleware — 공급자 특화 미들웨어

공급자별 고유 기능(프롬프트 캐시·네이티브 도구·컨텐츠 정책)을 미들웨어로 끼워 넣는 영역.
리포의 `docs/langchain/11-middleware-builtin.md` 는 이 부분을 한 줄로만 언급 — 여기서 실행 가능한 코드로 채운다.

## 커버리지 체크리스트

| # | 주제 | 클래스 | 패키지 | 상태 |
|---|------|--------|--------|------|
| 01 | Anthropic Prompt Caching | `AnthropicPromptCachingMiddleware` | `langchain-anthropic` | ✅ |
| 02 | Claude Bash Tool | `ClaudeBashToolMiddleware` | `langchain-anthropic` | ✅ |
| 03 | Claude Text Editor | `StateClaudeTextEditorMiddleware` · `FilesystemClaudeTextEditorMiddleware` | `langchain-anthropic` | ✅ |
| 04 | Claude Memory | `StateClaudeMemoryMiddleware` · `FilesystemClaudeMemoryMiddleware` | `langchain-anthropic` | ✅ |
| 05 | Anthropic File Search | `StateFileSearchMiddleware` | `langchain-anthropic` | ✅ |
| 06 | Bedrock Prompt Caching | `BedrockPromptCachingMiddleware` | `langchain-aws` | ✅ |
| 07 | OpenAI Moderation | `OpenAIModerationMiddleware` (param: `exit_behavior` — `end`/`error`/`replace`) | `langchain-openai` | ✅ |

## 학습 포인트

- **Prompt caching 공식**: Anthropic/Bedrock 모두 `ttl`(5m · 1h) + `min_messages_to_cache` + `unsupported_model_behavior` 4개 파라미터 패턴 동일
- **자동 checkpoint 지점**: system prompt, tool definitions, 마지막 메시지
- **Claude 네이티브 도구**: Bash·TextEditor·Memory·FileSearch는 Anthropic 서버가 직접 해석하는 built-in tool로, 일반 `@tool` 보다 지연·정확도 우위
- **State vs Filesystem 변형**: TextEditor/Memory는 상태 기반(State…)과 디스크 기반(Filesystem…) 두 구현 — 프로덕션 영속성 여부로 선택
- **OpenAI Moderation**: `check_input`/`check_output` + `on_violation="block"|"warn"` — 비용·지연 고려해 입력만 주로 씀

## 관련 문서

- https://docs.langchain.com/oss/python/integrations/middleware/anthropic
- https://docs.langchain.com/oss/python/integrations/middleware/aws
- https://docs.langchain.com/oss/python/integrations/middleware/openai
