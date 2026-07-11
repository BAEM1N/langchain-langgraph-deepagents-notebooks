// Auto-generated from 02_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "SQL 에이전트", subtitle: "자연어 데이터베이스 질의 + HITL 4-decision")

== 학습 목표
#learning-objectives([`SQLDatabaseToolkit`으로 SQL 도구 4종을 자동 생성한다], [AGENTS.md / Skills 기반 안전 규칙(READ-ONLY)을 적용한다], [HITL 4-decision(`approve` / `edit` / `reject` / `respond`)을 모두 시연한다], [`interrupt_on={"sql_db_query": {"allowed_decisions": [...]}}` 로 도구별 정책을 좁힌다], [`version="v2"` 호출과 `Command(resume={"decisions": [...]})` 재개 패턴을 익힌다])

== 개요

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[내용],
  [_프레임워크_],
  [LangChain v1 + Deep Agents],
  [_핵심 컴포넌트_],
  [`SQLDatabaseToolkit`, `SQLDatabase`, `InMemorySaver`],
  [_에이전트 패턴_],
  [AGENTS.md 안전 규칙 + Skills 기반 워크플로],
  [_HITL_],
  [`interrupt_on={"sql_db_query": {"allowed_decisions":[...]}}` + `Command(resume={"decisions":[...]})`],
  [_호출 버전_],
  [`version="v2"` — `GraphOutput` 의 `.interrupts` 필요],
  [_데이터베이스_],
  [Chinook (SQLite)],
  [_스킬_],
  [`skills/sql-agent/SKILL.md` — SQL 안전 규칙 + 쿼리 워크플로],
)

#note-box[참고: `docs/langchain/17-human-in-the-loop.md` — HITL 4-decision 사양]

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
# Observability 설정 (선택)
import os

# LangSmith — LANGSMITH_* 가 표준. LANGCHAIN_* 는 하위 호환 shim
if os.environ.get("LANGSMITH_TRACING", "").lower() == "true":
    project = os.environ.get("LANGSMITH_PROJECT", "default")
    print(f"LangSmith tracing ON — project: {os.environ['LANGSMITH_PROJECT']}")

langfuse_handler = None
if os.environ.get("LANGFUSE_SECRET_KEY"):
    from langfuse.langchain import CallbackHandler
    langfuse_handler = CallbackHandler()
    print(f"Langfuse tracing ON — {os.environ.get('LANGFUSE_HOST', '')}")
lf_config = {"callbacks": [langfuse_handler]} if langfuse_handler else {}

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI
from langchain.tools import tool

model = ChatOpenAI(model="gpt-5.4")

`````)

== 1단계: 데이터베이스 연결

Chinook은 디지털 음악 스토어의 샘플 데이터베이스입니다. Artist, Album, Track, Invoice 등의 테이블을 포함합니다.


#code-block(`````python
from langchain_community.utilities import SQLDatabase

db = SQLDatabase.from_uri("sqlite:///../05_advanced/Chinook.db")
print(f"테이블: {db.get_usable_table_names()}")

`````)
#output-block(`````
테이블: ['Album', 'Artist', 'Customer', 'Employee', 'Genre', 'Invoice', 'InvoiceLine', 'MediaType', 'Playlist', 'PlaylistTrack', 'Track']
`````)

== 2단계: SQLDatabaseToolkit 도구 생성

`SQLDatabaseToolkit`은 데이터베이스 연결에서 4개의 도구를 자동 생성합니다:

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[도구],
  text(weight: "bold")[설명],
  [`sql_db_list_tables`],
  [사용 가능한 테이블 목록 조회],
  [`sql_db_schema`],
  [테이블 스키마(DDL) 조회],
  [`sql_db_query`],
  [SQL 쿼리 실행],
  [`sql_db_query_checker`],
  [쿼리 실행 전 문법 검증],
)


#code-block(`````python
from langchain_community.agent_toolkits import SQLDatabaseToolkit

toolkit = SQLDatabaseToolkit(db=db, llm=model)
sql_tools = toolkit.get_tools()
for t in sql_tools:
    print(f"  {t.name}: {t.description[:60]}")

