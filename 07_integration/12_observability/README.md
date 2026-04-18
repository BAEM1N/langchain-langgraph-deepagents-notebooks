# 12. Observability — 트레이싱·로깅 벤더

에이전트는 프로덕션에서 "왜 이런 답을 했는지" 재현이 어렵다. Observability 벤더는 각 LLM·tool call을 트리 구조로 기록해 디버깅·eval·비용 추적을 가능하게 한다.

## 커버리지 체크리스트

| # | 벤더 | 연동 방식 | 상태 |
|---|------|----------|------|
| 01 | LangSmith | 환경변수 `LANGSMITH_API_KEY` + 자동 계측 | ⬜ |
| 02 | Langfuse + OpenTelemetry | `langfuse` SDK · OTel exporter · `CallbackHandler` | ⬜ |

## 학습 포인트

- **LangSmith**: LangChain 1차 지원 — `LANGSMITH_TRACING=true` 설정만으로 모든 `create_agent` 실행 추적
- **Langfuse**: 오픈소스/self-host 가능, cost tracking·eval·prompt management
- **OpenTelemetry**: 벤더 중립 — OTel 콜렉터로 Datadog·Grafana Tempo·Jaeger 등 라우팅
- **샘플링**: 고비용 프로덕션은 샘플링·PII 스크러빙 필요
- **Dataset + eval**: LangSmith/Langfuse 모두 트레이스 → 데이터셋 → 자동 평가 루프 제공

## 관련 문서

- `docs/OBSERVABILITY.md`
- `docs/langchain/30-observability.md`
- `docs/langgraph/17-observability.md`
