// Auto-generated from 04_context_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "컨텍스트 엔지니어링 & 메모리 심화", subtitle: "- Static/Dynamic Context, InMemoryStore, Skills 패턴")

LangGraph의 컨텍스트 시스템과 장기 메모리(Store)를 심층 학습합니다. 정적/동적 런타임 컨텍스트부터 시맨틱 검색 기반 장기 메모리, 그리고 Progressive Disclosure(Skills) 패턴까지 다룹니다.

== 학습 목표
#learning-objectives([컨텍스트 엔지니어링의 2차원(Mutability x Lifetime) 매트릭스를 이해한다], [`context_schema` + `@dataclass`로 정적 런타임 컨텍스트를 구현한다], [`state_schema`와 `AgentState` 커스텀으로 동적 런타임 컨텍스트를 관리한다], [`InMemoryStore`의 namespace, put, get, search API를 활용한다], [시맨틱 검색 기반 장기 메모리를 구축한다], [메모리 3유형(Semantic, Episodic, Procedural)을 구분하여 설계한다], [Skills 패턴으로 Progressive Disclosure를 구현한다], [Hot path vs Background 메모리 쓰기 전략을 비교한다])

== 4.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

model = ChatOpenAI(model="gpt-5.4")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

== 4.2 컨텍스트 엔지니어링 개요

컨텍스트 엔지니어링은 _"올바른 정보를, 올바른 형식으로, 올바른 시점에"_ AI에 제공하는 시스템 설계입니다. 단순한 프롬프트 엔지니어링을 넘어, 컨텍스트를 _런타임에 프로그래밍 방식으로 조립_하는 아키텍처적 접근입니다.

에이전트가 실패하는 주된 원인은 두 가지입니다:
+ LLM 능력 부족
+ _컨텍스트 부족 또는 부적절한 컨텍스트_ (더 빈번한 원인)

따라서 컨텍스트 엔지니어링은 AI 엔지니어의 핵심 역할이며, 에이전트 신뢰성의 근본적인 해결책입니다.

=== 2차원 매트릭스: Mutability x Lifetime

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[_Static_ (불변)],
  text(weight: "bold")[User ID, DB 연결, 도구 정의],
  text(weight: "bold")[설정 파일 등],
  [_Dynamic_ (가변)],
  [대화 히스토리, 중간 결과],
  [사용자 선호도, 학습된 메모리],
)

=== 3가지 컨텍스트 타입

#table(
  columns: 5,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[타입],
  text(weight: "bold")[Mutability],
  text(weight: "bold")[Lifetime],
  text(weight: "bold")[예시],
  text(weight: "bold")[LangGraph 구현],
  [Static Runtime],
  [Static],
  [Single run],
  [User ID, DB conn],
  [`context_schema`],
  [Dynamic Runtime (State)],
  [Dynamic],
  [Single run],
  [Messages, 중간결과],
  [`state_schema`],
  [Dynamic Cross-conv (Store)],
  [Dynamic],
  [Cross-conversation],
  [선호도, 메모리],
  [`InMemoryStore`],
)

=== 제어 가능한 3가지 컨텍스트 카테고리

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[카테고리],
  text(weight: "bold")[제어 대상],
  text(weight: "bold")[특성],
  [_Model Context_],
  [Instructions, 메시지 히스토리, 도구, 응답 형식],
  [Transient (일시적)],
  [_Tool Context_],
  [도구 접근, 상태 읽기/쓰기, 런타임 컨텍스트],
  [Persistent (영구적)],
  [_Life-cycle Context_],
  [단계 간 변환, 요약, 가드레일],
  [Persistent (영구적)],
)

LangChain은 _미들웨어(middleware)_ 메커니즘으로 컨텍스트 엔지니어링을 구현합니다. `@dynamic_prompt`, `@wrap_model_call` 등의 미들웨어로 컨텍스트를 업데이트하거나 라이프사이클 단계 간 제어를 할 수 있습니다.

