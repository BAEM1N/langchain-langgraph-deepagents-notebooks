// Auto-generated from 06_persistence_and_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "지속성과 메모리", subtitle: "체크포인터와 메모리 스토어")

== 학습 목표
체크포인터로 상태를 저장하고, 스토어로 장기 메모리를 구현합니다.

- _체크포인터_: 각 실행 단계의 상태를 자동으로 저장하고 복원
- _상태 조회_: `get_state()`와 `get_state_history()`로 저장된 상태 확인
- _상태 수정_: `update_state()`로 외부에서 상태 변경
- _스레드 독립성_: 서로 다른 `thread_id`는 완전히 독립된 상태
- _InMemoryStore_: 스레드 간 공유되는 장기 메모리 (standalone 및 그래프 연동)
- _Checkpointer vs Store_: 최신 문서 기준으로 thread-scoped state와 cross-thread memory를 구분
- _대화 길이 관리_: `trim_messages`와 `RemoveMessage`로 메시지 관리
- _Durable Execution_: 실패 시 마지막 체크포인트에서 재개

== 6.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
# docs/langgraph 패치 기준 canonical 모델 ID
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 6.2 체크포인터 — 각 실행 단계의 상태를 자동으로 저장합니다

LangGraph는 다양한 체크포인터 구현체를 제공합니다 (`BaseCheckpointSaver`를 구현).

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구현체],
  text(weight: "bold")[패키지],
  text(weight: "bold")[용도],
  [`InMemorySaver`],
  [`langgraph-checkpoint` (기본)],
  [개발/테스트, 메모리에만 저장],
  [`SqliteSaver` / `AsyncSqliteSaver`],
  [`langgraph-checkpoint-sqlite`],
  [로컬 개발, 파일 영속화],
  [`PostgresSaver` / `AsyncPostgresSaver`],
  [`langgraph-checkpoint-postgres`],
  [프로덕션 (LangSmith가 사용)],
  [`MongoDBSaver`],
  [`langgraph-checkpoint-mongodb`],
  [프로덕션],
  [`RedisSaver` / `AsyncRedisSaver`],
  [`langgraph-checkpoint-redis`],
  [프로덕션],
  [`OracleSaver`],
  [`langgraph-checkpoint-oracle`],
  [프로덕션],
  [`CosmosDBSaverSync` / `CosmosDBSaver`],
  [`langchain-azure-cosmosdb`],
  [Microsoft Entra ID 지원],
)

`compile()`에 체크포인터를 전달하면 각 노드 실행 후 상태가 자동으로 저장됩니다.

== 6.3 get_state() — 현재 저장된 상태 조회

`get_state()`는 지정된 스레드의 최신 체크포인트 상태를 반환합니다.
메시지 수, 체크포인트 ID, 다음 실행할 노드 등을 확인할 수 있습니다.

#code-block(`````python
state = graph.get_state(config)
print(f"스레드: {config['configurable']['thread_id']}")
print(f"메시지 수: {len(state.values['messages'])}")
print(f"체크포인트 ID: {state.config['configurable']['checkpoint_id']}")
print(f"다음 노드: {state.next}")
`````)
#output-block(`````
스레드: session-1
메시지 수: 4
체크포인트 ID: 1f1196e1-c938-68ee-8004-4f52838ad157
다음 노드: ()
`````)

== 6.4 get_state_history() — 전체 실행 이력 조회

`get_state_history()`는 해당 스레드의 모든 체크포인트를 최신순으로 반환합니다.
그래프 실행의 전체 이력을 추적할 수 있습니다.

#code-block(`````python
print("상태 이력 (최신순):")
for i, snapshot in enumerate(graph.get_state_history(config)):
    msg_count = len(snapshot.values.get("messages", []))
    print(f"  [{i}] 체크포인트={snapshot.config['configurable']['checkpoint_id'][:20]}... 메시지={msg_count}")
    if i >= 4:
        print("  ... (생략)")
        break
