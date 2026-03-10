// Auto-generated from 04_context_memory.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(4, "컨텍스트 엔지니어링 & 메모리 심화", subtitle: "- Static/Dynamic Context, InMemoryStore, Skills 패턴")

앞선 장들에서 미들웨어, 서브에이전트, Handoffs, Router를 학습하며 에이전트의 _실행 흐름_을 제어하는 방법을 익혔습니다. 이 장에서는 에이전트 성능의 또 다른 축인 _정보 관리_에 집중합니다. LangGraph의 컨텍스트 시스템과 장기 메모리(Store)를 심층 학습합니다. 정적/동적 런타임 컨텍스트부터 시맨틱 검색 기반 장기 메모리, 그리고 Progressive Disclosure(Skills) 패턴까지 다룹니다.

#learning-header()
#learning-objectives([컨텍스트 엔지니어링의 2차원(Mutability x Lifetime) 매트릭스를 이해한다], [`context_schema` + `@dataclass`로 정적 런타임 컨텍스트를 구현한다], [`state_schema`와 `AgentState` 커스텀으로 동적 런타임 컨텍스트를 관리한다], [`InMemoryStore`의 namespace, put, get, search API를 활용한다], [시맨틱 검색 기반 장기 메모리를 구축한다], [메모리 3유형(Semantic, Episodic, Procedural)을 구분하여 설계한다], [Skills 패턴으로 Progressive Disclosure를 구현한다], [Hot path vs Background 메모리 쓰기 전략을 비교한다])

== 4.1 환경 설정

#code-block(`````python
from dotenv import load_dotenv
load_dotenv(override=True)

from langchain_openai import ChatOpenAI, OpenAIEmbeddings