== 4.3 정적 런타임 컨텍스트 -- `context_schema` + `\@dataclass`

에이전트 실행 중 _변하지 않는_ 정보를 `context_schema`로 주입합니다. `@dataclass`로 스키마를 정의하고, 도구에서 `ToolRuntime[Context]`로 접근합니다.

#code-block(`````python
from dataclasses import dataclass
from langchain.tools import tool, ToolRuntime
from langchain.agents import create_agent

@dataclass
class UserContext:
    user_id: str
    role: str
    department: str
`````)

#code-block(`````python
@tool
def get_permissions(runtime: ToolRuntime[UserContext]) -> str:
    """현재 사용자의 역할에 따른 권한을 조회합니다."""
    ctx = runtime.context
    perms = {"admin": "read,write,delete", "editor": "read,write"}
    return f"사용자 {ctx.user_id} ({ctx.department}): {perms.get(ctx.role, 'read')}"
`````)

=== 핵심 포인트

- `context_schema`에 `@dataclass`를 전달하면 타입 안전한 컨텍스트를 사용할 수 있습니다
- 도구 함수에서 `runtime: ToolRuntime[Context]` 타입힌트로 자동 주입됩니다
- 실행 중에는 _읽기 전용_이며 변경되지 않습니다
- 적합한 데이터: User ID, DB 연결, API 키, 세션 메타데이터

== 4.4 동적 런타임 컨텍스트 -- `state_schema`, `AgentState` 커스텀

에이전트가 메시지를 처리하고 도구를 호출하면서 _변화하는_ 상태입니다. `AgentState`를 상속하여 커스텀 필드를 추가합니다.

#code-block(`````python
from langchain.agents import AgentState

class RAGState(AgentState):
    """동적 검색 컨텍스트를 포함한 상태."""
    retrieved_docs: list[str]
    query_count: int

print(f"상태 키: {list(RAGState.__annotations__.keys())}")
`````)
#output-block(`````
상태 키: ['messages', 'jump_to', 'structured_response', 'retrieved_docs', 'query_count']
`````)

=== Static vs Dynamic 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[구분],
  text(weight: "bold")[Static Runtime (`context_schema`)],
  text(weight: "bold")[Dynamic Runtime (`state_schema`)],
  [변경 여부],
  [불변 (읽기 전용)],
  [가변 (노드가 업데이트)],
  [전달 방식],
  [`context=` 파라미터],
  [invoke 입력 dict],
  [접근 방법],
  [`runtime.context.field`],
  [`state["field"]`],
  [적합한 데이터],
  [인증 정보, 설정],
  [대화 히스토리, 중간 결과],
)

== 4.4b 런타임 메타데이터 -- `runtime.execution_info` / `runtime.server_info`

`ToolRuntime` 은 `context` / `store` 외에 실행 추적용 두 채널을 노출합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[채널],
  text(weight: "bold")[설명],
  text(weight: "bold")[주요 필드],
  [`runtime.execution_info`],
  [현재 run 의 identity 와 retry 정보],
  [`thread_id`, `run_id`, `attempt`],
  [`runtime.server_info`],
  [LangGraph Server 위에서 실행 중일 때만 채워지는 메타데이터 (로컬은 `None`)],
  [`assistant_id`, `graph_id`, `user.identity`],
)

#tip-box[두 채널은 `deepagents>=0.5.0` 또는 `langgraph>=1.1.5` 가 필요합니다. 도구·미들웨어 양쪽 구현에 동일하게 적용됩니다.]

#code-block(`````python
# execution_info / server_info 노출 패턴
@tool
def whoami(runtime: ToolRuntime[UserContext]) -> str:
    """현재 run 의 identity 와 서버 메타데이터를 한 줄로 요약."""
    info = runtime.execution_info
    parts = [
        f"thread={info.thread_id}",
        f"run={info.run_id}",
        f"attempt={info.attempt}",
    ]
    server = runtime.server_info
    if server is not None:
        parts.append(f"assistant={server.assistant_id}")
        parts.append(f"graph={server.graph_id}")
        if server.user is not None:
            parts.append(f"user={server.user.identity}")
    else:
        parts.append("env=local")
    return " | ".join(parts)
