# LangGraph Stores

## Overview

Store는 agent가 thread를 넘어 정보를 보관하고 검색하는 key-value 저장 계층이다. 사용자 선호, 누적 지식, 조직 설정처럼 **한 대화 thread에 묶이지 않는 장기 기억**을 다룬다.

Checkpointer와 역할이 다르다.

| 계층 | 저장 대상 | scope |
|------|-----------|-------|
| Checkpointer | graph state snapshot | thread-local |
| Store | arbitrary key-value memory | cross-thread |

## Basic Usage

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
namespace = ("user-1", "memories")

store.put(namespace, "favorite-food", {"food": "kimchi-jjigae"})
item = store.get(namespace, "favorite-food")
results = store.search(namespace)
```

각 item은 `value`, `key`, `namespace`, `created_at`, `updated_at`을 갖는다.

## Namespaces and Pagination

Namespace는 tuple이다. 앞쪽 segment를 사용자·조직·앱 단위로 두면 prefix search와 권한 경계를 잡기 쉽다.

```python
store.search(("user-1", "memories"), limit=20, offset=0)
store.list_namespaces(prefix=("user-1",), max_depth=2)
```

## Semantic Search

Embedding index를 설정하면 `query=`로 의미 검색을 할 수 있다.

```python
from langchain.embeddings import init_embeddings
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["memory", "$"],
    }
)

store.put(("user-1", "memories"), "m1", {"memory": "Prefers concise answers"})
hits = store.search(("user-1", "memories"), query="How should I answer?", limit=3)
```

Per-item으로 embedding 대상 field를 고르거나 `index=False`로 제외할 수 있다.

## Using Store in Graph Nodes

`compile(store=store)`로 graph에 주입하고, node에서는 `Runtime[Context]`로 접근한다.

```python
from dataclasses import dataclass
from langgraph.runtime import Runtime

@dataclass
class Context:
    user_id: str

async def save_memory(state: State, runtime: Runtime[Context]) -> dict:
    namespace = (runtime.context.user_id, "memories")
    await runtime.store.aput(namespace, "latest", {"memory": state["summary"]})
    return {}

graph = builder.compile(checkpointer=checkpointer, store=store)
```

## Production Implementations

| 구현체 | 용도 |
|--------|------|
| `InMemoryStore` | 개발·테스트 |
| `PostgresStore` | 프로덕션 영속성, 동시 실행 |
| `RedisStore` | 낮은 지연 시간, cache-like memory |
| `MongoDBStore` | document-oriented memory |
| `OracleStore` | Oracle 환경, vector search |

## Design Rules

1. **thread-local state는 checkpointer에 둔다.** Store는 사용자·조직·도메인 기억처럼 재사용 가치가 있는 정보만 저장한다.
2. **namespace를 권한 경계로 설계한다.** `(org_id, user_id, "memories")`처럼 검색 범위를 명확히 한다.
3. **semantic search field를 제한한다.** 모든 JSON field를 embed하면 비용과 노이즈가 늘어난다.
4. **민감정보는 저장 전 정책을 통과시킨다.** 장기 기억은 삭제·감사·암호화 요구가 커진다.

## Related

- `05-persistence.md` — checkpointer와 store 통합 설명
- `25-checkpointers.md` — thread-local 실행 상태 저장
- `10-memory.md` — memory 설계 패턴