`````)
#output-block(`````
상태 이력 (최신순):
  [0] 체크포인트=1f1196e1-c938-68ee-8... 메시지=4
  [1] 체크포인트=1f1196e1-bf0f-6ddf-8... 메시지=3
  [2] 체크포인트=1f1196e1-bf0f-6dde-8... 메시지=2
  [3] 체크포인트=1f1196e1-bf0a-6139-8... 메시지=2
  [4] 체크포인트=1f1196e1-abd9-65c9-8... 메시지=1
  ... (생략)
`````)

== 6.5 update_state() — 저장된 상태를 외부에서 수정

`update_state()`로 체크포인트에 저장된 상태를 프로그래밍 방식으로 수정할 수 있습니다.
예를 들어 시스템 노트를 추가하거나 사용자 선호도를 반영하는 작업이 가능합니다.

== 6.6 스레드 독립성 — 다른 thread_id는 완전히 독립된 상태

각 `thread_id`는 완전히 독립된 대화 상태를 가집니다.
다른 스레드의 대화 내용은 서로 영향을 주지 않습니다.

=== 6.6.5 최신 문서 기준 — Checkpointer와 Store를 분리해서 생각하기

LangGraph 최신 문서는 지속성을 _checkpointer_와 _store_로 나누어 설명합니다. 둘 다 “저장”처럼 보이지만 범위와 목적이 다릅니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[Checkpointer],
  text(weight: "bold")[Store],
  [저장 범위],
  [`thread_id` 안의 그래프 상태],
  [여러 thread가 공유하는 장기 메모리],
  [대표 용도],
  [이어 실행, time travel, 상태 조회],
  [사용자 프로필, 선호도, 지식 베이스],
  [연결 방식],
  [`graph.compile(checkpointer=...)`],
  [`graph.compile(store=...)`],
  [노드 접근],
  [`get_state()`, `get_state_history()`],
  [`runtime.store.put/search/get`],
)

따라서 “대화 한 스레드를 복원”하려면 checkpointer, “사용자 A의 선호를 다음 스레드에서도 기억”하려면 store를 사용합니다.

== 6.7 InMemoryStore — 스레드 간 공유 장기 메모리

`InMemoryStore`는 스레드 간에 공유되는 키-값 저장소입니다.
사용자 프로필, 선호도 등 스레드를 넘어 유지해야 하는 정보를 저장합니다.

- `put()`: 네임스페이스와 키로 데이터 저장
- `get()`: 특정 항목 조회
- `search()`: 네임스페이스 내 검색

#code-block(`````python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# 데이터 저장
store.put(("users",), "alice", {"favorite_color": "blue", "city": "Seoul"})
store.put(("users",), "bob", {"favorite_color": "red", "city": "Tokyo"})

# 데이터 조회
alice = store.get(("users",), "alice")
print(f"Alice: {alice.value}")

# 검색
results = store.search(("users",))
print(f"\n전체 사용자 ({len(results)}명):")
for item in results:
    print(f"  {item.key}: {item.value}")
`````)
#output-block(`````
Alice: {'favorite_color': 'blue', 'city': 'Seoul'}

전체 사용자 (2명):
  alice: {'favorite_color': 'blue', 'city': 'Seoul'}
  bob: {'favorite_color': 'red', 'city': 'Tokyo'}