`````)

== 4.5 장기 메모리 -- InMemoryStore 기본 API

Cross-conversation 컨텍스트를 위해 `InMemoryStore`를 사용합니다. 장기 메모리는 세션과 스레드를 초월하여 지속되는 사용자별 또는 앱 수준의 데이터입니다.

=== 저장 구조
메모리는 _JSON 문서_ 형태로 저장되며, 계층적 _namespace_로 조직화됩니다:
- _namespace_: 메모리를 분류하는 폴더 역할 (예: `(user_id, "preferences")`)
- _key_: 각 메모리의 고유 식별자 (예: `"theme"`)
- 네임스페이스에는 보통 사용자 ID나 조직 ID를 포함하여 정보 관리를 용이하게 합니다

=== 기본 API
#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[API],
  text(weight: "bold")[설명],
  [`store.put(namespace, key, value)`],
  [메모리 저장 (upsert)],
  [`store.get(namespace, key)`],
  [특정 키로 메모리 조회],
  [`store.search(namespace)`],
  [네임스페이스 내 전체 검색],
  [`store.search(namespace, filter={...})`],
  [필터 조건으로 검색],
)

프로덕션 환경에서는 `InMemoryStore` 대신 _DB 기반 Store_ (예: PostgreSQL)를 사용해야 합니다.

#code-block(`````python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()
user_id = "user_42"
store.put((user_id, "preferences"), "theme", {"value": "dark"})
store.put((user_id, "preferences"), "language", {"value": "ko"})

item = store.get((user_id, "preferences"), "theme")
print(f"테마: {item.value}")
`````)
#output-block(`````
테마: {'value': 'dark'}
`````)

#code-block(`````python
items = store.search((user_id, "preferences"))
for item in items:
    print(f"  [{item.key}] = {item.value}")

filtered = store.search(
    (user_id, "preferences"), filter={"value": "dark"}
)
print(f"필터 결과: {len(filtered)}건")
`````)
#output-block(`````
[theme] = {'value': 'dark'}
  [language] = {'value': 'ko'}
필터 결과: 1건
`````)

== 4.6 장기 메모리 -- 시맨틱 검색

임베딩 함수를 설정하면 `InMemoryStore`가 _시맨틱 검색_을 지원합니다. `query` 파라미터로 의미 기반 유사도 검색을 수행합니다.

#code-block(`````python
semantic_store = InMemoryStore(
    index={"embed": embeddings, "dims": 1536}
)
ns = ("user_42", "memories")
semantic_store.put(ns, "mem1", {"content": "pytest를 unittest보다 선호"})
semantic_store.put(ns, "mem2", {"content": "모든 함수에 타입 힌트 사용"})
semantic_store.put(ns, "mem3", {"content": "좋아하는 음식은 초밥"})
semantic_store.put(ns, "mem4", {"content": "ML 인프라 팀에서 근무"})
print("임베딩과 함께 메모리 4개 저장 완료.")
`````)
#output-block(`````
임베딩과 함께 메모리 4개 저장 완료.
`````)

#code-block(`````python
results = semantic_store.search(
    ("user_42", "memories"), query="testing preferences", limit=2
)
for r in results:
    print(f"  [{r.key}] {r.value['content']}")
`````)
#output-block(`````
[mem1] pytest를 unittest보다 선호
  [mem2] 모든 함수에 타입 힌트 사용
`````)

#code-block(`````python
results2 = semantic_store.search(
    ("user_42", "memories"), query="machine learning work", limit=2
)
for r in results2:
    print(f"  [{r.key}] {r.value['content']}")
`````)
#output-block(`````
[mem4] ML 인프라 팀에서 근무
  [mem2] 모든 함수에 타입 힌트 사용
