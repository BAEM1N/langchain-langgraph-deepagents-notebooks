// Auto-generated from 06_persistence_and_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(6, "지속성과 메모리", subtitle: "체크포인터와 메모리 스토어")

5장에서 체크포인터를 사용하여 멀티턴 에이전트를 구축했습니다. 이 장에서는 체크포인터의 내부 동작을 심층적으로 탐구합니다. 에이전트가 단일 요청을 넘어 여러 턴에 걸친 대화나 장기 작업을 수행하려면, 실행 상태를 저장하고 복원하는 메커니즘이 필수입니다. `LangGraph`의 체크포인터(`Checkpointer`)는 각 슈퍼스텝(Graph API) 또는 각 태스크(Functional API) 실행 후 상태를 자동으로 스냅샷하여 장애 복구와 타임 트래블의 기반을 제공합니다.

LangGraph의 메모리 시스템은 두 가지 계층으로 구분됩니다. _단기 메모리(short-term memory)_는 체크포인터가 관리하며, 하나의 스레드(대화) 내에서 상태를 유지합니다. 동일한 `thread_id`로 요청을 보내면 이전 메시지가 자동으로 복원되는 것이 바로 단기 메모리의 동작입니다. _장기 메모리(long-term memory)_는 `InMemoryStore`가 관리하며, 스레드 경계를 넘어 사용자 프로필, 선호도 등을 저장합니다. 예를 들어, 사용자가 "나는 Python을 좋아해"라고 한 대화의 정보를 다른 대화에서도 활용할 수 있습니다. 이 장에서는 두 계층을 모두 다루며, 프로덕션 수준의 상태 관리 전략을 세워 봅니다.

#tip-box[단기 메모리와 장기 메모리의 핵심 차이를 기억하세요: 단기 메모리는 _스레드 내(within-thread)_ 상태를 유지하고, 장기 메모리는 _스레드 간(cross-thread)_ 데이터를 공유합니다. 체크포인터는 대화 이력을, `InMemoryStore`는 사용자 프로필이나 학습된 선호도를 저장하는 데 적합합니다.]

#learning-header()
체크포인터로 상태를 저장하고, 스토어로 장기 메모리를 구현합니다.

- _체크포인터_: 각 실행 단계의 상태를 자동으로 저장하고 복원
- _상태 조회_: `get_state()`와 `get_state_history()`로 저장된 상태 확인
- _상태 수정_: `update_state()`로 외부에서 상태 변경
- _스레드 독립성_: 서로 다른 `thread_id`는 완전히 독립된 상태
- _InMemoryStore_: 스레드 간 공유되는 장기 메모리 (standalone 및 그래프 연동)
- _대화 길이 관리_: `trim_messages`와 `RemoveMessage`로 메시지 관리
- _Durable Execution_: 실패 시 마지막 체크포인트에서 재개

== 6.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-5.4-mini")
`````)

== 6.2 체크포인터 --- 각 실행 단계의 상태를 자동으로 저장합니다

체크포인터는 LangGraph에서 지속성, Human-in-the-loop, 타임 트래블, 내구성 실행 등 거의 모든 고급 기능의 기반입니다. 체크포인터 없이는 그래프 실행이 끝나면 상태가 사라지지만, 체크포인터가 있으면 각 슈퍼스텝(노드 실행) 후 상태가 자동으로 스냅샷되어, 나중에 정확히 그 시점부터 재개할 수 있습니다.

LangGraph는 용도에 따라 다양한 체크포인터 구현을 제공합니다. 다음 표는 자주 쓰이는 7가지를 한눈에 비교합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[체크포인터],
  text(weight: "bold")[패키지],
  text(weight: "bold")[용도],
  [`InMemorySaver`],
  [`langgraph-checkpoint` (기본 포함)],
  [개발/테스트. 프로세스 종료 시 상태 소실],
  [`SqliteSaver`],
  [`langgraph-checkpoint-sqlite`],
  [로컬 개발. 단일 파일 영속화, async 변형 제공],
  [`PostgresSaver`],
  [`langgraph-checkpoint-postgres`],
  [프로덕션 기본값. `AsyncPostgresSaver` 비동기 지원],
  [`MongoDBSaver`],
  [`langgraph-checkpoint-mongodb`],
  [도큐먼트 DB. JSON 친화적인 스토리지 백엔드],
  [`RedisSaver`],
  [`langgraph-checkpoint-redis`],
  [인메모리 영속화. 낮은 지연, async 변형 제공],
  [`OracleSaver`],
  [`langgraph-checkpoint-oracle`],
  [엔터프라이즈 Oracle DB. 벡터 검색까지 지원],
  [`CosmosDBSaver`],
  [`langchain-azure-cosmosdb`],
  [Azure Cosmos DB. Microsoft Entra ID 인증 호환],
)

체크포인터를 `compile(checkpointer=checkpointer)`에 전달하면, 그래프의 각 노드 실행 후 자동으로 상태가 저장됩니다. 각 체크포인트는 `StateSnapshot` 객체로, 상태 값(`values`), 체크포인트 ID, 부모 체크포인트 ID, 다음 실행할 노드(`next`), 타임스탬프 등의 메타데이터를 포함합니다. 이 정보들을 통해 그래프 실행의 전체 이력을 추적하고, 특정 시점으로 돌아갈 수 있습니다.

DB 기반 체크포인터는 컨텍스트 매니저 + `setup()` 패턴으로 초기화합니다. 비동기 그래프에서는 `AsyncPostgresSaver` 같은 async 변형을 사용합니다.

#code-block(`````python
from langgraph.checkpoint.postgres import PostgresSaver