model = ChatOpenAI(model="gpt-4.1")
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
print("환경 준비 완료.")
`````)
#output-block(`````
환경 준비 완료.
`````)

환경이 준비되었으므로, 컨텍스트 엔지니어링의 개념 프레임워크부터 학습합니다. 이 프레임워크는 이후 모든 구현의 이론적 토대가 됩니다.

== 4.2 컨텍스트 엔지니어링 개요

컨텍스트 엔지니어링은 _"올바른 정보를, 올바른 형식으로, 올바른 시점에"_ AI에 제공하는 시스템 설계입니다. 단순한 프롬프트 엔지니어링을 넘어, 컨텍스트를 _런타임에 프로그래밍 방식으로 조립_하는 아키텍처적 접근입니다. 프롬프트 엔지니어링이 "무엇을 말할지"에 집중한다면, 컨텍스트 엔지니어링은 "어떤 정보를 언제, 어떻게 조립하여 제공할지"에 집중합니다.

에이전트가 실패하는 주된 원인은 두 가지입니다:
+ LLM 능력 부족
+ _컨텍스트 부족 또는 부적절한 컨텍스트_ (더 빈번한 원인)

실제로 GPT-4 수준의 모델도 필요한 정보가 컨텍스트에 없으면 올바른 답을 생성할 수 없습니다. 반면, 적절한 컨텍스트가 주어지면 비교적 작은 모델도 놀라운 성능을 보입니다. 따라서 컨텍스트 엔지니어링은 AI 엔지니어의 핵심 역할이며, 에이전트 신뢰성의 근본적인 해결책입니다.

=== 2차원 매트릭스: Mutability x Lifetime

#align(center)[#image("../../assets/diagrams/png/context_matrix_guide.png", width: 86%, height: 96mm, fit: "contain")]

이 다이어그램은 표의 행과 열을 _"언제 바뀌는가"_ 와 _"얼마나 오래 유지되는가"_ 라는 두 질문으로 다시 읽게 해 줍니다. 정리하면 다음 3줄 규칙으로 기억하면 됩니다:

+ _Static Runtime_ — 한 번의 실행 동안 고정되어야 하는 정보
+ _Dynamic Runtime_ — 실행 중 계속 변하는 작업 상태와 중간 결과
+ _Store_ — 다음 대화에서도 다시 써야 하는 장기 메모리

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

LangChain은 _미들웨어(middleware)_ 메커니즘으로 컨텍스트 엔지니어링을 구현합니다. `@dynamic_prompt`, `@wrap_model_call` 등의 미들웨어로 컨텍스트를 업데이트하거나 라이프사이클 단계 간 제어를 할 수 있습니다. Chapter 1에서 학습한 미들웨어가 여기서 컨텍스트 관리의 핵심 도구로 활용됩니다.

#tip-box[컨텍스트 엔지니어링의 3가지 타입(Static Runtime, Dynamic Runtime, Cross-conversation)은 상호 배타적이 아닙니다. 하나의 에이전트에서 세 가지를 모두 사용하는 것이 일반적이며, 각 타입은 서로 다른 종류의 정보를 담당합니다.]

개념 프레임워크를 이해했으니, 이제 각 컨텍스트 타입을 구체적인 코드로 구현해 보겠습니다. 가장 단순한 정적 런타임 컨텍스트부터 시작합니다.

== 4.3 정적 런타임 컨텍스트 -- `context_schema` + `\@dataclass`

에이전트 실행 중 _변하지 않는_ 정보를 `context_schema`로 주입합니다. "변하지 않는다"는 것은 `invoke()` 호출 시 설정된 값이 해당 실행 전체에 걸쳐 고정된다는 의미입니다. 동일한 에이전트를 다른 사용자에 대해 호출할 때는 다른 컨텍스트를 전달합니다. `@dataclass`로 스키마를 정의하고, 도구에서 `ToolRuntime[Context]`로 접근합니다.

다음 코드는 사용자 정보를 정적 컨텍스트로 정의하고, 도구에서 이를 활용하는 패턴입니다.

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

정적 컨텍스트는 실행 중 불변이므로 안전하고 예측 가능합니다. 그러나 에이전트가 도구를 호출하면서 중간 결과를 축적해야 하는 경우에는 동적 상태가 필요합니다.

== 4.4 동적 런타임 컨텍스트 -- `state_schema`, `AgentState` 커스텀

정적 컨텍스트가 "누가 요청했는가"를 다룬다면, 동적 런타임 컨텍스트는 "지금까지 무엇이 일어났는가"를 추적합니다. 에이전트가 메시지를 처리하고 도구를 호출하면서 _변화하는_ 상태입니다. `AgentState`를 상속하여 커스텀 필드를 추가합니다.

#warning-box[`AgentState`의 기본 필드(`messages`, `jump_to`, `structured_response`)는 시스템이 사용하는 예약 필드입니다. 커스텀 필드를 추가할 때 이 이름들과 충돌하지 않도록 주의하세요.]

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

정적 컨텍스트와 동적 상태는 모두 _단일 실행(run)_ 범위입니다. 하지만 사용자의 선호도, 과거 상호작용 패턴, 학습된 규칙 등은 여러 대화 세션에 걸쳐 지속되어야 합니다. 이를 위해 LangGraph는 `InMemoryStore`를 제공합니다.

정적 컨텍스트와 동적 상태는 모두 _단일 실행(run)_ 범위입니다. 에이전트를 종료하면 상태가 사라집니다. 그러나 "이 사용자는 Python을 선호한다", "지난번에 pytest 관련 질문을 했다" 같은 정보는 세션을 넘어 지속되어야 합니다. 이를 위해 LangGraph는 장기 메모리 시스템을 제공합니다.

== 4.5 장기 메모리 -- InMemoryStore 기본 API

Cross-conversation 컨텍스트를 위해 `InMemoryStore`를 사용합니다. 장기 메모리는 세션과 스레드를 초월하여 지속되는 사용자별 또는 앱 수준의 데이터입니다. 이는 인간의 장기 기억에 해당하며, 에이전트가 사용자에 대해 "학습"한 내용을 영구적으로 보존합니다.

=== 저장 구조
메모리는 _JSON 문서_ 형태로 저장되며, 계층적 _namespace_로 조직화됩니다:
- _namespace_: 메모리를 분류하는 폴더 역할 (예: `(user_id, "preferences")`)
- _key_: 각 메모리의 고유 식별자 (예: `"theme"`)
- 네임스페이스에는 보통 사용자 ID나 조직 ID를 포함하여 정보 관리를 용이하게 합니다

=== 기본 API

#align(center)[#image("../../assets/diagrams/png/memory_write_paths.png", width: 86%, height: 96mm, fit: "contain")]

핵심은 _읽기 경로_ 와 _쓰기 경로_ 를 분리해서 보는 것입니다. 현재 답변에 즉시 필요한 정보는 hot path에서 state로 반영하고, 장기적으로 축적할 내용만 background 경로를 통해 Store에 기록하면 토큰 비용과 지연 시간을 함께 관리할 수 있습니다.

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

#warning-box[`InMemoryStore`는 프로세스 메모리에 데이터를 저장하므로, 서버 재시작 시 모든 데이터가 유실됩니다. 프로덕션 환경에서는 반드시 _DB 기반 Store_ (예: PostgreSQL)를 사용해야 합니다. `InMemoryStore`는 개발과 테스트 용도로만 사용하세요.]

다음 코드는 `InMemoryStore`의 기본 CRUD 작업(put, get, search)을 보여줍니다.

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

키 기반 조회는 정확한 키를 알아야만 메모리에 접근할 수 있습니다. 그러나 에이전트가 "이 사용자는 어떤 테스팅 방법을 좋아하는가?"처럼 의미 기반으로 관련 메모리를 찾아야 하는 경우, 시맨틱 검색이 필요합니다.

키 기반 조회는 정확한 키를 알아야만 메모리에 접근할 수 있습니다. 그러나 에이전트가 "이 사용자는 어떤 테스팅 방법을 좋아하는가?"처럼 _의미_ 기반으로 관련 메모리를 찾아야 하는 경우, 정확한 키를 미리 알 수 없습니다. 이때 시맨틱 검색이 필요합니다.

== 4.6 장기 메모리 -- 시맨틱 검색

임베딩 함수를 설정하면 `InMemoryStore`가 _시맨틱 검색_을 지원합니다. 시맨틱 검색은 텍스트를 벡터로 변환한 후 코사인 유사도로 관련 메모리를 찾는 방식입니다. `query` 파라미터로 의미 기반 유사도 검색을 수행합니다. 키워드가 정확히 일치하지 않아도, 의미적으로 관련 있는 메모리를 찾을 수 있습니다.

다음 코드에서 "testing preferences"라는 쿼리로 검색하면, "pytest를 unittest보다 선호"라는 메모리가 반환됩니다. "testing"이나 "preferences"라는 단어가 메모리에 없어도, 의미적 유사성으로 매칭됩니다.

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

시맨틱 검색의 원리를 이해했으니, 이제 실제 에이전트의 도구에서 Store를 활용하는 방법을 살펴보겠습니다. 에이전트가 대화 중에 사용자 정보를 읽고 학습하는 핵심 메커니즘입니다.

== 4.7 도구에서 Store 읽기/쓰기 -- `ToolRuntime.store`

에이전트의 도구 내에서 Store에 접근하여 사용자 정보를 읽고 쓸 수 있습니다. `create_agent(store=...)`로 Store를 연결하면 `runtime.store`로 자동 주입됩니다. 이를 통해 도구는 "이 사용자에 대해 이전에 무엇을 배웠는가?"를 조회하고, "새로 알게 된 정보"를 저장할 수 있습니다.

=== 읽기 패턴
도구에서 `runtime.store`를 통해 저장된 사용자 정보를 조회합니다. `ToolRuntime[Context]` 타입힌트로 컨텍스트와 Store 모두에 접근할 수 있습니다.

=== 쓰기 패턴
도구 파라미터로 사용자 입력을 받아 `store.put()`으로 메모리를 저장합니다. 이를 통해 에이전트가 대화 중 학습한 정보를 영구 저장할 수 있습니다.

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

Store의 읽기/쓰기 메커니즘을 이해했으니, 이제 장기 메모리를 _어떤 구조로_ 조직할 것인지에 대한 체계를 살펴보겠습니다. 무작정 메모리를 저장하면 관리가 어려워지므로, 인지과학에서 영감을 받은 분류 체계를 적용합니다.

== 4.8 메모리 3유형: Semantic, Episodic, Procedural

장기 메모리는 인지과학에서 영감을 받은 세 가지 유형으로 분류됩니다. 인간의 기억이 "아는 것(Semantic)", "경험한 것(Episodic)", "할 줄 아는 것(Procedural)"으로 나뉘듯, 에이전트의 메모리도 동일하게 분류합니다. 각 유형에 따라 _저장 구조_와 _활용 방식_이 다릅니다.

#tip-box[세 유형의 메모리를 네임스페이스로 분리하면 관리가 용이해집니다. `(user_id, "profile")`, `(user_id, "episodes")`, `(user_id, "procedures")` 처럼 유형별 네임스페이스를 사용하세요. 검색할 때도 관련 유형의 네임스페이스만 조회하면 되므로 효율적입니다.]

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

지금까지 컨텍스트의 _저장과 검색_을 다뤘습니다. 마지막으로 중요한 질문은 "저장된 컨텍스트를 _언제, 얼마나_ 에이전트에게 노출할 것인가"입니다. Skills 패턴은 이 문제에 대한 우아한 해결책입니다.

지금까지 컨텍스트의 _저장과 검색_을 다뤘습니다. 마지막으로 중요한 질문은 "저장된 컨텍스트를 _언제, 얼마나_ 에이전트에게 노출할 것인가"입니다. 모든 정보를 항상 프롬프트에 넣는 것은 비효율적이고 역효과를 낼 수 있습니다.

== 4.9 Progressive Disclosure -- Skills 패턴

모든 컨텍스트를 프롬프트에 넣으면 토큰 비용이 증가하고 정확도가 떨어집니다. 이를 "컨텍스트 과부하(context overload)"라고 합니다. 연구에 따르면 프롬프트가 길어질수록 LLM의 주의력이 분산되어, 중간에 위치한 정보를 놓치는 "Lost in the Middle" 현상이 발생합니다. Skills 패턴은 _필요할 때만 관련 정보를 로드_하는 Progressive Disclosure 방식으로, 이 문제를 우아하게 해결합니다.

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

Skills 패턴으로 컨텍스트를 필요한 시점에 로드하는 방법을 배웠습니다. 마지막으로 남은 설계 결정은, 새로운 메모리를 _언제_ 저장할 것인가입니다. 이 결정은 사용자 경험(응답 속도)에 직접적인 영향을 미칩니다.

#note-box[실무에서는 먼저 `_이 정보가 다음 턴에도 필요할까?_`를 묻고, 그렇다면 Store로, 아니면 state로 둡니다. `_지금 답변 전에 꼭 필요할까?_`까지 예라고 답하면 hot path, 아니면 background 작업으로 미루는 것이 가장 안전한 기본 전략입니다.]

== 4.10 Hot Path vs Background 메모리 쓰기

메모리를 _언제_ 쓰느냐에 따라 사용자 응답 지연에 영향을 미칩니다. 이는 분산 시스템에서의 _일관성(Consistency) vs 가용성(Availability)_ 트레이드오프와 유사합니다.

#warning-box[Hot path 쓰기는 응답 지연을 증가시키므로, 반드시 필요한 경우에만 사용하세요. "사용자가 방금 알려준 이름을 다음 응답에서 바로 사용해야 하는 경우"처럼, 즉시 리콜이 필수적인 상황으로 한정합니다.]

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
에이전트 루프 내 인라인으로 메모리를 저장합니다. 바로 다음 턴에서 해당 메모리를 사용해야 할 때 적합합니다. 예: 사용자가 방금 알려준 선호도를 즉시 반영해야 하는 경우.

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
  [`context_schema` + `\@dataclass`],
  [`runtime.context.field`],
  [동적 런타임],
  [`state_schema` + `AgentState`],
  [`state["field"]`],
  [장기 메모리],
  [`InMemoryStore` + `store=`],
  [`store.put/get/search`],
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
  [충돌 방지를 위해 계층적 namespace 사용],
  [시맨틱 검색 우선],
  [정확 매칭보다 임베딩 기반 검색이 확장성 우수],
  [Background 쓰기 선호],
  [즉시 리콜 불필요시 background로 지연 감소],
  [Skills 패턴 적용],
  [대규모 컨텍스트는 Progressive Disclosure],
)

컨텍스트 엔지니어링은 에이전트의 _지능의 기반_입니다. 올바른 정보를 적시에 제공하는 것이 모델 선택보다 더 큰 영향을 미칩니다. 다음 장에서는 이 컨텍스트 엔지니어링을 실전에 적용하는 첫 번째 사례로, RAG 파이프라인을 심층적으로 다룹니다.