`````)

=== 기본 Store vs 시맨틱 Store 비교

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[기능],
  text(weight: "bold")[`InMemoryStore()`],
  text(weight: "bold")[`InMemoryStore(index={...})`],
  [정확 키 조회],
  [`get(ns, key)`],
  [`get(ns, key)`],
  [필터 검색],
  [`search(ns, filter={...})`],
  [`search(ns, filter={...})`],
  [시맨틱 검색],
  [불가],
  [`search(ns, query="...", limit=N)`],
  [프로덕션],
  [`InMemoryStore` 대신 DB 백엔드 사용],
  [PostgreSQL 기반 Store 권장],
)

== 4.7 도구에서 Store 읽기/쓰기 -- `ToolRuntime.store`

에이전트의 도구 내에서 Store에 접근하여 사용자 정보를 읽고 쓸 수 있습니다. `create_agent(store=...)`로 Store를 연결하면 `runtime.store`로 자동 주입됩니다.

=== 읽기 패턴
도구에서 `runtime.store`를 통해 저장된 사용자 정보를 조회합니다. `ToolRuntime[Context]` 타입힌트로 컨텍스트와 Store 모두에 접근할 수 있습니다.

=== 쓰기 패턴
도구 파라미터로 사용자 입력을 받아 `store.put()`으로 메모리를 저장합니다. 에이전트가 대화 중 학습한 정보를 영구 저장하는 방식입니다.

=== 핵심 사항
- `runtime.store`: Store 인스턴스에 접근
- `runtime.context`: 정적 런타임 컨텍스트에 접근
- Store와 Context를 결합하면 _"누구의(context) 어떤 정보(store)"_를 체계적으로 관리할 수 있습니다

#code-block(`````python
@tool
def get_user_info(runtime: ToolRuntime[UserContext]) -> str:
    """현재 사용자의 저장된 정보를 조회합니다."""
    store = runtime.store
    user_id = runtime.context.user_id
    info = store.get(("users",), user_id)
    return str(info.value) if info else "사용자 정보를 찾을 수 없습니다."
`````)

#code-block(`````python
@tool
def save_preference(key: str, value: str, runtime: ToolRuntime[UserContext]) -> str:
    """사용자 선호도를 저장합니다."""
    store = runtime.store
    user_id = runtime.context.user_id
    store.put((user_id, "preferences"), key, {"value": value})
    return f"선호도 저장됨: {key}={value}"
`````)

#code-block(`````python
# TypedDict 입력을 store 에 저장할 때 dict() 캐스트 — runtime.context.user_id 를 namespace 에 사용
from typing_extensions import TypedDict

class UserInfo(TypedDict):
    name: str
    language: str

@tool
def save_user_info(user_info: UserInfo, runtime: ToolRuntime[UserContext]) -> str:
    """사용자 프로필을 저장합니다. TypedDict → dict 캐스트 필수."""
    assert runtime.store is not None
    runtime.store.put(("users",), runtime.context.user_id, dict(user_info))
    return f"saved user_info for {runtime.context.user_id}"

@tool
def get_user_info_typed(runtime: ToolRuntime[UserContext]) -> str:
    """저장된 프로필을 조회합니다."""
    assert runtime.store is not None
    item = runtime.store.get(("users",), runtime.context.user_id)
    return str(item.value) if item else "Unknown user"