`````)
#output-block(`````
sql_db_query: Input to this tool is a detailed and correct SQL query, outp
  sql_db_schema: Input to this tool is a comma-separated list of tables, outp
  sql_db_list_tables: Input is an empty string, output is a comma-separated list o
  sql_db_query_checker: Use this tool to double check if your query is correct befor
`````)

== 3단계: 프롬프트 로드 (LangSmith / Langfuse / 기본값)

의  함수가 프롬프트를 로드합니다:
+ _LangSmith Hub_ — 가 있으면 Hub에서 pull
+ _Langfuse_ — 가 있으면 Langfuse에서 로드
+ _기본값_ — 둘 다 없으면 코드에 정의된 기본 프롬프트 사용

SQL 에이전트 프롬프트에는 READ-ONLY 안전 규칙과 워크플로가 포함되어 있습니다.

#code-block(`````python
from prompts import SQL_AGENT_PROMPT

print(SQL_AGENT_PROMPT)
`````)
#output-block(`````
Prompt 'rag-agent-label:production' not found during refresh, evicting from cache.

Prompt 'sql-agent-label:production' not found during refresh, evicting from cache.

Prompt 'data-analysis-agent-label:production' not found during refresh, evicting from cache.

Prompt 'ml-agent-label:production' not found during refresh, evicting from cache.

Prompt 'deep-research-agent-label:production' not found during refresh, evicting from cache.

당신은 SQL 에이전트입니다.

## 워크플로
1. sql_db_list_tables로 테이블 목록을 확인하세요
2. sql_db_schema로 관련 테이블의 스키마를 조회하세요
3. SQL 쿼리를 작성하고 sql_db_query_checker로 검증하세요
4. sql_db_query로 실행하고 결과를 해석하세요

## 안전 규칙
- READ-ONLY: SELECT만 허용. INSERT, UPDATE, DELETE, DROP 금지
- 항상 LIMIT 10을 사용하세요
- 쿼리 실행 전 반드시 스키마를 확인하세요
- 복잡한 쿼리는 write_todos로 단계별 계획을 세우세요
`````)

== 4단계: Skills 개념

Skills는 에이전트의 워크플로 가이드입니다. 반복되는 작업 패턴을 문서화하여 에이전트가 일관된 방식으로 작업하도록 합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[스킬],
  text(weight: "bold")[용도],
  [`query-writing`],
  [테이블 확인 → 스키마 조회 → SQL 작성 → 실행],
  [`schema-exploration`],
  [테이블 목록 → DDL 조회 → 관계 매핑],
)


== 5단계: 기본 SQL 에이전트 생성

`create_deep_agent`에 SQL 도구와 AGENTS.md를 전달하여 에이전트를 생성합니다. `system_prompt`로 AGENTS.md 내용을 주입합니다.


#code-block(`````python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend

agent = create_deep_agent(
    model=model,
    tools=sql_tools,
    system_prompt=SQL_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
)
`````)

#code-block(`````python
# 단순 쿼리
response = agent.invoke(
    {"messages": [{"role": "user", "content": "아티스트가 총 몇 명인가요?"}]},
    config=lf_config,
)
print(response["messages"][-1].content)

`````)
#output-block(`````
아티스트는 총 275명입니다.
`````)

#code-block(`````python
# 복합 쿼리 (write_todos 활용)
response = agent.invoke(
    {"messages": [{"role": "user", "content": "장르별 트랙 수와 평균 가격을 알려주세요. 트랙이 많은 순으로 정렬해주세요."}]},
    config=lf_config,
)
print(response["messages"][-1].content)

`````)
#output-block(`````
장르별 트랙 수와 평균 가격입니다. 트랙이 많은 순으로 정렬했습니다.

