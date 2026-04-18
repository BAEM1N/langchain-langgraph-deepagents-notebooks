# Long-term Memory

## Overview
Deep agents can implement persistent memory across conversation threads using a `CompositeBackend` that routes specific file paths to permanent storage while keeping other files ephemeral.

## Key Architecture

The system uses a path-based routing strategy:

- **`/memories/*` paths**: Stored persistently via `StoreBackend`
- **Other paths**: Remain transient in agent state via `StateBackend`

## Setup Implementation

Configuration requires three components:

1. A checkpointer (e.g., `MemorySaver`)
2. A store implementation (e.g., `InMemoryStore` for dev, `PostgresStore` for production)
3. A `CompositeBackend` with routing rules

The backend factory function receives a runtime parameter and returns the configured router.

## Storage Behavior

- **Transient files**: Persist only within a single conversation thread, discarded when it ends
- **Persistent files**: Survive thread completion and agent restarts, accessible across all conversations

## Important Implementation Detail

`CompositeBackend` strips the route prefix before storing — meaning `/memories/preferences.txt` is stored internally as `/preferences.txt`, though agents always reference the full path.

## Cross-Thread Access

Different threads with unique IDs can access the same `/memories/` files, enabling knowledge sharing between separate conversations.

## Production Considerations

For deployed agents on LangSmith, external code can interact with memories via the Store API using namespace tuples like `(assistant_id, "filesystem")`. Data uses a standardized format with content lines, creation timestamps, and modification timestamps.

## Common Use Cases

- Accumulating user preferences across sessions
- Self-improving instructions updated via feedback
- Building knowledge bases incrementally
- Maintaining research progress across multiple conversations

---

## 정보 유형 분류 (0.5 기준)

Deep Agents는 저장되는 정보를 세 범주로 구분해 관리한다. 각 유형은 저장 메커니즘·업데이트 주기·적합한 백엔드가 다르다.

| 유형 | 의미 | 저장 예 | 메커니즘 |
|------|------|---------|----------|
| **Episodic** | 과거 경험 — 대화 세션, 문제 해결 궤적 | 지난 대화의 스레드 히스토리 | Checkpointers (thread 단위) |
| **Procedural** | 재사용 가능한 지시·스킬·워크플로우 | `SKILL.md`, 절차 문서 | Skills (on-demand 로드) |
| **Semantic** | 사실·선호·정책 | `AGENTS.md`, `/memories/*.txt` | StoreBackend (always-on 파일) |

세 유형을 하나의 백엔드로 몰아넣지 말고, **성격에 맞는 메커니즘**에 분산시키는 것이 기본 원칙이다. 예: 장시간 누적 선호는 `/memories/`(semantic) + 일화적 사례 검색은 checkpointer(episodic) + 반복 절차는 skill(procedural).

## Scope 패턴: agent-scoped vs user-scoped

`StoreBackend`의 `namespace` 함수가 반환하는 튜플이 곧 메모리의 스코프다. 가장 흔한 두 패턴은 다음과 같다.

### Agent-scoped — 공통 정체성 축적

네임스페이스가 `(assistant_id,)`. 같은 assistant를 쓰는 **모든 사용자 대화**가 같은 메모리를 공유한다. 에이전트 자신의 페르소나·누적 지식·학습된 선호가 이 공간에 쌓인다.

```python
from deepagents.backends import StoreBackend

agent_scoped = StoreBackend(
    namespace=lambda rt: (
        rt.server_info.assistant_id,
    ),
)
```

주의: 사용자 간 정보가 섞이므로 **민감 정보 저장 금지**. 조직 공통 컨벤션·도메인 지식에 적합.

### User-scoped — 사용자별 격리

네임스페이스가 `(user_id,)` 또는 `(assistant_id, user_id,)`. 각 사용자의 메모리가 완전히 격리되어 A의 선호가 B의 대화에 노출되지 않는다.

```python
user_scoped = StoreBackend(
    namespace=lambda rt: (rt.server_info.user.identity,),
)
```

