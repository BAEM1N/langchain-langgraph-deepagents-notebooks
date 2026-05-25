// Source: 08_integration/11_provider_middleware/04_claude_memory.ipynb
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(5, "Claude Memory", subtitle: "`/memories/*` 경로 계약")

Claude 네이티브 `memory_20250818` 도구는 모델이 스스로 메모를 쓰고 다시 읽는 _장기 기억_을 구현합니다. 주입되는 시스템 프롬프트가 매 턴 "먼저 `/memories`를 확인하라"고 지시하므로, 같은 사용자와 여러 세션에 걸쳐 취향이나 사실이 자연스럽게 쌓입니다. State와 Filesystem 두 변형의 지속성 차이를 파악하는 것이 이 장의 핵심입니다.

#learning-header()
#learning-objectives(
  [Claude 메모리 도구의 `/memories/` 경로 계약을 이해한다],
  [State vs Filesystem 변형의 지속성 범위 차이를 구분한다],
  [주입되는 `system_prompt`가 모델에게 메모리 활용을 지시하는 방식을 안다],
  [Deep Agents `StoreBackend`와의 역할 분담을 정리한다],
)

== 5.1 언제 쓰나

- 같은 사용자와 _여러 세션에 걸쳐_ 취향/사실을 기억해야 하는 챗봇
- 에이전트가 장시간 작업 중 _중간 결과를 본인이 쓰고 본인이 다시 읽어야_ 하는 경우
- RAG와 달리 _모델이 직접 메모 내용을 관리_(쓰고 지우고 수정)하도록 맡기고 싶을 때

== 5.2 환경 설정

필요 패키지: `langchain`, `langchain-anthropic`. `.env`에 `ANTHROPIC_API_KEY`.

#code-block(`````python
from dotenv import load_dotenv
from langchain.agents import create_agent
from langchain_anthropic.middleware import (
    StateClaudeMemoryMiddleware,
    FilesystemClaudeMemoryMiddleware,
)
from langgraph.checkpoint.memory import MemorySaver

load_dotenv()
`````)

== 5.3 State 변형 — 스레드 내 지속

`StateClaudeMemoryMiddleware`는 메모 내용을 LangGraph 상태(`memory_files`)에 저장합니다. `MemorySaver` / `PostgresCheckpointer` 등 체크포인터를 쓰면 _같은 thread_id로 재개할 때마다_ 자동 복원됩니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`allowed_path_prefixes`],
  [`["/memories"]`],
  [메모 저장 허용 경로. 보통 그대로 둔다],
  [`system_prompt`],
  [Anthropic 기본],
  [매 턴 시작 전 "/memories를 먼저 확인하라"를 지시],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    checkpointer=MemorySaver(),
    middleware=[StateClaudeMemoryMiddleware()],
)

cfg = {"configurable": {"thread_id": "user-42"}}

agent.invoke(
    {"messages": [{"role": "user", "content": "내 이름은 지훈이야."}]},
    config=cfg,
)

# 같은 thread_id로 재호출 → 메모 재사용
result = agent.invoke(
    {"messages": [{"role": "user", "content": "내 이름 알지?"}]},
    config=cfg,
)
print(result["messages"][-1].content)
`````)

모델은 두 번째 호출에서 이름을 묻지 않고 `/memories`를 읽어 "지훈"으로 답합니다.

== 5.4 Filesystem 변형 — 프로세스 경계를 넘어

`FilesystemClaudeMemoryMiddleware`는 메모를 _실제 디스크 디렉터리_에 남깁니다. 프로세스가 종료되거나 체크포인터 저장소가 바뀌어도 디스크 파일이 있으면 그대로 다시 읽습니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[기본값],
  text(weight: "bold")[설명],
  [`root_path`],
  [(필수)],
  [메모리를 저장할 실제 디렉터리],
  [`allowed_prefixes`],
  [`["/memories"]`],
  [메모 작성 허용 가상 경로],
  [`max_file_size_mb`],
  [`10`],
  [한 메모 파일 최대 크기],
  [`system_prompt`],
  [기본 제공],
  [메모리 활용 지시 프롬프트],
)