`````)

=== 6.7.5 InMemoryStore를 그래프와 함께 사용하기 — `Runtime[Context]` 패턴

`compile(store=store)`로 그래프에 스토어를 연결하면 노드 함수에서 스토어에 접근할 수 있습니다.

LangGraph 1.x 권장 패턴은 _`Runtime[Context]`_ 입니다.

- `context_schema=Context`를 `StateGraph()`에 전달
- 노드 시그니처에 `runtime: Runtime[Context]` 파라미터 선언
- `runtime.context.user_id`로 타입-안전한 사용자 식별자 접근 (config dict의 `user_id` 키 대신)
- `runtime.store` (또는 `store` 파라미터)로 스토어 접근
- `runtime.store.aput(...)` / `runtime.store.asearch(...)` 비동기 메서드도 사용 가능

`graph.invoke(input, config, context=Context(user_id="..."))`로 호출 시점에 context를 주입합니다.

== 6.7.6 대화 길이 관리 — trim_messages와 RemoveMessage

대화가 길어지면 LLM의 컨텍스트 윈도우를 초과할 수 있습니다. LangGraph는 두 가지 방법으로 메시지를 관리합니다:

=== `trim_messages`
- 토큰 수 기준으로 오래된 메시지를 자동으로 잘라냅니다
- `strategy="last"`: 최근 메시지만 유지
- `start_on="human"`: 잘린 결과가 항상 사용자 메시지로 시작하도록 보장
- 원본 상태는 수정하지 않고 잘린 메시지 목록만 반환합니다 (체크포인트에는 전체 이력이 유지됨)

=== `RemoveMessage`
- 특정 메시지를 체크포인트에서 영구적으로 삭제합니다
- `MessagesState`의 리듀서가 `RemoveMessage`를 감지하여 해당 메시지를 제거합니다
- 오래된 메시지를 정리해 저장 공간을 절약할 때 유용합니다

== 6.8 Durable Execution — 실패 시 마지막 체크포인트에서 재개

체크포인터를 사용하면 _Durable Execution_이 가능합니다.
실행 중 오류가 발생해도 마지막으로 성공한 체크포인트에서 재개할 수 있습니다.
이미 완료된 노드는 다시 실행하지 않으므로 비용과 시간을 절약합니다.

아래 예제에서는 3단계 파이프라인을 구성합니다:
+ _step_1_: 데이터 수집 (항상 성공)
+ _step_2_: 데이터 분석 (항상 성공)
+ _step_3_: 외부 API 호출 (첫 번째 실행에서 실패, 재시도 시 성공)

`attempt_count`를 통해 첫 실행에서 step_3이 실패하고, 두 번째 `invoke()` 호출 시 step_1과 step_2를 건너뛰고 step_3에서만 재개되는 것을 확인합니다.

== 6.9 프로덕션 체크포인터 / 스토어 — 코드 레퍼런스

`InMemorySaver`는 데모용이며, 프로덕션에서는 DB-backed 체크포인터/스토어를 사용합니다. 모두 `from_conn_string()` 컨텍스트 매니저 패턴을 따르고, _최초 1회 `setup()`을 호출해 스키마를 생성_해야 합니다.

#note-box[아래 셀은 의존 DB가 없으면 실행하지 않습니다 — API 패턴 참고용 코드 레퍼런스입니다.]

#code-block(`````python
# =========================================================================
# 프로덕션 체크포인터 — API 레퍼런스 (실제 실행은 의존 DB가 있을 때만)
# =========================================================================
# 모든 체크포인터는 BaseCheckpointSaver 인터페이스를 구현하므로
# 그래프 측 코드는 동일하고 compile(checkpointer=...) 한 줄만 바뀝니다.

reference_code = r'''
# --- PostgreSQL (sync) ---
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()  # 최초 1회 — 스키마 생성
    graph = builder.compile(checkpointer=checkpointer)

# --- PostgreSQL (async) — 비동기 그래프 실행에 사용 ---
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver

async with AsyncPostgresSaver.from_conn_string(DB_URI) as checkpointer:
    await checkpointer.setup()
    graph = builder.compile(checkpointer=checkpointer)
    await graph.ainvoke(..., config={"configurable": {"thread_id": "1"}})

# --- MongoDB ---
from langgraph.checkpoint.mongodb import MongoDBSaver

with MongoDBSaver.from_conn_string("localhost:27017") as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)

# --- Redis ---
from langgraph.checkpoint.redis import RedisSaver

with RedisSaver.from_conn_string("redis://localhost:6379") as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)

# --- Oracle ---
from langgraph.checkpoint.oracle import OracleSaver

DB_URI = "oracle://user:password@localhost:1521/?service_name=FREEPDB1"
with OracleSaver.from_conn_string(DB_URI) as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)
'''