| 장르               | 트랙 수 | 평균 가격 |
|--------------------|--------|-----------|
| Rock               | 1297   | 0.99      |
| Latin              | 579    | 0.99      |
| Metal              | 374    | 0.99      |
| Alternative & Punk | 332    | 0.99      |
| Jazz               | 130    | 0.99      |
| TV Shows           | 93     | 1.99      |
| Blues              | 81     | 0.99      |
| Classical          | 74     | 0.99      |
| Drama              | 64     | 1.99      |
| R&B/Soul           | 61     | 0.99      |

모든 장르의 트랙 평균 가격은 대부분 0.99이며, TV Shows와 Drama 장르는 1.99입니다.
`````)

== 6단계: HITL 에이전트 (4-decision 정책)

`interrupt_on`은 도구별로 허용 결정을 좁힙니다. `sql_db_query`는 `approve`·`edit`·`reject`만 허용하고, 사람이 도구 역할을 하는 `ask_user`만 `respond`를 허용합니다. 모든 재개 호출은 같은 `thread_id`와 `version="v2"`를 사용합니다.

#table(
  columns: 3,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정 유형],
  text(weight: "bold")[적용 도구],
  text(weight: "bold")[동작],
  [`approve`],
  [`sql_db_query`],
  [제안한 쿼리를 그대로 실행],
  [`edit`],
  [`sql_db_query`],
  [검토한 쿼리로 바꿔 실행],
  [`reject`],
  [`sql_db_query`],
  [실행을 거부하고 피드백 전달],
  [`respond`],
  [`ask_user`],
  [사람의 답변을 성공한 ToolMessage로 반환],
)

부작용이나 쿼리를 거부할 때 `respond`를 쓰면 모델이 성공 결과로 오해할 수 있으므로 `reject`를 사용합니다.

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import ModelCallLimitMiddleware

@tool
def ask_user(question: str) -> str:
    """계속 진행하는 데 필요한 정보를 사용자에게 묻습니다."""
    return "응답 없음"

hitl_agent = create_deep_agent(
    model=model,
    tools=[*sql_tools, ask_user],
    system_prompt=SQL_AGENT_PROMPT + " 정보가 부족하면 ask_user로 확인하세요.",
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    interrupt_on={
        "sql_db_query": {"allowed_decisions": ["approve", "edit", "reject"]},
        "ask_user": {"allowed_decisions": ["respond"]},
    },
    middleware=[ModelCallLimitMiddleware(run_limit=15)],
)
`````)

#code-block(`````python
thread = {"configurable": {"thread_id": "hitl-approve"}}
result = hitl_agent.invoke(
    {"messages": [{"role": "user", "content": "고객별 총 구매 금액 상위 5명을 알려주세요."}]},
    config={**thread, **lf_config},
    version="v2",
)

# v2 호출은 GraphOutput 을 반환 — .interrupts 로 대기 중 요청 확인
print("중단 여부:", bool(result.interrupts))
for itp in result.interrupts:
    for req in itp.value.get("action_requests", []):
        print(f"  → 승인 대기 도구: {req['name']} / 인자: {req['args']}")

`````)

== 7단계: 4-decision 시연

각 결정 유형이 어떻게 동작하는지 개별 thread 에서 확인합니다.

=== 7-1. `approve` — 제안된 SQL 그대로 실행

#code-block(`````python
from langgraph.types import Command

resumed = hitl_agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config={**thread, **lf_config},
    version="v2",
)
print(resumed.value["messages"][-1].content)
`````)

=== 7-2. `edit` — SQL 인자를 수정한 뒤 실행

검토자가 더 엄격한 `LIMIT` 을 강제하거나 컬럼을 추가하고 싶을 때 사용합니다. `edited_action.args` 로 도구 인자를 덮어씁니다.

#code-block(`````python
thread_edit = {"configurable": {"thread_id": "hitl-edit"}}
result = hitl_agent.invoke(
    {"messages": [{"role": "user", "content": "고객별 총 구매 금액 상위 5명을 알려주세요."}]},
    config={**thread_edit, **lf_config},
    version="v2",
)
pending = result.interrupts[0].value["action_requests"][0]
print("원본 SQL:", pending["args"].get("query"))