`````)

== 4.8 메모리 3유형: Semantic, Episodic, Procedural

장기 메모리는 인지과학에서 영감을 받은 세 가지 유형으로 분류됩니다. 각 유형에 따라 _저장 구조_와 _활용 방식_이 다릅니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[유형],
  text(weight: "bold")[설명],
  text(weight: "bold")[예시],
  text(weight: "bold")[구조],
  [_Semantic_],
  [엔티티에 대한 사실적 지식],
  [사용자 선호도, 프로필 정보],
  [Profile 또는 Collection],
  [_Episodic_],
  [과거 경험과 이벤트 기억],
  [Few-shot 예시, 과거 액션 로그],
  [Collection],
  [_Procedural_],
  [수행 방법에 대한 규칙/지침],
  [시스템 프롬프트 수정, 가이드라인],
  [Profile (규칙 목록)],
)

=== Semantic Memory -- Profile vs Collection

Semantic 메모리는 저장 전략에 따라 두 가지 접근법이 있습니다:

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[접근법],
  text(weight: "bold")[구조],
  text(weight: "bold")[적합한 경우],
  text(weight: "bold")[예시],
  [_Profile_],
  [단일 JSON 문서, 지속 업데이트],
  [소수의 잘 알려진 속성],
  [`{"name": "Alice", "language": "Python", "preferred_style": "concise"}`],
  [_Collection_],
  [다수의 좁은 범위 문서, 높은 리콜],
  [오픈엔드 또는 대규모 지식],
  [`[{"topic": "testing", "content": "Prefers pytest"}, ...]`],
)

=== Episodic Memory
과거에 유사한 상황에서 어떻게 행동했는지를 기록합니다. Few-shot 예시로 활용되어 에이전트가 과거 경험에서 학습할 수 있게 합니다.

=== Procedural Memory
에이전트의 행동 규칙을 저장합니다. 시스템 프롬프트를 동적으로 수정하는 효과를 가져, 에이전트가 사용자별 맞춤 지침을 따르도록 합니다.

#code-block(`````python
mem_store = InMemoryStore(index={"embed": embeddings, "dims": 1536})
uid = "user_42"

# Semantic -- Profile (single JSON)
mem_store.put((uid, "profile"), "main", {
    "name": "Alice", "language": "Python",
    "preferred_style": "concise",
})
# Semantic -- Collection (multiple docs)
mem_store.put((uid, "facts"), "f1", {"content": "pytest 선호"})
`````)

#code-block(`````python
# Episodic -- past experiences (few-shot)
mem_store.put((uid, "episodes"), "ep1", {
    "content": "SQL 최적화 -> EXPLAIN ANALYZE 사용",
})

# Procedural -- rules/guidelines
mem_store.put((uid, "procedures"), "rules", {
    "content": "항상 에러 처리를 포함. logging 사용.",
})
print("3가지 메모리 유형 모두 저장 완료.")
`````)
#output-block(`````
3가지 메모리 유형 모두 저장 완료.
`````)

#code-block(`````python
# Episodic search: find similar past experiences
episodes = mem_store.search(
    (uid, "episodes"), query="database query help", limit=1
)
for ep in episodes:
    print(f"관련 에피소드: {ep.value['content']}")
`````)
#output-block(`````
관련 에피소드: SQL 최적화 -> EXPLAIN ANALYZE 사용
`````)

== 4.9 Progressive Disclosure -- Skills 패턴

모든 컨텍스트를 프롬프트에 넣으면 토큰 비용이 늘고 정확도가 떨어집니다. Skills 패턴은 _필요할 때만 관련 정보를 로드_하는 Progressive Disclosure 방식입니다.

=== Skill의 구조
Skill은 `{name, description, content}`로 구성된 지식 단위입니다:
- _name_: 스킬 식별자 (예: `"customers_schema"`)
- _description_: 짧은 설명 (시스템 프롬프트에 포함됨)
- _content_: 상세 내용 (`load_skill` 도구로 온디맨드 로드)

=== 크기별 전략

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[크기],
  text(weight: "bold")[전략],
  text(weight: "bold")[예시],
  [_\\\<1K tokens_],
  [시스템 프롬프트에 직접 포함],
  [테이블 이름, 고수준 관계],
  [_1-10K tokens_],
  [`load_skill` 도구로 온디맨드 로드],
  [테이블 스키마, 쿼리 패턴, 베스트 프랙티스],
  [_\\\>10K tokens_],
  [페이지네이션으로 온디맨드 로드],
  [대규모 참조 데이터, 과거 쿼리 로그],
)

=== 동작 흐름
+ _미들웨어_가 모든 스킬의 이름과 설명을 시스템 프롬프트에 주입
+ 에이전트가 질문을 분석하고 필요한 스킬을 판단
+ `load_skill` 도구를 호출하여 상세 내용을 로드
+ 로드된 내용을 바탕으로 작업 수행

=== 장점

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[장점],
  text(weight: "bold")[설명],
  [_토큰 효율성_],
  [현재 쿼리에 필요한 정보만 로드],
  [_확장성_],
  [수백 개의 테이블이 있는 DB도 지원],
  [_정확도_],
  [필요한 시점에 상세 스키마를 제공],
  [_비용 절감_],
  [요청당 입력 토큰 감소],
)

#code-block(`````python
skills = [
    {"name": "db_overview",
     "description": "모든 테이블의 고수준 개요",
     "content": "테이블: customers, orders, products"},
    {"name": "customers_schema",
     "description": "customers 테이블의 전체 스키마",
     "content": "CREATE TABLE customers (id INT PK, name VARCHAR)"},
]
SKILL_MAP = {s["name"]: s for s in skills}
print(f"스킬 {len(skills)}개 정의됨.")
`````)
#output-block(`````
스킬 2개 정의됨.
`````)

#code-block(`````python
from langchain_core.tools import tool

