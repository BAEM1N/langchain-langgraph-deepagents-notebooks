// Auto-generated from 02_sql_agent.ipynb
// Do not edit manually -- regenerate with nb2typ.py
#import "../../template.typ": *
#import "../../metadata.typ": *

#chapter(2, "SQL 에이전트", subtitle: "자연어 데이터베이스 질의")

이전 장에서 구축한 RAG 에이전트가 비정형 문서를 검색했다면, SQL 에이전트는 관계형 데이터베이스의 정형 데이터에 접근합니다. 자연어를 SQL 쿼리로 변환하는 에이전트는 비개발자도 데이터베이스에 접근할 수 있게 하는 대표적인 실전 응용입니다. 이 장에서는 `SQLDatabaseToolkit`으로 도구를 자동 생성하고, `AGENTS.md` 기반 안전 규칙으로 READ-ONLY 제약을 적용하며, `HumanInTheLoopMiddleware`로 쿼리 실행 전 사용자 승인을 구현합니다.

#learning-header()
#learning-objectives([SQLDatabaseToolkit으로 SQL 도구를 자동 생성한다], [AGENTS.md 기반 안전 규칙(READ-ONLY)을 적용한다], [HITL(Human-in-the-Loop) interrupt로 쿼리 실행 전 승인을 구현한다], [v1 미들웨어(HumanInTheLoopMiddleware, ModelCallLimitMiddleware)를 명시적으로 적용한다])

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
  [LangChain + Deep Agents],
  [_핵심 컴포넌트_],
  [SQLDatabaseToolkit, SQLDatabase, InMemorySaver],
  [_에이전트 패턴_],
  [AGENTS.md 안전 규칙 + Skills 기반 워크플로],
  [_HITL_],
  [`interrupt_on` + `Command(resume="approve")`],
  [_데이터베이스_],
  [Chinook (SQLite)],
  [_스킬_],
  [`skills/sql-agent/SKILL.md` — SQL 안전 규칙 + 쿼리 워크플로],
)

#code-block(`````python
from dotenv import load_dotenv
import os

load_dotenv()
assert os.environ.get("OPENAI_API_KEY"), "OPENAI_API_KEY를 .env에 설정하세요"

`````)

#code-block(`````python
from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4.1")

`````)

SQL 에이전트의 구현은 _스키마 탐색 → 쿼리 생성 → 검증 → 실행 → 결과 해석_의 워크플로를 따릅니다. `SQLDatabaseToolkit`이 이 워크플로에 필요한 4개 도구를 자동으로 생성해 주므로, 에이전트 구현에 집중할 수 있습니다.

== 1단계: 데이터베이스 연결

Chinook은 디지털 음악 스토어의 샘플 데이터베이스입니다. Artist, Album, Track, Invoice 등의 테이블을 포함합니다. `SQLDatabase.from_uri()`는 SQLAlchemy의 연결 문자열을 받아 데이터베이스에 연결하며, 테이블 메타데이터를 자동으로 반영(reflect)합니다. SQLite, PostgreSQL, MySQL 등 SQLAlchemy가 지원하는 모든 데이터베이스를 동일한 인터페이스로 사용할 수 있습니다.

#warning-box[프로덕션에서는 `SQLDatabase.from_uri()`에 _읽기 전용 사용자_의 연결 문자열을 사용해야 합니다. 시스템 프롬프트의 "DML 금지" 지시만으로는 안전하지 않습니다 -- LLM은 지시를 무시할 수 있으므로, DB 레벨에서 `GRANT SELECT ON ...` 권한만 부여하는 것이 근본적인 안전장치입니다.]


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

프롬프트가 에이전트의 _기본 행동 규칙_을 정의한다면, Skills는 특정 작업 수행 시 참조할 수 있는 _전문 지침_을 제공합니다. Skills의 핵심은 _필요한 시점에만 로드_된다는 것입니다.

== 4단계: Skills 개념

Skills는 에이전트의 워크플로 가이드입니다. Part 5 ch04에서 학습한 Progressive Disclosure 패턴의 실전 적용입니다. 에이전트가 SQL 작업을 수행할 때 참조할 수 있는 구조화된 지침을 제공합니다. 반복되는 작업 패턴을 문서화하여 에이전트가 일관된 방식으로 작업하도록 합니다.

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

도구, 프롬프트, Skills가 모두 준비되었으니 에이전트를 조립합니다. `create_deep_agent`에 SQL 도구와 시스템 프롬프트를 전달하여 에이전트를 생성합니다. `FilesystemBackend`는 에이전트가 분석 결과나 쿼리 이력을 파일로 저장할 수 있도록 파일시스템 접근을 제공합니다.

#tip-box[SQL 에이전트의 시스템 프롬프트에 현재 DB의 dialect(SQLite, PostgreSQL 등)를 명시하면 LLM이 해당 방언에 맞는 SQL 구문을 생성합니다. 예를 들어, SQLite에서는 `LIMIT`을, SQL Server에서는 `TOP`을, Oracle에서는 `ROWNUM`을 사용하도록 안내할 수 있습니다.]


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

기본 에이전트가 동작하는 것을 확인했습니다. 프로덕션에서는 에이전트가 생성한 SQL 쿼리를 실행하기 전에 _반드시 사람이 검토_해야 합니다. 의도하지 않은 대규모 조인이나 민감 데이터 접근을 사전에 차단하기 위해서입니다.

기본 에이전트가 동작하는 것을 확인했습니다. 이제 프로덕션에서 가장 중요한 안전 장치인 Human-in-the-Loop을 적용합니다. 에이전트가 생성한 SQL 쿼리가 의도하지 않은 대규모 조인이나 민감 데이터 접근을 포함할 수 있으므로, 실행 전 사람의 검토가 필수입니다.

== 6단계: HITL 에이전트 (interrupt_on)

`create_deep_agent`의 `interrupt_on` 파라미터로 도구별 승인 정책을 설정합니다. `sql_db_query` 도구만 중단 대상으로 지정하면, 테이블 목록 조회나 스키마 조회 같은 안전한 작업은 자동으로 진행되고, 실제 데이터를 반환하는 쿼리 실행 단계에서만 사람의 승인을 요청합니다. `sql_db_query` 호출 전에 실행이 중단되고, `Command(resume=...)`로 재개합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[파라미터],
  text(weight: "bold")[역할],
  [`interrupt_on={"sql_db_query": True}`],
  [`sql_db_query` 호출 전 실행 중단, 사람 승인 대기],
  [`ModelCallLimitMiddleware`],
  [무한 루프 방지 — 최대 15회 모델 호출 제한],
  [`InMemorySaver`],
  [체크포인팅으로 중단/재개 지원],
)

#code-block(`````python
from langgraph.checkpoint.memory import InMemorySaver
from langchain.agents.middleware import ModelCallLimitMiddleware