DB_URI = "postgresql://postgres:postgres@localhost:5442/postgres?sslmode=disable"
with PostgresSaver.from_conn_string(DB_URI) as checkpointer:
    checkpointer.setup()  # 최초 1회 — 스키마 생성
    graph = builder.compile(checkpointer=checkpointer)

# 비동기 그래프
from langgraph.checkpoint.postgres import AsyncPostgresSaver

checkpointer = AsyncPostgresSaver.from_conn_string(DB_URI)
await checkpointer.setup()
graph = builder.compile(checkpointer=checkpointer)
`````)

#warning-box[`InMemorySaver`는 프로세스가 종료되면 모든 상태가 사라집니다. 프로덕션 환경에서는 반드시 `PostgresSaver`(또는 `MongoDBSaver`/`RedisSaver`/`OracleSaver`)를 사용하세요. DB 기반 체크포인터는 첫 사용 시 반드시 `checkpointer.setup()`을 호출해 스키마를 생성해야 합니다.]

체크포인터를 설정했으니, 이제 저장된 상태를 조회하는 방법을 알아봅시다. LangGraph는 상태를 읽고, 이력을 추적하고, 수정하는 세 가지 핵심 API를 제공합니다.

== 6.3 get_state() — 현재 저장된 상태 조회

`get_state(config)`는 지정된 스레드의 _최신_ 체크포인트 상태를 `StateSnapshot` 객체로 반환합니다. 반환된 객체에서 `values`로 현재 상태 값을, `config`로 체크포인트 ID를, `next`로 다음에 실행할 노드 이름을 확인할 수 있습니다. `next`가 빈 튜플이면 그래프 실행이 완료된 상태입니다. 특정 체크포인트를 조회하려면 `config`에 `checkpoint_id`를 추가하면 됩니다.

아래 코드를 실행하면 저장된 상태의 핵심 정보를 확인할 수 있습니다. 특히 `checkpoint_id`는 타임 트래블이나 상태 복원에 사용되는 고유 식별자입니다.

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

현재 상태뿐 아니라 _전체 실행 이력_을 추적해야 하는 경우도 있습니다. 예를 들어, 에이전트가 어떤 단계에서 잘못된 판단을 했는지 사후 분석하거나, 특정 시점으로 되돌아가고 싶을 때가 그렇습니다.

== 6.4 get_state_history() — 전체 실행 이력 조회

`get_state_history(config)`는 해당 스레드의 _모든_ 체크포인트를 최신순으로 반환하는 제너레이터입니다. 각 체크포인트는 `StateSnapshot` 객체로, 해당 시점의 상태 값과 메타데이터를 포함합니다. 이를 통해 그래프 실행의 전체 이력을 시간순으로 추적할 수 있으며, 특정 체크포인트의 `config`를 `graph.invoke(None, config=snapshot.config)`에 전달하면 해당 시점부터 실행을 재개할 수 있습니다 --- 이것이 _타임 트래블_의 기초입니다.

아래 코드에서 출력되는 메시지 수의 변화를 관찰하세요. 메시지가 1개에서 점차 늘어나는 과정이 대화의 진행 이력을 보여줍니다.

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

상태를 조회하는 것에서 한 걸음 더 나아가, 저장된 상태를 _외부에서 수정_해야 하는 경우를 살펴봅시다.

== 6.5 update_state() --- 저장된 상태를 외부에서 수정

상태를 _읽는_ 것만으로는 부족한 경우가 있습니다. 에이전트가 잘못된 판단을 했을 때 외부에서 상태를 교정하거나, Human-in-the-loop 패턴에서 사람의 승인이나 입력을 상태에 반영해야 할 때 `update_state()`를 사용합니다.

`update_state(config, values)`를 호출하면 체크포인트에 저장된 상태를 프로그래밍 방식으로 수정할 수 있습니다. 이때 중요한 점은, 리듀서가 설정된 채널(예: `MessagesState`의 `messages`)은 값이 _병합(merge)_되고, 리듀서가 없는 채널은 값이 _덮어쓰기(overwrite)_된다는 것입니다. 예를 들어, 시스템 노트 메시지를 추가하거나, 사용자 선호도를 반영하거나, 에이전트의 잘못된 도구 호출 결과를 올바른 값으로 교체하는 등의 작업이 가능합니다.

수정된 상태는 _새로운 체크포인트_로 저장되므로, 원본 체크포인트는 변경되지 않습니다. 이 불변성(immutability) 덕분에 언제든 이전 상태로 되돌아갈 수 있습니다. 또한 `as_node` 파라미터를 지정하면, 수정 후 어떤 노드가 다음에 실행될지를 제어할 수 있습니다.

#tip-box[`update_state()`는 8장에서 다룰 Human-in-the-loop 패턴의 핵심 도구입니다. 에이전트가 `interrupt()`로 멈춘 뒤, 사람이 상태를 검토하고 `update_state()`로 수정한 다음, `Command(resume=...)`로 실행을 재개하는 흐름이 전형적인 패턴입니다.]

상태를 조회하고 수정하는 API를 익혔으니, 스레드 간의 관계를 명확히 이해할 차례입니다.

== 6.6 스레드 독립성 — 다른 thread_id는 완전히 독립된 상태

각 `thread_id`는 완전히 독립된 대화 상태를 가집니다. `thread_id="session-1"`과 `thread_id="session-2"`는 서로 다른 체크포인트 이력을 가지며, 한쪽 스레드의 메시지를 수정하거나 삭제해도 다른 스레드에는 영향을 주지 않습니다. 이 독립성 덕분에 하나의 그래프 인스턴스로 여러 사용자의 동시 대화를 안전하게 처리할 수 있습니다. 다만, 스레드 간에 정보를 _공유_해야 하는 경우(예: 사용자 프로필, 선호도)에는 다음 절에서 다루는 `InMemoryStore`를 사용해야 합니다.

스레드 독립성은 대화 격리에 유용하지만, 때로는 스레드 경계를 넘어 정보를 공유해야 합니다. 이것이 장기 메모리의 역할입니다.

== 6.7 InMemoryStore --- 스레드 간 공유 장기 메모리

체크포인터가 _하나의 스레드 안에서_ 상태를 유지하는 반면, `InMemoryStore`는 _스레드 경계를 넘어_ 데이터를 공유합니다. 예를 들어, 한 사용자가 여러 대화 스레드를 열더라도 "좋아하는 색상"이나 "프로그래밍 언어 선호도" 같은 정보는 모든 스레드에서 공유되어야 합니다. 체크포인터만으로는 이런 교차 스레드 데이터 공유가 불가능하므로, `InMemoryStore`라는 별도의 저장소가 필요합니다.

`InMemoryStore`는 _네임스페이스(namespace)_ 기반의 키-값 저장소로, 데이터를 계층적으로 조직합니다. 네임스페이스는 튜플 형태(예: `("users",)`, `("user_123", "memories")`)로 표현되며, 파일 시스템의 디렉터리 구조와 유사하게 데이터를 분류합니다. 저장된 각 항목은 `value`(실제 데이터), `key`(고유 식별자), `namespace`, `created_at`, `updated_at` 속성을 가집니다.

핵심 API는 다음 세 가지입니다:

- `put(namespace, key, value)`: 네임스페이스와 키로 데이터를 저장합니다. 동일한 키에 다시 `put()`하면 기존 값이 업데이트됩니다
- `get(namespace, key)`: 특정 항목을 조회합니다. 존재하지 않으면 `None`을 반환합니다
- `search(namespace)`: 네임스페이스 내 항목을 검색합니다. `query` 파라미터를 전달하면 시맨틱 검색도 가능합니다

#tip-box[`InMemoryStore`는 `index` 설정을 통해 임베딩 기반 _시맨틱 검색_도 지원합니다. `InMemoryStore(index={"embed": init_embeddings("openai:text-embedding-3-small"), "dims": 1536, "fields": ["food_preference", "$"]})` 형태로 초기화한 뒤, `store.search(namespace, query="...")` 형태로 호출하면 저장된 데이터 중 의미적으로 유사한 항목을 찾을 수 있습니다. `fields`로 임베딩 대상 키를 제한하거나, `put(..., index=False)`로 특정 항목의 임베딩을 건너뛸 수 있습니다. 프로덕션에서는 `PostgresStore`/`RedisStore`/`OracleStore`로 교체해 영속성을 확보하세요.]

=== Context와 Runtime --- 노드에서 사용자 식별자와 스토어 접근

장기 메모리를 _사용자별로_ 분리하려면 노드 함수가 현재 사용자의 ID를 알아야 합니다. LangGraph는 `@dataclass`로 정의한 `Context`를 `StateGraph(..., context_schema=Context)`로 등록하고, 노드 시그니처에 `runtime: Runtime[Context]`를 선언하는 방식으로 이를 해결합니다. `graph.invoke(...)` 호출 시 `context=Context(user_id=...)`를 전달하면, 노드 안에서 `runtime.context.user_id`로 접근할 수 있고, 동일한 runtime 객체에서 `runtime.store`로 스토어까지 자연스럽게 사용할 수 있습니다.

#code-block(`````python
import uuid
from dataclasses import dataclass
from langgraph.runtime import Runtime
from langgraph.graph import StateGraph, MessagesState, START