# 검토자가 더 안전한 형태(LIMIT 3)로 인자를 수정해 재개
edited_query = (
    "SELECT c.FirstName || ' ' || c.LastName AS customer, "
    "ROUND(SUM(i.Total), 2) AS total "
    "FROM Customer c JOIN Invoice i ON c.CustomerId = i.CustomerId "
    "GROUP BY c.CustomerId ORDER BY total DESC LIMIT 3"
)

resumed = hitl_agent.invoke(
    Command(resume={"decisions": [{
        "type": "edit",
        "edited_action": {"name": "sql_db_query", "args": {"query": edited_query}},
    }]}),
    config={**thread_edit, **lf_config},
    version="v2",
)
print(resumed.value["messages"][-1].content)
`````)

=== 7-3. `reject` — 실행 거부 후 에이전트에 피드백

`message` 가 ToolMessage 로 추가되어 에이전트가 다음 사고에서 이를 반영합니다.

#code-block(`````python
thread_reject = {"configurable": {"thread_id": "hitl-reject"}}
result = hitl_agent.invoke(
    {"messages": [{"role": "user", "content": "Employee 테이블에서 모든 직원의 개인정보(주소, 전화번호)를 조회해주세요."}]},
    config={**thread_reject, **lf_config},
    version="v2",
)
print("거부 대상 SQL:", result.interrupts[0].value["action_requests"][0]["args"].get("query"))

resumed = hitl_agent.invoke(
    Command(resume={"decisions": [{
        "type": "reject",
        "message": "개인정보(주소·전화번호) 조회는 보안 정책상 금지. 집계 통계만 응답해 주세요.",
    }]}),
    config={**thread_reject, **lf_config},
    version="v2",
)
print(resumed.value["messages"][-1].content)
`````)

=== 7-4. `respond` — `ask_user`에 사람이 직접 답변

`respond`는 질문형 도구를 실행하지 않고 사람의 `message`를 성공한 ToolMessage로 반환합니다. 아래에서는 에이전트가 기준 시점을 묻고, 사람이 답합니다. SQL 실행을 거부하는 상황이라면 `respond`가 아니라 `reject`를 사용합니다.

#code-block(`````python
thread_resp = {"configurable": {"thread_id": "hitl-respond"}}
result = hitl_agent.invoke(
    {"messages": [{"role": "user", "content": "트랙 수를 알려주세요. 먼저 어느 기준 시점으로 볼지 저에게 물어보세요."}]},
    config={**thread_resp, **lf_config},
    version="v2",
)
request = result.interrupts[0].value["action_requests"][0]
print("질문형 도구:", request["name"], request["args"])

resumed = hitl_agent.invoke(
    Command(resume={"decisions": [{
        "type": "respond",
        "message": "현재 데이터베이스 시점을 기준으로 답해주세요.",
    }]}),
    config={**thread_resp, **lf_config},
    version="v2",
)
print(resumed.value["messages"][-1].content)
`````)

#chapter-summary-header()

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[항목],
  text(weight: "bold")[핵심],
  [_도구 생성_],
  [`SQLDatabaseToolkit(db, llm).get_tools()` → 4개 SQL 도구 자동 생성],
  [_안전 규칙_],
  [Skills + 프롬프트로 READ-ONLY 정책 적용],
  [_HITL 정책_],
  [SQL은 `approve/edit/reject`, `ask_user`는 `respond`만 허용],
  [_HITL 호출_],
  [`version="v2"` → `GraphOutput.interrupts` → `Command(resume={"decisions":[...]})`],
)


#references-box[
- `docs/langchain/17-human-in-the-loop.md` — HITL 결정 의미와 `version="v2"` 사양
- `docs/deepagents/examples/03-text-to-sql-agent.md`
- #link("https://docs.langchain.com/oss/python/langchain/sql-agent")[LangChain SQL Agent Tutorial]
_다음 단계:_ → #link("./03_data_analysis_agent.ipynb")[03_data_analysis_agent.ipynb]: 데이터 분석 에이전트를 구축합니다.
]
#chapter-end()