hitl_agent = create_deep_agent(
    model=model,
    tools=sql_tools,
    system_prompt=SQL_AGENT_PROMPT,
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["/skills/"],
    checkpointer=InMemorySaver(),
    interrupt_on={"sql_db_query": True},
    middleware=[
        ModelCallLimitMiddleware(run_limit=15),
    ],
)
`````)

== 7단계: 승인 후 재개

에이전트가 `sql_db_query`를 호출하려 하면 실행이 중단됩니다. 이 시점에서 사용자는 에이전트가 생성한 SQL 쿼리를 검토할 수 있습니다. 쿼리가 적절하면 승인하고, 수정이 필요하면 수정된 쿼리를 전달하며, 부적절하면 거부 사유와 함께 거부합니다. 거부 시 에이전트는 사유를 참고하여 새로운 쿼리를 생성할 수 있습니다.

#warning-box[HITL 패턴을 사용할 때 반드시 `InMemorySaver` 등의 체크포인터를 설정해야 합니다. 체크포인터 없이 `interrupt_on`을 설정하면 실행 중단 후 상태가 소실되어 재개가 불가능합니다. 프로덕션에서는 `PostgresSaver`를 사용하여 서버 재시작 후에도 중단된 세션을 재개할 수 있도록 하세요.] 사람이 쿼리를 검토한 후 `Command(resume=...)`로 승인, 수정, 또는 거부를 결정합니다. v1에서는 `HITLResponse` 형식으로 결정을 전달합니다.

#table(
  columns: 2,
  align: left,
  stroke: 0.5pt + luma(200),
  inset: 8pt,
  fill: (_, row) => if row == 0 { rgb("#E0F2F3") } else if calc.odd(row) { luma(248) } else { white },
  text(weight: "bold")[결정 유형],
  text(weight: "bold")[설명],
  [`{"type": "approve"}`],
  [도구 호출 승인 — 그대로 실행],
  [`{"type": "edit", "edited_action": {...}}`],
  [도구 호출 수정 후 실행],
  [`{"type": "reject", "message": "..."}`],
  [도구 호출 거부 — 에이전트에 피드백],
)

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
  [AGENTS.md로 READ-ONLY 정책 적용],
  [_Skills_],
  [query-writing, schema-exploration 워크플로 가이드],
  [_HITL_],
  [`interrupt_on={"sql_db_query": True}` → `Command(resume="approve")`],
)


#references-box[
- `docs/deepagents/examples/03-text-to-sql-agent.md`
- #link("https://python.langchain.com/docs/tutorials/sql_qa/")[LangChain SQL Agent Tutorial]
- `docs/deepagents/06-backends.md`
_다음 단계:_ → #link("./03_data_analysis_agent.ipynb")[03_data_analysis_agent.ipynb]: 데이터 분석 에이전트를 구축합니다.
]
#chapter-end()