@dataclass
class Context:
    user_id: str

async def call_model(state: MessagesState, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    namespace = (user_id, "memories")  # docs 권장 형식

    memories = await runtime.store.asearch(
        namespace, query=state["messages"][-1].content, limit=3
    )
    await runtime.store.aput(
        namespace, str(uuid.uuid4()), {"data": "User prefers dark mode"}
    )
    return {"messages": [await model.ainvoke(state["messages"])]}

builder = StateGraph(MessagesState, context_schema=Context)
builder.add_node(call_model)
builder.add_edge(START, "call_model")
graph = builder.compile(checkpointer=checkpointer, store=store)

graph.invoke(
    {"messages": [{"role": "user", "content": "hi"}]},
    {"configurable": {"thread_id": "1"}},
    context=Context(user_id="alice"),
)
`````)

#tip-box[네임스페이스는 튜플 어떤 형태든 가능하지만, 공식 문서는 `(user_id, "memories")` 패턴을 권장합니다. 사용자별로 1차 분리하고, 두 번째 원소로 메모리 종류(`"memories"`, `"preferences"` 등)를 구분하면 `search`로 카테고리별 조회가 쉬워집니다.]

프로덕션 스토어는 체크포인터와 동일하게 컨텍스트 매니저로 사용합니다.

#code-block(`````python
from langgraph.store.postgres import PostgresStore

with PostgresStore.from_conn_string(DB_URI) as store:
    store.setup()
    graph = builder.compile(checkpointer=checkpointer, store=store)

# Redis / Oracle 도 동일 패턴
from langgraph.store.redis import RedisStore
from langgraph.store.oracle import OracleStore  # 벡터 검색 기본 지원
`````)

아래 코드에서는 `InMemoryStore`의 기본 CRUD 연산을 실습합니다. 네임스페이스로 사용자 데이터를 분류하고, `put()`, `get()`, `search()`로 데이터를 관리하는 패턴을 확인하세요.

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

독립적으로 `InMemoryStore`를 사용하는 방법을 배웠으니, 이제 그래프 노드 안에서 스토어에 접근하는 방법을 알아봅시다.

=== 6.7.5 InMemoryStore를 그래프와 함께 사용하기

`InMemoryStore`를 `compile(store=store)`로 그래프에 전달하면, 각 노드 함수에서 `store` 파라미터를 통해 스토어에 직접 접근할 수 있습니다. LangGraph의 의존성 주입 메커니즘이 노드 함수의 시그니처를 분석하여, `store`라는 이름의 파라미터가 있으면 자동으로 스토어 인스턴스를 전달합니다.

이 패턴을 사용하면 노드 안에서 사용자 정보를 저장하고 조회하여, 스레드를 넘어 장기 메모리를 유지할 수 있습니다. 예를 들어, 에이전트가 대화 중 파악한 사용자 선호도를 저장하면, 나중에 다른 대화에서도 그 정보를 활용할 수 있습니다.

- `compile(checkpointer=checkpointer, store=store)`: 그래프에 체크포인터와 스토어를 모두 연결합니다. 단기 메모리와 장기 메모리를 동시에 활용하는 전형적인 패턴입니다
- 노드 함수에 `store` 파라미터 추가: LangGraph가 자동으로 스토어 인스턴스를 주입합니다
- `config["configurable"]["user_id"]`로 사용자별 네임스페이스를 분리하여, 각 사용자의 데이터가 섞이지 않도록 합니다

#warning-box[`InMemoryStore`도 `InMemorySaver`와 마찬가지로 메모리 기반이므로, 프로세스 종료 시 모든 데이터가 사라집니다. 프로덕션에서는 `PostgresStore`(`pip install langgraph-checkpoint-postgres`)나 `RedisStore`(`pip install langgraph-checkpoint-redis`)를 사용하세요.]

체크포인터와 스토어로 메모리 시스템의 전체 구조를 파악했습니다. 하지만 실제 서비스에서는 대화가 수십, 수백 턴으로 길어질 수 있습니다. 이런 상황에 대비한 메시지 관리 전략을 살펴봅시다.

== 6.7.6 대화 길이 관리 — trim_messages와 RemoveMessage

대화가 길어지면 LLM의 컨텍스트 윈도우를 초과하여 오류가 발생하거나, 비용이 급증할 수 있습니다. LangGraph는 이 문제를 해결하기 위해 두 가지 상호 보완적인 방법을 제공합니다. `trim_messages`는 LLM에 _전달할_ 메시지를 줄이고, `RemoveMessage`는 체크포인트에서 메시지를 _영구 삭제_합니다.

=== `trim_messages`
- `langchain_core.messages.utils`에서 제공하는 유틸리티 함수로, 토큰 수 기준으로 오래된 메시지를 자동으로 잘라냅니다
- `strategy="last"`: 최근 메시지만 유지하여 지정된 `max_tokens` 이내로 메시지 목록을 줄입니다
- `start_on="human"`: 잘린 결과가 항상 사용자 메시지로 시작하도록 보장합니다. AI 메시지로 시작하면 LLM이 혼란스러워할 수 있기 때문입니다
- _핵심_: 원본 상태는 수정하지 않고, 잘린 메시지 목록만 반환합니다. 체크포인트에는 전체 이력이 그대로 유지되므로, 필요 시 과거 대화를 복원할 수 있습니다

=== `RemoveMessage`
- `langchain.messages`에서 제공하는 특수 메시지 타입으로, 특정 메시지를 체크포인트에서 _영구적으로_ 삭제합니다
- `MessagesState`의 리듀서가 `RemoveMessage`를 감지하여 해당 ID의 메시지를 제거합니다
- 오래된 메시지를 정리하여 저장 공간을 절약하거나, 민감한 정보가 포함된 메시지를 삭제할 때 유용합니다
- `RemoveMessage(id=REMOVE_ALL_MESSAGES)`를 사용하면 모든 메시지를 한 번에 삭제할 수도 있습니다

#tip-box[`trim_messages`와 `RemoveMessage`는 상호 보완적입니다. 일반적으로 `trim_messages`로 LLM에 전달하는 메시지를 줄이되 체크포인트는 유지하고, 저장 공간이 문제되거나 개인정보 삭제가 필요한 경우에만 `RemoveMessage`로 영구 삭제하는 전략을 권장합니다.]

== 6.8 Durable Execution --- 실패 시 마지막 체크포인트에서 재개

체크포인터와 메모리 관리를 모두 살펴보았으니, 이제 체크포인터가 제공하는 또 하나의 핵심 기능인 _내구성 실행(Durable Execution)_을 알아봅시다. 내구성 실행이란, 워크플로가 실행 중 핵심 지점마다 진행 상태를 저장하여, 실패하거나 중단되더라도 마지막으로 성공한 체크포인트에서 정확히 재개할 수 있는 기법입니다.

이 기능이 중요한 이유는 실무에서 외부 API 호출, 네트워크 요청 등은 언제든 실패할 수 있기 때문입니다. 체크포인터를 사용하면 이미 완료된 노드를 다시 실행하지 않으므로 비용과 시간을 절약합니다. 특히 LLM 호출은 비용이 높으므로, 불필요한 재실행을 방지하는 것이 경제적으로도 중요합니다.

LangGraph는 세 가지 내구성 모드를 제공합니다:
- `"exit"`: 그래프가 완료/오류/인터럽트될 때만 체크포인트를 저장합니다. 성능이 가장 좋지만, 중간 단계에서의 복구가 불가능합니다
- `"async"`: 다음 노드를 실행하면서 비동기로 체크포인트를 저장합니다. 성능과 안전성의 균형을 잡지만, 비동기 저장 중 크래시가 발생하면 데이터 손실 위험이 있습니다
- `"sync"`: 다음 노드를 실행하기 _전에_ 동기적으로 체크포인트를 저장합니다. 최대한의 안전성을 제공하지만, 저장 지연으로 인해 성능이 저하될 수 있습니다

아래 예제에서는 3단계 파이프라인을 구성합니다:
+ _step_1_: 데이터 수집 (항상 성공)
+ _step_2_: 데이터 분석 (항상 성공)
+ _step_3_: 외부 API 호출 (첫 번째 실행에서 실패, 재시도 시 성공)

`attempt_count`를 통해 첫 실행에서 step_3이 실패하고, 두 번째 `invoke()` 호출 시 step_1과 step_2를 건너뛰고 step_3에서만 재개되는 것을 확인합니다. 이것이 내구성 실행의 핵심 가치입니다 --- 이미 성공한 작업은 반복하지 않습니다.

#warning-box[내구성 실행을 위해서는 각 노드(Graph API)나 태스크(Functional API)가 _멱등성(idempotency)_을 가지는 것이 이상적입니다. 같은 입력으로 여러 번 실행해도 동일한 결과를 내야 재시도 시 부작용이 발생하지 않습니다. 예를 들어, 데이터베이스에 레코드를 삽입하는 노드는 중복 삽입을 방지하는 로직이 필요합니다. 이 주제는 12장에서 더 깊이 다룹니다.]

이 장에서 LangGraph의 지속성과 메모리 시스템 전체를 다루었습니다. 체크포인터를 통한 단기 메모리, `InMemoryStore`를 통한 장기 메모리, `trim_messages`와 `RemoveMessage`를 통한 대화 길이 관리, 그리고 내구성 실행을 통한 장애 복구까지 --- 프로덕션 에이전트의 상태 관리에 필요한 모든 도구를 갖추었습니다.

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
  [각 노드 실행 후 상태를 자동 저장 (`InMemorySaver`, `SqliteSaver`, `PostgresSaver`)],
  [`get_state()`],
  [현재 스레드의 최신 체크포인트 상태 조회],
  [`get_state_history()`],
  [스레드의 전체 체크포인트 이력 조회 (최신순)],
  [`update_state()`],
  [저장된 상태를 프로그래밍 방식으로 수정],
  [_스레드 독립성_],
  [서로 다른 `thread_id`는 완전히 독립된 상태],
  [`InMemoryStore`],
  [스레드 간 공유되는 키-값 장기 메모리 저장소],
  [`compile(store=store)`],
  [그래프 노드에서 `store` 파라미터로 장기 메모리 접근],
  [`trim_messages`],
  [토큰 수 기준으로 오래된 메시지를 잘라내어 LLM에 전달 (체크포인트 유지)],
  [`RemoveMessage`],
  [체크포인트에서 특정 메시지를 영구적으로 삭제],
  [_Durable Execution_],
  [실패 시 마지막 성공 체크포인트에서 재개],
)

#next-step-box[다음 장에서는 에이전트 실행 과정을 _실시간으로 관찰_하는 스트리밍을 다룹니다. `values`, `updates`, `messages`, `custom`, `debug` 다섯 가지 모드의 차이와 적합한 사용 사례를 익힙니다.]

#chapter-end()
