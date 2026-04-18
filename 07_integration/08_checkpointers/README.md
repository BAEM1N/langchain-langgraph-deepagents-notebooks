# 08. Checkpointers — LangGraph 상태 영속화

`StateGraph.compile(checkpointer=...)` 에 넘겨 스레드 단위로 대화/실행 이력을 저장한다.
프로덕션에서는 반드시 DB 기반 checkpointer 사용.

## 커버리지 체크리스트

| # | 백엔드 | 클래스 | 패키지 | 용도 | 상태 |
|---|--------|--------|--------|------|------|
| 01 | In-Memory | `InMemorySaver` | `langgraph` (포함) | 개발·단위 테스트 | ⬜ |
| 02 | SQLite | `SqliteSaver` · `AsyncSqliteSaver` | `langgraph-checkpoint-sqlite` | 로컬 워크플로 | ⬜ |
| 03 | Postgres | `PostgresSaver` · `AsyncPostgresSaver` | `langgraph-checkpoint-postgres` | 프로덕션 | ⬜ |
| 04 | Cosmos DB | `CosmosDBSaver` · `AsyncCosmosDBSaver` | `langgraph-checkpoint-cosmosdb` | Azure 환경 | ⬜ |

## 학습 포인트

- **스키마 초기화**: Postgres/CosmosDB는 최초 1회 `.setup()` 필요
- **thread_id 설계**: 유저 × 세션 × 에이전트 조합 정책
- **마이그레이션**: SQLite → Postgres 전환 시 동일 thread_id 유지하면 이력 호환
- **Time travel**: 모든 checkpointer는 `get_state_history(config)` 지원 (LangGraph 1.1 v2 opt-in 포함)
- **Subgraph scoping**: LangGraph 1.1+ subgraph 모드별 스코프 옵션 (`docs/skills/langgraph-persistence.md` 참고)