프로덕션 개인화 어시스턴트의 기본값. 두 스코프 조합 예는 `13-going-to-production.md`의 "Memory persistence scoping" 참고.

## Episodic memory via checkpointers

과거 대화를 단순히 "보관"하는 것이 아니라 **검색 가능한 기억**으로 만들려면 체크포인터가 저장한 스레드를 도구로 래핑한다.

```python
from langchain.tools import tool, ToolRuntime

@tool
async def search_past_conversations(query: str, runtime: ToolRuntime) -> str:
    """지난 대화에서 관련 맥락을 찾는다."""
    user_id = runtime.server_info.user.identity
    threads = await client.threads.search(
        metadata={"user_id": user_id},
        limit=5,
    )
    # threads를 필요한 포맷으로 요약해 반환
    ...
```

조직 차원 검색은 `metadata={"org_id": org_id}`. 이 패턴으로 에이전트가 "전에 이 문제를 어떻게 풀었는가"를 스스로 참조한다.

## Read-only policy (조직 차원)

조직 공유 메모리는 인젝션 벡터다. 다음과 같이 **쓰기 차단**을 강제한다.

```python
# policies는 조직 스코프, read-only
routes = {
    "/policies/": StoreBackend(
        namespace=lambda rt: (rt.context.org_id,),
    ),
}
```

`16-permissions.md`의 패턴 4를 결합해 `/policies/**`에 `write deny`를 건다. 정책은 애플리케이션 코드에서만 갱신한다.

```python
await client.store.put_item(
    (org_id,),
    "/compliance.md",
    create_file_data("""## Compliance policies
- Never disclose internal pricing
- Always include disclaimers on financial advice
"""),
)
```

## Background consolidation agent

메모리 갱신을 **대화 중(hot path)** 에 하면 지연이 늘고, 요약 품질도 모델이 서두른 결정을 따르게 된다. 대안은 별도 consolidation agent를 두고 **cron으로 주기 실행**하는 것이다.

```json
// langgraph.json
{
  "graphs": {
    "agent": "./agent.py:agent",
    "consolidation_agent": "./consolidation_agent.py:agent"
  }
}
```

Consolidation agent는 최근 대화를 훑고 선별해 메모리에 반영한다.

```python
from datetime import datetime, timedelta, timezone

since = datetime.now(timezone.utc) - timedelta(hours=6)
threads = await sdk_client.threads.search(
    metadata={"user_id": user_id},
    updated_after=since.isoformat(),
    limit=20,
)
# threads로부터 선호·사실·사례를 추출해 /memories/에 반영
```

cron 스케줄 등록:

```python
cron_job = await client.crons.create(
    assistant_id="consolidation_agent",
    schedule="0 */6 * * *",   # 6시간마다
    input={"messages": [{"role": "user", "content": "Consolidate recent memories."}]},
)
```

**중요**: cron 주기(`0 */6 * * *`)와 lookback window(`timedelta(hours=6)`)를 일치시켜야 누락·중복이 없다.

### 업데이트 타이밍 비교

| 타이밍 | 방식 | 지연 | 반영 시점 |
|--------|------|------|-----------|
| Hot path | 대화 중 에이전트가 직접 `edit_file` | 있음 | 즉시 |
| Background | Consolidation agent가 세션 사이에 처리 | 사용자 체감 없음 | 다음 대화부터 |

민감하거나 즉시 반영이 필수인 선호는 hot path, 장기 패턴 누적은 background로 분리하는 것이 기본 구성이다.

## 관련 문서

- `06-backends.md` — `StoreBackend` / `CompositeBackend` 기본
- `10-skills.md` — procedural memory로서의 스킬
- `13-going-to-production.md` — 스코프별 namespace 패턴, 공유 메모리 운영
- `14-context-engineering.md` — 메모리 파일을 컨텍스트에 끌어오는 전략
- `16-permissions.md` — 공유 메모리 read-only 강제
