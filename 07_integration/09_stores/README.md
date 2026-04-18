# 09. Stores — 장기 기억 영속화

Checkpointer가 "스레드별 실행 상태"를 저장한다면, Store는 "스레드 경계를 넘는 장기 기억"을 저장한다 (예: 유저 프로필, 선호도).

## 커버리지 체크리스트

| # | 백엔드 | 클래스 | 패키지 | 상태 |
|---|--------|--------|--------|------|
| 01 | In-Memory (+ 시맨틱 검색) | `InMemoryStore` | `langgraph` (포함) | ⬜ |
| 02 | Postgres | `PostgresStore` | `langgraph-checkpoint-postgres` | ⬜ |

## 학습 포인트

- **`IndexConfig`**: `embed=...`, `dims=1536` 설정 시 `store.search(query=...)` 시맨틱 검색 가능
- **네임스페이스**: `(user_id, "memories")` 튜플로 스코프 분리
- **Deep Agents `StoreBackend` 연동**: `/memories/` prefix 파일을 자동으로 Store에 영속 (04_deepagents/06_memory_and_skills 참고)
- **프로덕션**: `InMemoryStore`는 절대 프로덕션 금지 — Postgres 권장