@tool
def load_skill(skill_name: str) -> str:
    """데이터베이스 스킬에 대한 상세 정보를 로드합니다."""
    skill = SKILL_MAP.get(skill_name)
    if skill is None:
        return f"찾을 수 없음. 사용 가능: {', '.join(SKILL_MAP.keys())}"
    return f"## {skill['name']}\n\n{skill['content']}"
`````)

== 4.10 Hot Path vs Background 메모리 쓰기

메모리를 _언제_ 쓰느냐에 따라 사용자 응답 지연에 영향을 줍니다.

#table(
  columns: 4,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[방식],
  text(weight: "bold")[타이밍],
  text(weight: "bold")[즉시 사용 가능?],
  text(weight: "bold")[지연 영향],
  [_Hot path_],
  [대화 루프 내 실시간],
  [즉시 (다음 턴에 사용 가능)],
  [응답 지연 증가],
  [_Background_],
  [별도 비동기 태스크],
  [지연됨 (Eventual Consistency)],
  [지연 영향 없음],
)

=== Hot Path 쓰기
에이전트 루프 내 인라인으로 메모리를 저장합니다. 바로 다음 턴에서 해당 메모리를 써야 할 때 적합합니다. 예: 사용자가 방금 알려준 선호도를 즉시 반영해야 하는 경우.

=== Background 쓰기
별도의 프로세스나 비동기 태스크로 메모리를 저장합니다. Eventual Consistency가 허용되는 경우에 사용하며, 응답 지연에 영향을 주지 않습니다. 예: 대화 패턴 분석, 장기 학습 데이터 축적.

=== 선택 기준
- 즉시 리콜이 필요한가? -\> _Hot path_
- 지연 감소가 우선인가? -\> _Background_
- 대부분의 경우 Background 쓰기를 선호합니다

#code-block(`````python
from langgraph.store.base import BaseStore

# Hot path: write inline (adds latency)
def reflect_node(state, store: BaseStore):
    """메모리를 인라인으로 추출하고 저장합니다."""
    last_msg = state["messages"][-1].content
    store.put(("user", "reflections"), "latest", {"content": last_msg})
    return state

print("Hot path: 즉시 저장, 다음 턴에 사용 가능.")
`````)
#output-block(`````
Hot path: 즉시 저장, 다음 턴에 사용 가능.
`````)

#code-block(`````python
import asyncio

# Background: write in separate async task
async def background_memory_writer(state, store: BaseStore):
    """백그라운드에서 메모리를 저장합니다 (지연 없음)."""
    last_msg = state["messages"][-1].content
    await store.aput(
        ("user", "reflections"), "latest", {"content": last_msg}
    )