#code-block(`````python
agent = create_agent(
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        FilesystemClaudeMemoryMiddleware(
            root_path="/var/data/claude-memory",
            max_file_size_mb=2,
        ),
    ],
)
`````)

== 5.5 영속 체크포인터로 확장

`MemorySaver`는 프로세스 내 사전(dict) 저장이므로 재시작 시 휘발됩니다. 운영 환경에서는 `langgraph-checkpoint-postgres` 또는 `-sqlite`의 컨텍스트 매니저 패턴을 씁니다 — `from_conn_string()`으로 풀을 얻고, 처음 한 번 `setup()`을 호출해 스키마를 생성합니다.

#code-block(`````python
from langgraph.checkpoint.postgres import PostgresSaver

DB = "postgresql://user:pass@localhost/agent"

with PostgresSaver.from_conn_string(DB) as checkpointer:
    checkpointer.setup()  # 최초 1회 — 테이블/인덱스 생성

    agent = create_agent(
        model="anthropic:claude-sonnet-4-6",
        checkpointer=checkpointer,
        middleware=[StateClaudeMemoryMiddleware()],
    )
`````)

#tip-box[비동기 그래프는 `AsyncPostgresSaver.from_conn_string(DB)`를 `async with`로 받습니다. `setup()`도 `await`이 필요합니다. SQLite도 동일한 컨텍스트 매니저 API(`SqliteSaver` / `AsyncSqliteSaver`)를 따릅니다.]

== 5.6 `runtime.context.user_id`로 멀티 테넌트 분리

같은 디스크 디렉터리(또는 같은 Store)를 여러 사용자가 공유할 때는 _네임스페이스_로 격리해야 합니다. LangGraph 1.2부터 `runtime.context.user_id`를 직접 읽어 Store의 namespace 키로 쓰는 패턴이 표준입니다.

#code-block(`````python
from langgraph.store.postgres import PostgresStore
from langgraph.runtime import get_runtime

with PostgresStore.from_conn_string(DB) as store:
    store.setup()

    def upsert_profile(profile: dict) -> str:
        rt = get_runtime()
        ns = ("profiles", rt.context.user_id)  # 사용자별 네임스페이스
        store.put(ns, "self", profile)
        return "ok"
`````)

#tip-box[Claude Memory Middleware의 `/memories/*` 경로 계약과 LangGraph Store의 `(namespace, key)` 계약은 _층위가 다릅니다_. 전자는 Claude가 자율적으로 메모를 관리, 후자는 코드가 명시적으로 키를 부여 — 멀티 테넌트 격리는 Store 쪽이 자연스럽습니다.]

== 5.7 Deep Agents `StoreBackend`와의 관계

Deep Agents 0.5는 영구 메모리를 위한 `StoreBackend`를 별도로 제공합니다. 역할은 비슷하지만 적용 범위가 다릅니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[축],
  text(weight: "bold")[Claude Memory Middleware],
  text(weight: "bold")[Deep Agents `StoreBackend`],
  [제공자],
  [Anthropic 네이티브 도구],
  [LangGraph Store API 래퍼],
  [지원 모델],
  [Claude 전용],
  [모든 모델],
  [저장 구조],
  [`/memories/*` 파일],
  [`(namespace, key) → dict`],
  [검색 방식],
  [파일 목록 + 내용 읽기],
  [임베딩 벡터 검색 지원],
  [적합한 용도],
  [Claude가 자유롭게 메모 관리],
  [구조화된 프로필·사실 저장],
)

*조합 팁*: 둘을 함께 써도 됩니다. Claude가 단기 작업 노트를 `/memories`에 남기고, 장기 프로필은 Deep Agents `StoreBackend`에 넣어 다른 프로바이더 에이전트와 공유하는 패턴이 현실적입니다.

== 핵심 정리

- Claude 네이티브 메모리 도구는 `/memories/*` 경로 계약 + 자동 시스템 프롬프트로 "먼저 확인, 필요 시 갱신" 흐름을 강제한다
- State 변형은 체크포인터로 thread 재개 시 복원, Filesystem 변형은 디스크에 영구 보존
- `max_file_size_mb`로 모델이 한 메모에 몰아 쓰는 것을 방지
- Deep Agents `StoreBackend`는 벡터 검색·멀티 프로바이더 공유 시 보완재