print(reference_code)
print("패턴 요약:")
print("  1) from_conn_string(DB_URI) 컨텍스트 매니저 진입")
print("  2) 최초 1회 setup() 호출 → 스키마/인덱스 생성")
print("  3) compile(checkpointer=...) 로 그래프에 연결")
print("  4) 동기/비동기 변형: PostgresSaver vs AsyncPostgresSaver, RedisSaver vs AsyncRedisSaver, ...")
`````)

=== 6.9.1 프로덕션 Store

`InMemoryStore`도 마찬가지로 프로덕션 구현체로 교체할 수 있습니다. `BaseStore` 인터페이스를 따르므로 노드 측 코드(`runtime.store.put/search/...`)는 그대로 둡니다.

- `PostgresStore` — `langgraph.store.postgres`
- `RedisStore` — `langgraph.store.redis`
- `OracleStore` — `langgraph.store.oracle` (vector search 내장 지원)
- `MongoDBStore` — `langgraph.store.mongodb`

#code-block(`````python
# =========================================================================
# 프로덕션 Store — API 레퍼런스
# =========================================================================
store_reference = r'''
# --- PostgresStore ---
from langgraph.store.postgres import PostgresStore

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresStore.from_conn_string(DB_URI) as store:
    store.setup()
    graph = builder.compile(store=store)

# --- RedisStore ---
from langgraph.store.redis import RedisStore

with RedisStore.from_conn_string("redis://localhost:6379") as store:
    graph = builder.compile(store=store)

# --- OracleStore (vector search 내장) ---
from langgraph.store.oracle import OracleStore

DB_URI = "oracle://user:password@localhost:1521/?service_name=FREEPDB1"
with OracleStore.from_conn_string(DB_URI) as store:
    graph = builder.compile(store=store)

# --- Semantic search 옵션 (모든 store 공통) ---
from langchain.embeddings import init_embeddings
from langgraph.store.memory import InMemoryStore

store = InMemoryStore(
    index={
        "embed": init_embeddings("openai:text-embedding-3-small"),
        "dims": 1536,
        "fields": ["food_preference", "$"],
    }
)
memories = store.search(namespace, query="What does the user like to eat?", limit=3)
'''
print(store_reference)
print("setup() 한 번이면 끝 — 이후 노드 코드는 runtime.store.put/search/aput/asearch 그대로.")
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[개념],
  text(weight: "bold")[설명],
  [_체크포인터_],
  [각 노드 실행 후 상태를 자동 저장 (`InMemorySaver` / `SqliteSaver` / `PostgresSaver` / `MongoDBSaver` / `RedisSaver` / `OracleSaver` / `CosmosDBSaver`)],
  [`get_state()`],
  [현재 스레드의 최신 체크포인트 상태 조회],
  [`get_state_history()`],
  [스레드의 전체 체크포인트 이력 조회 (최신순)],
  [`update_state()`],
  [저장된 상태를 프로그래밍 방식으로 수정],
  [_스레드 독립성_],
  [서로 다른 `thread_id`는 완전히 독립된 상태],
  [`InMemoryStore`],
  [스레드 간 공유되는 키-값 장기 메모리 저장소 (`BaseStore` 구현)],
  [_Checkpointer vs Store_],
  [thread-scoped state와 cross-thread memory를 분리 설계],
  [`compile(store=store)` + `Runtime[Context]`],
  [`context_schema`로 user_id 등을 타입-안전하게 주입, 노드에서 `runtime.context.user_id`로 namespace 구성],
  [`trim_messages`],
  [토큰 수 기준으로 오래된 메시지를 잘라내어 LLM에 전달 (체크포인트 유지)],
  [`RemoveMessage`],
  [체크포인트에서 특정 메시지를 영구적으로 삭제],
  [_Durable Execution_],
  [실패 시 마지막 성공 체크포인트에서 재개],
  [_프로덕션_],
  [`from_conn_string()` + `setup()` 패턴 — `AsyncPostgresSaver`, `OracleSaver`, `OracleStore` 등],
)