print("Background: 최종 일관성, 지연 없음.")
`````)
#output-block(`````
Background: 최종 일관성, 지연 없음.
`````)

== 4.11 프로덕션 Store — PostgreSQL

`InMemoryStore` 는 프로세스가 종료되면 데이터가 사라집니다. 프로덕션에서는 `langgraph-checkpoint-postgres` 의 `PostgresStore` 로 교체합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Store],
  text(weight: "bold")[설치],
  text(weight: "bold")[용도],
  [`InMemoryStore`],
  [`langgraph` 에 기본 포함],
  [개발·테스트·일회성 데모],
  [`PostgresStore`],
  [`pip install langgraph-checkpoint-postgres`],
  [프로덕션 — 프로세스 간 영속, 동시 에이전트, 벡터 유사도 검색, 운영 도구 지원],
)

#code-block(`````python
from langgraph.store.postgres import PostgresStore
from langchain.agents import create_agent

DB_URI = "postgresql://user:pass@localhost:5432/agentdb"

with PostgresStore.from_conn_string(
    DB_URI,
    index={"embed": embeddings, "dims": 1536},
) as store:
    store.setup()   # 최초 1회 — 테이블/인덱스 생성

    agent = create_agent(
        model="claude-sonnet-4-6",
        tools=[save_user_info, get_user_info_typed],
        context_schema=UserContext,
        store=store,
    )
`````)

#tip-box[Store 는 반드시 `create_agent(store=...)` 로 명시 주입해야 `runtime.store` 가 채워집니다. 누락 시 도구의 `runtime.store` 는 `None` 이 되어 LTM 호출이 모두 실패합니다.]

#chapter-summary-header()

=== 컨텍스트 엔지니어링 3요소

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[요소],
  text(weight: "bold")[구현],
  text(weight: "bold")[API],
  [정적 런타임],
  [`\@dataclass Context` + `context_schema=Context` + `context=Context(...)`],
  [`runtime.context.user_id`],
  [동적 런타임],
  [`state_schema=AgentState` 커스텀],
  [`state["field"]`],
  [장기 메모리],
  [`create_agent(store=store)` 명시 주입],
  [`runtime.store.put / get / search`],
)

=== 런타임 메타데이터

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[채널],
  text(weight: "bold")[필드],
  text(weight: "bold")[비고],
  [`runtime.execution_info`],
  [`thread_id`, `run_id`, `attempt`],
  [항상 채워짐],
  [`runtime.server_info`],
  [`assistant_id`, `graph_id`, `user.identity`],
  [LangGraph Server 위에서만, 로컬은 `None`],
)

=== 메모리 3유형

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[유형],
  text(weight: "bold")[용도],
  text(weight: "bold")[Namespace 예시],
  [Semantic],
  [사용자 프로필/사실],
  [`(user_id, "profile")`, `(user_id, "facts")`],
  [Episodic],
  [과거 경험 (few-shot)],
  [`(user_id, "episodes")`],
  [Procedural],
  [규칙/프롬프트 수정],
  [`(user_id, "procedures")`],
)

=== Store 선택

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[Store],
  text(weight: "bold")[설치],
  text(weight: "bold")[용도],
  [`InMemoryStore`],
  [포함],
  [개발/테스트],
  [`PostgresStore`],
  [`langgraph-checkpoint-postgres`],
  [프로덕션, 영속, 벡터 유사도],
)

=== Best Practices

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[원칙],
  text(weight: "bold")[설명],
  [정적 컨텍스트 최소화],
  [현재 태스크에 필요한 것만 포함],
  [Namespace 구조화],
  [`runtime.context.user_id` 를 namespace 에 포함],
  [TypedDict → dict 캐스트],
  [`runtime.store.put(..., dict(user_info))` 로 안전하게 직렬화],
  [시맨틱 검색 우선],
  [정확 매칭보다 임베딩 기반 검색이 확장성 우수],
  [Background 쓰기 선호],
  [즉시 리콜 불필요시 background 로 지연 감소],
  [Skills 패턴 적용],
  [대규모 컨텍스트는 Progressive Disclosure],
)
